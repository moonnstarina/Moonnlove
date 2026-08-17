import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_palette.dart';
import '../providers/theme_provider.dart';
import '../services/app_lock_service.dart';

Color get _background => AppPalette.background;
Color get _primary => AppPalette.primary;
Color get _onSurface => AppPalette.onSurface;
Color get _onSurfaceVariant => AppPalette.onSurfaceVariant;
Color get _surfaceLowest => AppPalette.surfaceLowest;
Color get _surfaceContainerLow => AppPalette.surfaceContainerLow;
Color get _surfaceContainerHigh => AppPalette.surfaceContainerHigh;
Color get _primaryContainer => AppPalette.primaryContainer;
Color get _onPrimaryContainer => AppPalette.onPrimaryContainer;
Color get _error => AppPalette.error;
Color get _errorContainer => AppPalette.errorContainer;

class LockSettingsScreen extends StatefulWidget {
  const LockSettingsScreen({super.key});

  @override
  State<LockSettingsScreen> createState() => _LockSettingsScreenState();
}

class _LockSettingsScreenState extends State<LockSettingsScreen> {
  final _lockService = AppLockService();
  bool _enabled = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final enabled = await _lockService.isEnabled();
    if (mounted) {
      setState(() {
        _enabled = enabled;
        _loading = false;
      });
    }
  }

  Future<void> _toggle(bool value) async {
    if (value) {
      final pin = await _showPinDialog();
      if (pin != null) {
        await _lockService.enable(pin);
        if (mounted) {
          setState(() => _enabled = true);
          _showSnack('Kunci aplikasi aktif');
        }
      }
    } else {
      final confirmed = await _confirmDisable();
      if (confirmed == true) {
        await _lockService.disable();
        if (mounted) {
          setState(() => _enabled = false);
          _showSnack('Kunci aplikasi dimatikan');
        }
      }
    }
  }

  Future<void> _changePin() async {
    final pin = await _showPinDialog();
    if (pin != null) {
      await _lockService.changePin(pin);
      if (mounted) _showSnack('PIN berhasil diganti');
    }
  }

  Future<String?> _showPinDialog() async {
    final first = TextEditingController();
    final second = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          bool valid() {
            final a = first.text.trim();
            final b = second.text.trim();
            return a.length == 4 && a == b;
          }

          return AlertDialog(
            backgroundColor: _surfaceLowest,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Text(
              _enabled ? 'Ganti PIN' : 'Buat PIN',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: first,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  obscureText: true,
                  style: const TextStyle(fontSize: 20, letterSpacing: 8),
                  decoration: const InputDecoration(
                    labelText: 'PIN baru (4 digit)',
                    counterText: '',
                  ),
                  onChanged: (_) => setDialogState(() {}),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: second,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  obscureText: true,
                  style: const TextStyle(fontSize: 20, letterSpacing: 8),
                  decoration: const InputDecoration(
                    labelText: 'Ulangi PIN',
                    counterText: '',
                  ),
                  onChanged: (_) => setDialogState(() {}),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Batal',
                  style: TextStyle(color: _onSurfaceVariant),
                ),
              ),
              FilledButton(
                onPressed: valid() ? () => Navigator.pop(context, first.text.trim()) : null,
                style: FilledButton.styleFrom(
                  backgroundColor: _primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: const Text('Simpan'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<bool?> _confirmDisable() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _surfaceLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Matikan kunci aplikasi?',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Aplikasi tidak akan minta PIN saat dibuka.',
          style: TextStyle(color: _onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Batal',
              style: TextStyle(color: _onSurfaceVariant),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: _error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            child: const Text('Matikan'),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: Text(
          'Kunci Aplikasi',
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
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _surfaceLowest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _primaryContainer.withOpacity(0.4),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.lock_rounded,
                          color: _primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Kunci Aplikasi',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: _onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _enabled
                                  ? 'Minta PIN setiap kali app dibuka'
                                  : 'Amankan app dengan PIN 4 digit',
                              style: TextStyle(
                                fontSize: 13,
                                color: _onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _enabled,
                        activeColor: _primary,
                        onChanged: _toggle,
                      ),
                    ],
                  ),
                ),
                if (_enabled) ...[
                  const SizedBox(height: 16),
                  _buildActionTile(
                    icon: Icons.password_rounded,
                    label: 'Ganti PIN',
                    onTap: _changePin,
                  ),
                ],
                const SizedBox(height: 24),
                Text(
                  'PIN hanya disimpan di perangkat ini dan tidak dikirim ke server.',
                  style: TextStyle(fontSize: 13, color: _onSurfaceVariant),
                ),
              ],
            ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _surfaceLowest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _surfaceContainerHigh,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: _primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _onSurface,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: _onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
