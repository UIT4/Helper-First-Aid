import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../auth/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  final List<Map<String, dynamic>> _pages = [
    {
      'title': 'Important Disclaimer',
      'titleAr': 'تنبيه مهم',
      'desc':
      'This app provides emergency guidance only. It is not a medical diagnosis tool. Always call emergency services in critical situations.',
      'descAr':
      'هذا التطبيق يقدم إرشادات طارئة فقط وليس أداة تشخيص طبي. في الحالات الخطيرة اتصل بالطوارئ فوراً.',
      'icon': Icons.warning_amber_rounded,
      'color': const Color(0xFFF97316),
      'bg': const Color(0xFFFFF7ED),
    },
    {
      'title': 'Emergency Ready',
      'titleAr': 'جاهز للطوارئ',
      'desc':
      'Call emergency services and send SMS to emergency contacts quickly when help is needed.',
      'descAr':
      'اتصل بالطوارئ وأرسل رسالة لجهات الاتصال بسرعة عند الحاجة للمساعدة.',
      'icon': Icons.emergency_share_rounded,
      'color': const Color(0xFFDC2626),
      'bg': const Color(0xFFFFF1F2),
    },
    {
      'title': 'Instant Guidance',
      'titleAr': 'إرشاد فوري',
      'desc':
      'Get step-by-step first aid instructions even without internet connection.',
      'descAr':
      'احصل على إرشادات الإسعافات الأولية خطوة بخطوة حتى بدون إنترنت.',
      'icon': Icons.offline_bolt_rounded,
      'color': const Color(0xFF2563EB),
      'bg': const Color(0xFFEFF6FF),
    },
    {
      'title': 'Smart AI Diagnosis',
      'titleAr': 'تشخيص ذكي',
      'desc':
      'Describe the emergency in Arabic or English and the assistant identifies the case instantly.',
      'descAr':
      'صف الحالة الطارئة بالعربي أو الإنجليزي والمساعد يحدد الحالة فوراً.',
      'icon': Icons.psychology_rounded,
      'color': const Color(0xFF8B5CF6),
      'bg': const Color(0xFFF5F3FF),
    },
  ];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
    _fadeCtrl.reset();
    _fadeCtrl.forward();
    HapticFeedback.selectionClick();
  }

  void _goToLogin() {
    HapticFeedback.mediumImpact();

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, __, ___) => const LoginScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  void _goNext() {
    HapticFeedback.selectionClick();

    if (_currentIndex == _pages.length - 1) {
      _goToLogin();
      return;
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_currentIndex];
    final Color accent = page['color'] as Color;
    final isLast = _currentIndex == _pages.length - 1;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.health_and_safety,
                          color: accent,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Rescue',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: _onPageChanged,
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index]);
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(28, 12, 28, 24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                          (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        height: 8,
                        width: _currentIndex == i ? 28 : 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: _currentIndex == i
                              ? accent
                              : const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _goToLogin,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0,58),
                            side: BorderSide(color: accent),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: Text(
                            'Skip',
                            style: TextStyle(
                              color: accent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: SizedBox(
                          height: 58,
                          child: ElevatedButton(
                            onPressed: _goNext,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accent,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  isLast ? 'Start Now' : 'Next',
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  isLast
                                      ? Icons.login_rounded
                                      : Icons.arrow_forward_rounded,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(Map<String, dynamic> page) {
    final Color accent = page['color'] as Color;
    final Color bgColor = page['bg'] as Color;

    return FadeTransition(
      opacity: _fadeAnim,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: accent.withOpacity(0.18),
                    blurRadius: 40,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Icon(
                page['icon'] as IconData,
                size: 80,
                color: accent,
              ),
            ),
            const SizedBox(height: 48),

            Text(
              page['title'] as String,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),

            Text(
              page['titleAr'] as String,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: accent,
              ),
            ),
            const SizedBox(height: 20),

            Text(
              page['desc'] as String,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF64748B),
                height: 1.6,
              ),
            ),
            const SizedBox(height: 12),

            Text(
              page['descAr'] as String,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF475569),
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}