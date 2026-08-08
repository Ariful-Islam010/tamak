import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/check_in_provider.dart';
import '../providers/gamification_provider.dart';

class DailyCheckInScreen extends ConsumerStatefulWidget {
  const DailyCheckInScreen({super.key});

  @override
  ConsumerState<DailyCheckInScreen> createState() => _DailyCheckInScreenState();
}

class _DailyCheckInScreenState extends ConsumerState<DailyCheckInScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _reflectionController = TextEditingController();
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  final List<Map<String, String>> _moods = [
    {"emoji": "😁", "label": "অসাধারণ"},
    {"emoji": "🙂", "label": "ভালো"},
    {"emoji": "😐", "label": "মোটামুটি"},
    {"emoji": "😔", "label": "খারাপ"},
    {"emoji": "😠", "label": "রাগান্বিত"},
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(checkInProvider).loadCheckInStatus();
    });
  }

  @override
  void dispose() {
    _reflectionController.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final checkInProviderData = ref.watch(checkInProvider);

    if (checkInProviderData.isLoading) {
      return _buildLoadingScaffold();
    }

    if (checkInProviderData.hasCheckedInToday) {
      return _buildAlreadyCheckedIn(context);
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // ── Decorative Background ──
          const _DecorativeBg(),

          // ── Content ──
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Column(
                children: [
                  // Custom AppBar
                  _buildAppBar(context),

                  // Scrollable body
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Question Card
                          _buildSectionCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _sectionLabel(
                                    Icons.help_outline_rounded, "আজকের প্রশ্ন"),
                                const SizedBox(height: 12),
                                Text(
                                  "আজ কি আপনি তামাক ব্যবহার করেছেন?",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A1A2E),
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildChoiceButton(
                                        "না",
                                        Icons.thumb_up_rounded,
                                        const Color(0xFF00A36C),
                                        checkInProviderData.usedTobacco == false,
                                        () => ref.read(checkInProvider)
                                            .setUsedTobacco(false),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: _buildChoiceButton(
                                        "হ্যাঁ",
                                        Icons.thumb_down_rounded,
                                        const Color(0xFFE8325A),
                                        checkInProviderData.usedTobacco == true,
                                        () =>
                                            ref.read(checkInProvider).setUsedTobacco(true),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Craving Scale Card
                          _buildSectionCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _sectionLabel(Icons.local_fire_department_rounded,
                                    "ইচ্ছার তীব্রতা"),
                                const SizedBox(height: 4),
                                Text(
                                  "১ = একদম নেই  •  ১০ = খুব বেশি",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Craving level display
                                Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 8),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFFF97316),
                                          Color(0xFFE8325A)
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: Text(
                                      "${checkInProviderData.cravingLevel.round()}",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SliderTheme(
                                  data: SliderThemeData(
                                    activeTrackColor: const Color(0xFFF97316),
                                    inactiveTrackColor: const Color(0xFFF97316)
                                        .withValues(alpha: 0.2),
                                    thumbColor: const Color(0xFFE8325A),
                                    overlayColor: const Color(0xFFE8325A)
                                        .withValues(alpha: 0.15),
                                    trackHeight: 6,
                                    thumbShape: const RoundSliderThumbShape(
                                        enabledThumbRadius: 10),
                                  ),
                                  child: Slider(
                                    value: checkInProviderData.cravingLevel,
                                    min: 1,
                                    max: 10,
                                    divisions: 9,
                                    label: checkInProviderData.cravingLevel
                                        .round()
                                        .toString(),
                                    onChanged: (value) {
                                      ref.read(checkInProvider).setCravingLevel(value);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Mood Selector Card
                          _buildSectionCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _sectionLabel(
                                    Icons.emoji_emotions_rounded, "মনের অবস্থা"),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: _moods.map((mood) {
                                    final isSelected =
                                        checkInProviderData.selectedMood ==
                                            mood["label"];
                                    return GestureDetector(
                                      onTap: () => ref.read(checkInProvider)
                                          .setSelectedMood(mood["label"]),
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 200),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? const Color(0xFF00A36C)
                                                  .withValues(alpha: 0.12)
                                              : Colors.transparent,
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          border: Border.all(
                                            color: isSelected
                                                ? const Color(0xFF00A36C)
                                                : Colors.transparent,
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            Text(mood["emoji"]!,
                                                style: TextStyle(
                                                    fontSize: isSelected
                                                        ? 30
                                                        : 26)),
                                            const SizedBox(height: 6),
                                            Text(
                                              mood["label"]!,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: isSelected
                                                    ? const Color(0xFF00A36C)
                                                    : Colors.grey[500],
                                                fontWeight: isSelected
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Reflection Text Box Card
                          _buildSectionCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _sectionLabel(Icons.edit_note_rounded,
                                    "আজকের অনুভূতি লিখুন"),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _reflectionController,
                                  maxLines: 4,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF1A1A2E)),
                                  decoration: InputDecoration(
                                    hintText:
                                        "আজকের দিনটি কেমন ছিল? (ঐচ্ছিক)",
                                    hintStyle:
                                        TextStyle(color: Colors.grey[400]),
                                    fillColor: const Color(0xFFF8F9FA),
                                    filled: true,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(
                                          color: Colors.grey.withValues(
                                              alpha: 0.2)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(
                                          color: Colors.grey.withValues(
                                              alpha: 0.2)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(
                                          color: Color(0xFF00A36C), width: 1.5),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Submit Button
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: checkInProviderData.usedTobacco == null
                                  ? null
                                  : () async {
                                      final messenger = ScaffoldMessenger.of(context);
                                      final navigator = Navigator.of(context);
                                      final noteText = _reflectionController.text.trim();
                                      try {
                                        await ref.read(checkInProvider).submitCheckIn(
                                          note: noteText.isNotEmpty ? noteText : null,
                                        );
                                        ref.read(gamificationProvider).loadGamificationData();
                                        if (mounted) {
                                          messenger.showSnackBar(const SnackBar(
                                              content: Text(
                                                  "চেক-ইন সম্পন্ন হয়েছে! ✅")));
                                          navigator.pop();
                                        }
                                      } catch (e) {
                                        if (mounted) {
                                          final errStr = e.toString().replaceAll("Exception: ", "");
                                          messenger.showSnackBar(SnackBar(
                                              backgroundColor: Colors.red,
                                              content: Text("চেক-ইন ব্যর্থ হয়েছে: $errStr")));
                                        }
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    checkInProviderData.usedTobacco == null
                                        ? Colors.grey[300]
                                        : const Color(0xFF00A36C),
                                foregroundColor: Colors.white,
                                elevation: checkInProviderData.usedTobacco == null
                                    ? 0
                                    : 4,
                                shadowColor: const Color(0xFF00A36C)
                                    .withValues(alpha: 0.4),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text(
                                "জমা দিন",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
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
        ],
      ),
    );
  }

  // ── Custom AppBar ──
  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Color(0xFF1A1A2E), size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text(
              "দৈনিক চেক-ইন",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
              ),
            ),
          ),
          // balance space
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  // ── Section Card wrapper ──
  Widget _buildSectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00A36C).withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  // ── Section Label row ──
  Widget _sectionLabel(IconData icon, String label) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFF00A36C).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF00A36C), size: 16),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A2E),
          ),
        ),
      ],
    );
  }

  // ── Yes/No buttons ──
  Widget _buildChoiceButton(
    String text,
    IconData icon,
    Color color,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isSelected ? color : color.withValues(alpha: 0.3),
              width: 1.5),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.white : color, size: 28),
            const SizedBox(height: 8),
            Text(
              text,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Loading scaffold ──
  Widget _buildLoadingScaffold() {
    return Scaffold(
      body: Stack(
        children: [
          const _DecorativeBg(),
          const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  // ── Already checked in scaffold ──
  Widget _buildAlreadyCheckedIn(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const _DecorativeBg(),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00A36C).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_circle_rounded,
                          size: 72, color: Color(0xFF00A36C)),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "আজকের চেক-ইন সম্পন্ন!",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A2E),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "আগামীকাল আবার আসুন।",
                      style: TextStyle(
                          fontSize: 15, color: Colors.grey[500]),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00A36C),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text("ফিরে যান",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// Decorative Background with Blobs/Circles
// ─────────────────────────────────────────────────
class _DecorativeBg extends StatelessWidget {
  const _DecorativeBg();

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: CustomPaint(
        painter: _BgPainter(),
      ),
    );
  }
}

class _BgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFFE0F2FE), // Matching AppTheme
          Color(0xFFF0FDF4), // Matching AppTheme
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // ── Decorative blobs ──
    _drawBlob(
      canvas,
      center: Offset(size.width * 0.85, size.height * 0.04),
      radius: 90,
      color: const Color(0xFF00A36C).withValues(alpha: 0.10),
    );

    _drawBlob(
      canvas,
      center: Offset(size.width * 0.0, size.height * 0.15),
      radius: 70,
      color: const Color(0xFFE8325A).withValues(alpha: 0.08),
    );

    _drawBlob(
      canvas,
      center: Offset(size.width * 0.75, size.height * 0.38),
      radius: 55,
      color: const Color(0xFFF97316).withValues(alpha: 0.07),
    );

    _drawBlob(
      canvas,
      center: Offset(size.width * 0.1, size.height * 0.55),
      radius: 80,
      color: const Color(0xFF00A36C).withValues(alpha: 0.07),
    );

    _drawBlob(
      canvas,
      center: Offset(size.width * 0.9, size.height * 0.72),
      radius: 65,
      color: const Color(0xFFE8325A).withValues(alpha: 0.07),
    );

    _drawBlob(
      canvas,
      center: Offset(size.width * 0.3, size.height * 0.88),
      radius: 100,
      color: const Color(0xFF00A36C).withValues(alpha: 0.06),
    );

    // ── Subtle dot pattern ──
    _drawDotGrid(canvas, size);

    // ── Thin decorative arc lines ──
    _drawArc(
      canvas,
      center: Offset(size.width * 0.85, size.height * 0.04),
      radius: 110,
      color: const Color(0xFF00A36C).withValues(alpha: 0.12),
      strokeWidth: 1.5,
    );

    _drawArc(
      canvas,
      center: Offset(size.width * 0.1, size.height * 0.55),
      radius: 100,
      color: const Color(0xFFE8325A).withValues(alpha: 0.08),
      strokeWidth: 1.2,
    );
  }

  void _drawBlob(Canvas canvas,
      {required Offset center, required double radius, required Color color}) {
    final paint = Paint()..color = color;
    canvas.drawCircle(center, radius, paint);
  }

  void _drawArc(Canvas canvas,
      {required Offset center,
      required double radius,
      required Color color,
      required double strokeWidth}) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      math.pi * 1.5,
      false,
      paint,
    );
  }

  void _drawDotGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00A36C).withValues(alpha: 0.08);
    const spacing = 28.0;
    const dotRadius = 1.5;
    for (double x = spacing; x < size.width; x += spacing) {
      for (double y = spacing; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), dotRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_BgPainter oldDelegate) => false;
}
