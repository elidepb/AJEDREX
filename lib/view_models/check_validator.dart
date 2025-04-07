part of 'chess_view_model.dart';

class CheckValidator {
  static List<Position> validateKingMoves(Position pos, List<Position> moves, ChessBoard board) {
    final isWhite = ChessViewModel.isWhitePiece(board.squares[pos.row][pos.col]);
    final enemyKing = isWhite ? '♚' : '♔';
    Position? enemyKingPos;

    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        if (board.squares[r][c] == enemyKing) {
          enemyKingPos = Position(r, c);
          break;
        }
      }
      if (enemyKingPos != null) break;
    }

    return moves.where((move) {
      if (isCheck(move, isWhite, pos, board)) return false;

      if (enemyKingPos != null) {
        final rowDiff = (move.row - enemyKingPos.row).abs();
        final colDiff = (move.col - enemyKingPos.col).abs();
        if (rowDiff <= 1 && colDiff <= 1) return false;
      }

      return true;
    }).toList();
  }

  static bool isCheck(Position kingPos, bool isWhite, Position originalPos, ChessBoard board) {
    final tempBoard = _copyBoard(board);
    tempBoard[originalPos.row][originalPos.col] = '';
    tempBoard[kingPos.row][kingPos.col] = isWhite ? '♔' : '♚';

    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        final piece = tempBoard[r][c];
        if (piece.isNotEmpty && ChessViewModel.isWhitePiece(piece) != isWhite) {
          final enemyMoves = _getEnemyMoves(Position(r, c), tempBoard);
          if (enemyMoves.any((p) => p.row == kingPos.row && p.col == kingPos.col)) {
            return true;
          }
        }
      }
    }
    return false;
  }

  static List<List<String>> _copyBoard(ChessBoard board) =>
      board.squares.map((e) => List<String>.from(e)).toList();

  static List<Position> _getEnemyMoves(Position pos, List<List<String>> boardState) {
    final piece = boardState[pos.row][pos.col];
    final moves = <Position>[];

    const enemyMoveSets = {
      '♙': [[-1,-1],[-1,1]],
      '♟': [[1,-1],[1,1]],
      '♘': [[2,1],[2,-1],[-2,1],[-2,-1],[1,2],[1,-2],[-1,2],[-1,-2]],
      '♗': [[-1,-1],[-1,1],[1,-1],[1,1]],
      '♖': [[-1,0],[1,0],[0,-1],[0,1]],
      '♕': [[-1,-1],[-1,1],[1,-1],[1,1],[-1,0],[1,0],[0,-1],[0,1]],
      '♛': [[-1,-1],[-1,1],[1,-1],[1,1],[-1,0],[1,0],[0,-1],[0,1]],
      '♜': [[-1,0],[1,0],[0,-1],[0,1]],
      '♝': [[-1,-1],[-1,1],[1,-1],[1,1]],
      '♞': [[2,1],[2,-1],[-2,1],[-2,-1],[1,2],[1,-2],[-1,2],[-1,-2]],
      '♚': [[-1,-1],[-1,0],[-1,1],[0,-1],[0,1],[1,-1],[1,0],[1,1]],
    };

    if (enemyMoveSets.containsKey(piece)) {
      _addEnemyMoves(pos, moves, enemyMoveSets[piece]!, boardState, piece == '♙' || piece == '♟');
    }

    return moves;
  }

  static void _addEnemyMoves(
      Position pos,
      List<Position> moves,
      List<List<int>> directions,
      List<List<String>> boardState,
      bool isPawn
      ) {
    final isWhite = ChessViewModel.isWhitePiece(boardState[pos.row][pos.col]);

    for (final dir in directions) {
      int r = pos.row;
      int c = pos.col;
      while (true) {
        r += dir[0];
        c += dir[1];
        if (r < 0 || r >= 8 || c < 0 || c >= 8) break;

        final target = boardState[r][c];
        if (isPawn) {
          if (target.isNotEmpty && isWhite != ChessViewModel.isWhitePiece(target)) {
            moves.add(Position(r, c));
          }
          break;
        }

        if (target.isEmpty) {
          moves.add(Position(r, c));
        } else {
          if (isWhite != ChessViewModel.isWhitePiece(target)) moves.add(Position(r, c));
          break;
        }
        if (['♔','♚','♘','♞'].contains(boardState[pos.row][pos.col])) break;
      }
    }
  }

  static bool isSquareUnderAttack(Position pos, ChessBoard board, bool isWhite) {
    final tempBoard = _copyBoard(board);
    tempBoard[pos.row][pos.col] = isWhite ? '♔' : '♚';

    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        final piece = tempBoard[r][c];
        if (piece.isNotEmpty && ChessViewModel.isWhitePiece(piece) != isWhite) {
          final enemyMoves = _getEnemyMoves(Position(r, c), tempBoard);
          if (enemyMoves.any((p) => p.row == pos.row && p.col == pos.col)) {
            return true;
          }
        }
      }
    }
    return false;
  }

  static bool wouldCauseCheck(Position from, Position to, ChessBoard board) {
    final piece = board.squares[from.row][from.col];
    final isWhite = ChessViewModel.isWhitePiece(piece);

    final tempBoard = _copyBoard(board);

    // Realizar el movimiento en la copia
    tempBoard[to.row][to.col] = tempBoard[from.row][from.col];
    tempBoard[from.row][from.col] = '';

    Position kingPos = (piece == '♔' || piece == '♚')
        ? to
        : _findKingPosition(tempBoard, isWhite);

    return isCheck(kingPos, isWhite, kingPos, ChessBoard()..squares = tempBoard);
  }

  static Position _findKingPosition(List<List<String>> board, bool isWhite) {
    final king = isWhite ? '♔' : '♚';
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        if (board[r][c] == king) return Position(r, c);
      }
    }
    throw Exception("Rey no encontrado en el tablero");
  }

}