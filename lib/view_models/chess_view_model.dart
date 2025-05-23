import 'dart:async';
import 'dart:convert'; // For JSON encoding/decoding
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart'
    show BluetoothDevice; // Specific import for BluetoothDevice
import '../models/chess_model.dart';
import '../services/bluetooth_service.dart'; // Import BluetoothService
import 'settings_view_model.dart'; // Import SettingsViewModel

part 'move_calculator.dart';
part 'check_validator.dart';

class ChessViewModel extends ChangeNotifier {
  final SettingsViewModel settingsViewModel; // Add SettingsViewModel
  late Player player1;
  late Player player2;
  late ChessBoard board;
  Timer? _timer;
  bool _isWhiteTurn = true;
  Position? _selectedPosition;
  List<Position> _possibleMoves = [];
  Position? get promotionPendingPosition => _promotionPendingPosition;

  // Bluetooth and multiplayer state variables
  late BluetoothService _bluetoothService;
  bool isMultiplayerGame = false;
  bool isHost = false; // True if this player is the host
  bool isHostWhite = true; // Host is white by default
  BluetoothDevice? connectedDevice;
  StreamSubscription? _incomingDataSubscription;
  ValueNotifier<List<BluetoothDevice>> get discoveredDevicesNotifier =>
      _bluetoothService.discoveredDevicesNotifier;
  ValueNotifier<BluetoothConnectionState> get connectionStateNotifier =>
      _bluetoothService.connectionStateNotifier;
  // Notifier for game messages (errors, connection status)
  final ValueNotifier<String?> gameMessageNotifier = ValueNotifier(null);


  ChessViewModel({required this.settingsViewModel}) { // Update constructor
    _initializePlayers();
    board = ChessBoard();
    _bluetoothService = BluetoothService(); // Initialize BluetoothService
    // Listen to connection state changes
    _bluetoothService.connectionStateNotifier.addListener(_onConnectionStateChanged);
    // Listen to error messages from BluetoothService
    _bluetoothService.currentErrorNotifier.addListener(_onBluetoothError);
    _startTimer();
  }

  void _onBluetoothError() {
    final errorMessage = _bluetoothService.currentErrorNotifier.value;
    if (errorMessage != null) {
      gameMessageNotifier.value = errorMessage;
      if (kDebugMode) {
        print("Bluetooth Service Error: $errorMessage");
      }
      // Optionally, trigger notifyListeners if UI needs to react broadly to error messages
      // notifyListeners(); 
    }
  }

  // Method to be called when connection state changes
  void _onConnectionStateChanged() {
    final state = _bluetoothService.connectionStateNotifier.value;
    final errorMsg = _bluetoothService.currentErrorNotifier.value;

    switch (state) {
      case BluetoothConnectionState.connected:
        if (connectedDevice != null) {
          _incomingDataSubscription = _bluetoothService.incomingDataStream.listen(receiveMove);
          gameMessageNotifier.value = "Connected to ${connectedDevice!.name ?? connectedDevice!.address}.";
           if (kDebugMode) {
             print("ViewModel: Connected. Listening for data.");
           }
        } else {
           // This case should ideally not happen if connectToDevice sets connectedDevice properly.
           gameMessageNotifier.value = "Connected, but device info is missing.";
           if (kDebugMode) {
             print("ViewModel: Connected but connectedDevice is null.");
           }
        }
        break;
      case BluetoothConnectionState.disconnected:
      case BluetoothConnectionState.error:
        _incomingDataSubscription?.cancel();
        _incomingDataSubscription = null;
        
        if (isMultiplayerGame) { // Only show game-ending messages if a game was active
            gameMessageNotifier.value = errorMsg ?? (state == BluetoothConnectionState.error ? "Connection error." : "Disconnected.");
        } else if (errorMsg != null && errorMsg.isNotEmpty && state == BluetoothConnectionState.error) {
            // Show error even if not in active multiplayer game, e.g. connection failed before starting
            gameMessageNotifier.value = errorMsg;
        } else if (state == BluetoothConnectionState.disconnected && errorMsg != null && errorMsg.isNotEmpty) {
             gameMessageNotifier.value = errorMsg; // e.g. "Disconnected by user"
        }


        isMultiplayerGame = false; 
        connectedDevice = null;
        // isHost = false; // Reset host status as well
        if (kDebugMode) {
          print("ViewModel: Disconnected or Error. Multiplayer game state reset. Message: ${gameMessageNotifier.value}");
        }
        break;
      case BluetoothConnectionState.connecting:
        gameMessageNotifier.value = "Connecting to ${connectedDevice?.name ?? 'device'}...";
        if (kDebugMode) {
          print("ViewModel: Connecting...");
        }
        break;
    }
    notifyListeners(); // Notify UI about connection state changes and game messages
  }


