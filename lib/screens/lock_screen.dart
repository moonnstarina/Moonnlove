import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_palette.dart';
import '../providers/theme_provider.dart';
import '../services/app_lock_service.dart';

Color get _background => AppPalette.background;
Color get _primary => AppPalette.primary;
Color get _primaryContainer => AppPalette.primaryContainer;
Color get _onPrimaryContainer => AppPalette.onPrimaryContainer;
Color get _onSurface => AppPalette.onSurface;
Color get _onSurfaceVariant => AppPalette.onSurfaceVariant;
Color get _surfaceLowest => AppPalette.surfaceLowest;
Color get _surfaceContainerLow => AppPalette.surfaceContainerLow;
Color get _error => AppPalette.error;

class LockScreen extends StatefulWidget {
  const LockScreen({super.key, required this.onUnlocked});

  final VoidCallback onUnlocked;

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final _lockService = AppLockService();
  String _pin = '';
  bool _hasError = false;
  bool _verifying = false;

  void _onDigit(String d) {
    if (_pin.length >= 4 || _verifying) return;
    setState(() {
      _pin += d;
      _hasError = false;
    });
    if (_pin.length == 4) {
      _verify();
    }
  }

  void _onBackspace() {
    if (_pin.isEmpty || _verifying) return;
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
      _hasError = false;
    });
  }

  Future<void> _verify() async {
    setState(() => _verifying = true);
    final ok = await _lockService.verify(_pin);
    if (!mounted) return;
    if (ok) {
      widget.onUnlocked();
    } else {
      setState(() {
        _pin = '';
        _hasError = true;
        _verifying = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: _primaryContainer.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.lock_rounded, color: _primary, size: 40),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Masukkan PIN',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: _onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Aplikasi dikunci',
                    style: TextStyle(fontSize: 14, color: _onSurfaceVariant),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (i) {
                      final filled = i < _pin.length;
                      final color = _hasError
                          ? _error
                          : filled
                              ? _primary
                              : _surfaceContainerLow;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 120),
                        width: 16,
                        height: 16,
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      );
                    }),
                  ),
                  if (_hasError) ...[
                    const SizedBox(height: 14),
                    Text(
                      'PIN salah, coba lagi',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _error,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            _buildNumpad(),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildNumpad() {
    const rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
    ];
    return Column(
      children: [
        for (final row in rows)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final d in row) _buildKey(d),
            ],
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 76),
            _buildKey('0'),
            _buildBackspace(),
          ],
        ),
      ],
    );
  }

  Widget _buildKey(String d) {
    return GestureDetector(
      onTap: () => _onDigit(d),
      child: Container(
        width: 72,
        height: 72,
        margin: const EdgeInsets.all(6),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _surfaceLowest,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: _onSurface.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          d,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: _onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildBackspace() {
    return GestureDetector(
      onTap: _onBackspace,
      child: Container(
        width: 72,
        height: 72,
        margin: const EdgeInsets.all(6),
        alignment: Alignment.center,
        child: Icon(
          Icons.backspace_outlined,
          color: _onSurfaceVariant,
          size: 26,
        ),
      ),
    );
  }
}
