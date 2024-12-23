import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/theme_service.dart';
import '../services/history_service.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ThemeService _themeService = ThemeService();
  final HistoryService _historyService = HistoryService();
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final isDark = await _themeService.isDarkMode();
      if (!mounted) return;
      setState(() => _isDarkMode = isDark);
    } catch (e) {
      print('Error loading theme: $e');
    }
  }

  Future<void> _exportData(BuildContext context) async {
    try {
      final data = await _historyService.exportData();
      await Clipboard.setData(ClipboardData(text: data));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Data berhasil disalin ke clipboard')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengekspor data')),
      );
    }
  }

  Future<void> _importData(BuildContext context) async {
    try {
      final clipboardData = await Clipboard.getData('text/plain');
      final text = clipboardData?.text;
      if (text != null) {
        await _historyService.importData(text);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Data berhasil diimpor')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tidak ada data di clipboard')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengimpor data')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pengaturan'),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: Text('Mode Gelap'),
            subtitle: Text('Mengubah tema aplikasi'),
            value: _isDarkMode,
            onChanged: (value) async {
              try {
                await _themeService.setDarkMode(value);
                if (!mounted) return;
                setState(() => _isDarkMode = value);
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Gagal mengubah tema')),
                );
              }
            },
          ),
          Divider(),
          ListTile(
            title: Text('Backup Data'),
            subtitle: Text('Salin data ke clipboard'),
            leading: Icon(Icons.backup),
            onTap: () => _exportData(context),
          ),
          ListTile(
            title: Text('Restore Data'),
            subtitle: Text('Tempel data dari clipboard'),
            leading: Icon(Icons.restore),
            onTap: () => _importData(context),
          ),
          Divider(),
          AboutListTile(
            icon: Icon(Icons.info),
            applicationName: 'KomikApp',
            applicationVersion: '1.0.0',
            applicationLegalese: '© 2024 KomikApp',
            aboutBoxChildren: [
              SizedBox(height: 16),
              Text('Aplikasi pembaca komik online'),
            ],
          ),
        ],
      ),
    );
  }
}
