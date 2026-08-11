import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/partner_service.dart';

const Color _primary = Color(0xFF964549);
const Color _onSurface = Color(0xFF191C1D);
const Color _onSurfaceVariant = Color(0xFF544242);

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  static const List<Color> _presetColors = [
    Color(0xFFE91E63),
    Color(0xFF9C27B0),
    Color(0xFF3F51B5),
    Color(0xFF2196F3),
    Color(0xFF009688),
    Color(0xFF4CAF50),
    Color(0xFFFF9800),
    Color(0xFF795548),
    Color(0xFF607D8B),
    Color(0xFFF44336),
  ];

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
    final themeProvider = context.watch<ThemeProvider>();
    final primaryColor = themeProvider.primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
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
          const Text(
            'Tema',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _presetColors.map((color) {
              final isSelected = primaryColor.value == color.value;
              return GestureDetector(
                onTap: () => themeProvider.setPrimaryColor(color),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.transparent,
                      width: 3,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: color.withOpacity(0.5),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ]
                        : [],
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white)
                      : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Dark Mode'),
            subtitle: const Text('Mode gelap'),
            secondary: Icon(
              themeProvider.themeMode == ThemeMode.dark
                  ? Icons.dark_mode_rounded
                  : Icons.light_mode_rounded,
              color: primaryColor,
            ),
            value: themeProvider.themeMode == ThemeMode.dark,
            onChanged: (_) => themeProvider.toggleTheme(),
          ),
          const Divider(),
          if (!_loading && !_isPaired)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.person_add_rounded, color: primaryColor),
              title: const Text('Hubungkan Pasangan'),
              subtitle: const Text('Kirim undangan ke pasangan'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.pushNamed(context, '/partner'),
            ),
          if (!_loading && _isPaired) ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.favorite_rounded, color: primaryColor),
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
              leading: Icon(Icons.cake_rounded, color: primaryColor),
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
