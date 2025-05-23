import 'package:ajedrez_app/view_models/settings_view_model.dart';
import 'package:ajedrez_app/views/chess_game_screen.dart';
import 'package:ajedrez_app/views/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Import Provider

class MenuScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Consume SettingsViewModel to get user name and avatar
    return Consumer<SettingsViewModel>(
      builder: (context, settingsViewModel, child) {
        String titleText = 'Main Menu';
        if (settingsViewModel.userName.isNotEmpty && settingsViewModel.userName != 'Player') {
          titleText = 'Welcome, ${settingsViewModel.userName}!';
        }

        Widget? leadingAvatar;
        if (settingsViewModel.avatarImageUrl.isNotEmpty) {
          // Basic error handling for Image.network
          try {
            leadingAvatar = Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundImage: NetworkImage(settingsViewModel.avatarImageUrl),
                onBackgroundImageError: (exception, stackTrace) {
                  // Optionally handle image loading errors, e.g., show a default icon
                  print('Error loading avatar image: $exception');
                },
              ),
            );
          } catch (e) {
            print('Invalid URL for avatar: ${settingsViewModel.avatarImageUrl}');
            // Fallback to a default icon if URL is malformed or causes other issues
            leadingAvatar = const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircleAvatar(child: Icon(Icons.person)),
            );
          }
        } else {
            leadingAvatar = const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircleAvatar(child: Icon(Icons.person)),
            );
        }


        return Scaffold(
          appBar: AppBar(
            title: Text(titleText),
            leading: leadingAvatar,
          ),
          body: Center(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ChessGameScreen()),
                );
              },
              child: Text('Play'),
            ),
            SizedBox(height: 20), // Adds some space between the buttons
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SettingsScreen()),
                );
              },
              child: Text('Settings'),
            ),
          ],
        ),
      ),
    );
  });}
}
