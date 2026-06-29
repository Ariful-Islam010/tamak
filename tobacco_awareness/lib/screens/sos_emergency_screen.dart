import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';

class SosEmergencyScreen extends StatefulWidget {
  const SosEmergencyScreen({super.key});

  @override
  State<SosEmergencyScreen> createState() => _SosEmergencyScreenState();
}

enum _Mode { none, waiting, breathing }

class _SosEmergencyScreenState extends State<SosEmergencyScreen>
    with TickerProviderStateMixin {
  late AnimationController _breathController;

  Timer? _timer;
  Timer? _breathTimer;
  _Mode _mode = _Mode.none;
  int _secondsRemaining = 300;

  // 4-7-8 breathing
  int _breathPhase = 0;
  int _breathCount = 0;
  int _breathSeconds = 0;
  static const List<int> _breathDurations = [4, 7, 8];
  static const List<String> _breathLabels = ['শ্বাস নিন 😤', 'ধরে রাখুন 🧘', 'ছেড়ে দিন 💨'];
  static const List<Color> _breathColors = [
    AppTheme.accentLime,
    AppTheme.accentCyan,
    AppTheme.accentPink,
  ];

  // Water & walking tracking
  bool _waterDone = false;
  bool _walkingDone = false;

  // Multiple friends
  List<Map<String, String>> _friends = [];

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
        vsync: this, duration: const Duration(seconds: 4));
    _loadData();
  }

  @override
  void dispose() {
    _breathController.dispose();
    _timer?.cancel();
    _breathTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    final friendsJson = prefs.getString('sos_friends') ?? '[]';
    setState(() {
      _waterDone = prefs.getString('water_done_date') == today;
      _walkingDone = prefs.getString('walking_done_date') == today;
      _friends = List<Map<String, String>>.from(
        (jsonDecode(friendsJson) as List).map((e) => Map<String, String>.from(e)),
      );
    });
  }

  Future<void> _saveFriends() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sos_friends', jsonEncode(_friends));
  }

  Future<void> _markWaterDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('water_done_date', DateTime.now().toIso8601String().split('T')[0]);
    setState(() => _waterDone = true);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ পানি পান করা হয়েছে! সাবাশ! 💧'), 
          backgroundColor: AppTheme.accentCyan
        ),
      );
    }
  }

  Future<void> _markWalkingDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('walking_done_date', DateTime.now().toIso8601String().split('T')[0]);
    setState(() => _walkingDone = true);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ হাঁটাহাঁটি সম্পূর্ণ! অসাধারণ! 🚶‍♂️'), 
          backgroundColor: AppTheme.accentLime
        ),
      );
    }
  }

  void _startWaitTimer() {
    setState(() { _mode = _Mode.waiting; _secondsRemaining = 300; });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        t.cancel();
        _showAlarmDialog();
      }
    });
  }

  void _showAlarmDialog() {
    HapticFeedback.heavyImpact();
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.demonDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppTheme.accentLime, width: 3),
        ),
        title: const Text(
          '🎉 জাদুকরী মুহূর্ত!', 
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppTheme.accentLime), 
          textAlign: TextAlign.center
        ),
        content: const Text(
          '৫ মিনিট পার হয়ে গেছে!\nধূমপানের তীব্র ইচ্ছাটা এখন অনেক কমে গেছে।\nআপনি নিজেকে জয় করেছেন! 😈💪',
          style: TextStyle(fontSize: 16, height: 1.6, color: Colors.white, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentLime,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 4,
                shadowColor: AppTheme.accentLime.withValues(alpha: 0.3),
              ),
              onPressed: () {
                Navigator.pop(context);
                setState(() => _mode = _Mode.none);
              },
              child: const Text('আমি জিতেছি! 🏆', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  void _startBreathing() {
    setState(() {
      _mode = _Mode.breathing;
      _breathPhase = 0;
      _breathCount = 0;
      _breathSeconds = _breathDurations[0];
    });
    _breathController.duration = const Duration(seconds: 4);
    _breathController.forward(from: 0);
    _breathTimer?.cancel();
    _breathTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _breathSeconds--;
        if (_breathSeconds <= 0) {
          _breathPhase = (_breathPhase + 1) % 3;
          if (_breathPhase == 0) _breathCount++;
          _breathSeconds = _breathDurations[_breathPhase];
          _breathController.duration = Duration(seconds: _breathDurations[_breathPhase]);
          if (_breathPhase != 1) {
            _breathController.forward(from: 0);
          } else {
            _breathController.stop();
          }
        }
      });
    });
  }

  void _stopMode() {
    _timer?.cancel();
    _breathTimer?.cancel();
    _breathController.stop();
    setState(() => _mode = _Mode.none);
  }

  String get _formattedTime {
    int m = _secondsRemaining ~/ 60, s = _secondsRemaining % 60;
    String raw = '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    return raw.replaceAllMapped(RegExp(r'\d'), (match) =>
        ['০','১','২','৩','৪','৫','৬','৭','৮','৯'][int.parse(match.group(0)!)]);
  }

  void _showAddFriendDialog({int? editIndex}) {
    final nameCtrl = TextEditingController(
        text: editIndex != null ? _friends[editIndex]['name'] : '');
    final numCtrl = TextEditingController(
        text: editIndex != null ? _friends[editIndex]['number'] : '');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.demonDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppTheme.accentPink, width: 3),
        ),
        title: Text(
          editIndex != null ? 'বন্ধুর তথ্য সম্পাদনা ✏️' : 'নতুন বন্ধু যোগ করুন ➕',
          style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min, 
          children: [
            TextField(
              controller: nameCtrl,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                labelText: 'বন্ধুর নাম',
                labelStyle: const TextStyle(color: AppTheme.textLight),
                prefixIcon: const Icon(Icons.person, color: AppTheme.accentPink),
                fillColor: AppTheme.demonMid,
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: numCtrl,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                labelText: 'মোবাইল নম্বর',
                labelStyle: const TextStyle(color: AppTheme.textLight),
                prefixIcon: const Icon(Icons.phone, color: AppTheme.accentPink),
                fillColor: AppTheme.demonMid,
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
        actions: [
          if (editIndex != null)
            TextButton.icon(
              onPressed: () {
                setState(() => _friends.removeAt(editIndex));
                _saveFriends();
                Navigator.pop(context);
              },
              icon: const Icon(Icons.delete, color: AppTheme.errorColor),
              label: const Text('মুছুন', style: TextStyle(color: AppTheme.errorColor, fontWeight: FontWeight.bold)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text('বাতিল', style: TextStyle(color: AppTheme.textLight, fontWeight: FontWeight.bold))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentLime,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              final name = nameCtrl.text.trim();
              final number = numCtrl.text.trim();
              if (number.isNotEmpty) {
                setState(() {
                  if (editIndex != null) {
                    _friends[editIndex] = {'name': name, 'number': number};
                  } else {
                    _friends.add({'name': name, 'number': number});
                  }
                });
                _saveFriends();
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('সংরক্ষণ', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _callFriend(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('কল করা যাচ্ছে না!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Decorative background items
            Positioned(
              top: -80,
              left: -80,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.accentPink.withValues(alpha: 0.05),
                ),
              ),
            ),
            Positioned(
              bottom: 40,
              right: -60,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.accentCyan.withValues(alpha: 0.05),
                ),
              ),
            ),
            CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Column(
                      children: [
                        // Header row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "জরুরি সাহায্য 🚨",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            IconButton(
                              icon: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.demonDark,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppTheme.accentPink, width: 2),
                                ),
                                child: const Icon(Icons.close, size: 20, color: AppTheme.accentPink),
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "ইচ্ছেটা মাত্র ৫ মিনিটেই কমে যাবে! ⏳",
                          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                color: AppTheme.accentLime,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "নিচের যেকোনো একটি উপায় বেছে নিন এবং নিজেকে শান্ত করুন।",
                          style: TextStyle(
                            color: AppTheme.textLight,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 28),

                        // Mode area
                        if (_mode == _Mode.none) ...[
                          Column(children: [
                            _buildActionOption(
                              "দয়া করে ৫ মিনিট অপেক্ষা করুন ⏱️",
                              Icons.timer,
                              AppTheme.accentOrange,
                              _startWaitTimer,
                            ),
                            const SizedBox(height: 16),
                            _buildActionOption(
                              "৪-৭-৮ শ্বাস-প্রশ্বাস ব্যায়াম 💨",
                              Icons.air,
                              AppTheme.accentCyan,
                              _startBreathing,
                            ),
                          ]),
                        ] else if (_mode == _Mode.waiting) ...[
                          _buildWaitTimer(),
                        ] else if (_mode == _Mode.breathing) ...[
                          _buildBreathing(),
                        ],

                        if (_mode != _Mode.none) ...[
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.demonDark,
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: AppTheme.accentPink, width: 2),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                            onPressed: _stopMode,
                            icon: const Icon(Icons.refresh, color: AppTheme.accentPink),
                            label: const Text("অন্য উপায় বেছে নিন 🔄", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],

                        const Spacer(),
                        const SizedBox(height: 24),

                        // Distraction Cards Section Title
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "অন্যান্য বিভ্রান্তি বা উপায় 🎯",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Water card
                        _buildDistractionTile(
                          icon: Icons.water_drop,
                          color: AppTheme.accentCyan,
                          title: "এক গ্লাস ঠাণ্ডা পানি খান 💧",
                          done: _waterDone,
                          buttonText: _waterDone ? "পান করা হয়েছে ✅" : "পানি খেয়েছি 🥤",
                          onTap: _waterDone ? null : _markWaterDone,
                        ),
                        const SizedBox(height: 12),

                        // Friend call section
                        _buildFriendCallSection(),

                        const SizedBox(height: 12),

                        // Walking card
                        _buildDistractionTile(
                          icon: Icons.directions_walk,
                          color: AppTheme.accentLime,
                          title: "৫ মিনিট হাঁটাহাঁটি করুন 🚶‍♂️",
                          done: _walkingDone,
                          buttonText: _walkingDone ? "সম্পূর্ণ করা হয়েছে ✅" : "হাঁটাহাঁটি করেছি 🏃‍♂️",
                          onTap: _walkingDone ? null : _markWalkingDone,
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionOption(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.demonDark,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color, width: 3),
          boxShadow: AppTheme.glowShadow(color),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1), 
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title, 
                style: const TextStyle(
                  fontSize: 16, 
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                )
              ),
            ),
            Icon(Icons.chevron_right, color: color, size: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildWaitTimer() {
    final progress = _secondsRemaining / 300.0;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.demonDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.accentOrange, width: 3),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center, 
            children: [
              SizedBox(
                width: 180,
                height: 180,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 10,
                  backgroundColor: AppTheme.demonMid,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progress > 0.5 ? AppTheme.accentLime : progress > 0.25 ? AppTheme.accentOrange : AppTheme.errorColor,
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.timer, color: AppTheme.accentOrange, size: 36),
                  const SizedBox(height: 4),
                  Text(
                    _formattedTime, 
                    style: const TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w900)
                  ),
                  const Text('বাকি আছে', style: TextStyle(color: AppTheme.textLight, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBreathing() {
    final color = _breathColors[_breathPhase];
    return AnimatedBuilder(
      animation: _breathController,
      builder: (_, __) {
        double scale = _breathPhase == 0
            ? 0.6 + (_breathController.value * 0.4)
            : _breathPhase == 1 ? 1.0
            : 1.0 - (_breathController.value * 0.4);
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.demonDark,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color, width: 3),
            boxShadow: AppTheme.glowShadow(color),
          ),
          child: Column(
            children: [
              Stack(
                alignment: Alignment.center, 
                children: [
                  Container(
                    width: 180 * scale, height: 180 * scale,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.1)),
                  ),
                  Container(
                    width: 130 * scale, height: 130 * scale,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.2)),
                  ),
                  Container(
                    width: 90, height: 90,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
                    child: Center(
                      child: Text(
                        '$_breathSeconds',
                        style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                _breathLabels[_breathPhase],
                style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.w900)
              ),
              const SizedBox(height: 6),
              Text(
                '৪-৭-৮ ব্যায়াম • চক্র ${_breathCount + 1}',
                style: const TextStyle(color: AppTheme.textLight, fontSize: 13, fontWeight: FontWeight.bold)
              ),
              const SizedBox(height: 4),
              const Text(
                'শ্বাস নিন (৪) → ধরুন (৭) → ছাড়ুন (৮)',
                style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold), 
                textAlign: TextAlign.center
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDistractionTile({
    required IconData icon,
    required Color color,
    required String title,
    required bool done,
    required String buttonText,
    VoidCallback? onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.demonDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: done ? AppTheme.accentLime : color.withValues(alpha: 0.4), 
          width: done ? 3 : 2
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title, 
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)
            )
          ),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: done ? AppTheme.accentLime.withValues(alpha: 0.2) : color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: done ? AppTheme.accentLime : color),
              ),
              child: Text(
                buttonText,
                style: TextStyle(color: done ? AppTheme.accentLime : Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendCallSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.demonDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.accentPink.withValues(alpha: 0.4), width: 2),
      ),
      child: Column(
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppTheme.accentPink.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.call, color: AppTheme.accentPink, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    "বন্ধুকে কল করুন 📞", 
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)
                  )
                ),
                GestureDetector(
                  onTap: () => _showAddFriendDialog(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.accentPink.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.accentPink),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min, 
                      children: [
                        Icon(Icons.add, color: AppTheme.accentPink, size: 14),
                        SizedBox(width: 3),
                        Text("যোগ করুন", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Friend list
          if (_friends.isEmpty)
            const Padding(
              padding: EdgeInsets.only(left: 14, right: 14, bottom: 16),
              child: Text(
                "+ বাটনে চাপ দিয়ে বন্ধুর নম্বর যোগ করুন",
                style: TextStyle(color: AppTheme.textLight, fontSize: 12, fontWeight: FontWeight.bold)
              ),
            )
          else
            ...List.generate(_friends.length, (i) {
              final f = _friends[i];
              return Padding(
                padding: const EdgeInsets.only(left: 14, right: 14, bottom: 10),
                child: Row(
                  children: [
                    const SizedBox(width: 44),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start, 
                        children: [
                          Text(
                            f['name']!.isNotEmpty ? f['name']! : 'বন্ধু',
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.white)
                          ),
                          Text(f['number']!, style: const TextStyle(color: AppTheme.textLight, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _showAddFriendDialog(editIndex: i),
                      child: const Icon(Icons.edit, color: AppTheme.textLight, size: 18),
                    ),
                    const SizedBox(width: 14),
                    GestureDetector(
                      onTap: () => _callFriend(f['number']!),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: AppTheme.accentLime,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: AppTheme.glowShadow(AppTheme.accentLime),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min, 
                          children: [
                            Icon(Icons.call, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text("কল", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}
