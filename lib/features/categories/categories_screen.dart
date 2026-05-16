import 'package:flutter/material.dart';
import '../../core/database/app_database.dart';
import '../steps/steps_viewer_screen.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;
  String _lang = 'en';

  // =====================================================
  // LIFECYCLE
  // =====================================================

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final cats     = await AppDatabase.instance.getCategories();
    final settings = await AppDatabase.instance.getSettings();
    setState(() {
      _categories = cats;
      _lang       = settings['language'] ?? 'en';
      if (_lang == 'auto') _lang = 'en';
      _isLoading  = false;
    });
  }

  // =====================================================
  // HELPERS
  // =====================================================

  // Icon per category
  IconData _categoryIcon(String code) {
    switch (code) {
      case 'adult_choking':         return Icons.air;
      case 'child_choking':         return Icons.child_care;
      case 'asthma':                return Icons.wind_power;
      case 'anaphylaxis':           return Icons.warning_amber_rounded;
      case 'unconscious_breathing': return Icons.accessibility_new;
      case 'not_breathing_cpr':     return Icons.favorite;
      case 'bleeding':              return Icons.bloodtype;
      case 'burns':                 return Icons.local_fire_department;
      case 'fracture':              return Icons.healing;
      case 'seizure':               return Icons.emergency;
      case 'stroke':                return Icons.psychology;
      default:                      return Icons.medical_services;
    }
  }

  Color _categoryColor(String code) {
    switch (code) {
      case 'adult_choking':         return const Color(0xFFDC2626);
      case 'child_choking':         return const Color(0xFFF97316);
      case 'asthma':                return const Color(0xFF2563EB);
      case 'anaphylaxis':           return const Color(0xFF8B5CF6);
      case 'unconscious_breathing': return const Color(0xFF14B8A6);
      case 'not_breathing_cpr':     return const Color(0xFFDC2626);
      case 'bleeding':              return const Color(0xFFB91C1C);
      case 'burns':                 return const Color(0xFFEA580C);
      case 'fracture':              return const Color(0xFF64748B);
      case 'seizure':               return const Color(0xFF7C3AED);
      case 'stroke':                return const Color(0xFFBE123C);
      default:                      return const Color(0xFF475569);
    }
  }

  String _urgencyLabel(String code) {
    switch (code) {
      case 'adult_choking':
      case 'child_choking':
      case 'anaphylaxis':
      case 'not_breathing_cpr':
      case 'seizure':
      case 'stroke':
        return ' HIGH';

      case 'asthma':
      case 'unconscious_breathing':
      case 'bleeding':
      case 'burns':
        return ' MEDIUM';

      default:
        return ' LOW';
    }
  }

  Color _urgencyColor(String code) {
    switch (code) {
      case 'adult_choking':
      case 'child_choking':
      case 'anaphylaxis':
      case 'not_breathing_cpr':
      case 'seizure':
      case 'stroke':
        return const Color(0xFFDC2626);

      case 'asthma':
      case 'unconscious_breathing':
      case 'bleeding':
      case 'burns':
        return const Color(0xFFF97316);

      default:
        return const Color(0xFF16A34A);
    }
  }

  String _categoryName(Map<String, dynamic> cat) =>
      _lang == 'ar' ? (cat['name_ar'] ?? '') : (cat['name_en'] ?? '');

  // =====================================================
  // BUILD
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Manual Categories',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF2563EB),
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(
          child: CircularProgressIndicator(color: Color(0xFF2563EB)))
          : Column(
        children: [
          // Info banner
          Container(
            width: double.infinity,
            color: const Color(0xFFEFF6FF),
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 12),
            child: const Row(
              children: [
                Icon(Icons.info_outline,
                    color: Color(0xFF2563EB), size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Select the category that matches the emergency to view first aid steps.',
                    style: TextStyle(
                        fontSize: 13, color: Color(0xFF1E40AF)),
                  ),
                ),
              ],
            ),
          ),

          // Categories grid
          Expanded(
            child: GridView.builder(
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
                final cat  = _categories[index];
                final code = cat['code'] as String;
                return _buildCategoryCard(cat, code);
              },
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // CATEGORY CARD
  // =====================================================

  Widget _buildCategoryCard(Map<String, dynamic> cat, String code) {
    final color       = _categoryColor(code);
    final icon        = _categoryIcon(code);
    final name        = _categoryName(cat);
    final urgency     = _urgencyLabel(code);
    final urgencyClr  = _urgencyColor(code);

    return InkWell(
      onTap: () {
        Navigator.pop(context, code);
      },

      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon circle
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: color),
            ),
            const SizedBox(height: 12),

            // Category name
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A)),
              ),
            ),
            const SizedBox(height: 8),

            // Urgency badge
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: urgencyClr.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: urgencyClr.withOpacity(0.3)),
              ),
              child: Text(
                urgency,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: urgencyClr),
              ),
            ),
          ],
        ),
      ),
    );
  }
}