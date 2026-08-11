import 'package:flutter/material.dart';
import '../services/auth_service.dart';

const Color _primary = Color(0xFF964549);
const Color _onSurface = Color(0xFF191C1D);
const Color _onSurfaceVariant = Color(0xFF544242);
const Color _surfaceLowest = Color(0xFFFFFFFF);
const Color _surfaceVariant = Color(0xFFE1E3E4);

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _register() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua field harus diisi')),
      );
      return;
    }

    if (_passwordController.text != _confirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password tidak cocok')),
      );
      return;
    }

    if (_passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password minimal 6 karakter')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authService.register(
        _emailController.text.trim(),
        _passwordController.text,
        _nameController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Register berhasil! Silakan login')),
        );
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Register gagal: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surfaceLowest,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFEDEEEF),
                    foregroundColor: _onSurface,
                  ),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
              ),
              const SizedBox(height: 16),
              const _Header(),
              const SizedBox(height: 32),
              _buildField(
                label: 'Nama Lengkap',
                controller: _nameController,
                icon: Icons.person_outline_rounded,
              ),
              const SizedBox(height: 16),
              _buildField(
                label: 'Email',
                controller: _emailController,
                icon: Icons.alternate_email_rounded,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              _buildField(
                label: 'Password',
                controller: _passwordController,
                icon: Icons.lock_outline_rounded,
                obscure: _obscurePassword,
                suffix: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: _onSurfaceVariant,
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
              ),
              const SizedBox(height: 16),
              _buildField(
                label: 'Konfirmasi Password',
                controller: _confirmController,
                icon: Icons.lock_outline_rounded,
                obscure: true,
              ),
              const SizedBox(height: 28),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shadowColor: _primary.withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Daftar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Sudah punya akun? ',
                    style: TextStyle(
                      fontSize: 14,
                      color: _onSurfaceVariant.withOpacity(0.9),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text(
                      'Login',
                      style: TextStyle(
                        color: _primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffix,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(
        color: _onSurface,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: _onSurfaceVariant,
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
        floatingLabelStyle: const TextStyle(
          color: _primary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        prefixIcon: Icon(icon, color: _onSurfaceVariant, size: 22),
        suffixIcon: suffix,
        filled: true,
        fillColor: _surfaceLowest,
        contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
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
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Buat akun baru',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: _onSurface,
                letterSpacing: -0.02,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.favorite, color: _primary, size: 28),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Mulai perjalanan cinta kita di LoveNest',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: _onSurfaceVariant.withOpacity(0.9),
          ),
        ),
      ],
    );
  }
}
