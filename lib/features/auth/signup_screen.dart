import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/database/app_database.dart';
import '../../core/language/app_language.dart';
import 'questionnaire_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _pageController = PageController();

  int currentPage = 0;

  final _firstCtrl = TextEditingController();
  final _middleCtrl = TextEditingController();
  final _lastCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  static const Color primary = Color(0xFF2563EB);
  static const Color danger = Color(0xFFDC2626);
  static const Color background = Color(0xFFF8FAFC);

  @override
  void dispose() {
    _pageController.dispose();
    _firstCtrl.dispose();
    _middleCtrl.dispose();
    _lastCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[A-Za-z0-9._%+-]+@gmail\.com$').hasMatch(email);
  }

  bool _isValidPassword(String password) {
    return RegExp(
      r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[@$!%*#?&])[A-Za-z\d@$!%*#?&]{8,}$',
    ).hasMatch(password);
  }

  bool _isValidPhone(String phone) {
    return RegExp(r'^[0-9]{9,15}$').hasMatch(phone);
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: danger,
      ),
    );
  }

  bool _validateCurrentPage() {
    final isArabic = AppLanguage.isArabicContext(context);

    if (currentPage == 0) {
      if (_firstCtrl.text.trim().isEmpty ||
          _middleCtrl.text.trim().isEmpty ||
          _lastCtrl.text.trim().isEmpty) {
        _showSnack(isArabic ? 'عبّئ الاسم كامل' : 'Fill your full name');
        return false;
      }
    }

    if (currentPage == 1) {
      final email = _emailCtrl.text.trim().toLowerCase();

      if (email.isEmpty) {
        _showSnack(isArabic ? 'أدخل الإيميل' : 'Enter your email');
        return false;
      }

      if (!_isValidEmail(email)) {
        _showSnack(
          isArabic
              ? 'الإيميل يجب أن يكون Gmail صحيح'
              : 'Email must be a valid Gmail',
        );
        return false;
      }
    }

    if (currentPage == 2) {
      final password = _passwordCtrl.text.trim();
      final confirm = _confirmPasswordCtrl.text.trim();

      if (password.isEmpty || confirm.isEmpty) {
        _showSnack(
          isArabic ? 'أدخل كلمة المرور وتأكيدها' : 'Enter and confirm password',
        );
        return false;
      }

      if (!_isValidPassword(password)) {
        _showSnack(
          isArabic
              ? 'كلمة المرور يجب أن تكون 8 خانات وتحتوي حرف ورقم ورمز'
              : 'Password must be 8+ chars with letter, number and symbol',
        );
        return false;
      }

      if (password != confirm) {
        _showSnack(
          isArabic ? 'كلمة المرور غير متطابقة' : 'Passwords do not match',
        );
        return false;
      }
    }

    if (currentPage == 3) {
      final phone = _phoneCtrl.text.trim();

      if (phone.isEmpty) {
        _showSnack(isArabic ? 'أدخل رقم الهاتف' : 'Enter phone number');
        return false;
      }

      if (!_isValidPhone(phone)) {
        _showSnack(isArabic ? 'رقم الهاتف غير صحيح' : 'Invalid phone number');
        return false;
      }
    }

    return true;
  }

  void _nextPage() {
    if (!_validateCurrentPage()) return;

    if (currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishSignup();
    }
  }

  Future<void> _finishSignup() async {
    try {
      final first = _firstCtrl.text.trim();
      final middle = _middleCtrl.text.trim();
      final last = _lastCtrl.text.trim();
      final email = _emailCtrl.text.trim().toLowerCase();
      final password = _passwordCtrl.text.trim();
      final phone = _phoneCtrl.text.trim();

      final existingUser = await AppDatabase.instance.getUserByEmail(email);

      if (existingUser != null) {
        _showSnack(
          AppLanguage.text(
            context,
            'This email is already registered',
            'هذا الإيميل مسجل مسبقاً',
          ),
        );
        return;
      }

      final fullName = '$first $middle $last';

      await AppDatabase.instance.insertUser(
        fullName: fullName,
        email: email,
        phone: phone,
        password: password,
      );

      final prefs = await SharedPreferences.getInstance();

      await prefs.setBool('isGuest', false);
      await prefs.setBool('isLoggedIn', false);
      await prefs.setString('userEmail', email);
      await prefs.setString('registeredName', fullName);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => QuestionnaireScreen(
            name: fullName,
            email: email,
          ),
        ),
      );
    } catch (e) {
      _showSnack('Signup error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = AppLanguage.isArabicContext(context);

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 20),
                LinearProgressIndicator(
                  value: (currentPage + 1) / 4,
                  borderRadius: BorderRadius.circular(20),
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade300,
                  color: primary,
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (i) => setState(() => currentPage = i),
                    children: [
                      _page(
                        title: AppLanguage.text(
                          context,
                          'Your Full Name',
                          'اسمك الكامل',
                        ),
                        subtitle: AppLanguage.text(
                          context,
                          'Enter first, middle and last name',
                          'أدخل الاسم الأول والثاني والأخير',
                        ),
                        children: [
                          _field(
                            controller: _firstCtrl,
                            hint: AppLanguage.text(
                              context,
                              'First Name',
                              'الاسم الأول',
                            ),
                            icon: Icons.person_outline,
                          ),
                          _field(
                            controller: _middleCtrl,
                            hint: AppLanguage.text(
                              context,
                              'Middle Name',
                              'الاسم الثاني',
                            ),
                            icon: Icons.person_outline,
                          ),
                          _field(
                            controller: _lastCtrl,
                            hint: AppLanguage.text(
                              context,
                              'Last Name',
                              'الاسم الأخير',
                            ),
                            icon: Icons.person_outline,
                          ),
                        ],
                      ),
                      _page(
                        title: AppLanguage.text(context, 'Your Email', 'إيميلك'),
                        subtitle: AppLanguage.text(
                          context,
                          'Use your Gmail account',
                          'استخدم حساب Gmail',
                        ),
                        children: [
                          _field(
                            controller: _emailCtrl,
                            hint: 'example@gmail.com',
                            icon: Icons.email_outlined,
                            keyboard: TextInputType.emailAddress,
                          ),
                        ],
                      ),
                      _page(
                        title: AppLanguage.text(
                          context,
                          'Create Password',
                          'أنشئ كلمة مرور',
                        ),
                        subtitle: AppLanguage.text(
                          context,
                          'Use a strong password',
                          'استخدم كلمة مرور قوية',
                        ),
                        children: [
                          _field(
                            controller: _passwordCtrl,
                            hint: AppLanguage.text(
                              context,
                              'Password',
                              'كلمة المرور',
                            ),
                            icon: Icons.lock_outline,
                            obscure: true,
                          ),
                          _field(
                            controller: _confirmPasswordCtrl,
                            hint: AppLanguage.text(
                              context,
                              'Confirm Password',
                              'تأكيد كلمة المرور',
                            ),
                            icon: Icons.lock_reset,
                            obscure: true,
                          ),
                        ],
                      ),
                      _page(
                        title: AppLanguage.text(
                          context,
                          'Phone Number',
                          'رقم الهاتف',
                        ),
                        subtitle: AppLanguage.text(
                          context,
                          'Used for password recovery',
                          'يستخدم لاسترجاع كلمة المرور',
                        ),
                        children: [
                          _field(
                            controller: _phoneCtrl,
                            hint: '079XXXXXXX',
                            icon: Icons.phone_outlined,
                            keyboard: TextInputType.phone,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      currentPage == 3
                          ? AppLanguage.text(context, 'FINISH', 'إنهاء')
                          : AppLanguage.text(context, 'NEXT', 'التالي'),
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _page({
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Padding(
        padding: const EdgeInsets.only(top: 50, bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 17,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 42),
            ...children.map(
                  (e) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: e,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    TextInputType keyboard = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboard,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: primary),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 22,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}