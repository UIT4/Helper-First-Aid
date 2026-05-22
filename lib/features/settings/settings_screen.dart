import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  String _language = 'en';

  bool _largeText = false;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _showAdvanced = false;

  static const Color primary = Color(0xFF2563EB);
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

      if (!mounted) return;

      setState(() {
        final savedLang = settings['language'] ?? globalLang;
        _language = ['en', 'ar', 'auto'].contains(savedLang) ? savedLang : 'en';

        _emergencyCtrl.text = settings['emergency_number'] ?? '911';
        _ambulanceCtrl.text = settings['ambulance_number'] ?? '193';
        _fireCtrl.text = settings['fire_number'] ?? '199';

        _largeText = (settings['large_text'] ?? 0) == 1;
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

  Future<void> _logout() async {
    final isAr = AppLanguage.isArabicContext(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => Directionality(
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            AppLanguage.text(context, 'Logout', 'تسجيل الخروج'),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            AppLanguage.text(
              context,
              'Are you sure you want to logout?',
              'هل أنت متأكد أنك تريد تسجيل الخروج؟',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(AppLanguage.text(context, 'Cancel', 'إلغاء')),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: danger),
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                AppLanguage.text(context, 'Logout', 'تسجيل الخروج'),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirm != true) return;

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
              'Profile & Settings',
              'الملف الشخصي والإعدادات',
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
            ? const Center(child: CircularProgressIndicator(color: primary))
            : SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle(
                AppLanguage.text(
                  context,
                  'Language Preferences',
                  'تفضيلات اللغة',
                ),
                Icons.language,
              ),
              const SizedBox(height: 12),
              _buildLanguageDropdownCard(),
              const SizedBox(height: 24),

              _sectionTitle(
                AppLanguage.text(
                  context,
                  'Emergency Number',
                  'رقم الطوارئ',
                ),
                Icons.call,
              ),
              const SizedBox(height: 12),
              _buildNumberCard(
                label: AppLanguage.text(
                  context,
                  'Emergency Number',
                  'رقم الطوارئ الموحد',
                ),
                controller: _emergencyCtrl,
                icon: Icons.call,
                color: danger,
                hint: AppLanguage.text(
                  context,
                  'Default: 911',
                  'الافتراضي: 911',
                ),
                description: AppLanguage.text(
                  context,
                  'Used for calls and emergency messages',
                  'يستخدم للاتصال والرسائل في التطبيق',
                ),
              ),

              const SizedBox(height: 24),
              _sectionTitle(
                AppLanguage.text(
                  context,
                  'Accessibility',
                  'سهولة الاستخدام',
                ),
                Icons.accessibility_new,
              ),
              const SizedBox(height: 12),
              _buildLargeTextCard(),

              const SizedBox(height: 24),
              _buildAdvancedToggle(),
              if (_showAdvanced) ...[
                const SizedBox(height: 14),
                _buildNumberCard(
                  label: AppLanguage.text(
                    context,
                    'Ambulance',
                    'الإسعاف',
                  ),
                  controller: _ambulanceCtrl,
                  icon: Icons.local_hospital,
                  color: warning,
                  hint: AppLanguage.text(
                    context,
                    'Default: 193',
                    'الافتراضي: 193',
                  ),
                  description: AppLanguage.text(
                    context,
                    'Optional ambulance number',
                    'رقم الإسعاف الاختياري',
                  ),
                ),
                const SizedBox(height: 14),
                _buildNumberCard(
                  label: AppLanguage.text(
                    context,
                    'Fire Department',
                    'الدفاع المدني / الإطفاء',
                  ),
                  controller: _fireCtrl,
                  icon: Icons.local_fire_department,
                  color: warning,
                  hint: AppLanguage.text(
                    context,
                    'Default: 199',
                    'الافتراضي: 199',
                  ),
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

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 2,
        ),
        onPressed: _isSaving ? null : _saveSettings,
        icon: _isSaving
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        )
            : const Icon(Icons.save, color: Colors.white),
        label: Text(
          _isSaving
              ? AppLanguage.text(context, 'Saving...', 'جاري الحفظ...')
              : AppLanguage.text(context, 'Save Changes', 'حفظ التغييرات'),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
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
        label: Text(
          AppLanguage.text(context, 'Logout', 'تسجيل الخروج'),
          style: const TextStyle(
            color: danger,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: primary, size: 22),
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
          _iconBox(Icons.translate, primary),
          const SizedBox(width: 14),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _language,
                isExpanded: true,
                items: [
                  DropdownMenuItem(
                    value: 'auto',
                    child: Text(
                      AppLanguage.text(context, 'Auto Detect', 'تحديد تلقائي'),
                    ),
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
              keyboardType: TextInputType.phone,
              textAlign: AppLanguage.isArabicContext(context)
                  ? TextAlign.right
                  : TextAlign.left,
              style: TextStyle(
                fontSize: _titleSize,
                fontWeight: FontWeight.w600,
              ),
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
        activeThumbColor: primary,
        onChanged: (value) => setState(() => _largeText = value),
        secondary: _iconBox(Icons.text_fields, primary),
        title: Text(
          AppLanguage.text(context, 'Large Text Mode', 'وضع النص الكبير'),
          style: TextStyle(
            fontSize: _titleSize,
            fontWeight: FontWeight.bold,
            color: textDark,
          ),
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
            const Icon(Icons.tune, color: primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                AppLanguage.text(
                  context,
                  'Advanced Emergency Numbers',
                  'أرقام طوارئ إضافية ومتقدمة',
                ),
                style: TextStyle(
                  fontSize: _titleSize,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                ),
              ),
            ),
            Icon(
              _showAdvanced
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down,
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
              style: TextStyle(
                fontSize: _bodySize,
                color: const Color(0xFF7C2D12),
                height: 1.5,
              ),
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