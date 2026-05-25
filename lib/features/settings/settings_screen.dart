import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_colors.dart';
import '../../core/database/app_database.dart';
import '../../core/language/app_language.dart';
import '../auth/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _emergencyCtrl = TextEditingController();
  final _ambulanceCtrl = TextEditingController();
  final _fireCtrl = TextEditingController();

  String _language = 'auto';
  String _country = 'Jordan';

  bool _largeText = false;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _showAdvanced = false;
  bool _isGuest = false;

  static const Color danger = Color(0xFFDC2626);
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF97316);
  static const Color background = Color(0xFFF8FAFC);
  static const Color textDark = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);

  double get _titleSize => _largeText ? 18 : 16;
  double get _bodySize => _largeText ? 16 : 14;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _emergencyCtrl.dispose();
    _ambulanceCtrl.dispose();
    _fireCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await AppDatabase.instance.getSettings();
      final globalLang = await AppLanguage.getLanguage();
      final prefs = await SharedPreferences.getInstance();

      if (!mounted) return;

      setState(() {
        final savedLang = settings['language'] ?? globalLang;
        _language = ['en', 'ar', 'auto'].contains(savedLang) ? savedLang : 'auto';

        _country = prefs.getString('country') ?? 'Jordan';

        _largeText = (settings['large_text'] ?? 0) == 1;
        _isGuest = prefs.getBool('isGuest') ?? false;

        _applyEmergencyNumbersByCountry(_country);

        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnackbar(
        AppLanguage.text(
          context,
          'Error loading settings',
          'حدث خطأ أثناء تحميل البيانات',
        ),
        isError: true,
      );
    }
  }

  void _applyEmergencyNumbersByCountry(String country) {
    final c = country.toLowerCase().trim();

    if (c.contains('jordan') || c.contains('الأردن') || c.contains('اردن')) {
      _emergencyCtrl.text = '911';
      _ambulanceCtrl.text = '193';
      _fireCtrl.text = '199';
      return;
    }

    if (c.contains('egypt') || c.contains('مصر')) {
      _emergencyCtrl.text = '122';
      _ambulanceCtrl.text = '123';
      _fireCtrl.text = '180';
      return;
    }

    if (c.contains('saudi') || c.contains('ksa') || c.contains('السعودية')) {
      _emergencyCtrl.text = '911';
      _ambulanceCtrl.text = '997';
      _fireCtrl.text = '998';
      return;
    }

    if (c.contains('uae') ||
        c.contains('emirates') ||
        c.contains('الإمارات') ||
        c.contains('امارات')) {
      _emergencyCtrl.text = '999';
      _ambulanceCtrl.text = '998';
      _fireCtrl.text = '997';
      return;
    }

    if (c.contains('palestine') || c.contains('فلسطين')) {
      _emergencyCtrl.text = '100';
      _ambulanceCtrl.text = '101';
      _fireCtrl.text = '102';
      return;
    }

    if (c.contains('lebanon') || c.contains('لبنان')) {
      _emergencyCtrl.text = '112';
      _ambulanceCtrl.text = '140';
      _fireCtrl.text = '175';
      return;
    }

    if (c.contains('iraq') || c.contains('العراق') || c.contains('عراق')) {
      _emergencyCtrl.text = '104';
      _ambulanceCtrl.text = '122';
      _fireCtrl.text = '115';
      return;
    }

    if (c.contains('qatar') || c.contains('قطر')) {
      _emergencyCtrl.text = '999';
      _ambulanceCtrl.text = '999';
      _fireCtrl.text = '999';
      return;
    }

    if (c.contains('kuwait') || c.contains('الكويت') || c.contains('كويت')) {
      _emergencyCtrl.text = '112';
      _ambulanceCtrl.text = '112';
      _fireCtrl.text = '112';
      return;
    }

    if (c.contains('bahrain') || c.contains('البحرين') || c.contains('بحرين')) {
      _emergencyCtrl.text = '999';
      _ambulanceCtrl.text = '999';
      _fireCtrl.text = '999';
      return;
    }

    if (c.contains('oman') || c.contains('عمان') || c.contains('سلطنة')) {
      _emergencyCtrl.text = '9999';
      _ambulanceCtrl.text = '9999';
      _fireCtrl.text = '9999';
      return;
    }

    if (c.contains('syria') || c.contains('سوريا')) {
      _emergencyCtrl.text = '112';
      _ambulanceCtrl.text = '110';
      _fireCtrl.text = '113';
      return;
    }

    // Default fallback
    _emergencyCtrl.text = '911';
    _ambulanceCtrl.text = '193';
    _fireCtrl.text = '199';
  }

  Future<void> _applyCountryNumbersNow() async {
    setState(() {
      _applyEmergencyNumbersByCountry(_country);
    });

    _showSnackbar(
      AppLanguage.text(
        context,
        'Emergency numbers updated for your country',
        'تم تحديث أرقام الطوارئ حسب الدولة',
      ),
    );
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);

    try {
      await AppDatabase.instance.saveSettings({
        'language': _language,
        'emergency_number': _emergencyCtrl.text.trim(),
        'ambulance_number': _ambulanceCtrl.text.trim(),
        'fire_number': _fireCtrl.text.trim(),
        'large_text': _largeText ? 1 : 0,
      });

      await AppLanguage.setLanguage(_language);

      if (!mounted) return;

      setState(() => _isSaving = false);

      _showSnackbar(
        AppLanguage.text(
          context,
          'Settings saved ✓',
          'تم حفظ الإعدادات بنجاح ✓',
        ),
      );

      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showSnackbar(
        AppLanguage.text(
          context,
          'Save failed: check database',
          'فشل الحفظ: تأكد من قاعدة البيانات',
        ),
        isError: true,
      );
    }
  }

  Future<void> _exitGuestMode() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('isLoggedIn', false);
    await prefs.setBool('isGuest', false);

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  }

  Future<void> _logout() async {
    final isAr = AppLanguage.isArabicContext(context);

    final title = _isGuest
        ? AppLanguage.text(context, 'Exit Guest Mode', 'الخروج من وضع الضيف')
        : AppLanguage.text(context, 'Logout', 'تسجيل الخروج');

    final message = _isGuest
        ? AppLanguage.text(
      context,
      'Do you want to leave Guest Mode and go to the login screen?',
      'هل تريد الخروج من وضع الضيف والانتقال إلى شاشة تسجيل الدخول؟',
    )
        : AppLanguage.text(
      context,
      'Are you sure you want to logout?',
      'هل أنت متأكد أنك تريد تسجيل الخروج؟',
    );

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => Directionality(
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Text(message),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      AppLanguage.text(context, 'Cancel', 'إلغاء'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: danger,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _isGuest
                            ? AppLanguage.text(context, 'Exit', 'خروج')
                            : AppLanguage.text(context, 'Logout', 'خروج'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (confirm != true) return;

    if (_isGuest) {
      await _exitGuestMode();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    await prefs.setBool('isGuest', false);

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  }

  void _showSnackbar(String msg, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? danger : success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = AppLanguage.isArabicContext(context);

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: background,
        appBar: AppBar(
          title: Text(
            AppLanguage.text(
              context,
              _isGuest ? 'Guest Settings' : 'Profile & Settings',
              _isGuest ? 'إعدادات الضيف' : 'الملف الشخصي والإعدادات',
            ),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: AppColors.primary,
          centerTitle: true,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator(color: AppColors.primary))
            : SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle(
                AppLanguage.text(context, 'Language Preferences', 'تفضيلات اللغة'),
                Icons.language,
              ),
              const SizedBox(height: 12),
              _buildLanguageDropdownCard(),

              const SizedBox(height: 24),
              _sectionTitle(
                AppLanguage.text(context, 'Emergency Number', 'رقم الطوارئ'),
                Icons.call,
              ),
              const SizedBox(height: 12),
              _buildNumberCard(
                label: AppLanguage.text(context, 'Emergency Number', 'رقم الطوارئ الموحد'),
                controller: _emergencyCtrl,
                icon: Icons.call,
                color: danger,
                hint: AppLanguage.text(context, 'Default: 911', 'الافتراضي: 911'),
                description: AppLanguage.text(
                  context,
                  'Used for calls and emergency messages',
                  'يستخدم للاتصال والرسائل في التطبيق',
                ),
              ),

              const SizedBox(height: 24),
              _sectionTitle(
                AppLanguage.text(context, 'Accessibility', 'سهولة الاستخدام'),
                Icons.accessibility_new,
              ),
              const SizedBox(height: 12),
              _buildLargeTextCard(),

              const SizedBox(height: 24),
              _sectionTitle(
                AppLanguage.text(context, 'Theme Colors', 'ألوان التطبيق'),
                Icons.palette,
              ),
              const SizedBox(height: 12),
              _buildThemeSelector(),

              const SizedBox(height: 24),
              _buildAdvancedToggle(),
              if (_showAdvanced) ...[
                const SizedBox(height: 14),
                _buildNumberCard(
                  label: AppLanguage.text(context, 'Ambulance', 'الإسعاف'),
                  controller: _ambulanceCtrl,
                  icon: Icons.local_hospital,
                  color: warning,
                  hint: AppLanguage.text(context, 'Default: 193', 'الافتراضي: 193'),
                  description: AppLanguage.text(
                    context,
                    'Optional ambulance number',
                    'رقم الإسعاف الاختياري',
                  ),
                ),
                const SizedBox(height: 14),
                _buildNumberCard(
                  label: AppLanguage.text(context, 'Fire Department', 'الدفاع المدني / الإطفاء'),
                  controller: _fireCtrl,
                  icon: Icons.local_fire_department,
                  color: warning,
                  hint: AppLanguage.text(context, 'Default: 199', 'الافتراضي: 199'),
                  description: AppLanguage.text(
                    context,
                    'Optional fire department number',
                    'رقم الإطفاء الاختياري',
                  ),
                ),
              ],

              const SizedBox(height: 28),
              _buildSaveButton(),
              const SizedBox(height: 14),
              _buildLogoutButton(),
              const SizedBox(height: 28),
              _buildDisclaimerCard(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCountryNumbersCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _iconBox(Icons.public_rounded, AppColors.primary),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  AppLanguage.text(
                    context,
                    'Detected country: $_country',
                    'الدولة المحددة: $_country',
                  ),
                  style: TextStyle(
                    fontSize: _titleSize,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            AppLanguage.text(
              context,
              'Emergency, ambulance, and fire numbers are filled automatically based on the country selected during signup/onboarding.',
              'يتم تعبئة أرقام الطوارئ والإسعاف والإطفاء تلقائياً حسب الدولة المختارة عند التسجيل أو الاستبيان.',
            ),
            style: TextStyle(
              fontSize: _bodySize,
              color: textMuted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _applyCountryNumbersNow,
              icon: Icon(Icons.refresh_rounded, color: AppColors.primary),
              label: Text(
                AppLanguage.text(
                  context,
                  'Apply Country Numbers',
                  'تطبيق أرقام الدولة',
                ),
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _themeButton(color: AppColors.blue, themeName: 'blue'),
          _themeButton(color: AppColors.orange, themeName: 'orange'),
          _themeButton(color: AppColors.purple, themeName: 'purple'),
        ],
      ),
    );
  }

  Widget _themeButton({
    required Color color,
    required String themeName,
  }) {
    return GestureDetector(
      onTap: () async {
        await AppColors.changeTheme(themeName);

        if (!mounted) return;

        setState(() {});

        _showSnackbar(
          AppLanguage.text(
            context,
            'Theme color changed',
            'تم تغيير لون التطبيق',
          ),
        );
      },
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.primary == color ? textDark : Colors.white,
            width: AppColors.primary == color ? 4 : 3,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.35),
              blurRadius: 12,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 2,
        ),
        onPressed: _isSaving ? null : _saveSettings,
        icon: _isSaving
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
        )
            : const Icon(Icons.save, color: Colors.white),
        label: Text(
          _isSaving
              ? AppLanguage.text(context, 'Saving...', 'جاري الحفظ...')
              : AppLanguage.text(context, 'Save Changes', 'حفظ التغييرات'),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: danger, width: 1.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: _logout,
        icon: const Icon(Icons.logout, color: danger),
        label: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            AppLanguage.text(
              context,
              _isGuest ? 'Exit Guest Mode' : 'Logout',
              _isGuest ? 'الخروج من وضع الضيف' : 'تسجيل الخروج',
            ),
            style: const TextStyle(color: danger, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 22),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: _largeText ? 20 : 18,
              fontWeight: FontWeight.bold,
              color: textDark,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageDropdownCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          _iconBox(Icons.translate, AppColors.primary),
          const SizedBox(width: 14),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _language,
                isExpanded: true,
                items: [
                  DropdownMenuItem(
                    value: 'auto',
                    child: Text(AppLanguage.text(context, 'Auto Detect', 'تحديد تلقائي')),
                  ),
                  const DropdownMenuItem(value: 'en', child: Text('English')),
                  const DropdownMenuItem(value: 'ar', child: Text('العربية')),
                ],
                onChanged: (newValue) {
                  if (newValue == null) return;
                  setState(() => _language = newValue);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberCard({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required Color color,
    required String hint,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          _iconBox(icon, color),
          const SizedBox(width: 14),
          Expanded(
            child: TextField(
              controller: controller,
              readOnly: true,
              enableInteractiveSelection: false,
              keyboardType: TextInputType.phone,
              textAlign: AppLanguage.isArabicContext(context) ? TextAlign.right : TextAlign.left,
              style: TextStyle(fontSize: _titleSize, fontWeight: FontWeight.w600, color: textDark),
              decoration: InputDecoration(
                labelText: label,
                hintText: hint,
                helperText: description,
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLargeTextCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        value: _largeText,
        activeThumbColor: AppColors.primary,
        onChanged: (value) => setState(() => _largeText = value),
        secondary: _iconBox(Icons.text_fields, AppColors.primary),
        title: Text(
          AppLanguage.text(context, 'Large Text Mode', 'وضع النص الكبير'),
          style: TextStyle(fontSize: _titleSize, fontWeight: FontWeight.bold, color: textDark),
        ),
        subtitle: Text(
          AppLanguage.text(
            context,
            'Increase font size for easier reading',
            'تكبير حجم الخط لتسهيل القراءة',
          ),
          style: TextStyle(fontSize: _bodySize, color: textMuted),
        ),
      ),
    );
  }

  Widget _buildAdvancedToggle() {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => setState(() => _showAdvanced = !_showAdvanced),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: Row(
          children: [
            Icon(Icons.tune, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                AppLanguage.text(
                  context,
                  'Advanced Emergency Numbers',
                  'أرقام طوارئ إضافية ومتقدمة',
                ),
                style: TextStyle(fontSize: _titleSize, fontWeight: FontWeight.bold, color: textDark),
              ),
            ),
            Icon(
              _showAdvanced ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisclaimerCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: warning.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: warning),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              AppLanguage.text(
                context,
                'This app provides emergency guidance only. It is not a substitute for professional medical help.',
                'يقدم هذا التطبيق إرشادات طوارئ فقط، ولا يعتبر بديلاً عن المساعدة الطبية المهنية المتخصصة.',
              ),
              style: TextStyle(fontSize: _bodySize, color: const Color(0xFF7C2D12), height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconBox(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}
