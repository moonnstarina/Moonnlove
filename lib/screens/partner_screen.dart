import '../providers/app_palette.dart';
import '../providers/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/partner_service.dart';

Color get _primary => AppPalette.primary;
Color get _onSurface => AppPalette.onSurface;
Color get _onSurfaceVariant => AppPalette.onSurfaceVariant;
Color get _surfaceLowest => AppPalette.surfaceLowest;
Color get _surfaceVariant => AppPalette.surfaceVariant;

class PartnerScreen extends StatefulWidget {
  const PartnerScreen({super.key});

  @override
  State<PartnerScreen> createState() => _PartnerScreenState();
}

class _PartnerScreenState extends State<PartnerScreen> {
  final _partnerService = PartnerService();
  final _codeController = TextEditingController();
  String _myCode = '';
  String _partnerName = '';
  bool _loading = true;
  bool _pairing = false;
  bool _isPaired = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final myCode = await _partnerService.getMyCode();
      final partnerData = await _partnerService.getPartnerData();
      if (mounted) {
        setState(() {
          _myCode = myCode;
          _isPaired = partnerData != null;
          _partnerName = partnerData?['name'] ?? '';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pair() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan kode pasangan')),
      );
      return;
    }

    setState(() => _pairing = true);
    try {
      final result = await _partnerService.pairByCode(code);
      if (mounted) {
        setState(() {
          _isPaired = true;
          _partnerName = result['partner_name']?.toString() ?? '';
        });
        _codeController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terhubung dengan ${result['partner_name']}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _pairing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    return Scaffold(
      backgroundColor: _surfaceLowest,
      appBar: AppBar(
        backgroundColor: _surfaceLowest,
        elevation: 0,
        foregroundColor: _onSurface,
        title: const Text('Hubungkan Pasangan'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_isPaired)
                    _buildPairedCard()
                  else ...[
                    _buildInviteSection(),
                    const SizedBox(height: 28),
                    const Divider(),
                    const SizedBox(height: 28),
                    _buildPairSection(),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildPairedCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF1DEDE),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(Icons.favorite, color: _primary, size: 48),
          const SizedBox(height: 12),
          Text(
            'Terhubung dengan pasangan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _partnerName.isEmpty ? 'Partner' : _partnerName,
            style: TextStyle(fontSize: 16, color: _primary),
          ),
          const SizedBox(height: 12),
          Text(
            'Kamu sudah terhubung, bisa langsung chat, kirim lokasi, dan lainnya.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: _onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildInviteSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF1DEDE),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            'Kode Kamu',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _myCode,
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w700,
              letterSpacing: 8,
              color: _primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Kirim kode ini ke pasanganmu',
            style: TextStyle(fontSize: 14, color: _onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _myCode));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Kode disalin')),
              );
            },
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('Salin Kode'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _primary,
              side: BorderSide(color: _primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPairSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Masukkan kode pasangan',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _onSurface,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _codeController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            letterSpacing: 8,
            fontWeight: FontWeight.w700,
            color: _onSurface,
          ),
          decoration: InputDecoration(
            counterText: '',
            hintText: '••••••',
            hintStyle: TextStyle(
              color: _onSurfaceVariant.withOpacity(0.4),
              fontSize: 24,
            ),
            filled: true,
            fillColor: const Color(0xFFF3F4F5),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _surfaceVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _surfaceVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _primary, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _pairing ? null : _pair,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            child: _pairing
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Hubungkan',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ],
    );
  }
}