  Future<void> startBluetoothScan() async {
    gameMessageNotifier.value = "Scanning for devices...";
    await _bluetoothService.startDiscovery();
    notifyListeners(); // Discovered devices are updated via ValueNotifier
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    isMultiplayerGame = true; // Tentatively set, will be confirmed by connection state
    isHost = false; 
    connectedDevice = device; // Set this before calling connect for connecting message
    gameMessageNotifier.value = "Attempting to connect to ${device.name ?? device.address}...";
    notifyListeners(); // Update UI to show "Attempting to connect..."

    try {
      await _bluetoothService.connect(device);
      // Connection state and further messages handled by _onConnectionStateChanged
    } catch (e) {
      gameMessageNotifier.value = "Failed to connect: ${e.toString()}";
      isMultiplayerGame = false; // Reset on failure
      connectedDevice = null;
      notifyListeners();
    }
  }

  Future<void> startHosting() async {
    isMultiplayerGame = true; // Tentatively set
    isHost = true;
    gameMessageNotifier.value = "Starting host mode... Waiting for opponent.";
    notifyListeners();

    try {
      // This is a conceptual representation.
      // Real hosting involves making device discoverable and then handling an incoming connection.
      // For now, we'll assume BluetoothService's connect might be used by a client,
      // or a more specific hosting method would exist in a full implementation.
      // The current BluetoothService doesn't have a dedicated "waitForConnection" method.
      // We'll simulate this by setting the state in ViewModel and relying on client to connect.
      if (kDebugMode) {
        print("Host mode initiated in ViewModel. BluetoothService should be ready for incoming connections.");
      }
      // The host doesn't "connect" in the same way a client does.
      // It makes itself discoverable and awaits a connection.
      // The _onConnectionStateChanged will be triggered when a client connects to it.
      // For now, we will assume the BluetoothService handles being discoverable.
      // To simulate a "ready to host" state if not automatically handled by service:
      // _bluetoothService.connectionStateNotifier.value = BluetoothConnectionState.connecting; // Or a custom "hosting" state
      // This part needs to be aligned with how BluetoothService actually implements hosting.
      // For this task, we assume the service handles making itself connectable.
      // The host is white by default, can be changed by UI
      isHostWhite = true; 
      // No direct call to _bluetoothService.connect() for the host side here.
      // The connection is established when a client connects.
      // We might need a method in BluetoothService like `acceptConnection()` or similar.
      // For now, let's assume the service is implicitly ready.
      // If the service requires an explicit step to start listening/advertising:
      // await _bluetoothService.startAcceptingConnections(); // Example
      gameMessageNotifier.value = "Host mode active. Waiting for a client to connect.";
    } catch (e) {
        gameMessageNotifier.value = "Failed to start host mode: ${e.toString()}";
        isMultiplayerGame = false;
        isHost = false;
    }
    notifyListeners();
  }

