import 'package:flutter/material.dart';

import 'login_screen.dart';

/// Kept only for compatibility with old deep links. Registration is Google-only.
class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) => const LoginScreen();
}
