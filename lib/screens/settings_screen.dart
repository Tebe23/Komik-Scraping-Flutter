import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_file/open_file.dart';
import '../services/theme_service.dart';
import '../services/history_service.dart';
import '../services/settings_service.dart';
import 'download_progress_screen.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ThemeService _themeService = ThemeService();
  final HistoryService _historyService = HistoryService();
  final SettingsService _settingsService = SettingsService();
  bool _isDarkMode = false;
  int _maxConcurrentDownloads = 3;

  @override
  void initState() {
    super.initState();
    _loadTheme();
    _loadSettings();
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

  Future<void> _loadSettings() async {
    _maxConcurrentDownloads = await _settingsService.getMaxConcurrentDownloads();
    if (mounted) setState(() {});
  }

  Future<void> _exportData(BuildContext context) async {
    try {
      var status = await Permission.storage.request();
      print('Status izin: $status');
      if (status.isGranted) {
        final data = await _historyService.exportData();

        // Tentukan direktori penyimpanan eksternal
        final externalDirectory =
            Directory('/storage/emulated/0/MyAppBackup/Backups');

        // Buat folder jika belum ada
        if (!(await externalDirectory.exists())) {
          await externalDirectory.create(recursive: true);
        }

        final filePath =
            '${externalDirectory.path}/data.txt'; // Tentukan nama file

        final file = File(filePath);
        await file.writeAsString(data);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Data berhasil disimpan ke $filePath')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Izin akses penyimpanan ditolak')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengekspor data: $e')),
      );
    }
  }

  Future<void> _importData(BuildContext context) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        String? filePath = result.files.single.path;
        if (filePath != null) {
          final file = File(filePath);
          final text = await file.readAsString();
          await _historyService.importData(text);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Data berhasil diimpor dari $filePath')),
          );
        }
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
            subtitle: Text('Simpan data ke lokasi yang ditentukan'),
            leading: Icon(Icons.backup),
            onTap: () => _exportData(context),
          ),
          ListTile(
            title: Text('Restore Data'),
            subtitle: Text('Pilih file untuk dipulihkan'),
            leading: Icon(Icons.restore),
            onTap: () => _importData(context),
          ),
          Divider(),
          ListTile(
            title: Text('Batas Manga Bersamaan'),
            subtitle: Text('Jumlah maksimal manga yang dapat diunduh sekaligus'),
            trailing: DropdownButton<int>(
              value: _maxConcurrentDownloads,
              items: [1, 2, 3, 4, 5].map((int value) {
                return DropdownMenuItem<int>(
                  value: value,
                  child: Text('$value manga'),
                );
              }).toList(),
              onChanged: (int? newValue) async {
                if (newValue != null) {
                  await _settingsService.setMaxConcurrentDownloads(newValue);
                  setState(() => _maxConcurrentDownloads = newValue);
                }
              },
            ),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.download),
            title: Text('Proses Unduhan'),
            subtitle: Text('Lihat dan kelola unduhan yang sedang berlangsung'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DownloadProgressScreen(),
                ),
              );
            },
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
