import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../providers/app_palette.dart';
import '../providers/theme_provider.dart';
import '../services/auth_service.dart';
import '../services/partner_service.dart';

class StickerPickerSheet extends StatefulWidget {
  const StickerPickerSheet({super.key, required this.onSelect});

  final void Function(String url) onSelect;

  @override
  State<StickerPickerSheet> createState() => _StickerPickerSheetState();
}

class _StickerPickerSheetState extends State<StickerPickerSheet> {
  final _authService = AuthService();
  final _partnerService = PartnerService();
  StreamSubscription<DatabaseEvent>? _sub;
  DatabaseReference? _stickersRef;
  List<Map<String, dynamic>> _stickers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final ref = await _partnerService.getStickersRef();
    if (!mounted) return;
    if (ref == null) {
      setState(() => _loading = false);
      return;
    }
    _stickersRef = ref;
    _sub = ref.onValue.listen((event) {
      final data = event.snapshot.value;
      final list = <Map<String, dynamic>>[];
      if (data is Map) {
        data.forEach((key, val) {
          if (val is Map) {
            final s = Map<String, dynamic>.from(val);
            s['id'] = key.toString();
            list.add(s);
          }
        });
      }
      list.sort((a, b) =>
          (b['timestamp'] ?? 0).compareTo(a['timestamp'] ?? 0));
      if (mounted) setState(() { _stickers = list; _loading = false; });
    });
  }

  Future<void> _addFromUrl() async {
    final ctrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppPalette.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Tambah Stiker', style: TextStyle(color: AppPalette.onSurface)),
        content: TextField(
          controller: ctrl,
          decoration: InputDecoration(
            hintText: 'Tempel URL gambar...',
            hintStyle: TextStyle(color: AppPalette.onSurfaceVariant),
          ),
          keyboardType: TextInputType.url,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: TextStyle(color: AppPalette.outline)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: AppPalette.primary),
            child: Text('Tambah', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (result == null || result.isEmpty) return;
    await _partnerService.addSticker(result, 'stiker');
  }

  Future<void> _addFromGallery() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
    try {
      final url = await _partnerService.uploadChatImage(File(picked.path).path);
      await _partnerService.addSticker(url, 'stiker');
    } catch (_) {}
  }

  Future<void> _deleteSticker(String stickerId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppPalette.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus stiker ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _partnerService.deleteSticker(stickerId);
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppPalette.surfaceContainerLowest,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppPalette.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Stiker',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppPalette.onSurface,
                      ),
                    ),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: _addFromUrl,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppPalette.primaryContainer,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.link_rounded,
                                size: 18, color: AppPalette.onPrimaryContainer),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _addFromGallery,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppPalette.primaryContainer,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.photo_library_rounded,
                                size: 18, color: AppPalette.onPrimaryContainer),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _stickers.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.emoji_emotions_outlined,
                                    size: 48, color: AppPalette.onSurfaceVariant),
                                const SizedBox(height: 12),
                                Text(
                                  'Belum ada stiker\nTap + untuk tambah',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: AppPalette.onSurfaceVariant, fontSize: 14),
                                ),
                              ],
                            ),
                          )
                        : GridView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.all(16),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                            ),
                            itemCount: _stickers.length,
                            itemBuilder: (context, i) {
                              final s = _stickers[i];
                              final url = s['url']?.toString() ?? '';
                              final id = s['id']?.toString();
                              return GestureDetector(
                                onTap: () {
                                  widget.onSelect(url);
                                  Navigator.pop(context);
                                },
                                onLongPress: id != null ? () => _deleteSticker(id) : null,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppPalette.surfaceContainer,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: Image.network(
                                    url,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Icon(
                                      Icons.broken_image_rounded,
                                      color: AppPalette.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }
}
