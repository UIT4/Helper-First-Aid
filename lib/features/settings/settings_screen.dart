import 'package:flutter/material.dart';
import '../../core/database/app_database.dart';

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

  String _language = 'en';
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
    final settings = await AppDatabase.instance.getSettings();

    if (!mounted) return;

    setState(() {
      _language = settings['language'] ?? 'en';
      _emergencyCtrl.text = settings['emergency_number'] ?? '911';
      _ambulanceCtrl.text = settings['ambulance_number'] ?? '193';
      _fireCtrl.text = settings['fire_number'] ?? '199';
      _countryCtrl.text = settings['country_code'] ?? '+962';
      _largeText = (settings['large_text'] ?? 0) == 1;
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);

    await AppDatabase.instance.saveSettings({
      'language': _language,
      'emergency_number': _emergencyCtrl.text.trim(),
      'ambulance_number': _ambulanceCtrl.text.trim(),
      'fire_number': _fireCtrl.text.trim(),
      'country_code': _countryCtrl.text.trim(),
      'large_text': _largeText ? 1 : 0,
    });

    if (!mounted) return;

    setState(() => _isSaving = false);
    _showSnackbar('Settings saved ✓');
  }

  Future<void> _selectLanguage(String value) async {
    setState(() => _language = value);

    await AppDatabase.instance.saveSettings({
      'language': value,
      'emergency_number': _emergencyCtrl.text.trim(),
      'ambulance_number': _ambulanceCtrl.text.trim(),
      'fire_number': _fireCtrl.text.trim(),
      'country_code': _countryCtrl.text.trim(),
      'large_text': _largeText ? 1 : 0,
    });

    if (!mounted) return;
    _showSnackbar(_languageSavedLabel(value));
  }

  String _languageSavedLabel(String lang) {
    switch (lang) {
      case 'ar':
        return 'تم تغيير اللغة إلى العربية ✓';
      case 'auto':
        return 'Language set to Auto Detect ✓';
      default:
        return 'Language set to English ✓';
    }
  }

  void _showSnackbar(String msg, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor:
        isError ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  double get _titleSize => _largeText ? 18 : 16;
  double get _bodySize => _largeText ? 16 : 14;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF2563EB),
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(color: Color(0xFF2563EB)),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('Language', Icons.language),
            const SizedBox(height: 12),
            _buildLanguageSelector(),

            const SizedBox(height: 24),

            _sectionTitle('Emergency Number', Icons.emergency),
            const SizedBox(height: 12),
            _buildNumberCard(
              label: 'Unified Emergency',
              controller: _emergencyCtrl,
              icon: Icons.call,
              color: const Color(0xFFDC2626),
              hint: 'Default: 911',
              description: 'Used for Call & SMS throughout the app',
            ),

            const SizedBox(height: 14),
            _buildCountryCodeCard(),

            const SizedBox(height: 24),

            _sectionTitle('Accessibility', Icons.accessibility_new),
            const SizedBox(height: 12),
            _buildLargeTextCard(),

            const SizedBox(height: 24),

            _buildAdvancedToggle(),

            if (_showAdvanced) ...[
              const SizedBox(height: 14),
              _buildNumberCard(
                label: 'Ambulance',
                controller: _ambulanceCtrl,
                icon: Icons.local_hospital,
                color: const Color(0xFFF97316),
                hint: 'Default: 193',
                description: 'Optional ambulance number',
              ),
              const SizedBox(height: 14),
              _buildNumberCard(
                label: 'Fire Department',
                controller: _fireCtrl,
                icon: Icons.local_fire_department,
                color: const Color(0xFFF97316),
                hint: 'Default: 199',
                description: 'Optional fire department number',
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
                  _isSaving ? 'Saving...' : 'SAVE SETTINGS',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 28),
            _buildDisclaimerCard(),
            const SizedBox(height: 20),
          ],
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

  Widget _buildLanguageSelector() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _languageTile('en', 'English', 'Use English interface', Icons.translate),
          const Divider(),
          _languageTile('ar', 'العربية', 'استخدام الواجهة العربية', Icons.language),
          const Divider(),
          _languageTile(
            'auto',
            'Auto Detect',
            'Detect language automatically',
            Icons.public,
          ),
        ],
      ),
    );
  }

  Widget _languageTile(
      String value,
      String title,
      String subtitle,
      IconData icon,
      ) {
    final selected = _language == value;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        icon,
        color: selected ? const Color(0xFF2563EB) : const Color(0xFF64748B),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: _titleSize,
          fontWeight: selected ? FontWeight.bold : FontWeight.w500,
          color: const Color(0xFF0F172A),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: _bodySize,
          color: const Color(0xFF64748B),
        ),
      ),
      trailing: selected
          ? const Icon(Icons.check_circle, color: Color(0xFF2563EB))
          : null,
      onTap: () => _selectLanguage(value),
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
            child: const Icon(
              Icons.flag,
              color: Color(0xFF2563EB),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: TextField(
              controller: _countryCtrl,
              keyboardType: TextInputType.phone,
              style: TextStyle(
                fontSize: _titleSize,
                fontWeight: FontWeight.w600,
              ),
              decoration: const InputDecoration(
                labelText: 'Country Code',
                hintText: '+962',
                helperText: 'Used before phone numbers',
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
          child: const Icon(
            Icons.text_fields,
            color: Color(0xFF2563EB),
          ),
        ),
        title: Text(
          'Large Text Mode',
          style: TextStyle(
            fontSize: _titleSize,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
        subtitle: Text(
          'Increase text size for easier reading',
          style: TextStyle(
            fontSize: _bodySize,
            color: const Color(0xFF64748B),
          ),
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
                'Advanced Emergency Numbers',
                style: TextStyle(
                  fontSize: _titleSize,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ),
            Icon(
              _showAdvanced
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down,
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
          const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFF97316),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'This app provides emergency guidance only. It is not a replacement for professional medical help.',
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

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}