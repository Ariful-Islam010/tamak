import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../services/hive_helper.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/backend_service.dart';
import '../utils/error_utils.dart';
import '../utils/profile_image_helper.dart';
import 'auth_screen.dart';
import 'privacy_security_screen.dart';
import 'help_support_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isUploading = false;
  bool _notificationsEnabled = true;
  File? _localImageFile;

  @override
  void initState() {
    super.initState();
    _loadNotificationPreference();
    _loadCachedLocalPhoto();
  }

  Future<void> _loadCachedLocalPhoto() async {
    final uid = BackendService.userId;
    if (uid != null) {
      final path = await HiveHelper().getSetting('local_profile_photo_$uid');
      if (path != null && path.isNotEmpty) {
        final f = File(path);
        if (f.existsSync() && mounted) {
          setState(() {
            _localImageFile = f;
          });
        }
      }
    }
  }

  Future<void> _loadNotificationPreference() async {
    final prefs = HiveHelper();
    final enabled = prefs.getBool('notifications_enabled') ?? true;
    if (mounted) setState(() => _notificationsEnabled = enabled);
  }

  Future<void> _toggleNotifications(bool value) async {
    setState(() => _notificationsEnabled = value);
    final prefs = HiveHelper();
    await prefs.saveBool('notifications_enabled', value);

    if (!mounted) return;
    final authService = ref.read(authServiceProvider);

    if (value) {
      final granted = await NotificationService().requestPermission();
      if (granted) {
        await NotificationService().scheduleAllDailyNotifications(
          quitDate: authService.currentUser?.quitDate,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🔔 নোটিফিকেশন চালু করা হয়েছে!'),
              backgroundColor: AppTheme.primaryGreen,
            ),
          );
        }
      } else {
        setState(() => _notificationsEnabled = false);
        await prefs.saveBool('notifications_enabled', false);
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
    // Capture before any async gap
    final authService = ref.read(authServiceProvider);
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      final File file = File(pickedFile.path);
      setState(() {
        _localImageFile = file;
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
            duration: Duration(days: 1), // Keep open until dismissed
          ),
        );
      }

      final String? secureUrl = await authService.uploadProfilePhoto(file);

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
      }

      if (secureUrl != null) {
        final uid = BackendService.userId;
        if (uid != null) {
          await HiveHelper().saveSetting('local_profile_photo_$uid', file.path);
        }
        if (mounted) {
          await ref.read(authServiceProvider).updateProfilePhoto(secureUrl);
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
          SnackBar(content: Text(ErrorUtils.getFriendlyErrorMessage(e))),
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppTheme.primaryBlue),
                title: const Text("গ্যালারি থেকে সিলেক্ট করুন"),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppTheme.primaryBlue),
                title: const Text("ক্যামেরা দিয়ে ছবি তুলুন"),
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

  void _showEditProfileDialog() {
    final authService = ref.read(authServiceProvider);
    final user = authService.currentUser;
    final nameController = TextEditingController(text: user?.displayName ?? "");
    final eduController = TextEditingController(text: user?.educationalInfo ?? "");
    final ageController = TextEditingController(text: user?.age?.toString() ?? "");
    String? selectedGender = user?.gender ?? "পুরুষ";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "প্রোফাইল সম্পাদনা",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGreen,
                          ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: "নাম",
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: eduController,
                      maxLength: 100,
                      decoration: const InputDecoration(
                        labelText: "শিক্ষাগত যোগ্যতা (সর্বোচ্চ ১০০ অক্ষর)",
                        prefixIcon: Icon(Icons.school),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: ageController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "বয়স",
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedGender,
                      decoration: const InputDecoration(
                        labelText: "লিঙ্গ",
                        prefixIcon: Icon(Icons.wc),
                      ),
                      items: ["পুরুষ", "মহিলা", "অন্যান্য"]
                          .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() => selectedGender = val);
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () async {
                          final nameText = nameController.text.trim();
                          final ageText = ageController.text.trim();
                          final int? ageVal = int.tryParse(ageText);

                          if (nameText.length < 3 || nameText.length > 20) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("নাম অন্তত ৩ থেকে সর্বোচ্চ ২০ অক্ষরের হতে হবে!"),
                                backgroundColor: AppTheme.errorColor,
                              ),
                            );
                            return;
                          }

                          if (ageVal == null || ageVal < 7 || ageVal > 100) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("সঠিক বয়স টাইপ করুন (৭ থেকে ১০০ বছর)!"),
                                backgroundColor: AppTheme.errorColor,
                              ),
                            );
                            return;
                          }

                          final eduText = eduController.text.trim();
                          if (eduText.length > 100) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("শিক্ষাগত তথ্য ১০০ অক্ষরের বেশি হতে পারবে না!"),
                                backgroundColor: AppTheme.errorColor,
                              ),
                            );
                            return;
                          }

                          if (user != null) {
                            final updatedUser = user.copyWith(
                              displayName: nameText,
                              educationalInfo: eduController.text.trim().isNotEmpty ? eduController.text.trim() : null,
                              age: ageVal,
                              gender: selectedGender,
                            );
                            await authService.updateUserData(updatedUser);
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("প্রোফাইল সফলভাবে আপডেট করা হয়েছে!"), backgroundColor: AppTheme.primaryGreen),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text("সংরক্ষণ করুন", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    final randomCode = "DELETE-${Random().nextInt(9000) + 1000}";
    final textController = TextEditingController();
    bool isMatch = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "অ্যাকাউন্ট ডিলিট নিশ্চিতকরণ",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.red),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "সতর্কতা: অ্যাকাউন্ট ডিলিট করলে আপনার সমস্ত অগ্রগতি, স্ট্রাইক, ব্যাজ ও হিস্ট্রি স্থায়ীভাবে মুছে যাবে। এটি আর পুনরুদ্ধার করা সম্ভব হবে না।",
                    style: TextStyle(fontSize: 14, color: Color(0xFF4B5563), height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          "নিচে প্রদর্শিত সিকিউরিটি কোডটি হুবহু টাইপ করুন:",
                          style: TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        SelectableText(
                          randomCode,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: textController,
                    onChanged: (val) {
                      setDialogState(() {
                        isMatch = val.trim() == randomCode;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: "যেমন: $randomCode",
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.red, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text("বাতিল", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              ),
              ElevatedButton(
                onPressed: isMatch
                    ? () async {
                        Navigator.pop(dialogCtx);
                        _executeAccountDeletion(context);
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  disabledBackgroundColor: Colors.red.shade200,
                ),
                child: const Text("স্থায়ীভাবে ডিলিট করুন", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _executeAccountDeletion(BuildContext context) async {
    try {
      await ref.read(authServiceProvider).deleteAccount();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("আপনার অ্যাকাউন্ট ও تمام ডেটা স্থায়ীভাবে মুছে ফেলা হয়েছে।"),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AuthScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("অ্যাকাউন্ট ডিলিট করতে সমস্যা হয়েছে: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = ref.watch(authServiceProvider);
    final user = authService.currentUser;
    final userName = user?.displayName ?? "ব্যবহারকারী";

    return Scaffold(
      backgroundColor: const Color(0xFFF0FDF4), // Vibrant light green/mint background
      appBar: AppBar(
        title: const Text(
          "আমার প্রোফাইল",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // Profile Header Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFECFDF5), Colors.white],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFFA7F3D0), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF047857).withValues(alpha: 0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
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
                              colors: [Color(0xFF10B981), Color(0xFF3B82F6), Color(0xFFF59E0B)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF10B981).withValues(alpha: 0.3),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Hero(
                            tag: "profile-avatar",
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
                              backgroundImage: _localImageFile != null
                                  ? FileImage(_localImageFile!) as ImageProvider
                                  : (user?.photoUrl != null && user!.photoUrl!.isNotEmpty
                                      ? NetworkImage(
                                          user.photoUrl!.startsWith('/')
                                              ? '${BackendService.baseUrl}${user.photoUrl!}'
                                              : user.photoUrl!
                                        )
                                      : null),
                              child: _isUploading
                                  ? const CircularProgressIndicator(color: AppTheme.primaryBlue)
                                  : (_localImageFile == null && (user?.photoUrl == null || user!.photoUrl!.isEmpty)
                                      ? const Icon(Icons.person, size: 60, color: AppTheme.primaryBlue)
                                      : null),
                            ),
                          ),
                        ),
                        if (!_isUploading)
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryGreen,
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
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  if (user?.quitDate != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1FAE5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "তামাকমুক্ত যাত্রা শুরু: ${_getBengaliDateString(user!.quitDate!)}",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF065F46),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),


              // Settings Group
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.cardBackgroundColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.1), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildSettingsTile(
                      context, 
                      "প্রোফাইল সম্পাদনা", 
                      Icons.person_outline, 
                      AppTheme.primaryBlue,
                      onTap: _showEditProfileDialog,
                    ),
                    Divider(height: 1, color: Colors.grey.withValues(alpha: 0.1)),
                    _buildSettingsTile(
                      context, 
                      "নোটিফিকেশন", 
                      Icons.notifications_active, 
                      AppTheme.accentPink,
                      isNotificationTile: true,
                    ),
                    Divider(height: 1, color: Colors.grey.withValues(alpha: 0.1)),
                    _buildSettingsTile(
                      context, 
                      "প্রাইভেসি ও সিকিউরিটি", 
                      Icons.lock_outline, 
                      AppTheme.primaryPurple,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PrivacySecurityScreen()),
                      ),
                    ),
                    Divider(height: 1, color: Colors.grey.withValues(alpha: 0.1)),
                    _buildSettingsTile(
                      context, 
                      "সাহায্য ও সাপোর্ট", 
                      Icons.help_outline, 
                      AppTheme.primaryGreen,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const HelpSupportScreen()),
                      ),
                    ),
                    Divider(height: 1, color: Colors.grey.withValues(alpha: 0.1)),
                    _buildSettingsTile(
                      context, 
                      "অ্যাকাউন্ট মুছে ফেলুন", 
                      Icons.delete_forever_outlined, 
                      Colors.red,
                      onTap: () => _showDeleteAccountDialog(context),
                    ),
                  ],
                ),
              ),

              // Logout Button
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
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
                    icon: const Icon(Icons.logout, color: Colors.white),
                    label: const Text(
                      "লগআউট", 
                      style: TextStyle(
                        color: Colors.white, 
                        fontWeight: FontWeight.bold,
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
            ],
          ),
        ),
    );
  }

  // ignore: unused_element
  Widget _buildStatCard(
    BuildContext context, 
    String label, 
    String value, 
    IconData icon, 
    List<Color> gradientColors
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardBackgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradientColors),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: gradientColors[0].withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 10),
          FittedBox(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppTheme.textColor,
              ),
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textLight,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildBadgeItem(
    String label, 
    String title, 
    bool isUnlocked, 
    IconData icon, 
    List<Color> colors
  ) {
    return Container(
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isUnlocked ? LinearGradient(colors: colors) : null,
              color: isUnlocked ? null : Colors.grey.withValues(alpha: 0.15),
              boxShadow: isUnlocked
                  ? [
                      BoxShadow(
                        color: colors[0].withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              isUnlocked ? icon : Icons.lock_outline,
              color: isUnlocked ? Colors.white : Colors.grey.withValues(alpha: 0.6),
              size: 24,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isUnlocked ? AppTheme.textColor : AppTheme.textLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, 
    String title, 
    IconData icon, 
    Color iconBgColor, 
    {String? trailing, bool isNotificationTile = false, VoidCallback? onTap}
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isNotificationTile
            ? null
            : onTap ?? () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('"$title" অপশনটি শীঘ্রই চালু হবে।')),
                );
              },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBgColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconBgColor, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title, 
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textColor,
                      ),
                    ),
                    if (isNotificationTile)
                      Text(
                        _notificationsEnabled
                            ? 'দৈনিক অনুপ্রেরণা, চেক-ইন রিমাইন্ডার চালু'
                            : 'সব নোটিফিকেশন বন্ধ',
                        style: TextStyle(
                          fontSize: 11,
                          color: _notificationsEnabled
                              ? AppTheme.primaryGreen
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
                  activeThumbColor: AppTheme.primaryGreen,
                )
              else if (trailing != null) ...[
                Flexible(
                  child: Text(
                    trailing, 
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
              ] else
                const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  void _viewProfileImage() {
    final user = ref.read(authServiceProvider).currentUser;
    final imageProvider = ProfileImageHelper.getProfileImageProvider(
      user?.photoUrl,
      localFilePath: _localImageFile?.path,
    );
    if (imageProvider == null) return;

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        pageBuilder: (context, _, secondaryAnimation) {
          return Scaffold(
            backgroundColor: Colors.black.withValues(alpha: 0.85),
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
                          backgroundImage: imageProvider,
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
