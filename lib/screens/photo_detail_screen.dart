import '../providers/app_palette.dart';
import '../providers/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../services/auth_service.dart';
import '../services/partner_service.dart';

Color get _background => AppPalette.background;
Color get _primary => AppPalette.primary;
Color get _primaryContainer => AppPalette.primaryContainer;
Color get _onPrimaryContainer => AppPalette.onPrimaryContainer;
Color get _onSurface => AppPalette.onSurface;
Color get _onSurfaceVariant => AppPalette.onSurfaceVariant;
Color get _surfaceContainerLow => AppPalette.surfaceContainerLow;
Color get _outlineVariant => AppPalette.outlineVariant;

class PhotoDetailScreen extends StatefulWidget {
  const PhotoDetailScreen({
    super.key,
    required this.photoId,
    required this.initialUrl,
  });

  final String photoId;
  final String initialUrl;

  @override
  State<PhotoDetailScreen> createState() => _PhotoDetailScreenState();
}

class _PhotoDetailScreenState extends State<PhotoDetailScreen> {
  final _authService = AuthService();
  final _partnerService = PartnerService();

  DatabaseReference? _photoRef;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final photosRef = await _partnerService.getPhotosRef();
    if (!mounted) return;
    setState(() => _photoRef = photosRef?.child(widget.photoId));
  }

  Future<void> _toggleLike() async {
    await _partnerService.togglePhotoLike(widget.photoId);
  }

  Future<void> _editCaption(String current) async {
    final controller = TextEditingController(text: current);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFFFFFF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Edit Caption',
          style: TextStyle(fontWeight: FontWeight.w700, color: _onSurface),
        ),
        content: TextField(
          controller: controller,
          maxLines: 3,
          maxLength: 200,
          style: TextStyle(color: _onSurface),
          decoration: InputDecoration(
            hintText: 'Tulis caption...',
            hintStyle: TextStyle(color: _onSurfaceVariant),
            filled: true,
            fillColor: _surfaceContainerLow,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Batal',
              style: TextStyle(color: _onSurfaceVariant),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            style: FilledButton.styleFrom(
              backgroundColor: _primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      await _partnerService.updatePhotoCaption(widget.photoId, result);
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
            _buildTopBar(),
            Expanded(
              child: _photoRef == null
                  ? const Center(child: CircularProgressIndicator())
                  : StreamBuilder<DatabaseEvent>(
                      stream: _photoRef!.onValue,
                      builder: (context, snapshot) {
                        if (!snapshot.hasData ||
                            snapshot.data!.snapshot.value == null) {
                          return const Center(child: Text('Foto tidak ditemukan'));
                        }
                        final map = Map<String, dynamic>.from(
                            snapshot.data!.snapshot.value as Map);
                        return ListView(
                          padding: const EdgeInsets.only(top: 8),
                          children: [
                            _buildPhotoCard(map),
                            _buildDetails(map),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _roundButton(
            icon: Icons.arrow_back,
            onTap: () => Navigator.pop(context),
          ),
          _roundButton(icon: Icons.more_vert, onTap: () {}),
        ],
      ),
    );
  }

  Widget _roundButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _surfaceContainerLow,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: _onSurfaceVariant, size: 22),
      ),
    );
  }

  Widget _buildPhotoCard(Map<String, dynamic> photo) {
    final url = photo['url']?.toString() ?? widget.initialUrl;
    final likes = photo['likes'];
    final likeCount = likes is Map ? likes.length : 0;
    final uid = _authService.currentUser?.uid;
    final liked = likes is Map && uid != null && likes.containsKey(uid);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1F964549),
              blurRadius: 30,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: AspectRatio(
          aspectRatio: 4 / 5,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.network(
                  url,
                  fit: BoxFit.cover,
                  loadingBuilder: (_, child, progress) => progress == null
                      ? child
                      : Container(
                          color: _surfaceContainerLow,
                          child: Center(
                            child: CircularProgressIndicator(color: _primary),
                          ),
                        ),
                  errorBuilder: (_, __, ___) => Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFFFDAD9), Color(0xFFF9DCDC)],
                      ),
                    ),
                    child: const Icon(
                      Icons.photo_rounded,
                      size: 80,
                      color: Color(0x80FFFFFF),
                    ),
                  ),
                ),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(24)),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black54],
                  ),
                ),
              ),
              Positioned(
                bottom: 16,
                right: 16,
                child: GestureDetector(
                  onTap: _toggleLike,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                      ),
                      boxShadow: const [
                        BoxShadow(color: Color(0x33000000), blurRadius: 8),
                      ],
                    ),
                    child: Icon(
                      Icons.favorite_rounded,
                      color: liked ? _primaryContainer : Colors.white,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 16,
                left: 16,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.favorite_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$likeCount',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetails(Map<String, dynamic> photo) {
    final caption = photo['caption']?.toString() ?? '';
    final timestamp = photo['timestamp'];
    final likes = photo['likes'];
    final likeCount = likes is Map ? likes.length : 0;
    final uid = _authService.currentUser?.uid;
    final liked = likes is Map && uid != null && likes.containsKey(uid);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            caption.isEmpty ? 'Momen kita 💕' : caption,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _onSurface,
            ),
          ),
          if (timestamp is int) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.calendar_month_rounded,
                  size: 16,
                  color: _onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDate(timestamp),
                  style: TextStyle(
                    fontSize: 14,
                    color: _onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          if (caption.isNotEmpty) ...[
            Text(
              caption,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: _onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
          ],
          Divider(height: 1, thickness: 1, color: _outlineVariant),
          const SizedBox(height: 12),
          Row(
            children: [
              _interaction(
                icon: Icons.favorite_rounded,
                label: '$likeCount',
                color: _primary,
                onTap: _toggleLike,
              ),
              const SizedBox(width: 24),
              _interaction(
                icon: Icons.edit_rounded,
                label: 'Caption',
                color: _onSurfaceVariant,
                onTap: () => _editCaption(caption),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, thickness: 1, color: _outlineVariant),
          ),
          GestureDetector(
            onTap: () => _editCaption(caption),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person_rounded,
                    size: 18,
                    color: _onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: _surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      caption.isEmpty
                          ? 'Tambahkan caption...'
                          : caption,
                      style: TextStyle(
                        fontSize: 14,
                        color: caption.isEmpty
                            ? _onSurfaceVariant
                            : _onSurface,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _interaction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
