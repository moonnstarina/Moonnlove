import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_database/firebase_database.dart';
import '../services/auth_service.dart';
import '../services/partner_service.dart';

const Color _background = Color(0xFFF8F9FA);
const Color _primary = Color(0xFF964549);
const Color _primaryContainer = Color(0xFFFF999C);
const Color _onPrimaryContainer = Color(0xFF792E33);
const Color _onSurface = Color(0xFF191C1D);
const Color _onSurfaceVariant = Color(0xFF544242);
const Color _surfaceLowest = Color(0xFFFFFFFF);
const Color _surfaceContainer = Color(0xFFEDEEEF);
const Color _surfaceContainerHigh = Color(0xFFE7E8E9);
const Color _secondaryContainer = Color(0xFFF1DEDE);

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  final _authService = AuthService();
  final _partnerService = PartnerService();

  Position? _myPosition;
  Map<String, double>? _partnerLocation;
  bool _loading = true;
  bool _sharing = false;
  bool _paired = false;
  bool _permissionDenied = false;
  StreamSubscription<DatabaseEvent>? _partnerListener;
  String? _partnerName;
  String? _partnerUid;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _partnerListener?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final partnerData = await _partnerService.getPartnerData();
    if (!mounted) return;
    final partnerUid = partnerData?['uid']?.toString();
    setState(() {
      _paired = partnerUid != null && partnerUid.isNotEmpty;
      _partnerName = partnerData?['name'];
      _partnerUid = partnerUid;
      _loading = false;
    });
    if (_paired) _listenPartnerLocation();
  }

  void _listenPartnerLocation() {
    final uid = _partnerUid;
    if (uid == null) return;
    _partnerListener?.cancel();
    _partnerListener = FirebaseDatabase.instance
        .ref()
        .child('users/$uid/location')
        .onValue
        .listen((event) {
      final data = event.snapshot.value;
      if (data == null || !mounted) return;
      final map = Map<dynamic, dynamic>.from(data as Map);
      final lat = map['lat'];
      final lng = map['lng'];
      if (lat is num && lng is num) {
        setState(() {
          _partnerLocation = {'lat': lat.toDouble(), 'lng': lng.toDouble()};
        });
      }
    });
  }

  Future<void> _shareLocation() async {
    setState(() => _sharing = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (mounted) {
          _showSnack('Layanan lokasi (GPS) mati. Nyalakan dulu ya.');
          setState(() => _sharing = false);
        }
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _permissionDenied = true;
            _sharing = false;
          });
          _showSnack('Izin lokasi ditolak. Izinkan via pengaturan HP.');
        }
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 20),
        ),
      );
      await _partnerService.saveLocation(position.latitude, position.longitude);
      if (mounted) {
        setState(() {
          _myPosition = position;
          _permissionDenied = false;
        });
        _showSnack('Lokasi terkirim ke pasanganmu! 💖');
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Gagal dapat lokasi: $e');
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  double? get _distance {
    final my = _myPosition;
    final partner = _partnerLocation;
    if (my == null || partner == null) return null;
    return _haversine(my.latitude, my.longitude, partner['lat']!, partner['lng']!);
  }

  double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = _rad(lat2 - lat1);
    final dLon = _rad(lon2 - lon1);
    final a = pow(sin(dLat / 2), 2) +
        cos(_rad(lat1)) * cos(_rad(lat2)) * pow(sin(dLon / 2), 2);
    return 2 * r * asin(sqrt(a));
  }

  double _rad(double deg) => deg * pi / 180;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : !_paired
                      ? _buildNotPaired()
                      : _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Text(
            'Lokasi',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _primary,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              onPressed: _load,
              icon: const Icon(
                Icons.refresh_rounded,
                color: _onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotPaired() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_on_rounded,
              size: 60,
              color: _onSurfaceVariant.withOpacity(0.4),
            ),
            const SizedBox(height: 15),
            const Text(
              'Hubungkan pasangan dulu',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Fitur lokasi hanya tersedia setelah terhubung dengan pasangan',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: _onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/partner'),
              icon: const Icon(Icons.person_add_rounded, size: 18),
              label: const Text('Hubungkan Pasangan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final distance = _distance;
    final hasPartnerLoc = _partnerLocation != null;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 8),
        _buildDistanceCard(distance, hasPartnerLoc),
        const SizedBox(height: 16),
        _buildStatusCard(),
        const SizedBox(height: 16),
        _buildShareButton(),
      ],
    );
  }

  Widget _buildDistanceCard(double? distance, bool hasPartnerLoc) {
    final display = distance != null ? distance.toStringAsFixed(1) : '--';
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_primary, Color(0xFFB96B6E)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: Color(0x40964549), blurRadius: 24, offset: Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Colors.white24,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.favorite_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '$display km',
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Jarak dari ${_partnerName ?? 'pasanganmu'}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.85),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            !hasPartnerLoc
                ? 'Pasanganmu belum berbagi lokasi'
                : distance == null
                    ? 'Bagikan lokasimu untuk lihat jarak'
                    : 'Terhubung dan dekat! 💞',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surfaceLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x0F964549), blurRadius: 16, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Status Lokasi',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _onSurface,
            ),
          ),
          const SizedBox(height: 16),
          _statusRow(
            icon: Icons.my_location_rounded,
            color: _myPosition != null ? _primary : _onSurfaceVariant,
            title: _myPosition != null ? 'Lokasimu aktif' : 'Lokasimu belum dibagikan',
            subtitle: _myPosition != null
                ? 'Pasangan bisa melihat posisimu sekarang'
                : 'Tekan tombol di bawah untuk berbagi',
          ),
          const SizedBox(height: 16),
          _statusRow(
            icon: Icons.person_pin_rounded,
            color: _partnerLocation != null ? _primary : _onSurfaceVariant,
            title: _partnerLocation != null
                ? 'Lokasi ${_partnerName ?? 'pasangan'} aktif'
                : 'Lokasi ${_partnerName ?? 'pasangan'} belum ada',
            subtitle: _partnerLocation != null
                ? 'Posisi pasangan terdeteksi'
                : 'Minta pasangan bagikan lokasinya',
          ),
        ],
      ),
    );
  }

  Widget _statusRow({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _secondaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: _onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildShareButton() {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: _sharing ? null : _shareLocation,
        icon: _sharing
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.share_location_rounded),
        label: Text(
          _myPosition != null ? 'Perbarui Lokasiku' : 'Share Lokasi Saya',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}
