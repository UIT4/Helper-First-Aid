import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/database/app_database.dart';
import '../../core/language/app_language.dart';

class StepsViewerScreen extends StatefulWidget {
  final String categoryCode;
  final String lang;

  const StepsViewerScreen({
    super.key,
    required this.categoryCode,
    this.lang = 'en',
  });

  @override
  State<StepsViewerScreen> createState() => _StepsViewerScreenState();
}

class _StepsViewerScreenState extends State<StepsViewerScreen> {
  List<Map<String, dynamic>> _steps = [];
  int _currentStep = 0;
  bool _isLoading = true;
  String _categoryName = '';

  static Color get primary => AppColors.primary;
  static const Color danger = Color(0xFFDC2626);
  static const Color success = Color(0xFF16A34A);
  static const Color background = Color(0xFFF8FAFC);
  static const Color textDark = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF475569);

  @override
  void initState() {
    super.initState();
    _loadSteps();
  }

  Future<void> _loadSteps() async {
    final steps = await AppDatabase.instance.getStepsByCategory(
      widget.categoryCode,
    );

    final categories = await AppDatabase.instance.getCategories();

    final cat = categories.firstWhere(
          (c) => c['code'] == widget.categoryCode,
      orElse: () => {},
    );

    if (!mounted) return;

    final isArabic = AppLanguage.isArabicContext(context);

    setState(() {
      _steps = steps;
      _categoryName = isArabic
          ? (cat['name_ar'] ?? widget.categoryCode)
          : (cat['name_en'] ?? widget.categoryCode);
      _isLoading = false;
    });
  }

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      setState(() => _currentStep++);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _callEmergency() async {
    final settings = await AppDatabase.instance.getSettings();
    final number = settings['emergency_number'] ?? '911';

    final Uri url = Uri(
      scheme: 'tel',
      path: number,
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      _showSnackbar(
        AppLanguage.text(
          context,
          'Cannot open phone dialer',
          'تعذر فتح شاشة الاتصال',
        ),
        isError: true,
      );
    }
  }

  Future<void> _sendSms() async {
    final profile = await AppDatabase.instance.getProfile();
    final contacts = await AppDatabase.instance.getContacts();
    final settings = await AppDatabase.instance.getSettings();

    if (contacts.isEmpty) {
      _showSnackbar(
        AppLanguage.text(
          context,
          'No emergency contacts found',
          'لا توجد جهات اتصال للطوارئ',
        ),
        isError: true,
      );
      return;
    }

    final primary = contacts.firstWhere(
          (c) => c['is_primary'] == 1,
      orElse: () => contacts.first,
    );

    final phone = primary['phone'] ?? '';
    final countryCode = settings['country_code'] ?? '+962';
    final fullPhone = phone.toString().startsWith('+')
        ? phone.toString()
        : '$countryCode$phone';

    final age = profile?['age']?.toString() ?? '—';
    final sex = profile?['sex']?.toString() ?? '—';
    final allergies = profile?['allergies']?.toString() ?? 'None';
    final conditions = profile?['conditions']?.toString() ?? 'None';
    final notes = profile?['notes']?.toString() ?? 'None';

    final isArabic = AppLanguage.isArabicContext(context);

    final locationText = AppLanguage.text(
      context,
      'Location unavailable',
      'الموقع غير متوفر',
    );

    final body = isArabic
        ? 'طارئ: $_categoryName\n'
        'المريض: $age / $sex\n'
        'الحساسية: $allergies\n'
        'الأمراض: $conditions\n'
        'الموقع: $locationText\n'
        'ملاحظات: $notes'
        : 'EMERGENCY: $_categoryName\n'
        'Patient: $age / $sex\n'
        'Allergies: $allergies\n'
        'Conditions: $conditions\n'
        'Location: $locationText\n'
        'Notes: $notes';

    _showSmsBottomSheet(fullPhone, body);
  }

  void _showSmsBottomSheet(String phone, String body) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (_) {
        final isArabic = AppLanguage.isArabicContext(context);

        return Directionality(
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLanguage.text(
                    context,
                    'Send Emergency SMS',
                    'إرسال رسالة طوارئ',
                  ),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  AppLanguage.text(
                    context,
                    'To: $phone',
                    'إلى: $phone',
                  ),
                  style: TextStyle(
                    color: textMuted,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    body,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(text: body),
                          );
                          Navigator.pop(context);

                          _showSnackbar(
                            AppLanguage.text(
                              context,
                              'Message copied ✓',
                              'تم نسخ الرسالة ✓',
                            ),
                          );
                        },
                        icon: Icon(Icons.copy, size: 18),
                        label: Text(
                          AppLanguage.text(
                            context,
                            'Copy',
                            'نسخ',
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          Navigator.pop(context);

                          final encoded = Uri.encodeComponent(body);
                          final Uri url = Uri.parse('sms:$phone?body=$encoded');

                          if (await canLaunchUrl(url)) {
                            await launchUrl(url);
                          } else {
                            _showSnackbar(
                              AppLanguage.text(
                                context,
                                'Cannot open SMS app',
                                'تعذر فتح تطبيق الرسائل',
                              ),
                              isError: true,
                            );
                          }
                        },
                        icon: Icon(
                          Icons.send,
                          size: 18,
                          color: Colors.white,
                        ),
                        label: Text(
                          AppLanguage.text(
                            context,
                            'Send SMS',
                            'إرسال',
                          ),
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  void _markDone() {
    showDialog(
      context: context,
      builder: (_) {
        final isArabic = AppLanguage.isArabicContext(context);

        return Directionality(
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: success,
                  size: 28,
                ),
                const SizedBox(width: 10),
                Text(
                  AppLanguage.text(
                    context,
                    'Well Done!',
                    'أحسنت!',
                  ),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Text(
              AppLanguage.text(
                context,
                'You have completed all first aid steps.\n\nMake sure emergency services have been contacted.',
                'لقد أكملت جميع خطوات الإسعاف الأولي.\n\nتأكد من الاتصال بخدمات الطوارئ.',
              ),
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: success,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: const Size(double.infinity, 48),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: Text(
                  AppLanguage.text(
                    context,
                    'Done',
                    'تم',
                  ),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSnackbar(String msg, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? danger : success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  String _stepTitle(Map<String, dynamic> step) {
    final isArabic = AppLanguage.isArabicContext(context);

    return isArabic
        ? (step['title_ar'] ?? '')
        : (step['title_en'] ?? '');
  }

  String _stepBody(Map<String, dynamic> step) {
    final isArabic = AppLanguage.isArabicContext(context);

    return isArabic
        ? (step['body_ar'] ?? '')
        : (step['body_en'] ?? '');
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
            _categoryName,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: primary,
          centerTitle: true,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
        ),
        body: _isLoading
            ?  Center(
          child: CircularProgressIndicator(color: primary),
        )
            : _steps.isEmpty
            ? Center(
          child: Text(
            AppLanguage.text(
              context,
              'No steps found',
              'لا توجد خطوات',
            ),
          ),
        )
            : Column(
          children: [
            _buildProgressBar(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                children: [
                  _buildCurrentStepCard(),
                  const SizedBox(height: 16),
                  _buildStepsOverview(),
                ],
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    final progress = (_currentStep + 1) / _steps.length;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 10,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLanguage.text(
                  context,
                  'Step ${_currentStep + 1} of ${_steps.length}',
                  'الخطوة ${_currentStep + 1} من ${_steps.length}',
                ),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textMuted,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: AlwaysStoppedAnimation<Color>(primary),
              minHeight: 7,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStepCard() {
    final step = _steps[_currentStep];

    return Container(
      width: double.infinity,
      decoration: _cardDecoration(radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCurrentStepHeader(step),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Text(
              _stepBody(step),
              style: TextStyle(
                fontSize: 16,
                color: textDark,
                height: 1.6,
              ),
            ),
          ),
          if ((step['image_asset'] ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  step['image_asset'],
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
          _buildStepButtons(),
        ],
      ),
    );
  }

  Widget _buildCurrentStepHeader(Map<String, dynamic> step) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: primary,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '${_currentStep + 1}',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _stepTitle(step),
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepButtons() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _prevStep,
                icon: Icon(
                  Icons.arrow_back,
                  size: 18,
                  color: textMuted,
                ),
                label: Text(
                  AppLanguage.text(
                    context,
                    'Previous',
                    'السابق',
                  ),
                  style: TextStyle(color: textMuted),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  side: BorderSide(
                    color: Color(0xFFCBD5E1),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: _currentStep < _steps.length - 1
                  ? _nextStep
                  : _markDone,
              icon: Icon(
                _currentStep < _steps.length - 1
                    ? Icons.arrow_forward
                    : Icons.check_circle,
                color: Colors.white,
                size: 18,
              ),
              label: Text(
                _currentStep < _steps.length - 1
                    ? AppLanguage.text(
                  context,
                  'Next Step',
                  'الخطوة التالية',
                )
                    : AppLanguage.text(
                  context,
                  "I'm Done",
                  'انتهيت',
                ),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                _currentStep < _steps.length - 1 ? primary : success,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepsOverview() {
    return Container(
      decoration: _cardDecoration(radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(
              AppLanguage.text(
                context,
                'All Steps',
                'كل الخطوات',
              ),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: textMuted,
              ),
            ),
          ),
          const Divider(
            height: 1,
            color: Color(0xFFF1F5F9),
          ),
          ...List.generate(_steps.length, (index) {
            return _buildOverviewItem(index);
          }),
        ],
      ),
    );
  }

  Widget _buildOverviewItem(int index) {
    final step = _steps[index];
    final isDone = index < _currentStep;
    final isCurrent = index == _currentStep;

    return InkWell(
      onTap: () => setState(() => _currentStep = index),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: isCurrent ? AppColors.primary.withValues(alpha: 0.08) : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: index < _steps.length - 1
                  ? const Color(0xFFF1F5F9)
                  : Colors.transparent,
            ),
          ),
        ),
        child: Row(
          children: [
            _buildStepCircle(
              index: index,
              isDone: isDone,
              isCurrent: isCurrent,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _stepTitle(step),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  color: isCurrent
                      ? primary
                      : isDone
                      ? success
                      : textDark,
                ),
              ),
            ),
            if (isCurrent)
              Icon(
                Icons.chevron_right,
                color: primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepCircle({
    required int index,
    required bool isDone,
    required bool isCurrent,
  }) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: isDone
            ? success
            : isCurrent
            ? primary
            : const Color(0xFFF1F5F9),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: isDone
          ? Icon(
        Icons.check,
        size: 16,
        color: Colors.white,
      )
          : Text(
        '${index + 1}',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isCurrent ? Colors.white : textMuted,
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final emergencyLabel = AppLanguage.text(
      context,
      'Call Emergency',
      'اتصل بالطوارئ',
    );

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: danger,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _callEmergency,
                icon: Icon(
                  Icons.call,
                  color: Colors.white,
                  size: 20,
                ),
                label: Text(
                  emergencyLabel,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _sendSms,
                icon: Icon(
                  Icons.sms,
                  color: Colors.white,
                  size: 20,
                ),
                label: Text(
                  AppLanguage.text(
                    context,
                    'Send SMS',
                    'إرسال رسالة',
                  ),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration({required double radius}) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}