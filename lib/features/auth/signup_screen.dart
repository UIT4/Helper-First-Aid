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
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  static const Color primary = Color(0xFF2563EB);
  static const Color danger = Color(0xFFDC2626);
  static const Color success = Color(0xFF16A34A);
  static const Color background = Color(0xFFF8FAFC);

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  bool _isValidGmail(String email) {
    return RegExp(r'^[A-Za-z0-9._%+-]+@gmail\.com$').hasMatch(email);
  }

  bool _isValidPassword(String password) {
    return RegExp(
      r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[@$!%*#?&])[A-Za-z\d@$!%*#?&]{8,}$',
    ).hasMatch(password);
  }

  Future<void> _next() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim().toLowerCase();
    final password = _passwordCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty || confirm.isEmpty) {
      _showSnack(
        AppLanguage.text(context, 'Fill all fields', 'عبئ جميع الحقول'),
        isError: true,
      );
      return;
    }

    if (!_isValidGmail(email)) {
      _showSnack(
        AppLanguage.text(
          context,
          'Email must be like example@gmail.com',
          'الإيميل يجب أن يكون بصيغة example@gmail.com',
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

    if (password != confirm) {
      _showSnack(
        AppLanguage.text(context, 'Passwords do not match', 'كلمة المرور غير متطابقة'),
        isError: true,
      );
      return;
    }

    final existingUser = await AppDatabase.instance.getUserByEmail(email);

    if (existingUser != null) {
      _showSnack(
        AppLanguage.text(
          context,
          'This email is already registered. Log in instead.',
          'هذا البريد مسجل مسبقاً، سجّل دخول',
        ),
        isError: true,
      );
      return;
    }

    await AppDatabase.instance.insertUser(
      fullName: name,
      email: email,
      password: password,
    );

    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('isGuest', false);
    await prefs.setBool('isLoggedIn', false);
    await prefs.setString('userEmail', email);
    await prefs.setString('registeredName', name);

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuestionnaireScreen(
          name: name,
          email: email,
        ),
      ),
    );
  }

  Future<void> _toggleLanguage() async {
    final isArabic = AppLanguage.isArabicContext(context);
    await AppLanguage.setLanguage(isArabic ? 'en' : 'ar');
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
        appBar: AppBar(
          title: Text(
            AppLanguage.text(context, 'Create Account', 'إنشاء حساب'),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: primary,
          iconTheme: const IconThemeData(color: Colors.white),
          centerTitle: true,
          actions: [
            TextButton(
              onPressed: _toggleLanguage,
              child: Text(
                isArabic ? 'English' : 'العربية',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              _field(
                hint: AppLanguage.text(context, 'Full Name', 'الاسم الكامل'),
                controller: _nameCtrl,
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 18),
              _field(
                hint: AppLanguage.text(context, 'Gmail Email', 'البريد الإلكتروني Gmail'),
                controller: _emailCtrl,
                icon: Icons.email_outlined,
                keyboard: TextInputType.emailAddress,
              ),
              const SizedBox(height: 18),
              _field(
                hint: AppLanguage.text(
                  context,
                  'Password (letter + number + special)',
                  'كلمة المرور (حرف + رقم + رمز)',
                ),
                controller: _passwordCtrl,
                icon: Icons.lock_outline,
                obscure: true,
              ),
              const SizedBox(height: 18),
              _field(
                hint: AppLanguage.text(context, 'Confirm Password', 'تأكيد كلمة المرور'),
                controller: _confirmCtrl,
                icon: Icons.lock_reset,
                obscure: true,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: _next,
                  child: Text(
                    AppLanguage.text(context, 'NEXT', 'التالي'),
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field({
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    bool obscure = false,
    TextInputType keyboard = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboard,
      textDirection: TextDirection.ltr,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: primary),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
    );
  }
}
