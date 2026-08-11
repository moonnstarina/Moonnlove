import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();
  String _userName = 'User';
  String _partnerName = 'Belum terhubung';
  String _statusText = '';
  int _missCount = 0;
  String? _partnerUid;
  StreamSubscription<DatabaseEvent>? _userListener;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _listenUserData();
  }

  @override
  void dispose() {
    _userListener?.cancel();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = _authService.currentUser;
    if (user != null) {
      final data = await _authService.getUserData(user.uid);
      if (data != null && mounted) {
        setState(() {
          _userName = data['name'] ?? 'User';
          _partnerUid = data['partner_uid']?.toString();
          if (_partnerUid == null || _partnerUid!.isEmpty) {
            _partnerName = 'Belum terhubung';
          }
        });
        if (_partnerUid != null && _partnerUid!.isNotEmpty) {
          _loadPartnerName();
        }
      }
    }
  }

  void _listenUserData() {
    final user = _authService.currentUser;
    if (user == null) return;
    _userListener = FirebaseDatabase.instance
        .ref()
        .child('users/${user.uid}')
        .onValue
        .listen((event) {
      final data = event.snapshot.value;
      if (data == null || !mounted) return;
      final map = Map<dynamic, dynamic>.from(data as Map);
      final partnerUid = map['partner_uid']?.toString();
      setState(() {
        _userName = map['name']?.toString() ?? _userName;
        if (partnerUid != null && partnerUid.isNotEmpty) {
          _partnerUid = partnerUid;
        } else {
          _partnerUid = null;
          _partnerName = 'Belum terhubung';
        }
      });
      if (partnerUid != null && partnerUid.isNotEmpty) {
        _loadPartnerName();
      }
    });
  }

  Future<void> _loadPartnerName() async {
    final uid = _partnerUid;
    if (uid == null || uid.isEmpty) return;
    final data = await _authService.getUserData(uid);
    if (data != null && mounted) {
      setState(() {
        _partnerName = data['name'] ?? 'Partner';
      });
    }
  }

  void _sendMissYou() async {
    setState(() => _missCount++);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Kamu sudah miss $_partnerName $_missCount kali hari ini 🥺'),
        backgroundColor: context.read<ThemeProvider>().primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final primaryColor = themeProvider.primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('MoonnLove'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryColor,
                    primaryColor.withOpacity(0.7),
                  ],
                ),
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 55,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        child: const Icon(
                          Icons.person,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.circle,
                            size: 12,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Text(
                    _partnerName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Online',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  if (_statusText.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _statusText,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                  const SizedBox(height: 15),
                  Text(
                    'Hai, $_userName ❤️',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 15,
                crossAxisSpacing: 15,
                children: [
                  _buildFeatureCard(
                    context,
                    icon: Icons.chat_bubble_outline,
                    label: 'Chat',
                    color: Colors.blue,
                    onTap: () => Navigator.pushNamed(context, '/chat'),
                  ),
                  _buildFeatureCard(
                    context,
                    icon: Icons.location_on_outlined,
                    label: 'Lokasi',
                    color: Colors.green,
                    onTap: () => Navigator.pushNamed(context, '/location'),
                  ),
                  _buildFeatureCard(
                    context,
                    icon: Icons.note_outlined,
                    label: 'Catatan',
                    color: Colors.orange,
                    onTap: () => Navigator.pushNamed(context, '/notes'),
                  ),
                  _buildFeatureCard(
                    context,
                    icon: Icons.photo_library_outlined,
                    label: 'Album',
                    color: Colors.purple,
                    onTap: () => Navigator.pushNamed(context, '/album'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _sendMissYou,
                  icon: const Icon(Icons.favorite, size: 28),
                  label: Text(
                    'Miss You ($_missCount)',
                    style: const TextStyle(fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}