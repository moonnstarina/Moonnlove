import '../providers/app_palette.dart';
import '../providers/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import '../services/partner_service.dart';

Color get _background => AppPalette.background;
Color get _primary => AppPalette.primary;
Color get _surfaceLowest => AppPalette.surfaceLowest;
Color get _onSurface => AppPalette.onSurface;
Color get _onSurfaceVariant => AppPalette.onSurfaceVariant;
Color get _secondaryContainer => AppPalette.secondaryContainer;

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final _partnerService = PartnerService();

  bool _messages = true;
  bool _streak = true;
  bool _anniversary = true;
  bool _love = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await _partnerService.getNotificationPrefs();
    if (!mounted) return;
    setState(() {
      _messages = prefs['messages'] ?? true;
      _streak = prefs['streak'] ?? true;
      _anniversary = prefs['anniversary'] ?? true;
      _love = prefs['love'] ?? true;
      _loading = false;
    });
  }

  Future<void> _save(String key, bool value) async {
    setState(() {
      if (key == 'messages') _messages = value;
      if (key == 'streak') _streak = value;
      if (key == 'anniversary') _anniversary = value;
      if (key == 'love') _love = value;
    });
    await _partnerService.saveNotificationPrefs({
      'messages': _messages,
      'streak': _streak,
      'anniversary': _anniversary,
      'love': _love,
    });
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: Text(
          'Notifikasi',
          style: TextStyle(color: _onSurface),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: _onSurface,
      ),
        body: _loading
          ? Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _surfaceLowest.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: _surfaceLowest.withOpacity(0.5)),
                    boxShadow: [
                      BoxShadow(
                        color: AppPalette.cardShadow,
                        blurRadius: 30,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildToggle(
                        icon: Icons.chat_bubble_rounded,
                        title: 'Pesan Baru',
                        subtitle: 'Notifikasi chat dari pasangan',
                        value: _messages,
                        onChanged: (v) => _save('messages', v),
                      ),
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: AppPalette.surfaceVariant,
                      ),
                      _buildToggle(
                        icon: Icons.local_fire_department_rounded,
                        title: 'Streak',
                        subtitle: 'Pengingat streak harian',
                        value: _streak,
                        onChanged: (v) => _save('streak', v),
                      ),
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: AppPalette.surfaceVariant,
                      ),
                      _buildToggle(
                        icon: Icons.cake_rounded,
                        title: 'Anniversary',
                        subtitle: 'Pengingat tanggal jadian',
                        value: _anniversary,
                        onChanged: (v) => _save('anniversary', v),
                      ),
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: AppPalette.surfaceVariant,
                      ),
                      _buildToggle(
                        icon: Icons.favorite_rounded,
                        title: 'Momen & Foto',
                        subtitle: 'Notifikasi foto atau momen baru',
                        value: _love,
                        onChanged: (v) => _save('love', v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Pengaturan tersimpan otomatis dan disinkronkan ke pasangan.',
                  style: TextStyle(fontSize: 12, color: _onSurfaceVariant),
                ),
              ],
            ),
    );
  }

  Widget _buildToggle({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: _onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 13, color: _onSurfaceVariant),
      ),
      secondary: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _secondaryContainer,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: _primary, size: 22),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: _primary,
      activeTrackColor: AppPalette.primaryContainer,
    );
  }
}
