import 'package:flutter/material.dart';

final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  primarySwatch: Colors.green,
  visualDensity: VisualDensity.adaptivePlatformDensity,
  iconTheme: IconThemeData(color: Colors.green[700]),
  textTheme: ThemeData.light().textTheme.copyWith(
        bodyLarge: TextStyle(fontSize: 14.0),
        bodyMedium: TextStyle(fontSize: 12.0),
        titleLarge: TextStyle(fontSize: 20.0),
        titleMedium: TextStyle(fontSize: 15.0),
        labelLarge: TextStyle(fontSize: 13.0),
      ).apply(
        bodyColor: Colors.black,
        displayColor: Colors.black, // For headlines, etc.
      ),
  appBarTheme: AppBarTheme(backgroundColor: Colors.green[700]), // Added AppBar theme
  // Add other light theme specific properties
);

final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  primarySwatch: Colors.green,
  iconTheme: IconThemeData(color: Colors.green[700]),
  textTheme: ThemeData.dark().textTheme.copyWith(
        bodyLarge: TextStyle(fontSize: 14.0),
        bodyMedium: TextStyle(fontSize: 12.0),
        titleLarge: TextStyle(fontSize: 20.0),
        titleMedium: TextStyle(fontSize: 15.0),
        labelLarge: TextStyle(fontSize: 13.0),
      ).apply(
        bodyColor: Colors.white,
        displayColor: Colors.white, // For headlines, etc.
      ),
  appBarTheme: AppBarTheme(backgroundColor: Colors.green[700]), // Added AppBar theme
  // For dark themes, you might also want to set primaryColor to a specific shade
  // e.g., primaryColor: Colors.green[700], if Colors.green swatch isn't ideal.
  // But using primarySwatch directly is also valid.
  visualDensity: VisualDensity.adaptivePlatformDensity,
  // Add other dark theme specific properties
);
