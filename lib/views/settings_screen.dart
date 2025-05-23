import 'package:ajedrez_app/utils/avatar_utils.dart';
import 'package:ajedrez_app/utils/board_styles.dart';
import 'package:ajedrez_app/utils/themes.dart';
import 'package:ajedrez_app/view_models/settings_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _nameController;
  // _avatarUrlController is no longer needed as we're using a grid selection.

  @override
  void initState() {
    super.initState();
    // Initialize controllers when the state is created
    final settingsViewModel = Provider.of<SettingsViewModel>(context, listen: false);
    _nameController = TextEditingController(text: settingsViewModel.userName);
    // _avatarUrlController initialization removed.
  }

  @override
  void dispose() {
    _nameController.dispose();
    // _avatarUrlController disposal removed.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Using Consumer to access the SettingsViewModel
    return Consumer<SettingsViewModel>(
      builder: (context, settingsViewModel, child) {
        // This ensures that if the ViewModel updates from elsewhere for the name,
        // the text field is updated if it's not currently focused.
        if (_nameController.text != settingsViewModel.userName) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
             if (mounted && (ModalRoute.of(context)?.isCurrent ?? false) && !(FocusScope.of(context).hasFocus) ) {
                _nameController.text = settingsViewModel.userName;
             }
          });
        }
        // Logic for _avatarUrlController removed.

        return Scaffold(
          appBar: AppBar(
            title: Text('Settings'),
            backgroundColor: Colors.green[700], // Set AppBar background color
          ),
          body: Container( // Wrap ListView with a Container for gradient background
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.grey[900]!, // Darker gray
                  Colors.grey[700]!, // Slightly lighter gray
                ],
                begin: Alignment.centerLeft, // Changed from topCenter
                end: Alignment.centerRight,  // Changed from bottomCenter
              ),
            ),
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: <Widget>[
                SwitchListTile(
                title: Text('Light Theme'),
                value: settingsViewModel.currentTheme == lightTheme,
                secondary: Icon(Icons.wb_sunny, color: Colors.green[700]),
                onChanged: (bool value) {
                  if (value) {
                    settingsViewModel.setTheme(lightTheme);
                  }
                },
                // secondary: const Icon(Icons.wb_sunny), // Original secondary, removed for leading
              ),
              SwitchListTile(
                title: Text('Dark Theme'),
                value: settingsViewModel.currentTheme == darkTheme,
                secondary: Icon(Icons.brightness_6, color: Colors.green[700]), // Explicitly set color
                onChanged: (bool value) {
                  if (value) {
                    settingsViewModel.setTheme(darkTheme);
                  }
                },
                // secondary: const Icon(Icons.nightlight_round), // Original secondary, removed for leading
              ),
              const Divider(), // Divider after theme selection
              ListTile( // Changed from Padding/Text to ListTile for section header
                leading: Icon(Icons.dashboard_customize, color: Colors.green[700]), // Explicitly set color
                title: Text(
                  'Board Style',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              ...boardStyles.map((style) {
                  IconData specificIcon = Icons.style; // Default icon
                  if (style.name == 'Classic') {
                    specificIcon = Icons.view_compact;
                  } else if (style.name == 'Modern') {
                    specificIcon = Icons.view_quilt;
                  }
                  return RadioListTile<BoardStyle>(
                    title: Text(style.name),
                    value: style,
                    groupValue: settingsViewModel.currentBoardStyle,
                    secondary: Icon(specificIcon, color: Colors.green[700]), // Explicitly set color
                    onChanged: (BoardStyle? value) {
                      if (value != null) {
                        settingsViewModel.setBoardStyle(value);
                      }
                    },
                  );
              }),
              const Divider(), // Divider after board style options
              ListTile( // Changed from Padding/Text to ListTile for section header
                leading: Icon(Icons.person, color: Colors.green[700]), // Explicitly set color
                title: Text(
                  'Profile Information',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'User Name',
                  border: OutlineInputBorder(),
                  hintText: 'Enter your display name',
                ),
                onChanged: (value) {
                  settingsViewModel.setUserName(value);
                },
              ),
              const Divider(), // Divider after profile information (name TextField)
              SizedBox(height: 24), // Increased spacing - Kept for visual separation before header
              ListTile( // Changed from Text to ListTile for section header
                leading: Icon(Icons.collections, color: Colors.green[700]), // Explicitly set color
                title: Text(
                  'Select Avatar',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              const Divider(), // Divider after "Select Avatar" header
              // SizedBox(height: 8), // Original SizedBox, might not be needed if ListTile provides enough padding
              GridView.count(
                crossAxisCount: 5, // Show 5 avatars per row
                shrinkWrap: true, // Important for GridView inside ListView
                physics: NeverScrollableScrollPhysics(), // Disable GridView's scrolling
                mainAxisSpacing: 8.0,
                crossAxisSpacing: 8.0,
                children: predefinedAvatarUrls.map((url) {
                  final bool isSelected = settingsViewModel.avatarImageUrl == url;
                  return GestureDetector(
                    onTap: () {
                      settingsViewModel.setAvatarImageUrl(url);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.green[700]! : Colors.transparent,
                          width: 3.0,
                        ),
                      ),
                      child: CircleAvatar(
                        backgroundImage: NetworkImage(url),
                        radius: 30, // Adjust size as needed
                      ),
                    ),
                  );
                }).toList(),
              ),
              const Divider(), // Divider after avatar selection grid
              // SizedBox(height: 24), // Removed SizedBox as ListTile header will have its own padding.
              // The "Sound Settings" section header is next. The divider above separates avatar grid from sound settings.
              ListTile( // Changed from Padding/Text to ListTile for section header
                leading: Icon(Icons.volume_up_outlined, color: Colors.green[700]), // Explicitly set color
                title: Text(
                  'Sound Settings',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              const Divider(), // Divider after "Sound Settings" header
              SwitchListTile(
                title: Text('Enable Sounds'),
                value: settingsViewModel.isSoundEnabled,
                onChanged: (bool value) {
                  settingsViewModel.setSoundEnabled(value);
                },// Explicitly set color
                secondary: Icon(
                  settingsViewModel.isSoundEnabled ? Icons.volume_up : Icons.volume_off,
                  color: Colors.green[700], // Explicitly set color for dynamic icon
                ),
              ),
            ],
          ),
    ));
  });}
}
