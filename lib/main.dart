import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'providers/theme_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/main_shell.dart';
import 'screens/chat_screen.dart';
import 'screens/location_screen.dart';
import 'screens/notes_screen.dart';
import 'screens/photo_album_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/account_settings_screen.dart';
import 'screens/notification_settings_screen.dart';
import 'screens/partner_screen.dart';
import 'screens/streak_screen.dart';
import 'screens/lock_screen.dart';
import 'screens/lock_settings_screen.dart';
import 'services/app_lock_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  await Firebase.initializeApp();
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity,
    appleProvider: AppleProvider.appAttestWithDeviceCheckFallback,
    webProvider: ReCaptchaV3Provider(
      const String.fromEnvironment('RECAPTCHA_V3_SITE_KEY'),
    ),
  );
  runApp(const _Root());
}

class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'MoonnLove',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.lightTheme,
            initialRoute: '/',
            routes: {
              '/': (context) => const AuthGate(),
              '/login': (context) => const LoginScreen(),
              '/home': (context) => const MainShell(),
              '/chat': (context) => const ChatScreen(),
              '/location': (context) => const LocationScreen(),
              '/notes': (context) => const NotesScreen(),
              '/album': (context) => const PhotoAlbumScreen(),
              '/settings': (context) => const ProfileScreen(),
              '/account-settings': (context) => const AccountSettingsScreen(),
              '/notifications': (context) => const NotificationSettingsScreen(),
              '/partner': (context) => const PartnerScreen(),
              '/streak': (context) => const StreakScreen(),
              '/app-lock': (context) => const LockSettingsScreen(),
            },
          );
        },
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final user = snapshot.data;
        if (user != null &&
            user.emailVerified &&
            user.providerData.any((profile) => profile.providerId == 'google.com')) {
          return const _LockGate(child: MainShell());
        }
        return const LoginScreen();
      },
    );
  }
}

class _LockGate extends StatefulWidget {
  const _LockGate({required this.child});

  final Widget child;

  @override
  State<_LockGate> createState() => _LockGateState();
}

class _LockGateState extends State<_LockGate> {
  final _lockService = AppLockService();
  bool _loading = true;
  bool _unlocked = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final enabled = await _lockService.isEnabled();
    if (mounted) {
      setState(() {
        _unlocked = !enabled;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (!_unlocked) {
      return LockScreen(onUnlocked: () => setState(() => _unlocked = true));
    }
    return widget.child;
  }
}