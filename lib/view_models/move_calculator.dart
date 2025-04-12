part of 'chess_view_model.dart';

class MoveCalculator {
  static List<Position> calculateMoves({required Position pos, required ChessBoard board}) {
    final piece = board.squares[pos.row][pos.col];

    switch (piece) {
      case '♙':
      case '♟':
        return _PawnMoves.calculate(pos, board);
      case '♘':
      case '♞':
        return _KnightMoves.calculate(pos, board);
      case '♗':
      case '♝':
        return _BishopMoves.calculate(pos, board);
      case '♖':
      case '♜':
        return _RookMoves.calculate(pos, board);
      case '♕':
      case '♛':
        return _QueenMoves.calculate(pos, board);
      case '♔':
      case '♚':
        return _KingMoves.calculate(pos, board);
      default:
        return [];
    }
  }
}

abstract class _BaseMoves {
  static List<Position> _calculateSlidingMoves(Position pos, ChessBoard board, List<List<int>> directions) {
    final moves = <Position>[];
    final isWhite = ChessViewModel.isWhitePiece(board.squares[pos.row][pos.col]);

    for (final dir in directions) {
      int r = pos.row;
      int c = pos.col;
      while (true) {
        r += dir[0];
        c += dir[1];
        if (!_isValid(r, c)) break;

        final target = board.squares[r][c];
        if (target.isEmpty) {
          moves.add(Position(r, c));
        } else {
          if (isWhite != ChessViewModel.isWhitePiece(target)) moves.add(Position(r, c));
          break;
        }
      }
    }
    return moves;
  }

  static bool _isValid(int row, int col) => row >= 0 && row < 8 && col >= 0 && col < 8;
}

class _PawnMoves extends _BaseMoves {
  static List<Position> calculate(Position pos, ChessBoard board) {
    final moves = <Position>[];
    final piece = board.squares[pos.row][pos.col];
    final isWhite = ChessViewModel.isWhitePiece(piece);
    final dir = isWhite ? -1 : 1;
    final startRow = isWhite ? 6 : 1;
    final enemy = isWhite ? ['♟','♞','♝','♜','♛','♚'] : ['♙','♘','♗','♖','♕','♔'];

    // Movimiento frontal
    if (_BaseMoves._isValid(pos.row + dir, pos.col) &&
        board.squares[pos.row + dir][pos.col].isEmpty) {
      moves.add(Position(pos.row + dir, pos.col));
      if (pos.row == startRow &&
          _BaseMoves._isValid(pos.row + 2 * dir, pos.col) &&
          board.squares[pos.row + 2 * dir][pos.col].isEmpty) {
        moves.add(Position(pos.row + 2 * dir, pos.col));
      }
    }

    // Capturas normales
    for (final dc in [-1, 1]) {
      if (_BaseMoves._isValid(pos.row + dir, pos.col + dc) &&
          enemy.contains(board.squares[pos.row + dir][pos.col + dc])) {
        moves.add(Position(pos.row + dir, pos.col + dc));
      }
    }

    // Captura al paso
    if (board.enPassantTarget != null) {
      final ep = board.enPassantTarget!;
      if (pos.row == ep.row - dir && (pos.col == ep.col - 1 || pos.col == ep.col + 1)) {
        moves.add(ep);
      }
    }

    return moves;
  }
}

class _KnightMoves extends _BaseMoves {
  static List<Position> calculate(Position pos, ChessBoard board) {
    const moves = [
      [2, 1], [2, -1], [-2, 1], [-2, -1],
      [1, 2], [1, -2], [-1, 2], [-1, -2]
    ];
    return _calculateKnightMoves(pos, board, moves);
  }

  static List<Position> _calculateKnightMoves(Position pos, ChessBoard board, List<List<int>> moves) {
    final result = <Position>[];
    final isWhite = ChessViewModel.isWhitePiece(board.squares[pos.row][pos.col]);

    for (final move in moves) {
      final newRow = pos.row + move[0];
      final newCol = pos.col + move[1];

      if (_BaseMoves._isValid(newRow, newCol)) {
        final target = board.squares[newRow][newCol];
        if (target.isEmpty || ChessViewModel.isWhitePiece(target) != isWhite) {
          result.add(Position(newRow, newCol));
        }
      }
    }
    return result;
  }
}

