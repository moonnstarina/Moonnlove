import '../providers/app_palette.dart';
import 'package:flutter/material.dart';
import '../services/partner_service.dart';

Color get _primary => AppPalette.primary;
Color get _onSurface => AppPalette.onSurface;
Color get _onSurfaceVariant => AppPalette.onSurfaceVariant;

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final _partnerService = PartnerService();
  bool _isPaired = false;
  bool _loading = true;
  DateTime? _anniversary;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final isPaired = await _partnerService.isPaired();
    final anniversary = await _partnerService.getAnniversary();
    if (mounted) {
      setState(() {
        _isPaired = isPaired;
        _anniversary = anniversary;
        _loading = false;
      });
    }
  }

  Future<void> _pickAnniversary() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _anniversary ?? now,
      firstDate: DateTime(2000),
      lastDate: now,
      helpText: 'Tanggal Jadian',
      cancelText: 'Batal',
      confirmText: 'Simpan',
    );
    if (picked == null) return;
    await _partnerService.saveAnniversary(picked);
    if (mounted) {
      setState(() => _anniversary = picked);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tanggal jadian disimpan!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Pengaturan Akun',
          style: TextStyle(color: _onSurface),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: _onSurface,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (!_loading && !_isPaired)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.person_add_rounded, color: _primary),
              title: const Text('Hubungkan Pasangan'),
              subtitle: const Text('Kirim undangan ke pasangan'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.pushNamed(context, '/partner'),
            ),
          if (!_loading && _isPaired) ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.favorite_rounded, color: _primary),
              title: const Text('Pasangan'),
              subtitle: const Text('Kamu sudah terhubung'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.pushNamed(context, '/partner'),
            ),
            const Divider(),
          ],
          if (_isPaired) ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.cake_rounded, color: _primary),
              title: const Text('Tanggal Jadian'),
              subtitle: Text(
                _anniversary != null
                    ? _formatDate(_anniversary!)
                    : 'Set anniversary countdown',
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: _pickAnniversary,
            ),
            const Divider(),
          ],
        ],
      ),
    );
  }
}
