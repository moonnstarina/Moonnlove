import 'package:flutter/material.dart';

const Color _background = Color(0xFFF8F9FA);
const Color _primary = Color(0xFF964549);
const Color _primaryContainer = Color(0xFFFF999C);
const Color _onPrimaryContainer = Color(0xFF792E33);
const Color _onSurface = Color(0xFF191C1D);
const Color _onSurfaceVariant = Color(0xFF544242);
const Color _surfaceContainerLow = Color(0xFFF3F4F5);
const Color _outlineVariant = Color(0xFFDAC1C0);

class PhotoDetailScreen extends StatefulWidget {
  const PhotoDetailScreen({super.key, this.photoIndex = 0});

  final int photoIndex;

  @override
  State<PhotoDetailScreen> createState() => _PhotoDetailScreenState();
}

class _PhotoDetailScreenState extends State<PhotoDetailScreen> {
  static const _titles = [
    'Sunset di Jimbaran 🌅',
    'Kopi pagi bareng',
    'Pendakian bareng',
    'Selfie rumah',
    'Dinner anniversary',
    'Genggam tanganmu',
  ];

  static const _dates = [
    '12 Mar 2024',
    '20 Apr 2024',
    '05 Mei 2024',
    '18 Jun 2024',
    '01 Jul 2024',
    '22 Jul 2024',
  ];

  static const _places = [
    'Bali',
    'Jakarta',
    'Gunung Bromo',
    'Rumah',
    'Bandung',
    'Yogyakarta',
  ];

  static const _descriptions = [
    'Sore itu di Jimbaran terasa begitu magis. Angin laut yang sepoi-sepoi membawa aroma garam dan kebahagiaan yang tak terlukiskan. Kita duduk berdua di atas pasir yang masih hangat, menyaksikan matahari perlahan tenggelam di ufuk barat, mengubah langit menjadi kanvas warna merah muda dan jingga yang memukau.',
    'Momen sederhana seperti ini yang membuat segalanya terasa berarti. Tertawa bersama sambil menikmati jagung bakar dan suara ombak yang tenang. Sebuah kenangan yang akan selalu tersimpan rapi di sudut hati yang paling hangat.',
  ];

  bool _liked = false;

  @override
  Widget build(BuildContext context) {
    final index = widget.photoIndex % _titles.length;

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(top: 8),
                children: [
                  _buildPhotoCard(index),
                  _buildDetails(index),
                ],
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
        decoration: const BoxDecoration(
          color: _surfaceContainerLow,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: _onSurfaceVariant, size: 22),
      ),
    );
  }

  Widget _buildPhotoCard(int index) {
    final photoAsset = index == 0
        ? 'assets/images/sunset.jpg'
        : 'assets/images/album${(index % 6) + 1}.jpg';
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
              child: Image.asset(
                photoAsset,
                fit: BoxFit.cover,
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
                onTap: () => setState(() => _liked = !_liked),
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
                    color: _liked
                        ? _primaryContainer
                        : Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildDetails(int index) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _titles[index],
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.calendar_month_rounded,
                size: 16,
                color: _onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                _dates[index],
                style: const TextStyle(
                  fontSize: 14,
                  color: _onSurfaceVariant,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('•', style: TextStyle(color: _outlineVariant)),
              ),
              const Icon(
                Icons.location_on_rounded,
                size: 16,
                color: _onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                _places[index],
                style: const TextStyle(
                  fontSize: 14,
                  color: _onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          for (final paragraph in _descriptions)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                paragraph,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: _onSurfaceVariant,
                ),
              ),
            ),
          const SizedBox(height: 4),
          const Divider(height: 1, thickness: 1, color: _outlineVariant),
          const SizedBox(height: 12),
          Row(
            children: [
              _interaction(
                icon: Icons.favorite_rounded,
                label: '24',
                color: _primary,
                onTap: () => setState(() => _liked = !_liked),
              ),
              const SizedBox(width: 24),
              _interaction(
                icon: Icons.chat_bubble_rounded,
                label: '3',
                color: _onSurfaceVariant,
                onTap: () {},
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, thickness: 1, color: _outlineVariant),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: _primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
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
                  child: const Text(
                    'Tambahkan caption...',
                    style: TextStyle(fontSize: 14, color: _onSurfaceVariant),
                  ),
                ),
              ),
            ],
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
}
