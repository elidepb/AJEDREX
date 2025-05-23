import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart'
    show BluetoothDevice, BluetoothConnectionState; // Specific imports
import '../services/bluetooth_service.dart';
import '../view_models/chess_view_model.dart';
import '../view_models/settings_view_model.dart'; // Import SettingsViewModel
import '../models/chess_model.dart';

class ChessGameScreen extends StatefulWidget {
  const ChessGameScreen({Key? key}) : super(key: key);

  @override
  _ChessGameScreenState createState() => _ChessGameScreenState();
}

class _ChessGameScreenState extends State<ChessGameScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<ChessViewModel>(
      builder: (context, viewModel, child) {
        // Show promotion dialog when necessary
        if (viewModel.isPromotionPending) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showPromotionDialog(context, viewModel);
          });
        }

        // Connection Status Display (simple version below AppBar)
        Widget connectionStatusWidget = ValueListenableBuilder<BluetoothConnectionState>(
          valueListenable: viewModel.connectionStateNotifier,
          builder: (context, state, child) {
            String statusText = "Bluetooth: ";
            switch (state) {
              case BluetoothConnectionState.connecting:
                statusText += "Connecting...";
                break;
              case BluetoothConnectionState.connected:
                statusText += "Connected to ${viewModel.connectedDevice?.name ?? 'device'}";
                break;
              case BluetoothConnectionState.disconnected:
                statusText += "Disconnected";
                if (viewModel.isMultiplayerGame) { // If game was ongoing, mention it
                    statusText += " (Game ended)";
                }
                break;
              case BluetoothConnectionState.error:
                statusText += "Error";
                break;
              default:
                statusText += "Idle"; // Should be .disconnected initially
            }
            // Only show if multiplayer has been attempted or is active
            if (viewModel.isMultiplayerGame || state == BluetoothConnectionState.connecting || state == BluetoothConnectionState.connected) {
                return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 12.0),
                    child: Text(statusText, style: const TextStyle(color: Colors.white, fontSize: 12)),
                );
            }
            return const SizedBox.shrink(); // Empty if not relevant
          },
        );

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.black,
            title: const Center(
              child: Text("JUGAR", style: TextStyle(fontSize: 24)),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.bluetooth),
                onPressed: () {
                  _showBluetoothOptionsDialog(context, viewModel);
                },
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  _buildPlayerInfo(context, true),
                  const SizedBox(height: 4),
                  connectionStatusWidget, // Display connection status
                  const SizedBox(height: 8),
                  _buildChessBoard(context, viewModel),
                  const SizedBox(height: 12),
                  _buildPlayerInfo(context, false),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showBluetoothOptionsDialog(BuildContext context, ChessViewModel viewModel) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Bluetooth Multiplayer'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.bluetooth_searching_outlined), // Changed icon
                title: const Text('Host Game'),
                onTap: () {
                  Navigator.of(dialogContext).pop(); // Close this dialog
                  viewModel.startHosting().then((_) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Hosting game... Waiting for opponent.')),
                    );
                  }).catchError((error) {
                     ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to host: ${error.toString()}')),
                    );
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.search_outlined), // Changed icon
                title: const Text('Scan for Games'),
                onTap: () {
                  Navigator.of(dialogContext).pop(); // Close this dialog
                  viewModel.startBluetoothScan().then((_) {
                     _showDiscoveredDevicesDialog(context, viewModel);
                  }).catchError((error) {
                     ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Scan failed: ${error.toString()}')),
                    );
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDiscoveredDevicesDialog(BuildContext context, ChessViewModel viewModel) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Discovered Devices'),
          content: SizedBox(
            width: double.maxFinite, // Use available width
            child: ValueListenableBuilder<List<BluetoothDevice>>(
              valueListenable: viewModel.discoveredDevicesNotifier,
              builder: (context, devices, child) {
                if (devices.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 10),
                        Text('Scanning... No devices found yet.'),
                        Text('Ensure other device is hosting & discoverable.', textAlign: TextAlign.center),
                      ],
                    )
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: devices.length,
                  itemBuilder: (context, index) {
                    final device = devices[index];
                    return ListTile(
                      title: Text(device.name ?? 'Unknown Device'),
                      subtitle: Text(device.address),
                      leading: const Icon(Icons.bluetooth_connected_outlined), // Changed icon
                      onTap: () {
                        Navigator.of(dialogContext).pop(); // Close this dialog
                        viewModel.connectToDevice(device).then((_) {
                           ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Connecting to ${device.name ?? device.address}...')),
                          );
                        }).catchError((error) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Connection failed: ${error.toString()}')),
                          );
                        });
                      },
                    );
                  },
                );
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Rescan'),
              onPressed: () {
                 // No need to pop, just rescan
                 viewModel.startBluetoothScan().catchError((error) {
                     ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Rescan failed: ${error.toString()}')),
                    );
                  });
              },
            ),
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showPromotionDialog(BuildContext context, ChessViewModel viewModel) {
    final position = viewModel.promotionPendingPosition;
    if (position == null) return;

    final isWhite = position.row == 0;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Promocionar Peón'),
        content: SizedBox(
          height: 100,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildPromotionButton(context, viewModel, PromotionChoice.queen, isWhite),
              _buildPromotionButton(context, viewModel, PromotionChoice.rook, isWhite),
              _buildPromotionButton(context, viewModel, PromotionChoice.bishop, isWhite),
              _buildPromotionButton(context, viewModel, PromotionChoice.knight, isWhite),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPromotionButton(BuildContext context, ChessViewModel viewModel,
      PromotionChoice choice, bool isWhite) {
    final piece = _getPromotionPiece(choice, isWhite);
    return TextButton(
      onPressed: () {
        Navigator.of(context).pop();
        viewModel.handlePromotionChoice(choice);
      },
      child: Text(
        piece,
        style: const TextStyle(fontSize: 40, fontFamily: 'Segoe UI Symbol'),
      ),
    );
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

  Widget _buildPlayerInfo(BuildContext context, bool isPlayer1) {
    final viewModel = Provider.of<ChessViewModel>(context);
    final player = isPlayer1 ? viewModel.player1 : viewModel.player2;

    final String avatarUrl = (player.name == "Robert")
        ? "https://robohash.org/robert"
        : "https://robohash.org/anastasia";
    final String flagUrl = "https://via.placeholder.com/24";

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(avatarUrl),
              radius: 20,
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${player.name} (${player.elo})',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Image.network(
                  flagUrl,
                  width: 24,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.flag, color: Colors.white);
                  },
                ),
              ],
            ),
          ],
        ),
        Row(
          children: [
            const Icon(Icons.timer, size: 20, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              player.timeString,
              style: const TextStyle(color: Colors.white),
            )
          ],
        ),
      ],
    );
  }

  Widget _buildChessBoard(BuildContext context, ChessViewModel viewModel) {
    // Access SettingsViewModel to get the current board style
    final settingsViewModel = Provider.of<SettingsViewModel>(context);
    final lightSquareColor = settingsViewModel.currentBoardStyle.lightSquareColor;
    final darkSquareColor = settingsViewModel.currentBoardStyle.darkSquareColor;

    return AspectRatio(
      aspectRatio: 1,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 64,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 8,
        ),
        itemBuilder: (context, index) {
          final row = index ~/ 8;
          final col = index % 8;
          final isLightSquare = (row + col) % 2 == 0;
          final piece = viewModel.board.squares[row][col];
          final isSelected = viewModel.selectedPosition?.row == row &&
              viewModel.selectedPosition?.col == col;
          final isPossible = viewModel.possibleMoves.contains(Position(row, col));

          return GestureDetector(
            onTap: () => viewModel.handleSquareTap(row, col),
            child: Container(
              color: isSelected
                  ? Colors.blue[300]
                  : isPossible
                  ?  Colors.green.withOpacity(0.5)
                  : isLightSquare ? lightSquareColor : darkSquareColor,
              child: Center(
                child: Text(
                  piece,
                  style: TextStyle(
                    fontSize: 40,
                    color: ChessViewModel.isWhitePiece(piece)
                        ? Colors.white.withOpacity(0.9)
                        : Colors.black.withOpacity(0.9),
                    fontFamily: 'Segoe UI Symbol',
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}