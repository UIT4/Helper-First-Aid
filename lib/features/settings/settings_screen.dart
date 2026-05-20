import 'package:flutter/material.dart';
import '../../core/database/app_database.dart';

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
        if (savedLang == 'en' || savedLang == 'ar' || savedLang == 'auto') {
          _language = savedLang;
        } else {
          _language = 'auto';
        }

        final savedCountry = settings['country'] ?? 'Jordan';
        if (savedCountry == 'Jordan' || savedCountry == 'Other') {
          _selectedCountry = savedCountry;
        } else {
          _selectedCountry = 'Jordan';
        }

        _emergencyCtrl.text = settings['emergency_number'] ?? '911';
        _ambulanceCtrl.text = settings['ambulance_number'] ?? '193';
        _fireCtrl.text = settings['fire_number'] ?? '199';
        _countryCtrl.text = settings['country_code'] ?? '+962';
        _largeText = (settings['large_text'] ?? 0) == 1;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackbar('حدث خطأ أثناء تحميل البيانات', isError: true);
      }
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
      _showSnackbar('تم حفظ الإعدادات بنجاح ✓');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showSnackbar('فشل الحفظ: تأكد من قاعدة البيانات', isError: true);
    }
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
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text(
            'الملف الشخصي والإعدادات',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
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
                    _sectionTitle('تفضيلات اللغة', Icons.language),
                    const SizedBox(height: 12),
                    _buildLanguageDropdownCard(),

                    const SizedBox(height: 24),

                    _sectionTitle('الدولة وأرقام الطوارئ', Icons.public),
                    const SizedBox(height: 12),
                    _buildCountrySelectorCard(),

                    const SizedBox(height: 14),

                    _buildNumberCard(
                      label: 'رقم الطوارئ الموحد',
                      controller: _emergencyCtrl,
                      icon: Icons.call,
                      color: const Color(0xFFDC2626),
                      hint: 'الافتراضي: 911',
                      description: 'يستخدم للاتصال والرسائل في التطبيق',
                    ),

                    const SizedBox(height: 14),
                    _buildCountryCodeCard(),

                    const SizedBox(height: 24),

                    _sectionTitle('سهولة الاستخدام', Icons.accessibility_new),
                    const SizedBox(height: 12),
                    _buildLargeTextCard(),

                    const SizedBox(height: 24),

                    _buildAdvancedToggle(),

                    if (_showAdvanced) ...[
                      const SizedBox(height: 14),
                      _buildNumberCard(
                        label: 'الإسعاف',
                        controller: _ambulanceCtrl,
                        icon: Icons.local_hospital,
                        color: const Color(0xFFF97316),
                        hint: 'الافتراضي: 193',
                        description: 'رقم الإسعاف الاختياري',
                      ),
                      const SizedBox(height: 14),
                      _buildNumberCard(
                        label: 'الدفاع المدني (الإطفاء)',
                        controller: _fireCtrl,
                        icon: Icons.local_fire_department,
                        color: const Color(0xFFF97316),
                        hint: 'الافتراضي: 199',
                        description: 'رقم الإطفاء الاختياري',
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
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.save, color: Colors.white),
                        label: Text(
                          _isSaving ? 'جاري الحفظ...' : 'حفظ التغييرات',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),
                    _buildDisclaimerCard(),
                    const SizedBox(height: 20),
                  ],
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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.translate, color: Color(0xFF2563EB), size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _language,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 'auto', child: Text('تحديد تلقائي (Auto Detect)', style: TextStyle(fontWeight: FontWeight.w600))),
                  DropdownMenuItem(value: 'en', child: Text('English')),
                  DropdownMenuItem(value: 'ar', child: Text('العربية')),
                ],
                onChanged: (newValue) {
                  if (newValue != null) {
                    setState(() {
                      _language = newValue;
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

  Widget _buildCountrySelectorCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.public_rounded, color: Color(0xFF2563EB), size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCountry,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 'Jordan', child: Text('الأردن (Jordan)', style: TextStyle(fontWeight: FontWeight.w600))),
                  DropdownMenuItem(value: 'Other', child: Text('دولة أخرى (Other)')),
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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.phone,
              textAlign: TextAlign.right,
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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.pin_rounded, color: Color(0xFF2563EB), size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: TextField(
              controller: _countryCtrl,
              keyboardType: TextInputType.phone,
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: _titleSize, fontWeight: FontWeight.w600),
              decoration: const InputDecoration(
                labelText: 'رمز الدولة',
                hintText: '+962',
                helperText: 'يستخدم قبل أرقام الهواتف',
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
        onChanged: (value) {
          setState(() {
            _largeText = value;
          });
        },
        secondary: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB).withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.text_fields, color: Color(0xFF2563EB)),
        ),
        title: Text(
          'وضع النص الكبير',
          style: TextStyle(fontSize: _titleSize, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
        ),
        subtitle: Text(
          'تكبير حجم الخط لتسهيل القراءة',
          style: TextStyle(fontSize: _bodySize, color: const Color(0xFF64748B)),
        ),
      ),
    );
  }

  Widget _buildAdvancedToggle() {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        setState(() {
          _showAdvanced = !_showAdvanced;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: Row(
          children: [
            const Icon(Icons.tune, color: Color(0xFF2563EB)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'أرقام طوارئ إضافية ومتقدمة',
                style: TextStyle(fontSize: _titleSize, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
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
              'يقدم هذا التطبيق إرشادات طوارئ فقط. ولا يعتبر بديلاً عن المساعدة الطبية المهنية المتخصصة.',
              style: TextStyle(fontSize: _bodySize, color: const Color(0xFF7C2D12), height: 1.5),
            ),
          ),
        ],
      ),
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