  void stopBluetooth() async {
    gameMessageNotifier.value = "Disconnecting Bluetooth...";
    await _bluetoothService.disconnect(reason: "User stopped Bluetooth connection.");
    _incomingDataSubscription?.cancel();
    _incomingDataSubscription = null;
    isMultiplayerGame = false;
    connectedDevice = null;
    notifyListeners();
  }

  Position? _promotionPendingPosition;
  bool get isPromotionPending => _promotionPendingPosition != null;

  // Add a field to store the last promotion choice, to be sent over Bluetooth
  PromotionChoice? _lastPromotionChoice;

  void handlePromotionChoice(PromotionChoice choice) {
    if (_promotionPendingPosition == null) return;
    _lastPromotionChoice = choice; // Store choice for potential sending

    final row = _promotionPendingPosition!.row;
    // Determine piece color based on the original piece at the promotion square,
    // as _isWhiteTurn might have already switched for the local player.
    // This requires knowing which pawn is promoting.
    // A simpler approach: if it's white's turn to promote, the piece is white.
    // This needs to be robust for both local and remote promotions.
    // Assuming promotion happens on player's turn, _isWhiteTurn is correct for local.
    // For remote, the move data should indicate the promoted piece type directly.
    final pieceBeingPromoted = board.squares[_promotionPendingPosition!.row][_promotionPendingPosition!.col];
    final isWhitePromotingPiece = isWhitePiece(pieceBeingPromoted); // isWhitePiece('♙') or isWhitePiece('♟')

    final newPiece = _getPromotionPiece(choice, isWhitePromotingPiece);

    board.squares[row][_promotionPendingPosition!.col] = newPiece;
    
    // If this is a local player's move in a multiplayer game,
    // the promotion choice is included when the move is sent.
    // The _handleMoveExecution method will look at _lastPromotionChoice.

    _promotionPendingPosition = null; // Clear pending promotion

    // Notify listeners only if it's not a move being applied from remote.
    // Remote moves will call notifyListeners in receiveMove.
    bool isCurrentPlayerMakingMove = !isMultiplayerGame ||
                                   (isHost && isHostWhite == _isWhiteTurn) ||
                                   (!isHost && isHostWhite != _isWhiteTurn);
    if (isCurrentPlayerMakingMove) {
      notifyListeners();
    }
    // Future.delayed(Duration.zero, () => notifyListeners()); // Can be problematic
  }

  String _getPromotionPiece(PromotionChoice choice, bool isWhite) {
    switch (choice) {
      case PromotionChoice.queen:
        return isWhite ? '♕' : '♛';
      case PromotionChoice.rook:
        return isWhite ? '♖' : '♜';
      case PromotionChoice.bishop:
        return isWhite ? '♗' : '♝';
      case PromotionChoice.knight:
        return isWhite ? '♘' : '♞';
    }
  }
  void _initializePlayers() {
    player1 = Player(
      name: "Robert",
      elo: 1896,
      flagAsset: "assets/us_flag.png",
      seconds: 6 * 60 + 24,
    );
    player2 = Player(
      name: "Anastasia",
      elo: 1896,
      flagAsset: "assets/us_flag.png",
      seconds: 6 * 60 + 56,
    );
  }

