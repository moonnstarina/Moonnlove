import '../providers/app_palette.dart';
import '../providers/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import '../services/partner_service.dart';

Color get _background => AppPalette.background;
Color get _primary => AppPalette.primary;
Color get _primaryContainer => AppPalette.primaryContainer;
Color get _onPrimary => AppPalette.onPrimary;
Color get _onSurface => AppPalette.onSurface;
Color get _onSurfaceVariant => AppPalette.onSurfaceVariant;
Color get _surfaceLowest => AppPalette.surfaceLowest;
Color get _surfaceContainerHigh => AppPalette.surfaceContainerHigh;
Color get _secondaryContainer => AppPalette.secondaryContainer;
Color get _outlineVariant => AppPalette.outlineVariant;

const _milestones = [7, 30, 50, 100, 200, 365];

class StreakScreen extends StatefulWidget {
  const StreakScreen({super.key});

  @override
  State<StreakScreen> createState() => _StreakScreenState();
}

class _StreakScreenState extends State<StreakScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  final _partnerService = PartnerService();

  Map<String, bool> _streakDates = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _load();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    await _partnerService.markActiveToday();
    final dates = await _partnerService.getStreakDates();
    if (!mounted) return;
    setState(() {
      _streakDates = dates;
      _loading = false;
    });
  }

  int get _streak {
    final now = DateTime.now();
    final today = _dateKey(now);
    final yesterday = _dateKey(now.subtract(const Duration(days: 1)));
    var count = 0;
    var cursor = _streakDates[today] == true ? today : (_streakDates[yesterday] == true ? yesterday : null);
    if (cursor == null) return 0;
    while (true) {
      count++;
      final date = DateTime.parse(cursor!).subtract(const Duration(days: 1));
      cursor = _dateKey(date);
      if (_streakDates[cursor] != true) break;
    }
    return count;
  }

  String _dateKey(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final firstWeekday =
        DateTime(now.year, now.month, 1).weekday; // 1=Mon .. 7=Sun
    final streak = _streak;

    return Scaffold(
      backgroundColor: _background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFFFF), Color(0xFFFFF5F5)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 24,
                        ),
                        children: [
                          _buildHero(streak),
                          const SizedBox(height: 32),
                          _buildCalendarCard(now, daysInMonth, firstWeekday),
                          const SizedBox(height: 24),
                          _buildMilestoneCard(streak),
                          const SizedBox(height: 24),
                          _buildActionButton(),
                          const SizedBox(height: 16),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Icon(Icons.favorite_rounded, color: _primary, size: 24),
          Expanded(
            child: Center(
              child: Text(
                'Streak',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _primary,
                ),
              ),
            ),
          ),
          Icon(Icons.more_horiz_rounded, color: _onSurfaceVariant),
        ],
      ),
    );
  }

  Widget _buildHero(int streak) {
    return Column(
      children: [
        const SizedBox(height: 24),
        ScaleTransition(
          scale: Tween(begin: 0.96, end: 1.04).animate(
            CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
          ),
          child: SizedBox(
            width: 160,
            height: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(
                  Icons.favorite_rounded,
                  size: 160,
                  color: Color(0xFFFFB3B4),
                ),
                Text(
                  '$streak',
                  style: TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.w800,
                    color: _onPrimary,
                    letterSpacing: -2,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Days in a row',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          'Keep it going! 🔥',
          style: TextStyle(fontSize: 14, color: _onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildCalendarCard(
    DateTime now,
    int daysInMonth,
    int firstWeekday,
  ) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final today = now.day;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _surfaceLowest.withOpacity(0.7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.04),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _monthName(now.month) + ' ${now.year}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _onSurface,
                ),
              ),
              Row(
                children: [
                  Icon(Icons.chevron_left_rounded,
                      color: _onSurfaceVariant, size: 20),
                  SizedBox(width: 12),
                  Icon(Icons.chevron_right_rounded,
                      color: _onSurfaceVariant, size: 20),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: [
              for (final wd in weekdays)
                Center(
                  child: Text(
                    wd,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _onSurfaceVariant.withOpacity(0.7),
                    ),
                  ),
                ),
              for (var i = 0; i < firstWeekday - 1; i++)
                const SizedBox(),
              for (var day = 1; day <= daysInMonth; day++)
                _buildDayCell(day, today),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDayCell(int day, int today) {
    final isToday = day == today;
    final active = _isActiveDay(today, day);
    return Center(
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? _primaryContainer : Colors.transparent,
          shape: BoxShape.circle,
          boxShadow: active
              ? [
                  BoxShadow(
                    color: _primaryContainer.withOpacity(0.4),
                    blurRadius: 4,
                  ),
                ]
              : [],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              '$day',
              style: TextStyle(
                fontSize: 14,
                fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                color: active
                    ? Colors.white
                    : day < today
                        ? _onSurface
                        : _onSurfaceVariant,
              ),
            ),
            if (isToday)
              Positioned(
                bottom: 3,
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  bool _isActiveDay(int today, int day) {
    final now = DateTime.now();
    final date = DateTime(now.year, now.month, day);
    if (date.isAfter(DateTime(now.year, now.month, now.day))) return false;
    return _streakDates[_dateKey(date)] == true;
  }

  Widget _buildMilestoneCard(int streak) {
    int? next;
    for (final m in _milestones) {
      if (streak < m) {
        next = m;
        break;
      }
    }
    final target = next ?? 365;
    final progress = (streak / target).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _surfaceLowest.withOpacity(0.7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.04),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MILESTONE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _onSurfaceVariant,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    next == null ? '365+ Days' : '$target Days',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    next == null ? 'Legendary streak!' : 'Next milestone',
                    style: TextStyle(
                      fontSize: 12,
                      color: _onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '$streak',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _primary,
                      ),
                    ),
                    TextSpan(
                      text: '/$target Days',
                      style: TextStyle(
                        fontSize: 14,
                        color: _onSurfaceVariant.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Container(
              height: 12,
              color: _secondaryContainer,
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress,
                child: Container(
                  decoration: BoxDecoration(
                    color: _primary,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: _primary.withOpacity(0.5),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: () => _showMilestones(),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: _secondaryContainer.withOpacity(0.5),
          foregroundColor: _primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        child: const Text(
          'Lihat Semua',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  void _showMilestones() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _surfaceLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Text(
                  'Milestones',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              for (final m in _milestones)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Icon(
                        _streak >= m
                            ? Icons.emoji_events_rounded
                            : Icons.lock_rounded,
                        size: 22,
                        color: _streak >= m ? _primary : _onSurfaceVariant,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '$m Days',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _onSurface,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _streak >= m ? 'Tercapai 🎉' : '${m - _streak} hari lagi',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _streak >= m ? _primary : _onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];
    return months[month - 1];
  }
}
