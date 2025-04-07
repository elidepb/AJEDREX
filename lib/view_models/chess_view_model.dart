import 'dart:async';
import 'package:flutter/material.dart';
import '../models/chess_model.dart';

part 'move_calculator.dart';
part 'check_validator.dart';

class ChessViewModel extends ChangeNotifier {
  // Region: Game State
  late Player player1;
  late Player player2;
  late ChessBoard board;
  Timer? _timer;
  bool _isWhiteTurn = true;
  Position? _selectedPosition;
  List<Position> _possibleMoves = [];

  // Region: Initialization
  ChessViewModel() {
    _initializePlayers();
    board = ChessBoard();
    _startTimer();
  }

  Position? _promotionPendingPosition;
  bool get isPromotionPending => _promotionPendingPosition != null;

  void handlePromotionChoice(PromotionChoice choice) {
    if (_promotionPendingPosition == null) return;

    final row = _promotionPendingPosition!.row;
    final isWhite = row == 0; // Si es fila 0, el peón es blanco (♙)

    final newPiece = _getPromotionPiece(choice, isWhite);
    board.squares[row][_promotionPendingPosition!.col] = newPiece;

    _promotionPendingPosition = null;
    notifyListeners();
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

  // Region: Public Properties
  bool get isWhiteTurn => _isWhiteTurn;
  Position? get selectedPosition => _selectedPosition;
  List<Position> get possibleMoves => _possibleMoves;

  // Region: Timer Management
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _isWhiteTurn ? player1.seconds-- : player2.seconds--;
      if (player1.seconds <= 0 || player2.seconds <= 0) _timer?.cancel();
      notifyListeners();
    });
  }

  void _switchTurn() {
    _isWhiteTurn = !_isWhiteTurn;
    _timer?.cancel();
    _startTimer();
  }

  // Region: Game Logic
  void handleSquareTap(int row, int col) {
    final piece = board.squares[row][col];

    if (_selectedPosition == null) {
      _handlePieceSelection(row, col, piece);
    } else {
      _handleMoveExecution(row, col);
    }
    notifyListeners();
  }

  void _handlePieceSelection(int row, int col, String piece) {
    if (piece.isEmpty || isWhitePiece(piece) != _isWhiteTurn) return;
    _selectedPosition = Position(row, col);
    _possibleMoves = MoveCalculator.calculateMoves(pos: _selectedPosition!, board: board);
  }

  void _handleMoveExecution(int row, int col) {
    final target = Position(row, col);
    if (_possibleMoves.contains(target)) {
      _movePiece(_selectedPosition!, target);
      _switchTurn();
    }
    _selectedPosition = null;
    _possibleMoves.clear();
  }


  void _movePiece(Position from, Position to) {
    // Captura al paso
    _handleEnPassantCapture(from, to);

    // Enroque
    if (_isCastlingMove(from, to)) {
      _performCastling(from, to);
      return;
    }

    // Actualizar derechos de enroque
    _updateCastlingRights(from);

    // Movimiento normal
    board.squares[to.row][to.col] = board.squares[from.row][from.col];
    board.squares[from.row][from.col] = '';

    // Establecer objetivo para captura al paso
    _setEnPassantTarget(from, to);
  }

  void _handleEnPassantCapture(Position from, Position to) {
    if (board.squares[from.row][from.col] == '♙' || board.squares[from.row][from.col] == '♟') {
      // Captura al paso
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

    // Mover rey
    board.squares[kingTo.row][kingTo.col] = board.squares[kingFrom.row][kingFrom.col];
    board.squares[kingFrom.row][kingFrom.col] = '';

    // Mover torre
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

  // Region: Utility Methods
  static bool isWhitePiece(String piece) => ['♔', '♕', '♖', '♗', '♘', '♙'].contains(piece);

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}