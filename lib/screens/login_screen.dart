import '../providers/app_palette.dart';
import '../providers/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

Color get _bg => AppPalette.background;
Color get _primary => AppPalette.primary;
Color get _primaryContainer => AppPalette.primaryContainer;
Color get _onSurface => AppPalette.onSurface;
Color get _onSurfaceVariant => AppPalette.onSurfaceVariant;
Color get _surfaceLowest => AppPalette.surfaceLowest;
Color get _outlineVariant => AppPalette.outlineVariant;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;
  late final AnimationController _heartController;

  @override
  void initState() {
    super.initState();
    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _heartController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email dan password harus diisi')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
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

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan email kamu dulu')),
      );
      return;
    }
    try {
      await _authService.resetPassword(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Link reset password terkirim ke $email')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_authService.getErrorMessage(e))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          const _BackgroundDecor(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 448),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                    decoration: BoxDecoration(
                      color: _surfaceLowest.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: Colors.white.withOpacity(0.5)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 32,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _Branding(heartController: _heartController),
                        const SizedBox(height: 24),
                        _Illustration(heartController: _heartController),
                        const SizedBox(height: 24),
                        const _WelcomeText(),
                        const SizedBox(height: 20),
                        _buildTextField(
                          controller: _emailController,
                          icon: Icons.alternate_email_rounded,
                          hint: 'Email',
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _passwordController,
                          icon: Icons.lock_outline_rounded,
                          hint: 'Password',
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
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _forgotPassword,
                            style: TextButton.styleFrom(
                              foregroundColor: _primary,
                              textStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            child: const Text('Lupa password?'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
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
                                    'Masuk',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Belum punya akun? ',
                              style: TextStyle(
                                fontSize: 14,
                                color: _onSurfaceVariant.withOpacity(0.8),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.pushNamed(context, '/register');
                              },
                              child: Text(
                                'Daftar',
                                style: TextStyle(
                                  color: _primary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffix,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: TextStyle(color: _onSurface, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: _onSurfaceVariant.withOpacity(0.6), fontSize: 14),
        prefixIcon: Icon(icon, color: _primary.withOpacity(0.8), size: 22),
        suffixIcon: suffix,
        filled: true,
        fillColor: _surfaceLowest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide(color: _outlineVariant.withOpacity(0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide(color: _outlineVariant.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide(color: _primary, width: 1.5),
        ),
      ),
    );
  }
}

class _Branding extends StatelessWidget {
  const _Branding({required this.heartController});

  final AnimationController heartController;

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'LoveNest',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: _primary,
                letterSpacing: -0.02,
              ),
            ),
            const SizedBox(width: 8),
            ScaleTransition(
              scale: TweenSequence([
                TweenSequenceItem(
                  tween: Tween(begin: 1.0, end: 1.15).chain(CurveTween(curve: Curves.easeInOut)),
                  weight: 30,
                ),
                TweenSequenceItem(
                  tween: Tween(begin: 1.15, end: 1.0).chain(CurveTween(curve: Curves.easeInOut)),
                  weight: 70,
                ),
              ]).animate(heartController),
              child: Icon(Icons.favorite, color: _primaryContainer, size: 28),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Tempat kecil kita, untuk cinta yang besar.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: _onSurfaceVariant,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _Illustration extends StatelessWidget {
  const _Illustration({required this.heartController});

  final AnimationController heartController;

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    return SizedBox(
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              color: _primaryContainer.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
          ),
          Image.asset(
            'assets/images/couple.jpg',
            fit: BoxFit.contain,
            height: 190,
          ),
          Positioned(
            top: 10,
            left: 0,
            child: _FloatingHeart(
              controller: heartController,
              offset: const Duration(milliseconds: 0),
              color: _primaryContainer,
              size: 14,
              x: 0,
            ),
          ),
          Positioned(
            top: 30,
            right: 8,
            child: _FloatingHeart(
              controller: heartController,
              offset: const Duration(milliseconds: 400),
              color: _primary,
              size: 22,
              x: -6,
            ),
          ),
          Positioned(
            bottom: 20,
            left: 4,
            child: _FloatingHeart(
              controller: heartController,
              offset: const Duration(milliseconds: 800),
              color: const Color(0xFFCAafaf),
              size: 18,
              x: -10,
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingHeart extends StatelessWidget {
  const _FloatingHeart({
    required this.controller,
    required this.offset,
    required this.color,
    required this.size,
    required this.x,
  });

  final AnimationController controller;
  final Duration offset;
  final Color color;
  final double size;
  final double x;

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final t = ((controller.value * 1000 - offset.inMilliseconds).clamp(0, 1000).toDouble()) / 1000;
        final opacity = 0.6 + 0.4 * t;
        final y = -(t * 15);
        final scale = 1.0 + t * 0.1;
        return Transform.translate(
          offset: Offset(x, y),
          child: Opacity(
            opacity: opacity,
            child: Transform.scale(
              scale: scale,
              child: child,
            ),
          ),
        );
      },
      child: Icon(Icons.favorite, color: color, size: size),
    );
  }
}

class _WelcomeText extends StatelessWidget {
  const _WelcomeText();

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    return Column(
      children: [
        Text(
          'Selamat Datang di LoveNest',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: _onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Simpan setiap momen berharga kita dalam satu tempat spesial.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: _onSurfaceVariant.withOpacity(0.9),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 24,
              height: 6,
              decoration: BoxDecoration(
                color: _primary,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: const Color(0xFFFFB3B4),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: const Color(0xFFFFB3B4),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: const Color(0xFFFFB3B4),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BackgroundDecor extends StatelessWidget {
  const _BackgroundDecor();

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -80,
            left: -80,
            child: _Blob(color: const Color(0xFFFFB3B4).withOpacity(0.3), size: 256),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height / 3,
            right: -80,
            child: _Blob(color: const Color(0xFFF9DCDC).withOpacity(0.4), size: 288),
          ),
          Positioned(
            bottom: -128,
            left: MediaQuery.of(context).size.width / 4,
            child: _Blob(color: const Color(0xFFFFB3B4).withOpacity(0.2), size: 384),
          ),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: 64,
            spreadRadius: 8,
          ),
        ],
      ),
    );
  }
}
