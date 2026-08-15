import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_palette.dart';
import '../providers/theme_provider.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _authService = AuthService();
  bool _isLoading = false;

  Future<void> _signIn() async {
    setState(() => _isLoading = true);
    try {
      final result = await _authService.signInWithGoogle();
      if (result != null && mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_authService.getErrorMessage(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    return Scaffold(
      backgroundColor: AppPalette.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.favorite_rounded, color: AppPalette.primary, size: 64),
                      const SizedBox(height: 20),
                      Text('MoonnLove', style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 12),
                      Text(
                        'Masuk dengan akun Google yang sudah terverifikasi untuk melanjutkan.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppPalette.onSurfaceVariant),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: OutlinedButton.icon(
                          onPressed: _isLoading ? null : _signIn,
                          icon: _isLoading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.account_circle_outlined),
                          label: Text(_isLoading ? 'Memproses...' : 'Lanjutkan dengan Google'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Tidak ada pendaftaran atau login email/password.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: AppPalette.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
