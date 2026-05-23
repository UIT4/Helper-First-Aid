import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../../core/constants/app_colors.dart';

import '../../core/database/app_database.dart';
import '../../core/language/app_language.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool codeSent = false;
  bool verified = false;
  bool isLoading = false;

  String generatedOtp = '';

  static Color get primary => AppColors.primary;
  static const Color danger = Color(0xFFDC2626);
  static const Color success = Color(0xFF16A34A);
  static const Color background = Color(0xFFF8FAFC);
  static const Color textDark = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  String _generateOtp() {
    final random = Random();
    return (1000 + random.nextInt(9000)).toString();
  }

  bool _isValidPassword(String password) {
    return RegExp(
      r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[@$!%*#?&])[A-Za-z\d@$!%*#?&]{8,}$',
    ).hasMatch(password);
  }

  void _showSnack(
    String msg, {
    bool error = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? danger : success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
  
  Future<void> _sendCode() async {
    final phone = _phoneCtrl.text.trim();

    if (phone.isEmpty) {
      _showSnack(
        AppLanguage.text(
          context,
          'Enter your phone number',
          'أدخل رقم الهاتف',
        ),
        error: true,
      );
      return;
    }

    if (phone.length != 10 || !RegExp(r'^[0-9]+$').hasMatch(phone)) {
      _showSnack(
        AppLanguage.text(
          context,
          'Phone number must be exactly 10 digits',
          'يجب أن يتكون رقم الهاتف من 10 أرقام تماماً',
        ),
        error: true,
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final user = await AppDatabase.instance.getUserByPhone(phone);

      if (user == null) {
        _showSnack(
          AppLanguage.text(
            context,
            'No account found with this phone number',
            'لا يوجد حساب مسجل برقم الهاتف هذا',
          ),
          error: true,
        );
        setState(() => isLoading = false);
        return;
      }

      generatedOtp = _generateOtp();

      // 💡 تعديل الـ IP هنا ضروري ليفهم المحاكي السيرفر الخاص بك
      // استخدم '10.0.2.2' لمحاكي الأندرويد الافتراضي بدلاً من localhost
      final url = Uri.parse('http://10.0.2.2/rescue_assistant_api/send_otp.php'); 
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': phone,
          'otp': generatedOtp,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          codeSent = true;
          verified = false;
          _otpCtrl.clear();
        });

        _showSnack(
          AppLanguage.text(
            context,
            'Verification code sent successfully to server',
            'تم إرسال رمز التحقق إلى السيرفر بنجاح',
          ),
        );
      } else {
        _showSnack(
          AppLanguage.text(
            context,
            'Server error (${response.statusCode}), failed to send code',
            'فشل السيرفر في استقبال الكود - خطأ رقم ${response.statusCode}',
          ),
          error: true,
        );
      }
    } catch (e) {
      // في حال وجود مشكلة حقيقية بالاتصال تظهر لك هنا لتفحصها
      _showSnack(
        AppLanguage.text(
          context,
          'Connection Error: Cannot connect to server',
          'خطأ في الاتصال: لا يمكن الوصول للسيرفر حالياً',
        ),
        error: true,
      );
    } finally {
      setState(() => isLoading = false);
    }
  }
  
  void _verifyCode() {
    final enteredOtp = _otpCtrl.text.trim();

    if (enteredOtp.isEmpty) {
      _showSnack(
        AppLanguage.text(
          context,
          'Enter the code',
          'أدخل الكود',
        ),
        error: true,
      );
      return;
    }

    if (enteredOtp != generatedOtp) {
      _showSnack(
        AppLanguage.text(
          context,
          'Wrong code',
          'الكود غير صحيح',
        ),
        error: true,
      );
      return;
    }

    setState(() {
      verified = true;
    });

    _showSnack(
      AppLanguage.text(
        context,
        'Code verified',
        'تم التحقق من الكود بنجاح',
      ),
    );
  }

  Future<void> _resetPassword() async {
    final newPass = _newPassCtrl.text.trim();
    final confirmPass = _confirmPassCtrl.text.trim();

    if (newPass.isEmpty || confirmPass.isEmpty) {
      _showSnack(
        AppLanguage.text(
          context,
          'Fill all password fields',
          'املأ جميع حقول كلمة المرور',
        ),
        error: true,
      );
      return;
    }

    if (!_isValidPassword(newPass)) {
      _showSnack(
        AppLanguage.text(
          context,
          'Password must be 8+ chars with letters, numbers, and special character',
          'كلمة المرور يجب أن تكون 8 خانات على الأقل وتحتوي حرف ورقم ورمز',
        ),
        error: true,
      );
      return;
    }

    if (newPass != confirmPass) {
      _showSnack(
        AppLanguage.text(
          context,
          'Passwords do not match',
          'كلمتا المرور غير متطابقتين',
        ),
        error: true,
      );
      return;
    }

    final updated = await AppDatabase.instance.updateUserPassword(
      phone: _phoneCtrl.text.trim(),
      newPassword: newPass,
    );

    if (updated == 0) {
      _showSnack(
        AppLanguage.text(
          context,
          'Password was not updated',
          'لم يتم تغيير كلمة المرور',
        ),
        error: true,
      );
      return;
    }

    if (!mounted) return;

    _showSnack(
      AppLanguage.text(
        context,
        'Password updated successfully',
        'تم تغيير كلمة المرور بنجاح',
      ),
    );

    Navigator.pop(context);
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
              'Forgot Password',
              'نسيت كلمة المرور',
            ),
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          backgroundColor: primary,
          iconTheme: const IconThemeData(color: Colors.white),
          centerTitle: true,
          elevation: 0,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.lock_reset_rounded,
                    size: 70,
                    color: primary,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    AppLanguage.text(
                      context,
                      'Reset your password',
                      'إعادة تعيين كلمة المرور',
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      color: textDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLanguage.text(
                      context,
                      'Enter your registered phone number, verify the code, then create a new password.',
                      'أدخل رقم هاتفك المسجل، تحقق من الكود، ثم أنشئ كلمة مرور جديدة.',
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: textMuted,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 28),
                  _inputField(
                    controller: _phoneCtrl,
                    hint: AppLanguage.text(
                      context,
                      'Phone Number (10 digits)',
                      'رقم الهاتف (10 أرقام)',
                    ),
                    icon: Icons.phone_android_rounded,
                    keyboard: TextInputType.phone,
                    enabled: !codeSent,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                  ),
                  const SizedBox(height: 18),
                  if (!codeSent)
                    _button(
                      text: AppLanguage.text(
                        context,
                        'Send Code',
                        'إرسال الكود',
                      ),
                      onTap: _sendCode,
                      isLoading: isLoading,
                    ),
                  if (codeSent) ...[
                    _infoBox(
                      AppLanguage.text(
                        context,
                        'Enter the 4-digit code sent to your phone',
                        'أدخل رمز التحقق المكون من 4 أرقام المرسل لهاتفك',
                      ),
                    ),
                    const SizedBox(height: 18),
                    _inputField(
                      controller: _otpCtrl,
                      hint: AppLanguage.text(
                        context,
                        'Enter OTP',
                        'أدخل الكود',
                      ),
                      icon: Icons.sms_outlined,
                      keyboard: TextInputType.number,
                      enabled: !verified,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                    ),
                    const SizedBox(height: 18),
                    if (!verified)
                      _button(
                        text: AppLanguage.text(
                          context,
                          'Verify Code',
                          'تحقق من الكود',
                        ),
                        onTap: _verifyCode,
                      ),
                  ],
                  if (verified) ...[
                    const SizedBox(height: 18),
                    _inputField(
                      controller: _newPassCtrl,
                      hint: AppLanguage.text(
                        context,
                        'New Password',
                        'كلمة المرور الجديدة',
                      ),
                      icon: Icons.lock_outline,
                      obscure: true,
                    ),
                    const SizedBox(height: 18),
                    _inputField(
                      controller: _confirmPassCtrl,
                      hint: AppLanguage.text(
                        context,
                        'Confirm Password',
                        'تأكيد كلمة المرور',
                      ),
                      icon: Icons.lock_reset,
                      obscure: true,
                    ),
                    const SizedBox(height: 22),
                    _button(
                      text: AppLanguage.text(
                        context,
                        'Reset Password',
                        'تغيير كلمة المرور',
                      ),
                      onTap: _resetPassword,
                    ),
                  ],
                ],
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
    bool enabled = true,
    TextInputType keyboard = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      enabled: enabled,
      keyboardType: keyboard,
      textDirection: TextDirection.ltr,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: primary),
        filled: true,
        fillColor: const Color(0xFFF1F5F9),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _button({
    required String text,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _infoBox(String text) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: textDark,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}