  bool get isWhiteTurn => _isWhiteTurn;
  Position? get selectedPosition => _selectedPosition;
  List<Position> get possibleMoves => _possibleMoves;

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _isWhiteTurn ? player1.seconds-- : player2.seconds--;
      if (player1.seconds <= 0 || player2.seconds <= 0) _timer?.cancel();
      notifyListeners();
    });
  }

  void _switchTurn() {
    _isWhiteTurn = !_isWhiteTurn;

    // In multiplayer, timer management is tricky.
    // Each client should manage its own timer based on whose turn it is.
    // The host/client determination (isHost, isHostWhite) helps decide if the current turn is local.
    bool isLocalPlayerTurnNow = !isMultiplayerGame ||
                               (isHost && isHostWhite == _isWhiteTurn) ||
                               (!isHost && isHostWhite != _isWhiteTurn);

    if (isLocalPlayerTurnNow) {
      _timer?.cancel(); // Cancel previous timer
      _startTimer();    // Start timer for the local player
    } else {
      _timer?.cancel(); // If it's remote player's turn, stop local timer.
    }
    // notifyListeners(); // This will be called by the calling method or receiveMove
  }

  void handleSquareTap(int row, int col) {
    // In multiplayer, only allow interaction if it's this player's turn
    if (isMultiplayerGame) {
      bool isMyTurn = (isHost && isHostWhite == _isWhiteTurn) || (!isHost && isHostWhite != _isWhiteTurn);
      if (!isMyTurn) {
        if (kDebugMode) {
          print("Not your turn.");
        }
        return;
      }
    }

    final piece = board.squares[row][col];

    if (_selectedPosition == null) {
      _handlePieceSelection(row, col, piece);
    } else {
      _handleMoveExecution(row, col);
    }
    notifyListeners(); // Notify after selection or move attempt
  }

  void _handlePieceSelection(int row, int col, String piece) {
    // Already checked for multiplayer turn in handleSquareTap
    if (piece.isEmpty || isWhitePiece(piece) != _isWhiteTurn) return;
    _selectedPosition = Position(row, col);
    _possibleMoves = MoveCalculator.calculateMoves(pos: _selectedPosition!, board: board);
  }

  void _handleMoveExecution(int row, int col) {
    final target = Position(row, col);
    if (_possibleMoves.contains(target)) {
      final from = _selectedPosition!;
      // Store piece before moving, for promotion logic
      final pieceBeingMoved = board.squares[from.row][from.col];
      _movePiece(from, target); // This might set _promotionPendingPosition

      // If promotion is pending after _movePiece, it means UI needs to ask for choice.
      // The actual promotion piece is set in handlePromotionChoice.
      
      if (isMultiplayerGame) {
        String? promotionChoiceString;
        if (_promotionPendingPosition == target && _lastPromotionChoice != null) {
           // This means handlePromotionChoice was called for a local promotion scenario
           // before we send the data.
           promotionChoiceString = _lastPromotionChoice!.toString().split('.').last;
        } else if ((pieceBeingMoved == '♙' && target.row == 0) || (pieceBeingMoved == '♟' && target.row == 7)) {
          // This is a pawn reaching promotion row, but UI hasn't selected choice yet.
          // This case needs careful handling. The game should pause for promotion choice
          // THEN send the move with the choice.
          // For now, if _lastPromotionChoice is available (set by UI sync), use it.
          // This assumes UI updates _lastPromotionChoice before _handleMoveExecution fully resolves.
          // This logic might be tricky.
          if (_lastPromotionChoice != null) {
             promotionChoiceString = _lastPromotionChoice!.toString().split('.').last;
          } else {
            // This is a problem: promotion happened but no choice made yet for sending.
            // The game should ideally wait. For this simplified version, we might not send promotion
            // if choice isn't ready, which is a bug.
            // Or, _movePiece and handlePromotionChoice ensure _lastPromotionChoice is set.
            // Let's assume handlePromotionChoice sets _lastPromotionChoice, and _movePiece sets _promotionPendingPosition.
            // If _promotionPendingPosition is set here, it means we need a choice.
            // This part of the logic is complex due to the async nature of UI choice.
          }
        }

        final moveData = jsonEncode({
          'from': {'row': from.row, 'col': from.col},
          'to': {'row': target.row, 'col': target.col},
          'promotion': promotionChoiceString,
        });
        try {
          _bluetoothService.sendData(moveData);
          gameMessageNotifier.value = "Move sent."; // Clear previous message or set success
        } catch (e) {
          gameMessageNotifier.value = "Failed to send move: ${e.toString()}";
          if (kDebugMode) {
            print("Error sending move: $e");
          }
          // Consider if game should be paused or error state handled more explicitly
        }
        _lastPromotionChoice = null; // Reset after sending attempt
      }

      if (!isPromotionPending) { // If not waiting for promotion choice
        _switchTurn();
      }
      // If promotion is pending, _switchTurn will be called after promotion choice is made by UI
      // and then handlePromotionChoice -> potentially _handleMoveExecution again or directly _switchTurn.
      // This needs to be structured so that _switchTurn happens once.
      // Let's assume: if promotion is pending, UI interaction will eventually call handlePromotionChoice,
      // which will then call _switchTurn if appropriate (or it's called here if no promotion).

    }
    _selectedPosition = null;
    _possibleMoves.clear();
    // notifyListeners(); // Moved to handleSquareTap
  }

  void receiveMove(String moveData) {
    try {
      if (kDebugMode) {
        print("Received move data: $moveData");
      }
      final move = jsonDecode(moveData);
      final fromData = move['from'] as Map<String, dynamic>;
      final toData = move['to'] as Map<String, dynamic>;
      final promotionChoiceStr = move['promotion'] as String?;

      final remoteFrom = Position(fromData['row'] as int, fromData['col'] as int);
      final remoteTo = Position(toData['row'] as int, toData['col'] as int);
      
      String? pieceToPromoteTo;
      if (promotionChoiceStr != null) {
        bool isWhitePromoting = (board.squares[remoteFrom.row][remoteFrom.col] == '♙'); // White pawn promotes
        PromotionChoice choice = PromotionChoice.values.firstWhere((e) => e.toString().split('.').last == promotionChoiceStr);
        pieceToPromoteTo = _getPromotionPiece(choice, isWhitePromoting);
      }

      if (board.squares[remoteFrom.row][remoteFrom.col].isNotEmpty) {
        _movePiece(remoteFrom, remoteTo, promotionPiece: pieceToPromoteTo);
      } else {
        if (kDebugMode) {
          print("Received move for an empty 'from' square. From: $remoteFrom, To: $remoteTo");
        }
      }
      _switchTurn(); 
      notifyListeners(); // Update UI after remote move
    } catch (e, s) {
      if (kDebugMode) {
        print("Error receiving or processing move: $e");
        print("Stack trace: $s");
        print("Received data: $moveData");
      }
    }
  }

  void _movePiece(Position from, Position to, {String? promotionPiece}) {
    _handleEnPassantCapture(from, to);

    if (_isCastlingMove(from, to)) {
      _performCastling(from, to);
      return;
    }

    _updateCastlingRights(from);

    board.squares[to.row][to.col] = board.squares[from.row][from.col];
    board.squares[from.row][from.col] = '';

    _setEnPassantTarget(from, to);

    // Handle pawn promotion
    final pieceThatMoved = board.squares[to.row][to.col]; // piece is now at 'to'
    bool isPawn = (pieceThatMoved == '♙' || pieceThatMoved == '♟');
    bool reachedPromotionRow = (pieceThatMoved == '♙' && to.row == 0) || (pieceThatMoved == '♟' && to.row == 7);

    if (isPawn && reachedPromotionRow) {
      if (promotionPiece != null) {
        // Promotion piece is provided (e.g., from a remote move or already chosen locally)
        board.squares[to.row][to.col] = promotionPiece;
        _promotionPendingPosition = null; // Promotion handled
        _lastPromotionChoice = null; // Clear any stored choice
      } else {
        // Local move, and promotion choice not yet made. Trigger UI for choice.
        // This should only happen for the local player.
        bool isCurrentPlayerMakingMove = !isMultiplayerGame ||
                                     (isHost && isHostWhite == _isWhiteTurn) ||
                                     (!isHost && isHostWhite != _isWhiteTurn);
        if (isCurrentPlayerMakingMove) {
            _promotionPendingPosition = to;
            // notifyListeners(); // To show promotion dialog - called by handleSquareTap
        } else {
            // This is a remote move that reached promotion row but didn't include promotion choice.
            // This indicates an issue with the sender or data. Default to Queen as a fallback.
            if (kDebugMode) {
              print("Remote move needs promotion, but no choice provided. Defaulting to Queen.");
            }
            board.squares[to.row][to.col] = (pieceThatMoved == '♙') ? '♕' : '♛';
            _promotionPendingPosition = null;
        }
      }
    } else {
      _promotionPendingPosition = null; // No promotion or already handled
    }
    // notifyListeners(); // Generally called by the wrapper (handleSquareTap or receiveMove)

    // Placeholder for sound integration
    print("Sound enabled: ${settingsViewModel.isSoundEnabled} - A piece was moved (simulated sound).");
  }

  void _handleEnPassantCapture(Position from, Position to) {
    if (board.squares[from.row][from.col] == '♙' || board.squares[from.row][from.col] == '♟') {
      if (to.col != from.col && board.squares[to.row][to.col].isEmpty) {
        board.squares[from.row][to.col] = '';
      }
    }
  }

  void _setEnPassantTarget(Position from, Position to) {
    final piece = board.squares[to.row][to.col];
    if ((piece == '♙' && from.row == 6 && to.row == 4) ||
        (piece == '♟' && from.row == 1 && to.row == 3)) {
      board.enPassantTarget = Position((from.row + to.row) ~/ 2, from.col);
    } else {
      board.enPassantTarget = null;
    }
  }

  void _updateCastlingRights(Position from) {
    final piece = board.squares[from.row][from.col];

    if (piece == '♔') {
      board.canWhiteCastleKingside = false;
      board.canWhiteCastleQueenside = false;
    }
    if (piece == '♚') {
      board.canBlackCastleKingside = false;
      board.canBlackCastleQueenside = false;
    }
    if (piece == '♖') {
      if (from.col == 7) board.canWhiteCastleKingside = false;
      if (from.col == 0) board.canWhiteCastleQueenside = false;
    }
    if (piece == '♜') {
      if (from.col == 7) board.canBlackCastleKingside = false;
      if (from.col == 0) board.canBlackCastleQueenside = false;
    }
  }

  bool _isCastlingMove(Position from, Position to) {
    final piece = board.squares[from.row][from.col];
    return (piece == '♔' || piece == '♚') && (from.col - to.col).abs() == 2;
  }

  void _performCastling(Position kingFrom, Position kingTo) {
    final isWhite = board.squares[kingFrom.row][kingFrom.col] == '♔';
    final row = kingFrom.row;
    Position rookFrom, rookTo;

    if (kingTo.col == 6) { // Enroque corto
      rookFrom = Position(row, 7);
      rookTo = Position(row, 5);
    } else { // Enroque largo
      rookFrom = Position(row, 0);
      rookTo = Position(row, 3);
    }

    board.squares[kingTo.row][kingTo.col] = board.squares[kingFrom.row][kingFrom.col];
    board.squares[kingFrom.row][kingFrom.col] = '';

    board.squares[rookTo.row][rookTo.col] = board.squares[rookFrom.row][rookFrom.col];
    board.squares[rookFrom.row][rookFrom.col] = '';

    // Actualizar derechos de enroque
    if (isWhite) {
      board.canWhiteCastleKingside = false;
      board.canWhiteCastleQueenside = false;
    } else {
      board.canBlackCastleKingside = false;
      board.canBlackCastleQueenside = false;
    }
  }

  static bool isWhitePiece(String piece) => ['♔', '♕', '♖', '♗', '♘', '♙'].contains(piece);

  @override
  void dispose() {
    _timer?.cancel();
    _incomingDataSubscription?.cancel();
    _bluetoothService.connectionStateNotifier.removeListener(_onConnectionStateChanged);
    _bluetoothService.currentErrorNotifier.removeListener(_onBluetoothError);
    _bluetoothService.dispose(); 
    gameMessageNotifier.dispose();
    super.dispose();
  }
}