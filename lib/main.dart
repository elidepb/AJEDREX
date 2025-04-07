import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'view_models/chess_view_model.dart';
import 'views/chess_game_screen.dart';

void main() {
  runApp(const ChessApp());
}

class ChessApp extends StatelessWidget {
  const ChessApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChessViewModel(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Ajedrex',
        theme: ThemeData(
          primarySwatch: Colors.blueGrey,
          scaffoldBackgroundColor: Colors.black87,
        ),
        home: const ChessGameScreen(),
      ),
    );
  }
}
