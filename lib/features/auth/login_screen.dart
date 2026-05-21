import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../home/home_screen.dart';
import '../chatbot/chatbot_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _rememberMe = false;
  bool _isArabic = false;

  static const Color primary = Color(0xFF2563EB);
  static const Color background = Color(0xFFF8FAFC);
  static const Color danger = Color(0xFFDC2626);
  static const Color success = Color(0xFF16A34A);

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    final regex = RegExp(r'^[A-Za-z0-9._%+-]+@gmail\.com$');
    return regex.hasMatch(email);
  }

  bool _isValidPassword(String password) {
    final regex = RegExp(
      r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[@$!%*#?&])[A-Za-z\d@$!%*#?&]{8,}$',
    );
    return regex.hasMatch(password);
  }

  Future<void> _login() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnack(
        _isArabic
            ? 'أدخل البريد الإلكتروني وكلمة المرور'
            : 'Enter email and password',
        isError: true,
      );
      return;
    }

    if (!_isValidEmail(email)) {
      _showSnack(
        _isArabic
            ? 'البريد يجب أن يكون مثل example@gmail.com'
            : 'Email must be like example@gmail.com',
        isError: true,
      );
      return;
    }

    if (!_isValidPassword(password)) {
      _showSnack(
        _isArabic
            ? 'كلمة المرور يجب أن تكون 8 خانات على الأقل وتحتوي حرف ورقم ورمز'
            : 'Password must be 8+ chars with letters, numbers, and special character',
        isError: true,
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();

    final registeredEmail = prefs.getString('registeredEmail');
    final registeredPassword = prefs.getString('registeredPassword');

    if (registeredEmail == null || registeredPassword == null) {
      _showSnack(
        _isArabic
            ? 'أنت غير مسجل. أنشئ حساب أولاً.'
            : 'You are not registered. Create an account first.',
        isError: true,
      );
      return;
    }

    if (email != registeredEmail) {
      _showSnack(
        _isArabic
            ? 'هذا البريد غير مسجل. أنشئ حساب.'
            : 'This email is not registered. Create an account.',
        isError: true,
      );
      return;
    }

    if (password != registeredPassword) {
      _showSnack(
        _isArabic ? 'كلمة المرور غير صحيحة' : 'Wrong password',
        isError: true,
      );
      return;
    }

    await prefs.setBool('isGuest', false);
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('userEmail', email);

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  Future<void> _guestLogin() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('isGuest', true);
    await prefs.setBool('isLoggedIn', false);

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  void _forgotPassword() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            left: 22,
            right: 22,
            top: 22,
            bottom: MediaQuery.of(context).viewInsets.bottom + 22,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock_reset_rounded,
                  size: 50,
                  color: primary,
                ),
                const SizedBox(height: 12),
                Text(
                  _isArabic ? 'إعادة تعيين كلمة المرور' : 'Reset Password',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isArabic
                      ? 'استرجاع كلمة المرور متاح عبر رقم الهاتف فقط.'
                      : 'Password reset is available by phone number only.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 20),

                _resetOption(
                  icon: Icons.sms_outlined,
                  title: _isArabic
                      ? 'استرجاع بواسطة رقم الهاتف'
                      : 'Reset by Phone Number',
                  subtitle: _isArabic
                      ? 'سيتم إرسال رمز تحقق للهاتف لاحقاً'
                      : 'Verification code will be sent by SMS later',
                  onTap: () {
                    Navigator.pop(context);
                    _showSnack(
                      _isArabic
                          ? 'ربط خدمة SMS لاحقاً'
                          : 'SMS service will be connected later',
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _resetOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(16),
          color: const Color(0xFFF8FAFC),
        ),
        child: Row(
          children: [
            Icon(icon, color: primary, size: 30),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment:
                _isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    textAlign: _isArabic ? TextAlign.right : TextAlign.left,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    textAlign: _isArabic ? TextAlign.right : TextAlign.left,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16),
          ],
        ),
      ),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? danger : success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: background,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 430),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 30),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            primary,
                            Color(0xFF1E40AF),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(22),
                        ),
                      ),
                      child: Column(
                        children: [
                          Align(
                            alignment: _isArabic
                                ? Alignment.topLeft
                                : Alignment.topRight,
                            child: Padding(
                              padding:
                              const EdgeInsets.symmetric(horizontal: 16),
                              child: TextButton(
                                onPressed: () {
                                  setState(() => _isArabic = !_isArabic);
                                },
                                child: Text(
                                  _isArabic ? 'English' : 'العربية',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.health_and_safety_rounded,
                            color: Colors.white,
                            size: 78,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _isArabic ? 'مساعد الإسعاف' : 'Rescue Assistant',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _isArabic
                                ? 'مساعدة فورية في الحالات الطارئة'
                                : 'Instant emergency help',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                      child: Column(
                        children: [
                          _inputField(
                            controller: _emailCtrl,
                            hint: _isArabic
                                ? 'البريد الإلكتروني Gmail'
                                : 'Gmail Email',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 14),

                          _inputField(
                            controller: _passwordCtrl,
                            hint: _isArabic ? 'كلمة المرور' : 'Password',
                            icon: Icons.lock_outline,
                            obscure: true,
                            keyboardType: TextInputType.text,
                          ),

                          const SizedBox(height: 8),

                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            runSpacing: 4,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Checkbox(
                                    value: _rememberMe,
                                    activeColor: primary,
                                    visualDensity: VisualDensity.compact,
                                    onChanged: (v) {
                                      setState(() => _rememberMe = v ?? false);
                                    },
                                  ),
                                  Text(
                                    _isArabic ? 'تذكرني' : 'Remember',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ],
                              ),
                              TextButton(
                                onPressed: _forgotPassword,
                                child: Text(
                                  _isArabic ? 'نسيت كلمة المرور؟' : 'Forgot Password?',
                                  style: const TextStyle(
                                    color: Color(0xFF334155),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primary,
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              child: Text(
                                _isArabic ? 'تسجيل الدخول' : 'Log in',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 18),

                          const Divider(),

                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SignupScreen(),
                                ),
                              );
                            },
                            child: Text(
                              _isArabic ? 'إنشاء حساب' : 'CREATE ACCOUNT',
                              style: const TextStyle(
                                color: primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          const Divider(),

                          TextButton(
                            onPressed: _guestLogin,
                            child: RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: _isArabic
                                        ? 'مساعدة أولية؟ '
                                        : 'FIRST HELP? ',
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),

                                  TextSpan(
                                    text: _isArabic
                                        ? 'اضغط هنا'
                                        : 'CLICK HERE',
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      textDirection: TextDirection.ltr,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF64748B)),
        filled: true,
        fillColor: const Color(0xFFF1F5F9),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}