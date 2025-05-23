import 'package:flutter/material.dart';

class BoardStyle {
  final Color lightSquareColor;
  final Color darkSquareColor;
  final String name; // Added name for easier identification in UI and storage

  const BoardStyle({
    required this.name,
    required this.lightSquareColor,
    required this.darkSquareColor,
  });
}

final BoardStyle classicBoardStyle = BoardStyle(
  name: 'Classic',
  lightSquareColor: Color(0xFFD18B47), // A light wood color
  darkSquareColor: Color(0xFF8B4513),  // A dark wood color (SaddleBrown)
);

final BoardStyle modernBoardStyle = BoardStyle(
  name: 'Modern',
  lightSquareColor: Colors.grey[300]!, // Light grey
  darkSquareColor: Colors.blueGrey[700]!, // Dark blue-grey
);

// List of available styles for easy access
final List<BoardStyle> boardStyles = [
  classicBoardStyle,
  modernBoardStyle,
  // Add more styles here if needed
];

// Helper to get style by name, useful for loading from preferences
BoardStyle getBoardStyleByName(String name) {
  return boardStyles.firstWhere((style) => style.name == name, orElse: () => classicBoardStyle);
}