class _BishopMoves extends _BaseMoves {
  static List<Position> calculate(Position pos, ChessBoard board) {
    return _BaseMoves._calculateSlidingMoves(pos, board, [[-1, -1], [-1, 1], [1, -1], [1, 1]]);
  }
}

class _RookMoves extends _BaseMoves {
  static List<Position> calculate(Position pos, ChessBoard board) {
    return _BaseMoves._calculateSlidingMoves(pos, board, [[-1, 0], [1, 0], [0, -1], [0, 1]]);
  }
}

class _QueenMoves extends _BaseMoves {
  static List<Position> calculate(Position pos, ChessBoard board) {
    return _BaseMoves._calculateSlidingMoves(pos, board, [
      [-1, -1], [-1, 1], [1, -1], [1, 1],
      [-1, 0], [1, 0], [0, -1], [0, 1]
    ]);
  }
}

class _KingMoves extends _BaseMoves {
  static List<Position> calculate(Position pos, ChessBoard board) {
    const kingMoves = [
      [-1, -1], [-1, 0], [-1, 1],
      [0, -1], [0, 1],
      [1, -1], [1, 0], [1, 1]
    ];

    final result = <Position>[];
    final isWhite = ChessViewModel.isWhitePiece(board.squares[pos.row][pos.col]);

    // Movimientos básicos del rey
    for (final move in kingMoves) {
      final newRow = pos.row + move[0];
      final newCol = pos.col + move[1];

      if (_BaseMoves._isValid(newRow, newCol)) {
        final target = board.squares[newRow][newCol];
        if (target.isEmpty || ChessViewModel.isWhitePiece(target) != isWhite) {
          result.add(Position(newRow, newCol));
        }
      }
    }

    _addCastlingMoves(pos, board, result, isWhite);

    return result.where((move) {
      return !CheckValidator.wouldCauseCheck(pos, move, board);
    }).toList();
  }

  static void _addCastlingMoves(Position kingPos, ChessBoard board, List<Position> moves, bool isWhite) {
    final row = kingPos.row;

    if (_canCastleKingside(kingPos, board, isWhite)) {
      moves.add(Position(row, 6));
    }

    if (_canCastleQueenside(kingPos, board, isWhite)) {
      moves.add(Position(row, 2));
    }
  }

  static bool _canCastleKingside(Position kingPos, ChessBoard board, bool isWhite) {
    final row = kingPos.row;
    final hasRook = isWhite
        ? board.squares[row][7] == '♖'
        : board.squares[row][7] == '♜';

    final canCastle = isWhite
        ? board.canWhiteCastleKingside
        : board.canBlackCastleKingside;

    return canCastle &&
        hasRook &&
        _isCastlingPathClear(row, 5, 6, board) &&
        !_isAnySquareUnderAttack(row, [4, 5, 6], board, isWhite) &&
        !CheckValidator.isSquareUnderAttack(kingPos, board, isWhite);
  }

  static bool _canCastleQueenside(Position kingPos, ChessBoard board, bool isWhite) {
    final row = kingPos.row;
    final hasRook = isWhite
        ? board.squares[row][0] == '♖'
        : board.squares[row][0] == '♜';

    final canCastle = isWhite
        ? board.canWhiteCastleQueenside
        : board.canBlackCastleQueenside;

    return canCastle &&
        hasRook &&
        _isCastlingPathClear(row, 1, 3, board) &&
        !_isAnySquareUnderAttack(row, [2, 3, 4], board, isWhite) && // Solo casillas que el rey atraviesa
        !CheckValidator.isSquareUnderAttack(kingPos, board, isWhite);
  }

  static bool _isCastlingPathClear(int row, int startCol, int endCol, ChessBoard board) {
    for (int col = startCol; col <= endCol; col++) {
      if (board.squares[row][col].isNotEmpty) return false;
    }
    return true;
  }

  static bool _isAnySquareUnderAttack(int row, List<int> cols, ChessBoard board, bool isWhite) {
    return cols.any((col) => CheckValidator.isSquareUnderAttack(Position(row, col), board, isWhite));
  }
}