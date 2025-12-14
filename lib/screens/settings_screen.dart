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
import '../widgets/islamic_pattern_painter.dart';

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
    // Use Hive.isBoxOpen to reuse already open box
    if (Hive.isBoxOpen(_settingsBoxName)) {
      _settingsBox = Hive.box<AppSettings>(_settingsBoxName);
    } else {
      _settingsBox = await Hive.openBox<AppSettings>(_settingsBoxName);
    }

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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              dialHandColor: Theme.of(context).colorScheme.primary,
              dialBackgroundColor: Theme.of(context).colorScheme.surface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _settings!.notificationHour = picked.hour;
        _settings!.notificationMinute = picked.minute;
      });
      await _saveSettings();
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    if (_settings == null) return;

    if (value) {
      final hasPermission = await _notificationService.requestPermissions();
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Notification permission denied')),
          );
        }
        return;
      }
    }

    setState(() {
      _settings!.notificationsEnabled = value;
    });
    await _saveSettings();
  }

  Future<void> _toggleQuickGlance(bool value) async {
    if (_settings == null) return;
    setState(() {
      _settings!.enableQuickGlance = value;
    });
    await _saveSettings();

    // If enabling, we might want to show an immediate notification or update the service
    // Assuming NotificationService handles this based on settings or we need to trigger it
    // For now, we just save the setting as per previous implementation logic
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_settings == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(theme),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSectionHeader('Appearance', Icons.palette, theme),
                _buildThemeSection(theme),
                const SizedBox(height: 24),

                _buildSectionHeader(
                  'Notifications',
                  Icons.notifications,
                  theme,
                ),
                _buildNotificationSection(theme),
                const SizedBox(height: 24),

                _buildSectionHeader('Data & Storage', Icons.storage, theme),
                _buildDataSection(theme),
                const SizedBox(height: 24),

                _buildSectionHeader('Widget', Icons.widgets, theme),
                _buildWidgetSection(theme),
                const SizedBox(height: 24),

                _buildSectionHeader('About', Icons.info_outline, theme),
                _buildAboutSection(theme),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(ThemeData theme) {
    return SliverAppBar(
      expandedHeight: 200.0,
      floating: false,
      pinned: true,
      backgroundColor: theme.colorScheme.primary,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        centerTitle: true,
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.secondary,
                  ],
                ),
              ),
            ),
            CustomPaint(
              painter: IslamicPatternPainter(color: Colors.white, opacity: 0.1),
            ),
            Positioned(
              bottom: -20,
              right: -20,
              child: Icon(
                Icons.settings,
                size: 150,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: theme.colorScheme.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.titleLarge?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(Widget child, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(24), child: child),
    );
  }

  Widget _buildThemeSection(ThemeData theme) {
    return _buildCard(
      ListenableBuilder(
        listenable: _themeService,
        builder: (context, child) {
          return Column(
            children: [
              _buildRadioTile(
                'Light Mode',
                Icons.wb_sunny_rounded,
                AppThemeMode.light,
                theme,
              ),
              Divider(height: 1, color: theme.dividerColor.withOpacity(0.1)),
              _buildRadioTile(
                'Dark Mode',
                Icons.nightlight_round,
                AppThemeMode.dark,
                theme,
              ),
              Divider(height: 1, color: theme.dividerColor.withOpacity(0.1)),
              _buildRadioTile(
                'System Default',
                Icons.brightness_auto,
                AppThemeMode.system,
                theme,
              ),
            ],
          );
        },
      ),
      theme,
    );
  }

  Widget _buildRadioTile(
    String title,
    IconData icon,
    AppThemeMode value,
    ThemeData theme,
  ) {
    final isSelected = _themeService.currentThemeMode == value;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _themeService.setThemeMode(value),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? theme.colorScheme.primary : Colors.grey,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isSelected ? theme.colorScheme.primary : null,
                  ),
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle, color: theme.colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationSection(ThemeData theme) {
    return _buildCard(
      Column(
        children: [
          SwitchListTile(
            value: _settings!.notificationsEnabled,
            onChanged: _toggleNotifications,
            title: const Text('Daily Reminders'),
            subtitle: const Text('Get notified to read your daily ayah'),
            activeThumbColor: theme.colorScheme.primary,
            secondary: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _settings!.notificationsEnabled
                    ? theme.colorScheme.primary.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_active,
                size: 20,
                color: _settings!.notificationsEnabled
                    ? theme.colorScheme.primary
                    : Colors.grey,
              ),
            ),
          ),
          if (_settings!.notificationsEnabled) ...[
            Divider(height: 1, color: theme.dividerColor.withOpacity(0.1)),
            ListTile(
              onTap: _pickTime,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.access_time,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
              ),
              title: const Text('Reminder Time'),
              trailing: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Text(
                  _settings!.notificationTimeString,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
            Divider(height: 1, color: theme.dividerColor.withOpacity(0.1)),
            ListTile(
              onTap: () async {
                await _notificationService.showTestNotification();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Test notification sent! Check notification bar.',
                      ),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.send,
                  size: 20,
                  color: theme.colorScheme.secondary,
                ),
              ),
              title: const Text('Test Notification'),
              subtitle: const Text('Send a test notification now'),
            ),
          ],
          Divider(height: 1, color: theme.dividerColor.withOpacity(0.1)),
          SwitchListTile(
            value: _settings!.enableQuickGlance,
            onChanged: _toggleQuickGlance,
            title: const Text('Quick Glance'),
            subtitle: const Text('Persistent notification for easy access'),
            activeThumbColor: theme.colorScheme.primary,
            secondary: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _settings!.enableQuickGlance
                    ? theme.colorScheme.primary.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.visibility,
                size: 20,
                color: _settings!.enableQuickGlance
                    ? theme.colorScheme.primary
                    : Colors.grey,
              ),
            ),
          ),
        ],
      ),
      theme,
    );
  }

  Widget _buildDataSection(ThemeData theme) {
    return _buildCard(
      Column(
        children: [
          _buildActionTile(
            'Export Favorites',
            'Backup your collection',
            Icons.upload_file,
            () async {
              final backupService = BackupService();
              await backupService.exportFavorites(context);
            },
            theme,
            showChevron: false,
          ),
          Divider(height: 1, color: theme.dividerColor.withOpacity(0.1)),
          _buildActionTile(
            'Import Favorites',
            'Restore from backup',
            Icons.file_download,
            () async {
              final backupService = BackupService();
              await backupService.importFavorites(context);
            },
            theme,
            showChevron: false,
          ),
          Divider(height: 1, color: theme.dividerColor.withOpacity(0.1)),
          _buildActionTile(
            'Weekly Digest',
            'Generate PDF summary',
            Icons.picture_as_pdf,
            () async {
              final pdfService = PdfService();
              await pdfService.generateAndShareWeeklyDigest();
            },
            theme,
            showChevron: false,
          ),
        ],
      ),
      theme,
    );
  }

  Widget _buildWidgetSection(ThemeData theme) {
    return _buildCard(
      Column(
        children: [
          _buildActionTile(
            'Refresh Widget',
            'Update home screen content',
            Icons.refresh,
            () async {
              await _widgetService.updateWidget();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Widget refreshed successfully!'),
                  ),
                );
              }
            },
            theme,
            showChevron: false,
          ),
          Divider(height: 1, color: theme.dividerColor.withOpacity(0.1)),
          _buildActionTile(
            'Add to Home Screen',
            'Pin the Daily Ayah widget',
            Icons.add_to_home_screen,
            () async {
              try {
                await HomeWidget.requestPinWidget(
                  androidName: 'DailyAyahWidgetProvider',
                );
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Could not pin widget: $e')),
                  );
                }
              }
            },
            theme,
            showChevron: false,
          ),
        ],
      ),
      theme,
    );
  }

  Widget _buildAboutSection(ThemeData theme) {
    return _buildCard(
      Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.menu_book,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Daily Ayah',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Version 1.0.0',
                      style: TextStyle(color: theme.textTheme.bodySmall?.color),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'A beautiful companion for your daily Quran reading journey. Designed with love and care for the Ummah.',
              style: TextStyle(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
      theme,
    );
  }

  Widget _buildActionTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
    ThemeData theme, {
    bool showChevron = true,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: theme.dividerColor.withOpacity(0.5),
                  ),
                ),
                child: Icon(icon, size: 20, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),
              if (showChevron)
                Icon(Icons.chevron_right, color: theme.dividerColor, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
