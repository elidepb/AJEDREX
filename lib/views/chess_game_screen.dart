import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/chess_view_model.dart';
import '../models/chess_model.dart';

class ChessGameScreen extends StatelessWidget {
  const ChessGameScreen({Key? key}) : super(key: key);

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

  Widget _buildChessBoard(BuildContext context) {
    const lightSquareColor = Color(0xFFF0D9B5);
    const darkSquareColor = Color(0xFFB58863);
    final viewModel = Provider.of<ChessViewModel>(context);

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
                // En chess_game_screen.dart
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Center(
          child: Text("JUGAR", style: TextStyle(fontSize: 24)),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              _buildPlayerInfo(context, true),
              const SizedBox(height: 12),
              _buildChessBoard(context),
              const SizedBox(height: 12),
              _buildPlayerInfo(context, false),
            ],
          ),
        ),
      ),
    );
  }
}
