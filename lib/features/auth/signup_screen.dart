import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  final _pinCtrl = TextEditingController();

  bool _isArabic = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  bool _isValidGmail(String email) {
    return RegExp(r'^[A-Za-z0-9._%+-]+@gmail\.com$').hasMatch(email);
  }

  bool _isValidPassword(String password) {
    return RegExp(r'^\d{6,}$').hasMatch(password);
  }

  bool _isValidPin(String pin) {
    return RegExp(r'^\d{4}$').hasMatch(pin);
  }

  Future<void> _next() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();
    final pin = _pinCtrl.text.trim();

    if (name.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirm.isEmpty ||
        pin.isEmpty) {
      _showSnack(_isArabic ? 'عبئ جميع الحقول' : 'Fill all fields',
          isError: true);
      return;
    }

    if (!_isValidGmail(email)) {
      _showSnack(
        _isArabic
            ? 'الإيميل يجب أن يكون بصيغة example@gmail.com'
            : 'Email must be like example@gmail.com',
        isError: true,
      );
      return;
    }

    if (!_isValidPassword(password)) {
      _showSnack(
        _isArabic
            ? 'كلمة المرور يجب أن تكون أرقام فقط وأقل شيء 6 أرقام'
            : 'Password must be numbers only and at least 6 digits',
        isError: true,
      );
      return;
    }

    if (password != confirm) {
      _showSnack(
        _isArabic ? 'كلمة المرور غير متطابقة' : 'Passwords do not match',
        isError: true,
      );
      return;
    }

    if (!_isValidPin(pin)) {
      _showSnack(
        _isArabic
            ? 'رمز الاسترجاع يجب أن يكون 4 أرقام'
            : 'Recovery PIN must be exactly 4 digits',
        isError: true,
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('registeredEmail', email);
    await prefs.setString('registeredPassword', password);
    await prefs.setString('registeredName', name);
    await prefs.setString('recoveryPin', pin);

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

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor:
        isError ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: Text(
            _isArabic ? 'إنشاء حساب' : 'Create Account',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: const Color(0xFF2563EB),
          iconTheme: const IconThemeData(color: Colors.white),
          centerTitle: true,
          actions: [
            TextButton(
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
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              _field(
                hint: _isArabic ? 'الاسم الكامل' : 'Full Name',
                controller: _nameCtrl,
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 18),
              _field(
                hint: _isArabic ? 'البريد الإلكتروني Gmail' : 'Gmail Email',
                controller: _emailCtrl,
                icon: Icons.email_outlined,
                keyboard: TextInputType.emailAddress,
              ),
              const SizedBox(height: 18),
              _field(
                hint: _isArabic ? 'كلمة المرور - أرقام فقط' : 'Password - numbers only',
                controller: _passwordCtrl,
                icon: Icons.lock_outline,
                obscure: true,
                keyboard: TextInputType.number,
              ),
              const SizedBox(height: 18),
              _field(
                hint: _isArabic ? 'تأكيد كلمة المرور' : 'Confirm Password',
                controller: _confirmCtrl,
                icon: Icons.lock_reset,
                obscure: true,
                keyboard: TextInputType.number,
              ),
              const SizedBox(height: 18),
              _field(
                hint: _isArabic ? 'رمز الاسترجاع - 4 أرقام' : 'Recovery PIN - 4 digits',
                controller: _pinCtrl,
                icon: Icons.pin_outlined,
                obscure: true,
                keyboard: TextInputType.number,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: _next,
                  child: Text(
                    _isArabic ? 'التالي' : 'NEXT',
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
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
    );
  }
}