import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isDarkMode = false;
  String imageQuality = 'Medium';
  bool useExternalDownloader = false;
  String downloadLocation = 'Default Location';
  bool autoUpdateCheck = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          _buildSettingsSection('Appearance', [
            SwitchListTile(
              title: const Text('Dark Mode'),
              subtitle: const Text('Enable dark theme for the app'),
              value: isDarkMode,
              onChanged: (value) {
                setState(() {
                  isDarkMode = value;
                });
                _saveSettings();
              },
            ),
            ListTile(
              title: const Text('Image Quality'),
              subtitle: const Text('Select image quality for reading'),
              trailing: DropdownButton<String>(
                value: imageQuality,
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      imageQuality = newValue;
                    });
                    _saveSettings();
                  }
                },
                items: <String>['Low', 'Medium', 'High']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ),
          ]),
          // Additional settings sections can be added here
        ],
      ),
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ),
        ...children,
        const Divider(),
      ],
    );
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDarkMode);
    await prefs.setString('imageQuality', imageQuality);
    await prefs.setBool('useExternalDownloader', useExternalDownloader);
    await prefs.setString('downloadLocation', downloadLocation);
    await prefs.setBool('autoUpdateCheck', autoUpdateCheck);
  }
}
