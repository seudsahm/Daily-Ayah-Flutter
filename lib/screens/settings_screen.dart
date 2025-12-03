import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:home_widget/home_widget.dart';
import '../models/app_settings.dart';
import '../services/notification_service.dart';
import '../services/widget_service.dart';
import '../services/theme_service.dart';
import '../services/backup_service.dart';
import '../services/pdf_service.dart';
import '../models/theme_mode.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const String _settingsBoxName = 'settings';
  static const String _settingsKey = 'app_settings';

  final NotificationService _notificationService = NotificationService();
  final WidgetService _widgetService = WidgetService();
  final ThemeService _themeService = ThemeService();
  Box<AppSettings>? _settingsBox;
  AppSettings? _settings;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _settingsBox = await Hive.openBox<AppSettings>(_settingsBoxName);

    setState(() {
      _settings = _settingsBox!.get(_settingsKey);
      if (_settings == null) {
        _settings = AppSettings();
        _settingsBox!.put(_settingsKey, _settings!);
      }
    });
  }

  Future<void> _saveSettings() async {
    if (_settings != null && _settingsBox != null) {
      await _settingsBox!.put(_settingsKey, _settings!);

      // Reschedule notifications
      if (_settings!.notificationsEnabled) {
        await _notificationService.scheduleDailyNotification(
          hour: _settings!.notificationHour,
          minute: _settings!.notificationMinute,
        );
      } else {
        await _notificationService.cancelAllNotifications();
      }
    }
  }

  Future<void> _pickTime() async {
    if (_settings == null) return;

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: _settings!.notificationHour,
        minute: _settings!.notificationMinute,
      ),
    );

    if (picked != null) {
      setState(() {
        _settings!.notificationHour = picked.hour;
        _settings!.notificationMinute = picked.minute;
      });
      await _saveSettings();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Reminder time updated to ${_settings!.notificationTimeString}',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    if (_settings == null) return;

    if (value) {
      // Request permission before enabling
      final hasPermission = await _notificationService.requestPermissions();
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notification permission denied'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
    }

    setState(() {
      _settings!.notificationsEnabled = value;
    });
    await _saveSettings();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value ? 'Notifications enabled' : 'Notifications disabled',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _testNotification() async {
    await _notificationService.showTestNotification();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Test notification sent!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _refreshWidget() async {
    await _widgetService.updateWidget();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Widget refreshed successfully!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _settings == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Theme Section
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.palette, color: Color(0xFF1B5E20)),
                            SizedBox(width: 12),
                            Text(
                              'Appearance',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Choose your preferred theme',
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 16),

                        // Theme options
                        ListenableBuilder(
                          listenable: _themeService,
                          builder: (context, child) {
                            return Column(
                              children: [
                                RadioListTile<AppThemeMode>(
                                  title: const Row(
                                    children: [
                                      Icon(Icons.brightness_5, size: 20),
                                      SizedBox(width: 8),
                                      Text('Light'),
                                    ],
                                  ),
                                  value: AppThemeMode.light,
                                  groupValue: _themeService.currentThemeMode,
                                  onChanged: (value) {
                                    if (value != null) {
                                      _themeService.setThemeMode(value);
                                    }
                                  },
                                ),
                                RadioListTile<AppThemeMode>(
                                  title: const Row(
                                    children: [
                                      Icon(Icons.brightness_2, size: 20),
                                      SizedBox(width: 8),
                                      Text('Dark'),
                                    ],
                                  ),
                                  value: AppThemeMode.dark,
                                  groupValue: _themeService.currentThemeMode,
                                  onChanged: (value) {
                                    if (value != null) {
                                      _themeService.setThemeMode(value);
                                    }
                                  },
                                ),
                                RadioListTile<AppThemeMode>(
                                  title: const Row(
                                    children: [
                                      Icon(Icons.brightness_auto, size: 20),
                                      SizedBox(width: 8),
                                      Text('System'),
                                    ],
                                  ),
                                  subtitle: const Text(
                                    'Follow device settings',
                                  ),
                                  value: AppThemeMode.system,
                                  groupValue: _themeService.currentThemeMode,
                                  onChanged: (value) {
                                    if (value != null) {
                                      _themeService.setThemeMode(value);
                                    }
                                  },
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Notifications Section
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.notifications, color: Color(0xFF1B5E20)),
                            SizedBox(width: 12),
                            Text(
                              'Daily Reminders',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Get a daily reminder to read your ayah',
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 16),

                        // Enable/Disable Switch
                        SwitchListTile(
                          value: _settings!.notificationsEnabled,
                          onChanged: _toggleNotifications,
                          title: const Text('Enable Reminders'),
                          activeColor: const Color(0xFF1B5E20),
                          contentPadding: EdgeInsets.zero,
                        ),

                        const Divider(),

                        // Time Picker
                        ListTile(
                          leading: const Icon(
                            Icons.access_time,
                            color: Color(0xFF1B5E20),
                          ),
                          title: const Text('Reminder Time'),
                          subtitle: Text(_settings!.notificationTimeString),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: _settings!.notificationsEnabled
                              ? _pickTime
                              : null,
                          enabled: _settings!.notificationsEnabled,
                          contentPadding: EdgeInsets.zero,
                        ),

                        const Divider(),

                        // Test Notification Button
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _testNotification,
                            icon: const Icon(Icons.send),
                            label: const Text('Send Test Notification'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF1B5E20),
                              side: const BorderSide(color: Color(0xFF1B5E20)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Data & Storage Section
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.storage, color: Color(0xFF1B5E20)),
                            SizedBox(width: 12),
                            Text(
                              'Data & Storage',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          leading: const Icon(
                            Icons.upload_file,
                            color: Color(0xFF1B5E20),
                          ),
                          title: const Text('Export Favorites'),
                          subtitle: const Text(
                            'Backup your favorites to a file',
                          ),
                          onTap: () async {
                            final backupService = BackupService();
                            await backupService.exportFavorites(context);
                          },
                          contentPadding: EdgeInsets.zero,
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(
                            Icons.file_download,
                            color: Color(0xFF1B5E20),
                          ),
                          title: const Text('Import Favorites'),
                          subtitle: const Text('Restore favorites from backup'),
                          onTap: () async {
                            final backupService = BackupService();
                            await backupService.importFavorites(context);
                          },
                          contentPadding: EdgeInsets.zero,
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(
                            Icons.picture_as_pdf,
                            color: Color(0xFF1B5E20),
                          ),
                          title: const Text('Weekly Digest'),
                          subtitle: const Text(
                            'Generate PDF of recent activity',
                          ),
                          onTap: () async {
                            final pdfService = PdfService();
                            await pdfService.generateAndShareWeeklyDigest();
                          },
                          contentPadding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Quick Glance Section
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.visibility, color: Color(0xFF1B5E20)),
                            SizedBox(width: 12),
                            Text(
                              'Quick Glance',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Show today\'s ayah in a persistent notification',
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 16),

                        Switch.adaptive(
                          value: _settings!.enableQuickGlance,
                          onChanged: (value) async {
                            setState(() {
                              _settings!.enableQuickGlance = value;
                            });
                            await _settingsBox!.put(_settingsKey, _settings!);

                            if (value) {
                              // Show pinned notification
                              // TODO: Get today's ayah and show it
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Quick glance enabled'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            } else {
                              await _notificationService.cancelQuickGlance();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Quick glance disabled'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Widget Section
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.widgets, color: Color(0xFF1B5E20)),
                            SizedBox(width: 12),
                            Text(
                              'Home Screen Widget',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Keep your home screen widget up to date',
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _refreshWidget,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Refresh Widget'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF1B5E20),
                              side: const BorderSide(color: Color(0xFF1B5E20)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              try {
                                await HomeWidget.requestPinWidget(
                                  androidName: 'DailyAyahWidgetProvider',
                                );
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Could not pin widget: $e'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.add_to_home_screen),
                            label: const Text('Add to Home Screen'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1B5E20),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // App Info Section
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.info_outline, color: Color(0xFF1B5E20)),
                            SizedBox(width: 12),
                            Text(
                              'About',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow('App Name', 'Daily Ayah'),
                        _buildInfoRow('Version', '1.0.0'),
                        _buildInfoRow('Total Ayahs', '6,236'),
                        const SizedBox(height: 8),
                        const Text(
                          'A beautiful app to read a different Quranic verse every day.',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
