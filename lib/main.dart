import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'view_models/chess_view_model.dart';
import 'view_models/settings_view_model.dart'; // Import SettingsViewModel
import 'utils/themes.dart'; // Import themes
import 'views/chess_game_screen.dart';
import 'views/menu_screen.dart'; // Assuming MenuScreen is the initial screen

void main() {
  runApp(const ChessApp());
}

class ChessApp extends StatelessWidget {
  const ChessApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // MultiProvider to combine multiple providers
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsViewModel()), // SettingsViewModel provided first
        ChangeNotifierProxyProvider<SettingsViewModel, ChessViewModel>(
          create: (context) {
            // Read SettingsViewModel instance directly using context.read or Provider.of
            // This is acceptable in 'create' if SettingsViewModel is guaranteed to be available.
            final settingsViewModel = Provider.of<SettingsViewModel>(context, listen: false);
            return ChessViewModel(settingsViewModel: settingsViewModel);
          },
          update: (context, settingsViewModel, previousChessViewModel) {
            // This update is called whenever SettingsViewModel notifies listeners,
            // or when ChessViewModel is first created after SettingsViewModel.
            // If ChessViewModel itself doesn't need to change when SettingsViewModel changes,
            // we can just return the existing instance or a new one if it was null.
            if (previousChessViewModel == null) {
              return ChessViewModel(settingsViewModel: settingsViewModel);
            }
            // If ChessViewModel's internal state *depended* on changes in SettingsViewModel,
            // you might update it here, e.g., previousChessViewModel.updateSettings(settingsViewModel);
            // For now, we just need to pass it at construction.
            return previousChessViewModel; // Or create new if it needs to rebuild based on settings
          },
        ),
      ],
      child: Consumer<SettingsViewModel>( // Consume SettingsViewModel for theming MaterialApp
        builder: (context, settingsViewModel, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Ajedrex',
            theme: lightTheme, // Apply light theme
            darkTheme: darkTheme, // Apply dark theme
            themeMode: settingsViewModel.currentTheme.brightness == Brightness.dark
                ? ThemeMode.dark
                : ThemeMode.light, // Set themeMode based on ViewModel
            home: MenuScreen(), // Changed home to MenuScreen
          );
        },
      ),
    );
  }
}
