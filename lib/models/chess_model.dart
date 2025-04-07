class Player {
  final String name;
  final int elo;
  final String flagAsset;
  int seconds;

  Player({
    required this.name,
    required this.elo,
    required this.flagAsset,
    required this.seconds,
  });

  String get timeString {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remainingSeconds = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remainingSeconds';
  }
}
enum PromotionChoice { queen, rook, bishop, knight }

class Position {
  final int row;
  final int col;

  Position(this.row, this.col);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Position && row == other.row && col == other.col;

  @override
  int get hashCode => row.hashCode ^ col.hashCode;
}

class ChessBoard {
  List<List<String>> squares;
  Position? enPassantTarget;
  bool canWhiteCastleKingside = true;
  bool canWhiteCastleQueenside = true;
  bool canBlackCastleKingside = true;
  bool canBlackCastleQueenside = true;

  ChessBoard() : squares = List.generate(8, (row) {
    return List.generate(8, (col) {
      // Peones
      if (row == 1) return '♟'; // Peones negros
      if (row == 6) return '♙'; // Peones blancos

      // Piezas negras
      if (row == 0) {
        return ['♜', '♞', '♝', '♛', '♚', '♝', '♞', '♜'][col];
      }

      // Piezas blancas
      if (row == 7) {
        return ['♖', '♘', '♗', '♕', '♔', '♗', '♘', '♖'][col];
      }

      return '';
    });
  }) {
    enPassantTarget = null;
  }
}