import 'package:flutter/material.dart';

import '../../core/database/app_database.dart';
import '../../core/language/app_language.dart';
import '../steps/steps_viewer_screen.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;

  static const Color primary = Color(0xFF2563EB);

  static const List<String> _allowedCodes = [
    'adult_choking',
    'child_choking',
    'asthma',
    'anaphylaxis',
    'unconscious_breathing',
    'not_breathing_cpr',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final cats = await AppDatabase.instance.getCategories();

      final filteredCats = cats.where((cat) {
        final code = (cat['code'] ?? '').toString();
        return _allowedCodes.contains(code);
      }).toList();

      if (!mounted) return;

      setState(() {
        _categories = filteredCats;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _categories = [];
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLanguage.text(
              context,
              'Failed to load categories',
              'فشل تحميل التصنيفات',
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  IconData _categoryIcon(String code) {
    switch (code) {
      case 'adult_choking':
        return Icons.air;

      case 'child_choking':
        return Icons.child_care;

      case 'asthma':
        return Icons.wind_power;

      case 'anaphylaxis':
        return Icons.warning_amber_rounded;

      case 'unconscious_breathing':
        return Icons.accessibility_new;

      case 'not_breathing_cpr':
        return Icons.favorite;

      default:
        return Icons.medical_services;
    }
  }

  Color _categoryColor(String code) {
    switch (code) {
      case 'adult_choking':
        return const Color(0xFFDC2626);

      case 'child_choking':
        return const Color(0xFFF97316);

      case 'asthma':
        return primary;

      case 'anaphylaxis':
        return const Color(0xFF8B5CF6);

      case 'unconscious_breathing':
        return const Color(0xFF14B8A6);

      case 'not_breathing_cpr':
        return const Color(0xFFDC2626);

      default:
        return const Color(0xFF475569);
    }
  }

  String _urgencyLabel(
      BuildContext context,
      String code,
      ) {
    if ([
      'adult_choking',
      'child_choking',
      'anaphylaxis',
      'not_breathing_cpr',
    ].contains(code)) {
      return AppLanguage.text(
        context,
        'HIGH',
        'عالي',
      );
    }

    if ([
      'asthma',
      'unconscious_breathing',
    ].contains(code)) {
      return AppLanguage.text(
        context,
        'MEDIUM',
        'متوسط',
      );
    }

    return AppLanguage.text(
      context,
      'LOW',
      'منخفض',
    );
  }

  Color _urgencyColor(String code) {
    if ([
      'adult_choking',
      'child_choking',
      'anaphylaxis',
      'not_breathing_cpr',
    ].contains(code)) {
      return const Color(0xFFDC2626);
    }

    if ([
      'asthma',
      'unconscious_breathing',
    ].contains(code)) {
      return const Color(0xFFF97316);
    }

    return const Color(0xFF16A34A);
  }

  String _categoryName(
      BuildContext context,
      Map<String, dynamic> cat,
      ) {
    final isArabic = AppLanguage.isArabicContext(context);

    final name = isArabic ? cat['name_ar'] : cat['name_en'];

    return (name ?? '').toString();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = AppLanguage.isArabicContext(context);

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: Text(
            AppLanguage.text(
              context,
              'Manual Categories',
              'الفئات اليدوية',
            ),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: primary,
          centerTitle: true,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: _isLoading
            ? const Center(
          child: CircularProgressIndicator(
            color: primary,
          ),
        )
            : Column(
          children: [
            Container(
              width: double.infinity,
              color: const Color(0xFFEFF6FF),
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: primary,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      AppLanguage.text(
                        context,
                        'Select category to view first aid steps',
                        'اختر الحالة لعرض خطوات الإسعاف',
                      ),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF1E40AF),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _categories.isEmpty
                  ? Center(
                child: Text(
                  AppLanguage.text(
                    context,
                    'No categories available',
                    'لا توجد تصنيفات متاحة',
                  ),
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
                  : GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 0.95,
                ),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final code = (cat['code'] ?? '').toString();

                  return _buildCategoryCard(
                    cat,
                    code,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
      Map<String, dynamic> cat,
      String code,
      ) {
    final color = _categoryColor(code);
    final icon = _categoryIcon(code);
    final urgency = _urgencyLabel(context, code);
    final urgencyColor = _urgencyColor(code);
    final name = _categoryName(context, cat);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StepsViewerScreen(
              categoryCode: code,
              lang: AppLanguage.isArabicContext(context) ? 'ar' : 'en',
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 36,
                color: color,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: urgencyColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: urgencyColor.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                urgency,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: urgencyColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}