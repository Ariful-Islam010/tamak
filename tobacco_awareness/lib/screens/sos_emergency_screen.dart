import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import '../services/hive_helper.dart';
import '../services/backend_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../utils/time_utils.dart';

class SosEmergencyScreen extends StatefulWidget {
  const SosEmergencyScreen({super.key});

  @override
  State<SosEmergencyScreen> createState() => _SosEmergencyScreenState();
}

enum _Mode { none, waiting, breathing }

class _SosEmergencyScreenState extends State<SosEmergencyScreen>
    with TickerProviderStateMixin {
  late AnimationController _breathController;
  final AudioPlayer _audioPlayer = AudioPlayer();

  Future<void> _logSosToBackend(String mode, {String? distraction}) async {
    if (BackendService.token == null) return;
    try {
      await http.post(
        Uri.parse('${BackendService.baseUrl}/api/profile/sos-log'),
        headers: BackendService.headers(),
        body: jsonEncode({
          'selected_mode': mode,
          'distraction_clicked': distraction,
        }),
      ).timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint("Error logging SOS: $e");
    }
  }


  Timer? _timer;
  Timer? _breathTimer;
  _Mode _mode = _Mode.none;
  int _secondsRemaining = 300;

  // 4-7-8 breathing
  int _breathPhase = 0;
  int _breathCount = 0;
  int _breathSeconds = 0;
  static const List<int> _breathDurations = [4, 7, 8];
  static const List<String> _breathLabels = ['শ্বাস নিন', 'ধরুন', 'ছাড়ুন'];
  static const List<Color> _breathColors = [
    Color(0xFF00C6A7),
    Color(0xFF7C3AED),
    Color(0xFF2563EB),
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
    _audioPlayer.dispose();
    _timer?.cancel();
    _breathTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    final prefs = HiveHelper();
    final today = TimeUtils.todayBstDateString;
    final friendsJson = await prefs.getSetting('sos_friends') ?? '[]';
    final waterDoneDate = await prefs.getSetting('water_done_date');
    final walkingDoneDate = await prefs.getSetting('walking_done_date');
    
    setState(() {
      _waterDone = waterDoneDate == today;
      _walkingDone = walkingDoneDate == today;
      _friends = List<Map<String, String>>.from(
        (jsonDecode(friendsJson) as List).map((e) => Map<String, String>.from(e)),
      );
    });
  }

  Future<void> _saveFriends() async {
    final prefs = HiveHelper();
    await prefs.saveSetting('sos_friends', jsonEncode(_friends));
  }

  Future<void> _markWaterDone() async {
    final prefs = HiveHelper();
    await prefs.saveSetting('water_done_date', TimeUtils.todayBstDateString);
    setState(() => _waterDone = true);
    _logSosToBackend('distraction', distraction: 'drink_water');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ পানি পান করা হয়েছে! শাবাশ!'), backgroundColor: Color(0xFF00C6A7)),
      );
    }
  }

  Future<void> _markWalkingDone() async {
    final prefs = HiveHelper();
    await prefs.saveSetting('walking_done_date', TimeUtils.todayBstDateString);
    setState(() => _walkingDone = true);
    _logSosToBackend('distraction', distraction: 'walking');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ হাঁটাহাঁটি সম্পূর্ণ! অসাধারণ!'), backgroundColor: Color(0xFF00C6A7)),
      );
    }
  }

  void _startWaitTimer() {
    setState(() { _mode = _Mode.waiting; _secondsRemaining = 300; });
    _logSosToBackend('5_min_timer');
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

  Future<void> _playPopSound() async {
    try {
      await _audioPlayer.play(UrlSource(
        'https://www.soundjay.com/buttons/sounds/button-09.mp3',
      ));
    } catch (_) {
      // fallback to haptic if sound fails
    }
  }

  void _showAlarmDialog() {
    HapticFeedback.heavyImpact();
    _playPopSound();
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('🎉 দারুণ!', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        content: const Text(
          '৫ মিনিট পার হয়ে গেছে!\nইচ্ছেটা এখন অনেক কমে গেছে।\nআপনি জিতে গেছেন! 💪',
          style: TextStyle(fontSize: 16, height: 1.6),
          textAlign: TextAlign.center,
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(editIndex != null ? 'বন্ধুর তথ্য সম্পাদনা' : 'নতুন বন্ধু যোগ করুন',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: nameCtrl,
            decoration: InputDecoration(
              labelText: 'বন্ধুর নাম',
              prefixIcon: const Icon(Icons.person),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: numCtrl,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'মোবাইল নম্বর',
              prefixIcon: const Icon(Icons.phone),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ]),
        actions: [
          if (editIndex != null)
            TextButton.icon(
              onPressed: () {
                setState(() => _friends.removeAt(editIndex));
                _saveFriends();
                Navigator.pop(context);
              },
              icon: const Icon(Icons.delete, color: Colors.red),
              label: const Text('মুছুন', style: TextStyle(color: Colors.red)),
            ),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('বাতিল')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
            onPressed: () {
              final name = nameCtrl.text.trim();
              final number = numCtrl.text.trim().replaceAll(' ', '');
              
              if (name.length < 3 || name.length > 20) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('বন্ধুর নাম ৩ থেকে ২০ অক্ষরের মধ্যে হতে হবে!'),
                    backgroundColor: AppTheme.errorColor,
                  ),
                );
                return;
              }

              final bdPhoneRegex = RegExp(r'^(?:\+88|88)?01[3-9]\d{8}$');
              if (!bdPhoneRegex.hasMatch(number)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('সঠিক ১১ ডিজিটের মোবাইল নম্বর দিন (যেমন: 01712345678)!'),
                    backgroundColor: AppTheme.errorColor,
                  ),
                );
                return;
              }

              setState(() {
                if (editIndex != null) {
                  _friends[editIndex] = {'name': name, 'number': number};
                } else {
                  _friends.add({'name': name, 'number': number});
                }
              });
              _saveFriends();
              Navigator.pop(context);
            },
            child: const Text('সংরক্ষণ'),
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('কল করা যাচ্ছে না!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _mode == _Mode.none,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _mode != _Mode.none) {
          _stopMode();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          color: const Color(0xFF1565C0),
          child: SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Column(
                    children: [
                      // Header row
                      Padding(
                        padding: const EdgeInsets.only(left: 8, top: 8, right: 16),
                        child: Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: Icon(
                                  _mode == _Mode.none
                                      ? Icons.close
                                      : Icons.arrow_back_ios_new_rounded,
                                  size: 22,
                                  color: Colors.white,
                                ),
                                onPressed: () {
                                  if (_mode == _Mode.none) {
                                    Navigator.pop(context);
                                  } else {
                                    _stopMode();
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          _mode == _Mode.none
                              ? "ইচ্ছেটা মাত্র ৫ মিনিটেই কমে যাবে!"
                              : _mode == _Mode.waiting
                                  ? "৫ মিনিট অপেক্ষা করুন"
                                  : "৪-৭-৮ শ্বাস-প্রশ্বাস",
                          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                color: Colors.white,
                                fontSize: 26,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Content area
                      if (_mode == _Mode.none) ...[
                        // First Screen: ALL options together
                        Expanded(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              children: [
                                // Action options
                                _buildActionOption(
                                  "দয়া করে ৫ মিনিট অপেক্ষা করুন",
                                  Icons.timer,
                                  AppTheme.accentOrange,
                                  _startWaitTimer,
                                ),
                                const SizedBox(height: 14),
                                _buildActionOption(
                                  "৪-৭-৮ শ্বাস-প্রশ্বাস নিন",
                                  Icons.air,
                                  Colors.lightBlueAccent,
                                  _startBreathing,
                                ),
                                const SizedBox(height: 20),

                                // Divider
                                Row(children: [
                                  Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.25))),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    child: Text("অথবা", style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13)),
                                  ),
                                  Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.25))),
                                ]),
                                const SizedBox(height: 16),

                                // Distraction tiles
                                _buildDistractionTile(
                                  icon: Icons.water_drop,
                                  color: Colors.lightBlueAccent,
                                  title: "এক গ্লাস পানি খান",
                                  done: _waterDone,
                                  buttonText: _waterDone ? "পান করা হয়েছে ✅" : "পানি খেয়েছি",
                                  onTap: _waterDone ? null : _markWaterDone,
                                ),
                                const SizedBox(height: 12),
                                _buildFriendCallSection(),
                                const SizedBox(height: 12),
                                _buildDistractionTile(
                                  icon: Icons.directions_walk,
                                  color: Colors.orangeAccent,
                                  title: "হাঁটাহাঁটি করুন",
                                  done: _walkingDone,
                                  buttonText: _walkingDone ? "সম্পূর্ণ করা হয়েছে ✅" : "হাঁটাহাঁটি সম্পূর্ণ করেছি",
                                  onTap: _walkingDone ? null : _markWalkingDone,
                                ),
                                const SizedBox(height: 32),
                              ],
                            ),
                          ),
                        ),
                      ] else if (_mode == _Mode.waiting) ...[
                        // Timer Screen only
                        const Spacer(),
                        _buildWaitTimer(),
                        const Spacer(),
                      ] else if (_mode == _Mode.breathing) ...[
                        // Breathing Screen only
                        const Spacer(),
                        _buildBreathing(),
                        const Spacer(),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildActionOption(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
              child: Icon(icon, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                title, 
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white70),
          ],
        ),
      ),
    );
  }

  Widget _buildWaitTimer() {
    final progress = _secondsRemaining / 300.0;
    return Column(children: [
      Stack(alignment: Alignment.center, children: [
        SizedBox(
          width: 200,
          height: 200,
          child: CircularProgressIndicator(
            value: progress,
            strokeWidth: 8,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(
              progress > 0.5 ? const Color(0xFF00E5FF) : progress > 0.25 ? Colors.orange : Colors.redAccent,
            ),
          ),
        ),
        Column(children: [
          const Icon(Icons.timer, color: Colors.white70, size: 40),
          const SizedBox(height: 8),
          Text(_formattedTime, style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold)),
          Text('বাকি আছে', style: TextStyle(color: Colors.white70, fontSize: 13)),
        ]),
      ]),
    ]);
  }

  Widget _buildBreathing() {
    final color = _breathColors[_breathPhase];
    return AnimatedBuilder(
      animation: _breathController,
      builder: (context, child) {
        double scale = _breathPhase == 0
            ? 0.6 + (_breathController.value * 0.4)
            : _breathPhase == 1 ? 1.0
            : 1.0 - (_breathController.value * 0.4);
        return Column(children: [
          Stack(alignment: Alignment.center, children: [
            Container(
              width: 220 * scale, height: 220 * scale,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.1)),
            ),
            Container(
              width: 160 * scale, height: 160 * scale,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.2)),
            ),
            Container(
              width: 120, height: 120,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
              child: Center(
                child: Text('$_breathSeconds',
                    style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold)),
              ),
            ),
          ]),
          const SizedBox(height: 20),
          Text(_breathLabels[_breathPhase],
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text('৪-৭-৮ ব্যায়াম • চক্র ${_breathCount + 1}',
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 4),
          Text('শ্বাস নিন (৪) → ধরুন (৭) → ছাড়ুন (৮)',
              style: const TextStyle(color: Colors.white60, fontSize: 12), textAlign: TextAlign.center),
        ]);
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
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: done 
              ? Colors.greenAccent.withValues(alpha: 0.8) 
              : Colors.white.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
          child: Icon(icon, color: Colors.white, size: 26),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title, 
            style: const TextStyle(
              fontWeight: FontWeight.bold, 
              fontSize: 15,
              color: Colors.white,
            ),
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: done 
                  ? Colors.greenAccent.withValues(alpha: 0.25) 
                  : Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: done ? Colors.greenAccent : Colors.white.withValues(alpha: 0.5)),
            ),
            child: Text(buttonText,
                style: TextStyle(color: done ? Colors.greenAccent : Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
          ),
        ),
      ]),
    );
  }

  Widget _buildFriendCallSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                child: const Icon(Icons.call, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  "বন্ধুকে কল করুন", 
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    fontSize: 15,
                    color: Colors.white,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _showAddFriendDialog(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
                  ),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.add, color: Colors.white, size: 14),
                    SizedBox(width: 3),
                    Text("যোগ করুন", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ]),
                ),
              ),
            ]),
          ),

          // Friend list
          if (_friends.isEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 14, right: 14, bottom: 12),
              child: Text("+ বাটনে চাপ দিয়ে বন্ধুর নম্বর যোগ করুন",
                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
            )
          else
            ...List.generate(_friends.length, (i) {
              final f = _friends[i];
              return Padding(
                padding: const EdgeInsets.only(left: 14, right: 14, bottom: 10),
                child: Row(children: [
                  const SizedBox(width: 46),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(f['name']!.isNotEmpty ? f['name']! : 'বন্ধু',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.white)),
                      Text(f['number']!, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ]),
                  ),
                  GestureDetector(
                    onTap: () => _showAddFriendDialog(editIndex: i),
                    child: const Icon(Icons.edit, color: Colors.white54, size: 18),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => _callFriend(f['number']!),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.7)),
                      ),
                      child: const Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.call, color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text("কল", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      ]),
                    ),
                  ),
                ]),
              );
            }),
        ],
      ),
    );
  }
}
