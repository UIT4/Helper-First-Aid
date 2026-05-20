import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/database/app_database.dart';
import '../auth/login_screen.dart';

// تعديل اسم الكلاس ليتوافق مع الاستدعاءات الخارجية في home_screen وغيرها
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _emergencyCtrl = TextEditingController();
  final _ambulanceCtrl = TextEditingController();
  final _fireCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();

  String _language = 'auto';
  String _selectedCountry = 'Jordan';

  bool _largeText = false;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _showAdvanced = false;

  bool get isArabic => _language == 'ar';

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
    _countryCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await AppDatabase.instance.getSettings();

      if (!mounted) return;

      setState(() {
        final savedLang = settings['language'] ?? 'auto';
        _language = ['en', 'ar', 'auto'].contains(savedLang) ? savedLang : 'auto';

        final savedCountry = settings['country'] ?? 'Jordan';
        _selectedCountry =
        ['Jordan', 'Other'].contains(savedCountry) ? savedCountry : 'Jordan';

        _emergencyCtrl.text = settings['emergency_number'] ?? '911';
        _ambulanceCtrl.text = settings['ambulance_number'] ?? '193';
        _fireCtrl.text = settings['fire_number'] ?? '199';
        _countryCtrl.text = settings['country_code'] ?? '+962';

        _largeText = (settings['large_text'] ?? 0) == 1;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnackbar(
        isArabic ? 'حدث خطأ أثناء تحميل البيانات' : 'Error loading settings',
        isError: true,
      );
    }
  }

  void _applyJordanDefaults() {
    _emergencyCtrl.text = '911';
    _ambulanceCtrl.text = '193';
    _countryCtrl.text = '+962';
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);

    try {
      await AppDatabase.instance.saveSettings({
        'language': _language,
        'country': _selectedCountry,
        'emergency_number': _emergencyCtrl.text.trim(),
        'ambulance_number': _ambulanceCtrl.text.trim(),
        'fire_number': _fireCtrl.text.trim(),
        'country_code': _countryCtrl.text.trim(),
        'large_text': _largeText ? 1 : 0,
      });

      if (!mounted) return;

      setState(() => _isSaving = false);
      _showSnackbar(isArabic ? 'تم حفظ الإعدادات بنجاح ✓' : 'Settings saved ✓');
    } catch (_) {
      if (!mounted) return;

      setState(() => _isSaving = false);
      _showSnackbar(
        isArabic ? 'فشل الحفظ: تأكد من قاعدة البيانات' : 'Save failed: check database',
        isError: true,
      );
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isArabic ? 'تسجيل الخروج' : 'Logout',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          isArabic
              ? 'هل أنت متأكد أنك تريد تسجيل الخروج؟'
              : 'Are you sure you want to logout?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(isArabic ? 'إلغاء' : 'Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              isArabic ? 'تسجيل الخروج' : 'Logout',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
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
        content: Text(msg, style: const TextStyle(fontFamily: 'Roboto')),
        backgroundColor: isError ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  double get _titleSize => _largeText ? 18 : 16;
  double get _bodySize => _largeText ? 16 : 14;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: Text(
            isArabic ? 'الملف الشخصي والإعدادات' : 'Profile & Settings',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          backgroundColor: const Color(0xFF2563EB),
          centerTitle: true,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
            : SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle(
                isArabic ? 'تفضيلات اللغة' : 'Language Preferences',
                Icons.language,
              ),
              const SizedBox(height: 12),
              _buildLanguageDropdownCard(),

              const SizedBox(height: 24),

              _sectionTitle(
                isArabic ? 'الدولة وأرقام الطوارئ' : 'Country & Emergency Numbers',
                Icons.public,
              ),
              const SizedBox(height: 12),
              _buildCountrySelectorCard(),

              const SizedBox(height: 14),

              _buildNumberCard(
                label: isArabic ? 'رقم الطوارئ الموحد' : 'Emergency Number',
                controller: _emergencyCtrl,
                icon: Icons.call,
                color: const Color(0xFFDC2626),
                hint: isArabic ? 'الافتراضي: 911' : 'Default: 911',
                description: isArabic
                    ? 'يستخدم للاتصال والرسائل في التطبيق'
                    : 'Used for calls and emergency messages',
              ),

              const SizedBox(height: 14),
              _buildCountryCodeCard(),

              const SizedBox(height: 24),

              _sectionTitle(
                isArabic ? 'سهولة الاستخدام' : 'Accessibility',
                Icons.accessibility_new,
              ),
              const SizedBox(height: 12),
              _buildLargeTextCard(),

              const SizedBox(height: 24),
              _buildAdvancedToggle(),

              if (_showAdvanced) ...[
                const SizedBox(height: 14),
                _buildNumberCard(
                  label: isArabic ? 'الإسعاف' : 'Ambulance',
                  controller: _ambulanceCtrl,
                  icon: Icons.local_hospital,
                  color: const Color(0xFFF97316),
                  hint: isArabic ? 'الافتراضي: 193' : 'Default: 193',
                  description: isArabic ? 'رقم الإسعاف الاختياري' : 'Optional ambulance number',
                ),
                const SizedBox(height: 14),
                _buildNumberCard(
                  label: isArabic ? 'الدفاع المدني / الإطفاء' : 'Fire Department',
                  controller: _fireCtrl,
                  icon: Icons.local_fire_department,
                  color: const Color(0xFFF97316),
                  hint: isArabic ? 'الافتراضي: 199' : 'Default: 199',
                  description: isArabic ? 'رقم الإطفاء الاختياري' : 'Optional fire department number',
                ),
              ],

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
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
                        ? (isArabic ? 'جاري الحفظ...' : 'Saving...')
                        : (isArabic ? 'حفظ التغييرات' : 'Save Changes'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),

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

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFDC2626), width: 1.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: _logout,
        icon: const Icon(Icons.logout, color: Color(0xFFDC2626)),
        label: Text(
          isArabic ? 'تسجيل الخروج' : 'Logout',
          style: const TextStyle(
            color: Color(0xFFDC2626),
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
        Icon(icon, color: const Color(0xFF2563EB), size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: _largeText ? 20 : 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
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
          _iconBox(Icons.translate, const Color(0xFF2563EB)),
          const SizedBox(width: 14),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _language,
                isExpanded: true,
                items: [
                  DropdownMenuItem(
                    value: 'auto',
                    child: Text(isArabic ? 'تحديد تلقائي' : 'Auto Detect'),
                  ),
                  const DropdownMenuItem(value: 'en', child: Text('English')),
                  const DropdownMenuItem(value: 'ar', child: Text('العربية')),
                ],
                onChanged: (newValue) {
                  if (newValue != null) {
                    setState(() => _language = newValue);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountrySelectorCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          _iconBox(Icons.public_rounded, const Color(0xFF2563EB)),
          const SizedBox(width: 14),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCountry,
                isExpanded: true,
                items: [
                  DropdownMenuItem(
                    value: 'Jordan',
                    child: Text(isArabic ? 'الأردن' : 'Jordan'),
                  ),
                  DropdownMenuItem(
                    value: 'Other',
                    child: Text(isArabic ? 'دولة أخرى' : 'Other Country'),
                  ),
                ],
                onChanged: (newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedCountry = newValue;
                      if (_selectedCountry == 'Jordan') {
                        _applyJordanDefaults();
                      }
                    });
                  }
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
              textAlign: isArabic ? TextAlign.right : TextAlign.left,
              style: TextStyle(fontSize: _titleSize, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                labelText: label,
                alignLabelWithHint: true,
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

  Widget _buildCountryCodeCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          _iconBox(Icons.pin_rounded, const Color(0xFF2563EB)),
          const SizedBox(width: 14),
          Expanded(
            child: TextField(
              controller: _countryCtrl,
              keyboardType: TextInputType.phone,
              textAlign: isArabic ? TextAlign.right : TextAlign.left,
              style: TextStyle(fontSize: _titleSize, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                labelText: isArabic ? 'رمز الدولة' : 'Country Code',
                hintText: '+962',
                helperText: isArabic
                    ? 'يستخدم قبل أرقام الهواتف'
                    : 'Used before phone numbers',
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
        activeColor: const Color(0xFF2563EB),
        onChanged: (value) => setState(() => _largeText = value),
        secondary: _iconBox(Icons.text_fields, const Color(0xFF2563EB)),
        title: Text(
          isArabic ? 'وضع النص الكبير' : 'Large Text Mode',
          style: TextStyle(
            fontSize: _titleSize,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
        subtitle: Text(
          isArabic ? 'تكبير حجم الخط لتسهيل القراءة' : 'Increase font size for easier reading',
          style: TextStyle(fontSize: _bodySize, color: const Color(0xFF64748B)),
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
            const Icon(Icons.tune, color: Color(0xFF2563EB)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isArabic ? 'أرقام طوارئ إضافية ومتقدمة' : 'Advanced Emergency Numbers',
                style: TextStyle(
                  fontSize: _titleSize,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ),
            Icon(
              _showAdvanced ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: const Color(0xFF64748B),
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
        border: Border.all(color: const Color(0xFFF97316).withOpacity(0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFF97316)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isArabic
                  ? 'يقدم هذا التطبيق إرشادات طوارئ فقط. ولا يعتبر بديلاً عن المساعدة الطبية المهنية المتخصصة.'
                  : 'This app provides emergency guidance only. It is not a substitute for professional medical help.',
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
        color: color.withOpacity(0.12),
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
        BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
      ],
    );
  }
}