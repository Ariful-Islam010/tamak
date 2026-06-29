import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/cloudinary_service.dart';
import '../services/notification_service.dart';
import 'auth_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isUploading = false;
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationPreference();
  }

  Future<void> _loadNotificationPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('notifications_enabled') ?? true;
    if (mounted) setState(() => _notificationsEnabled = enabled);
  }

  Future<void> _toggleNotifications(bool value) async {
    setState(() => _notificationsEnabled = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);

    if (value) {
      final granted = await NotificationService().requestPermission();
      if (granted) {
        await NotificationService().scheduleAllDailyNotifications();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🔔 নোটিফিকেশন চালু করা হয়েছে!'),
              backgroundColor: AppTheme.accentLime,
            ),
          );
        }
      } else {
        setState(() => _notificationsEnabled = false);
        await prefs.setBool('notifications_enabled', false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('নোটিফিকেশন permission দেওয়া হয়নি।'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    } else {
      await NotificationService().cancelDailyNotifications();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🔕 নোটিফিকেশন বন্ধ করা হয়েছে।')),
        );
      }
    }
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() {
        _isUploading = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                ),
                SizedBox(width: 16),
                Text("ছবি আপলোড করা হচ্ছে..."),
              ],
            ),
            duration: Duration(days: 1),
          ),
        );
      }

      final File file = File(pickedFile.path);
      final String? secureUrl = await CloudinaryService.uploadImage(file);

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
      }

      if (secureUrl != null) {
        if (mounted) {
          await context.read<AuthService>().updateProfilePhoto(secureUrl);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("প্রোফাইল ছবি সফলভাবে পরিবর্তন করা হয়েছে!")),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("ছবি আপলোড করতে সমস্যা হয়েছে। আবার চেষ্টা করুন।")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("ত্রুটি: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.demonMid,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppTheme.accentCyan),
                title: const Text("গ্যালারি থেকে সিলেক্ট করুন", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppTheme.accentPink),
                title: const Text("ক্যামেরা দিয়ে ছবি তুলুন", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String _getBengaliDateString(DateTime date) {
    final months = [
      "জানুয়ারি", "ফেব্রুয়ারি", "মার্চ", "এপ্রিল", "মে", "জুন",
      "জুলাই", "আগস্ট", "সেপ্টেম্বর", "অক্টোবর", "নভেম্বর", "ডিসেম্বর"
    ];
    
    final String dayStr = date.day.toString()
        .replaceAll('0', '০').replaceAll('1', '১').replaceAll('2', '২')
        .replaceAll('3', '৩').replaceAll('4', '৪').replaceAll('5', '৫')
        .replaceAll('6', '৬').replaceAll('7', '৭').replaceAll('8', '৮')
        .replaceAll('9', '৯');
        
    final String yearStr = date.year.toString()
        .replaceAll('0', '০').replaceAll('1', '১').replaceAll('2', '২')
        .replaceAll('3', '৩').replaceAll('4', '৪').replaceAll('5', '৫')
        .replaceAll('6', '৬').replaceAll('7', '৭').replaceAll('8', '৮')
        .replaceAll('9', '৯');
        
    return "$dayStr ${months[date.month - 1]}, $yearStr";
  }

  String _toBengaliNumber(String englishNumber) {
    return englishNumber
        .replaceAll('0', '০').replaceAll('1', '১').replaceAll('2', '২')
        .replaceAll('3', '৩').replaceAll('4', '৪').replaceAll('5', '৫')
        .replaceAll('6', '৬').replaceAll('7', '৭').replaceAll('8', '৮')
        .replaceAll('9', '৯');
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final user = authService.currentUser;
    final userName = user?.displayName ?? "ব্যবহারকারী";
    final userEmail = user?.email ?? "ইমেইল দেওয়া হয়নি";

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          "আমার প্রোফাইল 👤✨",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: AppTheme.demonDark,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Profile Header Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppTheme.accentPink, width: 3.5),
                boxShadow: AppTheme.glowShadow(AppTheme.accentPink),
              ),
              child: Column(
                children: [
                  // Avatar with glowing ring
                  GestureDetector(
                    onTap: _isUploading ? null : _showImagePickerOptions,
                    onLongPress: () => _viewProfileImage(),
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [AppTheme.accentPink, AppTheme.accentYellow, AppTheme.accentCyan],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Hero(
                            tag: "profile-avatar",
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: AppTheme.primaryPurple.withValues(alpha: 0.1),
                              backgroundImage: user?.photoUrl != null ? NetworkImage(user!.photoUrl!) : null,
                              child: _isUploading
                                  ? const CircularProgressIndicator(color: AppTheme.accentPink)
                                  : (user?.photoUrl == null
                                      ? const Icon(Icons.person, size: 60, color: AppTheme.primaryPurple)
                                      : null),
                            ),
                          ),
                        ),
                        if (!_isUploading)
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: AppTheme.accentPink,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt, size: 16, color: AppTheme.white),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    userName, 
                    style: const TextStyle(
                      fontSize: 22, 
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userEmail, 
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textLight,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  if (user?.quitDate != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.accentLime.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.accentLime, width: 2),
                      ),
                      child: Text(
                        "তামাকমুক্ত যাত্রা: ${_getBengaliDateString(user!.quitDate!)}",
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.accentLime,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Settings Group
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppTheme.primaryPurple.withValues(alpha: 0.1), width: 3),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryPurple.withValues(alpha: 0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildSettingsTile(
                    context, 
                    "প্রোফাইল সম্পাদনা", 
                    Icons.person_outline, 
                    AppTheme.accentCyan,
                  ),
                  Divider(height: 1, color: AppTheme.primaryPurple.withValues(alpha: 0.1)),
                  _buildSettingsTile(
                    context, 
                    "ভাষা (Language)", 
                    Icons.language, 
                    AppTheme.accentOrange, 
                    trailing: "বাংলা",
                  ),
                  Divider(height: 1, color: AppTheme.primaryPurple.withValues(alpha: 0.1)),
                  _buildSettingsTile(
                    context, 
                    "নোটিফিকেশন", 
                    Icons.notifications_active, 
                    AppTheme.accentPink,
                    isNotificationTile: true,
                  ),
                  Divider(height: 1, color: AppTheme.primaryPurple.withValues(alpha: 0.1)),
                  _buildSettingsTile(
                    context, 
                    "প্রাইভেসি ও সিকিউরিটি", 
                    Icons.lock_outline, 
                    AppTheme.accentYellow,
                  ),
                  Divider(height: 1, color: AppTheme.primaryPurple.withValues(alpha: 0.1)),
                  _buildSettingsTile(
                    context, 
                    "সাহায্য ও সাপোর্ট", 
                    Icons.help_outline, 
                    AppTheme.accentLime,
                  ),
                ],
              ),
            ),

            // Logout Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await authService.signOut();
                    if (context.mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const AuthScreen()),
                        (route) => false,
                      );
                    }
                  },
                  icon: const Icon(Icons.logout, color: Colors.white, size: 24),
                  label: const Text(
                    "লগআউট", 
                    style: TextStyle(
                      color: Colors.white, 
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.errorColor,
                    elevation: 4,
                    shadowColor: AppTheme.errorColor.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, 
    String title, 
    IconData icon, 
    Color iconBgColor, 
    {String? trailing, bool isNotificationTile = false}
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isNotificationTile
            ? null
            : () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('"$title" অপশনটি শীঘ্রই চালু হবে।')),
                );
              },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconBgColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: iconBgColor.withValues(alpha: 0.3), width: 1.5),
                ),
                child: Icon(icon, color: iconBgColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title, 
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textColor,
                      ),
                    ),
                    if (isNotificationTile)
                      Text(
                        _notificationsEnabled
                            ? 'দৈনিক অনুপ্রেরণা, চেক-ইন রিমাইন্ডার চালু'
                            : 'সব নোটিফিকেশন বন্ধ',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _notificationsEnabled
                              ? AppTheme.accentLime
                              : AppTheme.textLight,
                        ),
                      ),
                  ],
                ),
              ),
              if (isNotificationTile)
                Switch(
                  value: _notificationsEnabled,
                  onChanged: _toggleNotifications,
                  activeColor: AppTheme.accentLime,
                  activeTrackColor: AppTheme.accentLime.withValues(alpha: 0.3),
                  inactiveThumbColor: Colors.grey,
                  inactiveTrackColor: Colors.grey.withValues(alpha: 0.3),
                )
              else if (trailing != null) ...[
                Flexible(
                  child: Text(
                    trailing, 
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textLight,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.textLight),
              ] else
                const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.textLight),
            ],
          ),
        ),
      ),
    );
  }

  void _viewProfileImage() {
    final user = context.read<AuthService>().currentUser;
    if (user?.photoUrl == null) return;

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        pageBuilder: (context, _, secondaryAnimation) {
          return Scaffold(
            backgroundColor: Colors.black.withValues(alpha: 0.9),
            body: Stack(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Center(
                    child: Hero(
                      tag: "profile-avatar",
                      child: InteractiveViewer(
                        clipBehavior: Clip.none,
                        child: CircleAvatar(
                          radius: 140,
                          backgroundColor: Colors.white10,
                          backgroundImage: NetworkImage(user!.photoUrl!),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 40,
                  right: 20,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 30),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
