import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/database/app_database.dart';
import '../../core/language/app_language.dart';
import '../home/home_screen.dart';
import 'forgot_password_screen.dart';
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

  static Color get primary => AppColors.primary;
  static const Color background = Color(0xFFF8FAFC);
  static const Color danger = Color(0xFFDC2626);
  static const Color success = Color(0xFF16A34A);
  static const Color textDark = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    _loadRememberedLogin();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadRememberedLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final remember = prefs.getBool('rememberMe') ?? false;

    if (!mounted) return;

    setState(() {
      _rememberMe = remember;

      if (remember) {
        _emailCtrl.text = prefs.getString('rememberedEmail') ?? '';
        _passwordCtrl.text = prefs.getString('rememberedPassword') ?? '';
      }
    });
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[A-Za-z0-9._%+-]+@gmail\.com$').hasMatch(email);
  }

  bool _isValidPassword(String password) {
    return RegExp(
      r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[@$!%*#?&])[A-Za-z\d@$!%*#?&]{8,}$',
    ).hasMatch(password);
  }

  Future<void> _login() async {
    final email = _emailCtrl.text.trim().toLowerCase();
    final password = _passwordCtrl.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnack(
        AppLanguage.text(
          context,
          'Enter email and password',
          'أدخل البريد الإلكتروني وكلمة المرور',
        ),
        isError: true,
      );
      return;
    }

    if (!_isValidEmail(email)) {
      _showSnack(
        AppLanguage.text(
          context,
          'Email must be like example@gmail.com',
          'البريد يجب أن يكون مثل example@gmail.com',
        ),
        isError: true,
      );
      return;
    }

    if (!_isValidPassword(password)) {
      _showSnack(
        AppLanguage.text(
          context,
          'Password must be 8+ chars with letters, numbers, and special character',
          'كلمة المرور يجب أن تكون 8 خانات على الأقل وتحتوي حرف ورقم ورمز',
        ),
        isError: true,
      );
      return;
    }

    final user = await AppDatabase.instance.loginUser(
      email: email,
      password: password,
    );

    if (user == null) {
      _showSnack(
        AppLanguage.text(
          context,
          'Wrong email or password',
          'الإيميل أو كلمة المرور غير صحيحة',
        ),
        isError: true,
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('isGuest', false);
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('userEmail', email);

    if (_rememberMe) {
      await prefs.setBool('rememberMe', true);
      await prefs.setString('rememberedEmail', email);
      await prefs.setString('rememberedPassword', password);
    } else {
      await prefs.setBool('rememberMe', false);
      await prefs.remove('rememberedEmail');
      await prefs.remove('rememberedPassword');
    }

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

  Future<void> _toggleLanguage() async {
    final isArabic = AppLanguage.isArabicContext(context);
    await AppLanguage.setLanguage(isArabic ? 'en' : 'ar');
  }

  void _forgotPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ForgotPasswordScreen(),
      ),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? danger : success,
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
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildHeader(),
                    _buildForm(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final isArabic = AppLanguage.isArabicContext(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primary, AppColors.primary.withValues(alpha: 0.80)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Column(
        children: [
          Align(
            alignment: isArabic ? Alignment.topLeft : Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextButton(
                onPressed: _toggleLanguage,
                child: Text(
                  isArabic ? 'English' : 'العربية',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          Icon(
            Icons.health_and_safety_rounded,
            color: Colors.white,
            size: 78,
          ),
          const SizedBox(height: 16),
          Text(
            AppLanguage.text(context, 'Rescue Assistant', 'مساعد الإسعاف'),
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            AppLanguage.text(
              context,
              'Instant emergency help',
              'مساعدة فورية في الحالات الطارئة',
            ),
            style: TextStyle(color: Colors.white70, fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      child: Column(
        children: [
          _inputField(
            controller: _emailCtrl,
            hint: AppLanguage.text(
              context,
              'Gmail Email',
              'البريد الإلكتروني Gmail',
            ),
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 14),
          _inputField(
            controller: _passwordCtrl,
            hint: AppLanguage.text(context, 'Password', 'كلمة المرور'),
            icon: Icons.lock_outline,
            obscure: true,
          ),
          const SizedBox(height: 8),
          _buildRememberAndForgotRow(),
          const SizedBox(height: 8),
          _buildLoginButton(),
          const SizedBox(height: 18),
          const Divider(),
          _buildCreateAccountButton(),
          const Divider(),
          _buildGuestButton(),
        ],
      ),
    );
  }

  Widget _buildRememberAndForgotRow() {
    return Wrap(
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
                setState(() {
                  _rememberMe = v ?? false;
                });
              },
            ),
            Text(
              AppLanguage.text(context, 'Remember', 'تذكرني'),
              style: TextStyle(fontSize: 13),
            ),
          ],
        ),
        TextButton(
          onPressed: _forgotPassword,
          child: Text(
            AppLanguage.text(context, 'Forgot Password?', 'نسيت كلمة المرور؟'),
            style: TextStyle(
              color: Color(0xFF334155),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
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
          AppLanguage.text(context, 'Log in', 'تسجيل الدخول'),
          style: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildCreateAccountButton() {
    return TextButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SignupScreen()),
        );
      },
      child: Text(
        AppLanguage.text(context, 'CREATE ACCOUNT', 'إنشاء حساب'),
        style: TextStyle(
          color: primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildGuestButton() {
    return TextButton(
      onPressed: _guestLogin,
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: AppLanguage.text(context, 'FIRST HELP? ', 'مساعدة أولية؟ '),
              style: TextStyle(
                color: danger,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextSpan(
              text: AppLanguage.text(context, 'CLICK HERE', 'اضغط هنا'),
              style: TextStyle(
                color: danger,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
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
        prefixIcon: Icon(icon, color: textMuted),
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