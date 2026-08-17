import '../providers/app_palette.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/auth_service.dart';
import '../services/partner_service.dart';
import 'sticker_picker_sheet.dart';

Color get _background => AppPalette.background;
Color get _surfaceLowest => AppPalette.surfaceLowest;
Color get _surfaceContainer => AppPalette.surfaceContainer;
Color get _surfaceContainerHigh => AppPalette.surfaceContainerHigh;
Color get _surfaceVariant => AppPalette.surfaceVariant;
Color get _outlineVariant => AppPalette.outlineVariant;
Color get _primary => AppPalette.primary;
Color get _primaryContainer => AppPalette.primaryContainer;
Color get _onPrimaryContainer => AppPalette.onPrimaryContainer;
Color get _onSurface => AppPalette.onSurface;
Color get _onSurfaceVariant => AppPalette.onSurfaceVariant;

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _authService = AuthService();
  final _scrollController = ScrollController();
  final _partnerService = PartnerService();
  final _focusNode = FocusNode();

  String? _coupleId;
  String? _partnerName;
  bool _loading = true;
  bool _inputFocused = false;
  DatabaseReference? _chatRef;
  StreamSubscription<DatabaseEvent>? _partnerListener;
  StreamSubscription<DatabaseEvent>? _userListener;

  @override
  void initState() {
    super.initState();
    _loadCouple();
    _listenForPairingChanges();
    _focusNode.addListener(() {
      if (mounted) {
        setState(() => _inputFocused = _focusNode.hasFocus);
      }
    });
  }

  @override
  void dispose() {
    _partnerListener?.cancel();
    _userListener?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadCouple() async {
    final coupleId = await _partnerService.getCoupleId();
    final partnerData = await _partnerService.getPartnerData();
    if (!mounted) return;
    final partnerUid = partnerData?['uid']?.toString();
    setState(() {
      _coupleId = coupleId;
      _partnerName = partnerData?['name'];
      _chatRef = coupleId != null
          ? FirebaseDatabase.instance
              .ref()
              .child('couples/$coupleId/messages')
          : null;
      _loading = false;
    });
    if (partnerUid != null && partnerUid.isNotEmpty) {
      _partnerListener?.cancel();
      _partnerListener = FirebaseDatabase.instance
          .ref()
          .child('users/$partnerUid')
          .onValue
          .listen((event) {
        final data = event.snapshot.value;
        if (data == null || !mounted) return;
        final map = Map<dynamic, dynamic>.from(data as Map);
        setState(() {
          _partnerName = map['name']?.toString() ?? _partnerName;
        });
      });
    }
  }

  void _listenForPairingChanges() {
    final uid = _authService.currentUser?.uid;
    if (uid == null) return;
    _userListener?.cancel();
    _userListener = FirebaseDatabase.instance
        .ref()
        .child('users/$uid')
        .onValue
        .listen((event) {
      final data = event.snapshot.value;
      if (data == null || !mounted) return;
      final map = Map<dynamic, dynamic>.from(data as Map);
      final coupleId = map['couple_id']?.toString();
      if (coupleId != null && coupleId.isNotEmpty && coupleId != _coupleId) {
        _loadCouple();
      }
    });
  }

  bool _isGifUrl(String text) {
    final lower = text.toLowerCase();
    if (!lower.startsWith('http')) return false;
    if (lower.contains('.gif')) return true;
    if (lower.contains('giphy.com') || lower.contains('tenor.com')) return true;
    if (lower.contains('gifbin.com') || lower.contains('imgur.com') && lower.endsWith('.gif')) return true;
    return false;
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    final ref = _chatRef;
    final user = _authService.currentUser;
    if (ref == null || user == null) return;

    final text = _messageController.text.trim();
    final isGif = _isGifUrl(text);

    await ref.push().set({
      'sender_uid': user.uid,
      'message': text,
      'type': isGif ? 'gif' : 'text',
      if (isGif) 'gifUrl': text,
      'timestamp': ServerValue.timestamp,
      'is_read': false,
    });

    _messageController.clear();
  }

  Future<void> _sendPhoto() async {
    final ref = _chatRef;
    final user = _authService.currentUser;
    if (ref == null || user == null) return;

    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;

    try {
      final url = await _partnerService.uploadChatImage(picked.path);
      await ref.push().set({
        'sender_uid': user.uid,
        'message': '',
        'type': 'photo',
        'url': url,
        'timestamp': ServerValue.timestamp,
        'is_read': false,
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal kirim foto: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _markAllRead() async {
    final ref = _chatRef;
    final user = _authService.currentUser;
    if (ref == null || user == null) return;
    final snapshot = await ref.orderByChild('is_read').equalTo(false).once();
    final data = snapshot.snapshot.value;
    if (data == null) return;
    (data as Map).forEach((key, value) {
      final map = Map<String, dynamic>.from(value);
      if (map['sender_uid']?.toString() != user.uid) {
        ref.child(key.toString()).child('is_read').set(true);
      }
    });
  }

  void _showComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fitur ini segera hadir!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openStickerPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StickerPickerSheet(onSelect: _sendSticker),
    );
  }

  Future<void> _sendSticker(String url) async {
    final ref = _chatRef;
    final user = _authService.currentUser;
    if (ref == null || user == null || url.isEmpty) return;
    await ref.push().set({
      'sender_uid': user.uid,
      'message': '',
      'type': 'sticker',
      'stickerUrl': url,
      'timestamp': ServerValue.timestamp,
      'is_read': false,
    });
  }

  void _showChatMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _surfaceLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () async {
                  Navigator.pop(context);
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: _surfaceLowest,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      title: const Text('Hapus semua chat?'),
                      content: const Text('Semua pesan akan dihapus permanen.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Batal'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Hapus',
                              style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await _partnerService.deleteAllMessages();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _surfaceLowest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.delete_sweep_rounded,
                          color: Colors.red, size: 22),
                      SizedBox(width: 12),
                      Text('Hapus semua chat',
                          style: TextStyle(fontSize: 16)),
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

  void _showMessageOptions(String messageId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _surfaceLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () async {
                  Navigator.pop(context);
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: _surfaceLowest,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      title: const Text('Hapus pesan ini?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Batal'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Hapus',
                              style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await _partnerService.deleteMessage(messageId);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _surfaceLowest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.delete_rounded, color: Colors.red, size: 22),
                      SizedBox(width: 12),
                      Text('Hapus pesan', style: TextStyle(fontSize: 16)),
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

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final primaryColor = themeProvider.primaryColor;

    return Scaffold(
      backgroundColor: _background,
      body: Column(
        children: [
          _buildHeader(primaryColor),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _coupleId == null
                    ? _buildNotPaired(primaryColor)
                    : _buildMessageList(),
          ),
          _buildInputBar(primaryColor),
        ],
      ),
    );
  }

  Widget _buildHeader(Color primaryColor) {
    return Container(
      decoration: BoxDecoration(
        color: _background.withOpacity(0.95),
        border: Border(
          bottom: BorderSide(color: _surfaceVariant, width: 0.5),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              if (Navigator.canPop(context))
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  color: _onSurfaceVariant,
                  onPressed: () => Navigator.pop(context),
                ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      children: [
                        ClipOval(
                          child: Image.asset(
                            'assets/images/logo.png',
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.person,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: const Color(0xFF4CAF50),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _partnerName ?? 'Partner',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: _onSurface,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '♥',
                              style: TextStyle(
                                fontSize: 14,
                                color: _primary,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Online',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert),
                color: _onSurfaceVariant,
                onPressed: _showChatMenu,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    final user = _authService.currentUser;
    return StreamBuilder<DatabaseEvent>(
      stream: _chatRef!.orderByChild('timestamp').onValue,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 60,
                  color: Color(0xFF9E9E9E),
                ),
                SizedBox(height: 15),
                Text(
                  'Mulai ngobrol yuk!',
                  style: TextStyle(fontSize: 16, color: Color(0xFF9E9E9E)),
                ),
              ],
            ),
          );
        }

        final data = snapshot.data!.snapshot.value as Map;
        final messages = <Map<String, dynamic>>[];
        data.forEach((key, value) {
          final msg = Map<String, dynamic>.from(value);
          msg['_id'] = key.toString();
          messages.add(msg);
        });
        messages.sort(
          (a, b) => (b['timestamp'] ?? 0).compareTo(a['timestamp'] ?? 0),
        );

        WidgetsBinding.instance.addPostFrameCallback((_) => _markAllRead());

        final items = <Widget>[];
        String? lastDay;
        for (final msg in messages) {
          final day = _dayLabel(msg['timestamp']);
          if (day != null && day != lastDay) {
            items.add(_buildDatePill(msg['timestamp']));
            lastDay = day;
          }
          final isMe = msg['sender_uid'] == user?.uid;
          final msgId = msg['_id']?.toString();
          items.add(GestureDetector(
            onLongPress: msgId != null ? () => _showMessageOptions(msgId) : null,
            child: _buildMessageBubble(msg, isMe),
          ));
        }

        return ListView.builder(
          controller: _scrollController,
          reverse: true,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          itemCount: items.length,
          itemBuilder: (context, index) => items[index],
        );
      },
    );
  }

  String? _dayLabel(dynamic timestamp) {
    if (timestamp is! int) return null;
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final sameDay = date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
    return '$sameDay-${date.year}-${date.month}-${date.day}';
  }

  Widget _buildDatePill(dynamic timestamp) {
    final isToday = _dayLabel(timestamp)?.startsWith('true') ?? false;
    String label;
    if (timestamp is! int) {
      label = '';
    } else if (isToday) {
      label = 'Today';
    } else {
      final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
      const months = [
        'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
        'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
      ];
      label = '${date.day} ${months[date.month - 1]} ${date.year}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: _surfaceContainerHigh,
            borderRadius: BorderRadius.circular(999),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 4,
              ),
            ],
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg, bool isMe) {
    final maxWidth = MediaQuery.of(context).size.width * 0.85;
    final timeText = _formatTime(msg['timestamp']);
    final isRead = msg['is_read'] == true;
    final isPhoto = msg['type'] == 'photo';
    final photoUrl = msg['url']?.toString() ?? '';
    final isInteraction = msg['type'] == 'interaction';
    final isSticker = msg['type'] == 'sticker';
    final stickerUrl = msg['stickerUrl']?.toString() ?? '';
    final isGif = msg['type'] == 'gif';
    final gifUrl = msg['gifUrl']?.toString() ?? '';

    if (isInteraction) {
      return _buildInteractionBubble(msg, maxWidth);
    }

    if (isSticker && stickerUrl.isNotEmpty) {
      return Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Image.network(
              stickerUrl,
              width: 120,
              height: 120,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: _surfaceContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.emoji_emotions_outlined,
                    color: _onSurfaceVariant, size: 40),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(timeText,
                      style: TextStyle(fontSize: 10, color: _onSurfaceVariant)),
                  if (isMe) ...[
                    const SizedBox(width: 3),
                    Icon(
                      isRead ? Icons.done_all_rounded : Icons.done_rounded,
                      size: 14,
                      color: isRead ? _primary : _onSurfaceVariant,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (isGif && gifUrl.isNotEmpty) {
      return Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              constraints: BoxConstraints(maxWidth: maxWidth * 0.6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _surfaceVariant),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.network(
                gifUrl,
                fit: BoxFit.cover,
                loadingBuilder: (_, child, progress) => progress == null
                    ? child
                    : Container(
                        width: 200,
                        height: 150,
                        color: _surfaceContainer,
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                errorBuilder: (_, __, ___) => Container(
                  width: 200,
                  height: 150,
                  color: _surfaceContainer,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.gif_box_rounded, color: _onSurfaceVariant, size: 40),
                      const SizedBox(height: 4),
                      Text('GIF', style: TextStyle(fontSize: 12, color: _onSurfaceVariant)),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(timeText,
                      style: TextStyle(fontSize: 10, color: _onSurfaceVariant)),
                  if (isMe) ...[
                    const SizedBox(width: 3),
                    Icon(
                      isRead ? Icons.done_all_rounded : Icons.done_rounded,
                      size: 14,
                      color: isRead ? _primary : _onSurfaceVariant,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (isPhoto) {
      return Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              constraints: BoxConstraints(maxWidth: maxWidth * 0.7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: isMe ? null : Border.all(color: _surfaceVariant),
                boxShadow: [
                  BoxShadow(
                    color: _primary.withOpacity(isMe ? 0.08 : 0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: GestureDetector(
                onTap: () => _viewPhoto(photoUrl),
                child: Image.network(
                  photoUrl,
                  fit: BoxFit.cover,
                  width: 220,
                  height: 220,
                  loadingBuilder: (_, child, progress) => progress == null
                      ? child
                      : Container(
                          width: 220,
                          height: 220,
                          color: _surfaceContainer,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                  errorBuilder: (_, __, ___) => Container(
                    width: 220,
                    height: 220,
                    color: _surfaceContainer,
                    child: const Icon(Icons.broken_image_rounded, size: 40),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    timeText,
                    style: TextStyle(
                      fontSize: 10,
                      color: _onSurfaceVariant,
                    ),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 3),
                    Icon(
                      isRead ? Icons.done_all_rounded : Icons.done_rounded,
                      size: 14,
                      color: isRead ? _primary : _onSurfaceVariant,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (isMe) {
      return Align(
        alignment: Alignment.centerRight,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: _primaryContainer,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(4),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _primary.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  msg['message'] ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    color: _onPrimaryContainer,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4, right: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      timeText,
                      style: TextStyle(
                        fontSize: 10,
                        color: _onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Icon(
                      isRead
                          ? Icons.done_all_rounded
                          : Icons.done_rounded,
                      size: 14,
                      color: isRead
                          ? _primary
                          : _onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            ClipOval(
              child: Image.asset(
                'assets/images/logo.png',
                width: 32,
                height: 32,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.person, size: 20, color: Colors.grey),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: _surfaceVariant),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                        bottomLeft: Radius.circular(4),
                        bottomRight: Radius.circular(16),
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x05000000),
                          blurRadius: 10,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      msg['message'] ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        color: _onSurface,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 4),
                    child: Text(
                      timeText,
                      style: TextStyle(
                        fontSize: 10,
                        color: _onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractionBubble(Map<String, dynamic> msg, double maxWidth) {
    const emojiMap = {
      'heart': '❤️',
      'hug': '🤗',
      'kiss': '😘',
      'miss': '🥺',
      'mood': '😊',
    };
    final emoji = emojiMap[msg['interaction']] ?? '💌';
    final text = msg['message'] ?? '';
    final timeText = _formatTime(msg['timestamp']);
    final isRead = msg['is_read'] == true;

    return Align(
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
            decoration: BoxDecoration(
              color: _primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 40)),
                const SizedBox(height: 8),
                Text(
                  text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                timeText,
                style: TextStyle(fontSize: 10, color: _onSurfaceVariant),
              ),
              const SizedBox(width: 3),
              Icon(
                isRead ? Icons.done_all_rounded : Icons.done_rounded,
                size: 14,
                color: isRead ? _primary : _onSurfaceVariant,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _viewPhoto(String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Stack(
              children: [
                Positioned.fill(
                  child: InteractiveViewer(
                    child: Center(
                      child: Image.network(url, fit: BoxFit.contain),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputBar(Color primaryColor) {
    return Container(
      decoration: BoxDecoration(
        color: _surfaceLowest,
        border: Border(
          top: BorderSide(color: _outlineVariant.withOpacity(0.4), width: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.add_circle_rounded),
                color: _onSurfaceVariant,
                onPressed: _sendPhoto,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  decoration: BoxDecoration(
                    color: _surfaceLowest,
                    border: Border.all(
                      color: _inputFocused ? _primary : _outlineVariant,
                      width: _inputFocused ? 1.2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          focusNode: _focusNode,
                          style: TextStyle(
                            fontSize: 14,
                            color: _onSurface,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Type a message...',
                            hintStyle: TextStyle(color: _onSurfaceVariant),
                            border: InputBorder.none,
                            isCollapsed: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 12),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.mood_rounded),
                        color: _onSurfaceVariant,
                        onPressed: _openStickerPicker,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _sendMessage,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.2),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotPaired(Color primaryColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 60, color: Colors.grey),
            const SizedBox(height: 15),
            const Text(
              'Belum terhubung dengan pasangan',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'Hubungkan pasangan dulu biar bisa chat',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/partner'),
              icon: const Icon(Icons.person_add, size: 18),
              label: const Text('Hubungkan Pasangan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
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

  String _formatTime(dynamic timestamp) {
    if (timestamp is! int) return '';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
