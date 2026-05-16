import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../categories/categories_screen.dart';
import '../steps/steps_viewer_screen.dart';
import '../../core/database/app_database.dart';

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

  String _categoryDisplay(String code, String lang) {
    const map = {
      'adult_choking': {
        'en': 'Adult Choking',
        'ar': 'اختناق بالغ',
      },
      'child_choking': {
        'en': 'Child Choking',
        'ar': 'اختناق طفل',
      },
      'asthma': {
        'en': 'Asthma Attack',
        'ar': 'نوبة ربو',
      },
      'anaphylaxis': {
        'en': 'Severe Allergy',
        'ar': 'حساسية شديدة',
      },
      'unconscious_breathing': {
        'en': 'Unconscious but Breathing',
        'ar': 'فاقد الوعي ويتنفس',
      },
      'not_breathing_cpr': {
        'en': 'Not Breathing / CPR',
        'ar': 'لا يتنفس / إنعاش',
      },
      'bleeding': {
        'en': 'Heavy Bleeding',
        'ar': 'نزيف شديد',
      },

      'burns': {
        'en': 'Burn Injury',
        'ar': 'حروق',
      },

      'fracture': {
        'en': 'Fracture',
        'ar': 'كسر',
      },

      'seizure': {
        'en': 'Seizure',
        'ar': 'تشنج',
      },

      'stroke': {
        'en': 'Stroke',
        'ar': 'سكتة دماغية',
      },
      'unknown': {
        'en': 'Unknown',
        'ar': 'غير معروف',
      },
    };

    return map[code]?[lang] ?? code;
  }

  String _urgencyLabel(String urgency, String lang) {
    switch (urgency) {
      case 'high':
        return lang == 'ar' ? '🚨 خطورة عالية' : '🚨 HIGH URGENCY';
      case 'med':
        return lang == 'ar' ? '⚠️ خطورة متوسطة' : '⚠️ MEDIUM URGENCY';
      case 'low':
        return lang == 'ar' ? 'ℹ️ خطورة منخفضة' : 'ℹ️ LOW URGENCY';
      default:
        return lang == 'ar' ? 'غير معروف' : 'UNKNOWN';
    }
  }

  Color _urgencyColor(String urgency) {
    switch (urgency) {
      case 'high':
        return const Color(0xFFDC2626);
      case 'med':
        return const Color(0xFFF97316);
      case 'low':
        return const Color(0xFF16A34A);
      default:
        return const Color(0xFF64748B);
    }
  }

  Future<void> _callEmergency(BuildContext context) async {
    final settings = await AppDatabase.instance.getSettings();

    final number = settings['emergency_number'] ?? '911';

    final uri = Uri(
      scheme: 'tel',
      path: number,
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot open dialer'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isAr = lang == 'ar';

    final double confidencePercent = confidence * 100;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2563EB),
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          isAr ? 'نتيجة التحليل' : 'Prediction Result',
          style: const TextStyle(
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
              // =====================================================
              // MAIN RESULT CARD
              // =====================================================

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: _urgencyColor(urgency).withOpacity(0.12),
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
                      isAr
                          ? 'تم توقع الحالة'
                          : 'Predicted Condition',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      _categoryDisplay(category, lang),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),

                    const SizedBox(height: 18),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: _urgencyColor(urgency).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        _urgencyLabel(urgency, lang),
                        style: TextStyle(
                          color: _urgencyColor(urgency),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 26),

                    // =====================================================
                    // CONFIDENCE
                    // =====================================================

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isAr ? 'نسبة الثقة' : 'Confidence',
                          style: const TextStyle(
                            color: Color(0xFF475569),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${confidencePercent.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            color: Color(0xFF2563EB),
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

                    // =====================================================
                    // USER INPUT
                    // =====================================================

                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        isAr ? 'الوصف المدخل' : 'Your Description',
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
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
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Text(
                        userText,
                        style: const TextStyle(
                          color: Color(0xFF334155),
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // =====================================================
              // ACTION BUTTONS
              // =====================================================

              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  icon: const Icon(
                    Icons.menu_book_rounded,
                    color: Colors.white,
                  ),
                  label: Text(
                    isAr ? 'عرض خطوات الإسعاف' : 'VIEW EMERGENCY STEPS',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StepsViewerScreen(
                          categoryCode: category,
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 14),

              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF97316),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  icon: const Icon(
                    Icons.category_rounded,
                    color: Colors.white,
                  ),
                  label: Text(
                    isAr ? 'اختيار يدوي' : 'MANUAL CATEGORY',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CategoriesScreen(),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 14),

              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  icon: const Icon(
                    Icons.call,
                    color: Colors.white,
                  ),
                  label: Text(
                    isAr ? 'الاتصال بالطوارئ' : 'CALL EMERGENCY',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () => _callEmergency(context),
                ),
              ),

              const SizedBox(height: 24),

              // =====================================================
              // DISCLAIMER
              // =====================================================

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFFFED7AA),
                  ),
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
                        isAr
                            ? 'هذا التطبيق يقدم إرشادات إسعافية أولية فقط وليس بديلاً عن المساعدة الطبية الاحترافية.'
                            : 'This app provides first-aid guidance only and is not a replacement for professional medical assistance.',
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}