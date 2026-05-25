import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/database/app_database.dart';
import '../../core/language/app_language.dart';
import '../categories/categories_screen.dart';
import '../steps/steps_viewer_screen.dart';

class ResultScreen extends StatelessWidget {
  final String category;
  final double confidence;
  final String urgency;
  final String lang;
  final String userText;

  const ResultScreen({
    super.key,
    required this.category,
    required this.confidence,
    required this.urgency,
    required this.lang,
    required this.userText,
  });

  static Color get primary => AppColors.primary;
  static const Color danger = Color(0xFFDC2626);
  static const Color warning = Color(0xFFF97316);
  static const Color success = Color(0xFF16A34A);
  static const Color background = Color(0xFFF8FAFC);
  static const Color textDark = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);

  String _categoryDisplay(BuildContext context, String code) {
    final isArabic = AppLanguage.isArabicContext(context);

    const map = {
      'adult_choking': {'en': 'Adult Choking', 'ar': 'اختناق بالغ'},
      'child_choking': {'en': 'Child Choking', 'ar': 'اختناق طفل'},
      'asthma': {'en': 'Asthma Attack', 'ar': 'نوبة ربو'},
      'anaphylaxis': {'en': 'Severe Allergy', 'ar': 'حساسية شديدة'},
      'unconscious_breathing': {
        'en': 'Unconscious but Breathing',
        'ar': 'فاقد الوعي ويتنفس',
      },
    };

    final item = map[code];
    if (item == null) return code;

    return isArabic ? item['ar']! : item['en']!;
  }

  String _urgencyLabel(BuildContext context, String urgency) {
    switch (urgency) {
      case 'high':
        return AppLanguage.text(context, '🚨 HIGH URGENCY', '🚨 خطورة عالية');
      case 'med':
        return AppLanguage.text(context, '⚠️ MEDIUM URGENCY', '⚠️ خطورة متوسطة');
      case 'low':
        return AppLanguage.text(context, 'ℹ️ LOW URGENCY', 'ℹ️ خطورة منخفضة');
      default:
        return AppLanguage.text(context, 'UNKNOWN', 'غير معروف');
    }
  }

  Color _urgencyColor(String urgency) {
    switch (urgency) {
      case 'high':
        return danger;
      case 'med':
        return warning;
      case 'low':
        return success;
      default:
        return textMuted;
    }
  }

  Future<void> _callEmergency(BuildContext context) async {
    final settings = await AppDatabase.instance.getSettings();
    final number = settings['emergency_number'] ?? '911';

    final uri = Uri(scheme: 'tel', path: number);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      return;
    }

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLanguage.text(
            context,
            'Cannot open dialer',
            'تعذر فتح شاشة الاتصال',
          ),
        ),
        backgroundColor: danger,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = AppLanguage.isArabicContext(context);
    final confidencePercent = confidence * 100;

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: background,
        appBar: AppBar(
          backgroundColor: primary,
          centerTitle: true,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
          title: Text(
            AppLanguage.text(context, 'Prediction Result', 'نتيجة التحليل'),
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildResultCard(context, confidencePercent),
                const SizedBox(height: 24),
                _mainButton(
                  context: context,
                  icon: Icons.menu_book_rounded,
                  label: AppLanguage.text(
                    context,
                    'VIEW EMERGENCY STEPS',
                    'عرض خطوات الإسعاف',
                  ),
                  color: primary,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StepsViewerScreen(
                          categoryCode: category,
                          lang: isArabic ? 'ar' : 'en',
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 14),
                _mainButton(
                  context: context,
                  icon: Icons.category_rounded,
                  label: AppLanguage.text(
                    context,
                    'MANUAL CATEGORY',
                    'اختيار يدوي',
                  ),
                  color: warning,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CategoriesScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 14),
                _mainButton(
                  context: context,
                  icon: Icons.call,
                  label: AppLanguage.text(
                    context,
                    'CALL EMERGENCY',
                    'الاتصال بالطوارئ',
                  ),
                  color: danger,
                  onPressed: () => _callEmergency(context),
                ),
                const SizedBox(height: 24),
                _buildDisclaimer(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard(BuildContext context, double confidencePercent) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(28),
      child: Column(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: _urgencyColor(urgency).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.health_and_safety_rounded,
              size: 50,
              color: _urgencyColor(urgency),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            AppLanguage.text(context, 'Predicted Condition', 'تم توقع الحالة'),
            style: TextStyle(
              color: textMuted,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _categoryDisplay(context, category),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textDark,
              fontSize: 30,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: _urgencyColor(urgency).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              _urgencyLabel(context, urgency),
              style: TextStyle(
                color: _urgencyColor(urgency),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 26),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLanguage.text(context, 'Confidence', 'نسبة الثقة'),
                style: TextStyle(
                  color: textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${confidencePercent.toStringAsFixed(0)}%',
                style: TextStyle(
                  color: primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: confidence.clamp(0.0, 1.0),
              minHeight: 12,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(
                _urgencyColor(urgency),
              ),
            ),
          ),
          const SizedBox(height: 26),
          Align(
            alignment: AppLanguage.isArabicContext(context)
                ? Alignment.centerRight
                : Alignment.centerLeft,
            child: Text(
              AppLanguage.text(context, 'Your Description', 'الوصف المدخل'),
              style: TextStyle(
                color: textDark,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Text(
              userText,
              style: TextStyle(
                color: Color(0xFF334155),
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mainButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        icon: Icon(icon, color: Colors.white),
        label: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildDisclaimer(BuildContext context) {
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
          Icon(Icons.warning_amber_rounded, color: warning),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              AppLanguage.text(
                context,
                'This app provides first-aid guidance only and is not a replacement for professional medical assistance.',
                'هذا التطبيق يقدم إرشادات إسعافية أولية فقط وليس بديلاً عن المساعدة الطبية الاحترافية.',
              ),
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

  BoxDecoration _cardDecoration(double radius) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }
}
