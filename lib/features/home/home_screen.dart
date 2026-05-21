import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/database/app_database.dart';
import '../../core/language/app_language.dart';
import '../../core/network/content_update_service.dart';

import '../auth/login_screen.dart';
import '../auth/signup_screen.dart';
import '../chatbot/chatbot_screen.dart';
import '../categories/categories_screen.dart';
import '../profile/patient_profile_screen.dart';
import '../contacts/emergency_contacts_screen.dart';
import '../history/incident_history_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _emergencyNumber = '911';

  bool _isPressed = false;
  bool _isCheckingUpdates = false;
  bool _isGuest = false;

  static const Color primary = Color(0xFF2563EB);
  static const Color danger = Color(0xFFDC2626);
  static const Color success = Color(0xFF16A34A);
  static const Color background = Color(0xFFF8FAFC);
  static const Color textDark = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    _loadGuestStatus();
    _loadSettings();
    _checkContentUpdates();
  }

  Future<void> _loadGuestStatus() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      _isGuest = prefs.getBool('isGuest') ?? false;
    });
  }

  Future<void> _loadSettings() async {
    final settings = await AppDatabase.instance.getSettings();

    if (!mounted) return;

    setState(() {
      _emergencyNumber = settings['emergency_number'] ?? '911';
    });
  }

  Future<void> _checkContentUpdates() async {
    setState(() => _isCheckingUpdates = true);

    await ContentUpdateService.checkForUpdate();

    if (!mounted) return;

    setState(() => _isCheckingUpdates = false);
  }

  Future<void> _handleEmergencyAction({
    required String phoneNumber,
    required String messageBody,
    required bool isDirectCall,
  }) async {
    HapticFeedback.heavyImpact();

    if (isDirectCall) {
      final Uri callUri = Uri(
        scheme: 'tel',
        path: phoneNumber,
      );

      if (await canLaunchUrl(callUri)) {
        await launchUrl(callUri);
      } else {
        _showSnackBar(
          AppLanguage.text(
            context,
            'Cannot open phone dialer',
            'تعذر فتح شاشة الاتصال',
          ),
          isError: true,
        );
      }

      return;
    }

    final Uri smsUri = Uri(
      scheme: 'sms',
      path: phoneNumber,
      queryParameters: {
        'body': messageBody,
      },
    );

    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
    } else {
      _showSnackBar(
        AppLanguage.text(
          context,
          'Cannot open SMS app',
          'تعذر فتح تطبيق الرسائل',
        ),
        isError: true,
      );
    }
  }

  void _openScreen(
      Widget screen, {
        bool requireLogin = false,
      }) {
    HapticFeedback.selectionClick();

    if (_isGuest && requireLogin) {
      _showGuestDialog();
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    ).then((_) {
      _loadGuestStatus();
      _loadSettings();
    });
  }

  void _showGuestDialog() {
    showDialog(
      context: context,
      builder: (_) {
        final isArabic = AppLanguage.isArabicContext(context);

        return Directionality(
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            title: Text(
              AppLanguage.text(
                context,
                'Login Required',
                'تسجيل الدخول مطلوب',
              ),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              AppLanguage.text(
                context,
                'You are using Guest Mode. Please log in or create an account to access this page.',
                'أنت تستخدم وضع الضيف. سجّل الدخول أو أنشئ حسابًا للوصول إلى هذه الصفحة.',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);

                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LoginScreen(),
                    ),
                  );
                },
                child: Text(
                  AppLanguage.text(
                    context,
                    'Log in',
                    'تسجيل الدخول',
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);

                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SignupScreen(),
                    ),
                  );
                },
                child: Text(
                  AppLanguage.text(
                    context,
                    'Sign up',
                    'إنشاء حساب',
                  ),
                  style: const TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? danger : success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = AppLanguage.isArabicContext(context);

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: background,
        appBar: AppBar(
          title: Text(
            AppLanguage.text(
              context,
              'Rescue Assistant',
              'مساعد الإسعاف',
            ),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: primary,
          centerTitle: true,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        drawer: _buildDrawer(),
        body: RefreshIndicator(
          color: primary,
          onRefresh: () async {
            await _loadGuestStatus();
            await _loadSettings();
            await _checkContentUpdates();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                _buildHeroSection(),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildEmergencyCallButton(),
                      const SizedBox(height: 24),
                      _buildUpdateStatusCard(),
                      const SizedBox(height: 20),
                      _buildDisclaimer(),
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

  Widget _buildHeroSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 34),
      decoration: const BoxDecoration(
        color: primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(34),
          bottomRight: Radius.circular(34),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.health_and_safety,
              size: 58,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            AppLanguage.text(
              context,
              'Emergency?',
              'حالة طارئة؟',
            ),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLanguage.text(
              context,
              'Describe the situation and get instant first-aid guidance',
              'صف الحالة واحصل على إرشادات إسعاف أولي فورية',
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 15,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTapDown: (_) => setState(() => _isPressed = true),
            onTapUp: (_) => setState(() => _isPressed = false),
            onTapCancel: () => setState(() => _isPressed = false),
            onTap: () => _openScreen(const ChatbotScreen()),
            child: AnimatedScale(
              duration: const Duration(milliseconds: 120),
              scale: _isPressed ? 0.96 : 1.0,
              child: Container(
                width: double.infinity,
                height: 62,
                decoration: BoxDecoration(
                  color: danger,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: danger.withOpacity(0.40),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      AppLanguage.text(
                        context,
                        'I NEED HELP',
                        'أحتاج مساعدة',
                      ),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
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

  Widget _buildEmergencyCallButton() {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        _handleEmergencyAction(
          phoneNumber: _emergencyNumber,
          messageBody: '',
          isDirectCall: true,
        );
      },
      onLongPress: () {
        _handleEmergencyAction(
          phoneNumber: _emergencyNumber,
          messageBody: AppLanguage.text(
            context,
            'Critical emergency! I need immediate help. This alert was sent from Rescue Assistant app.',
            'حالة طارئة حرجة! أحتاج مساعدة فورية. تم إرسال طلب استغاثة عبر التطبيق.',
          ),
          isDirectCall: false,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: danger.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.call,
                color: danger,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLanguage.text(
                      context,
                      'Call Emergency',
                      'اتصال طوارئ',
                    ),
                    style: const TextStyle(
                      color: textDark,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppLanguage.text(
                      context,
                      'Tap to call $_emergencyNumber immediately',
                      'اضغط للاتصال فوراً بـ $_emergencyNumber',
                    ),
                    style: const TextStyle(
                      color: textMuted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 18,
              color: Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpdateStatusCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        children: [
          Icon(
            _isCheckingUpdates
                ? Icons.sync_rounded
                : Icons.offline_bolt_rounded,
            color: primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _isCheckingUpdates
                  ? AppLanguage.text(
                context,
                'Checking content updates...',
                'جارٍ فحص تحديثات المحتوى...',
              )
                  : AppLanguage.text(
                context,
                'Offline guidance is ready. Updates will sync when server is available.',
                'الإرشادات غير المتصلة جاهزة وسيتم مزامنة التحديثات عند توفر الخادم.',
              ),
              style: const TextStyle(
                color: Color(0xFF1E3A8A),
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFF97316),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              AppLanguage.text(
                context,
                'This app provides first-aid guidance only. It is not a medical diagnosis tool. In serious emergencies, call emergency services immediately.',
                'هذا التطبيق يقدم إرشادات إسعاف أولي فقط وليس أداة تشخيص طبي. في الحالات الخطيرة، اتصل بخدمات الطوارئ فوراً.',
              ),
              style: const TextStyle(
                color: Color(0xFF7C2D12),
                fontSize: 13,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Drawer _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            _buildDrawerHeader(),
            const SizedBox(height: 12),
            _drawerItem(
              icon: Icons.home_rounded,
              title: AppLanguage.text(context, 'Home', 'الرئيسية'),
              onTap: () => Navigator.pop(context),
            ),
            _drawerItem(
              icon: Icons.chat_bubble_rounded,
              title: AppLanguage.text(
                context,
                'Describe Situation',
                'وصف الحالة',
              ),
              onTap: () {
                Navigator.pop(context);
                _openScreen(const ChatbotScreen());
              },
            ),
            _drawerItem(
              icon: Icons.category_rounded,
              title: AppLanguage.text(
                context,
                'Manual Categories',
                'التصنيفات',
              ),
              onTap: () {
                Navigator.pop(context);
                _openScreen(const CategoriesScreen());
              },
            ),
            _drawerItem(
              icon: Icons.person_rounded,
              title: AppLanguage.text(
                context,
                'Patient Profile',
                'الملف الشخصي',
              ),
              onTap: () {
                Navigator.pop(context);
                _openScreen(
                  const PatientProfileScreen(),
                  requireLogin: true,
                );
              },
            ),
            _drawerItem(
              icon: Icons.contacts_rounded,
              title: AppLanguage.text(
                context,
                'Emergency Contacts',
                'جهات الاتصال',
              ),
              onTap: () {
                Navigator.pop(context);
                _openScreen(
                  const EmergencyContactsScreen(),
                  requireLogin: true,
                );
              },
            ),
            _drawerItem(
              icon: Icons.history_rounded,
              title: AppLanguage.text(
                context,
                'Incident History',
                'سجل الحالات',
              ),
              onTap: () {
                Navigator.pop(context);
                _openScreen(
                  const IncidentHistoryScreen(),
                  requireLogin: true,
                );
              },
            ),
            _drawerItem(
              icon: Icons.settings_rounded,
              title: AppLanguage.text(
                context,
                'Settings',
                'الإعدادات',
              ),
              onTap: () {
                Navigator.pop(context);
                _openScreen(
                  const SettingsScreen(),
                  requireLogin: true,
                );
              },
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                AppLanguage.text(
                  context,
                  'Version 1.0 • Offline Ready',
                  'الإصدار 1.0 • يعمل دون إنترنت',
                ),
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: const BoxDecoration(
        color: primary,
        borderRadius: BorderRadius.only(
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.health_and_safety,
            color: Colors.white,
            size: 46,
          ),
          const SizedBox(height: 12),
          Text(
            AppLanguage.text(
              context,
              'Rescue Assistant',
              'مساعد الإسعاف',
            ),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppLanguage.text(
              context,
              'Emergency guidance app',
              'تطبيق إرشادات الطوارئ',
            ),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: primary),
      title: Text(
        title,
        style: const TextStyle(
          color: textDark,
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: onTap,
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}