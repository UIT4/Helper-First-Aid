import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/database/app_database.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/login_screen.dart';
import '../auth/signup_screen.dart';
import '../chatbot/chatbot_screen.dart';
import '../categories/categories_screen.dart';
import '../profile/patient_profile_screen.dart';
import '../contacts/emergency_contacts_screen.dart';
import '../history/incident_history_screen.dart';
import '../settings/settings_screen.dart';
import '../../core/network/content_update_service.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _emergencyNumber = '911';
  bool _isPressed = false;
  bool _isCheckingUpdates = false;

// دالة التعامل الذكي مع الحالات الخطيرة والحرجة
  Future<void> _handleHighUrgencyCase({
    required String phoneNumber, 
    required String messageBody,
    bool isDirectCall = true, 
  }) async {
    if (isDirectCall) {
      // فتح شاشة الاتصال بالرقم فوراً
      final Uri callUri = Uri(scheme: 'tel', path: phoneNumber);
      if (await canLaunchUrl(callUri)) {
        await launchUrl(callUri);
      } else {
        _showSnackbar('تعذر إجراء مكالمة الطوارئ للرقم: $phoneNumber', isError: true);
      }
    } else {
      // تجهيز رسالة SMS تحتوي على تفاصيل الاستغاثة
      final Uri smsUri = Uri(
        scheme: 'sms',
        path: phoneNumber,
        queryParameters: <String, String>{
          'body': messageBody,
        },
      );
      
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
      } else {
        _showSnackbar('تعذر تجهيز رسالة الطوارئ', isError: true);
      }
    }
  }
  bool _isGuest = false;

  Future<void> _loadGuestStatus() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _isGuest = prefs.getBool('isGuest') ?? false;
    });
  }

  void _openGuestBlockedDialog() {

    showDialog(

      context: context,

      builder: (_) => AlertDialog(

        shape: RoundedRectangleBorder(
          borderRadius:
          BorderRadius.circular(16),
        ),

        title: const Text(
          'Guest Mode',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

        content: const Text(
          'You are using Guest Mode.\n'
              'يمكنك التصفح لكن لا يمكنك تعديل البيانات.',
        ),

        actions: [

          TextButton(

            onPressed:(){

              Navigator.push(
                context,

                MaterialPageRoute(
                  builder:(_)=>const LoginScreen(),
                ),
              );

            },

            child: const Text(
              'Log in',
            ),

          ),

          ElevatedButton(

            style:
            ElevatedButton.styleFrom(
              backgroundColor:
              const Color(0xFF2563EB),
            ),

            onPressed:(){

              Navigator.push(

                context,

                MaterialPageRoute(
                  builder:(_)=>const SignupScreen(),
                ),

              );

            },

            child: const Text(
              'Sign up',
              style: TextStyle(
                color: Colors.white,
              ),
            ),

          )

        ],

      ),

    );

  }

  void _openScreenProtected(

      Widget screen,

      {bool needsLogin=false}

      ){

    if(_isGuest && needsLogin){

      _openGuestBlockedDialog();

      return;

    }

    _openScreen(screen);

  }

  // دالة مساعدة لإظهار رسائل التحذير (Snackbar) في شاشة الـ Home
  void _showSnackbar(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadGuestStatus();
    _loadSettings();
    _checkContentUpdates();
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

  Future<void> _callEmergency() async {
    HapticFeedback.heavyImpact();

    final Uri url = Uri(scheme: 'tel', path: _emergencyNumber);

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      _showSnackBar('Cannot open phone dialer', isError: true);
    }
  }

  void _openScreen(Widget screen) {
    HapticFeedback.selectionClick();

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    ).then((_) => _loadSettings());
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
        isError ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Rescue Assistant',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF2563EB),
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
       
      ),
      drawer: _buildDrawer(),
      body: RefreshIndicator(
        color: const Color(0xFF2563EB),
        onRefresh: () async {
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
    );
  }

  Widget _buildHeroSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 34),
      decoration: const BoxDecoration(
        color: Color(0xFF2563EB),
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

          const Text(
            'Emergency?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Describe the situation and get instant first-aid guidance',
            textAlign: TextAlign.center,
            style: TextStyle(
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
            onTap: () => _openScreenProtected(const ChatbotScreen()),
            child: AnimatedScale(
              duration: const Duration(milliseconds: 120),
              scale: _isPressed ? 0.96 : 1.0,
              child: Container(
                width: double.infinity,
                height: 62,
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFDC2626).withOpacity(0.40),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'I NEED HELP',
                      style: TextStyle(
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
      // 1. عند الضغط العادي: اتصال فوري ومباشر
      onTap: () {
        _handleHighUrgencyCase(
          phoneNumber: _emergencyNumber, // الرقم المجلوب ديناميكياً من قاعدة البيانات
          messageBody: '',
          isDirectCall: true, // توجيه مالي لشاشة الاتصال فوراً
        );
      },
      // 2. عند الضغط المطول: تجهيز رسالة استغاثة طوارئ تلقائية
      onLongPress: () {
        _handleHighUrgencyCase(
          phoneNumber: _emergencyNumber,
          messageBody: 'حالة طارئة حرجة! أطلب المساعدة الفورية، تم إرسال طلب استغاثة عبر التطبيق.',
          isDirectCall: false, // لتجهيز وإرسال الرسالة النصية SMS
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626).withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.call,
                color: Color(0xFFDC2626),
                size: 28,
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Call Emergency',
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap to call $_emergencyNumber immediately',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
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

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionsGrid() {
    final actions = [
      _HomeAction(
        title: 'Describe',
        subtitle: 'AI guidance',
        icon: Icons.chat_bubble_rounded,
        color: const Color(0xFF2563EB),
        screen: const ChatbotScreen(),
      ),
     ];

    return GridView.builder(
      itemCount: actions.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 1,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 2.6,
      ),
      itemBuilder: (context, index) {
        final item = actions[index];

        return InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => _openScreenProtected(item.screen),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.045),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: item.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    item.icon,
                    color: item.color,
                    size: 25,
                  ),
                ),

                const Spacer(),

                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  item.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
            color: const Color(0xFF2563EB),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              _isCheckingUpdates
                  ? 'Checking content updates...'
                  : 'Offline guidance is ready. Updates will sync when server is available.',
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
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFF97316),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'This app provides first-aid guidance only. It is not a medical diagnosis tool. In serious emergencies, call emergency services immediately.',
              style: TextStyle(
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
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: const BoxDecoration(
                color: Color(0xFF2563EB),
                borderRadius: BorderRadius.only(
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.health_and_safety,
                    color: Colors.white,
                    size: 46,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Rescue Assistant',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Emergency guidance app',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            _drawerItem(
              icon: Icons.chat_bubble_rounded,
              title: 'Describe Situation',
              onTap: () {
                Navigator.pop(context);

                _openScreenProtected(
                  const ChatbotScreen(),
                );
              },
            ),

            _drawerItem(
              icon: Icons.category_rounded,
              title: 'Manual Categories',
              onTap: () {
                Navigator.pop(context);

                _openScreenProtected(
                  const CategoriesScreen(),
                );
              },
            ),

            _drawerItem(
              icon: Icons.person_rounded,
              title: 'Patient Profile',
              onTap: () {
                Navigator.pop(context);

                _openScreenProtected(
                  const PatientProfileScreen(),
                  needsLogin: true,
                );
              },
            ),

            _drawerItem(
              icon: Icons.contacts_rounded,
              title: 'Emergency Contacts',
              onTap: () {
                Navigator.pop(context);

                _openScreenProtected(
                  const EmergencyContactsScreen(),
                  needsLogin: true,
                );
              },
            ),

            _drawerItem(
              icon: Icons.history_rounded,
              title: 'Incident History',
              onTap: () {
                Navigator.pop(context);

                _openScreenProtected(
                  const IncidentHistoryScreen(),
                );
              },
            ),

            _drawerItem(
              icon: Icons.settings_rounded,
              title: 'Settings',
              onTap: () {
                Navigator.pop(context);

                _openScreenProtected(
                  const SettingsScreen(),
                  needsLogin: true,
                );
              },
            ),

            const Spacer(),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Version 1.0 • Offline Ready',
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

  Widget _drawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF2563EB)),
      title: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF0F172A),
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: onTap,
    );
  }
}

class _HomeAction {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget screen;

  const _HomeAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.screen,
  });
}