import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/database/app_database.dart';
import '../../core/language/app_language.dart';
import '../home/home_screen.dart';

class QuestionnaireScreen extends StatefulWidget {
  final String name;
  final String email;

  const QuestionnaireScreen({
    super.key,
    required this.name,
    required this.email,
  });

  @override
  State<QuestionnaireScreen> createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<QuestionnaireScreen> {
  final nameCtrl = TextEditingController();
  final dobCtrl = TextEditingController();
  final notesCtrl = TextEditingController();

  final allergyOtherCtrl = TextEditingController();
  final conditionOtherCtrl = TextEditingController();
  final medicationOtherCtrl = TextEditingController();
  final countryCtrl = TextEditingController();

  bool isSaving = false;
  bool isLoadingLocation = false;

  DateTime? selectedDob;

  String? selectedGender;
  String? selectedBloodType;

  String? selectedAllergy;
  String? selectedAllergyDetail;

  String? selectedCondition;
  String? selectedConditionDetail;

  String? selectedMedication;
  String? selectedMedicationDetail;

  static const Color primary = Color(0xFF2563EB);
  static const Color danger = Color(0xFFDC2626);
  static const Color success = Color(0xFF16A34A);
  static const Color background = Color(0xFFF8FAFC);

  final genders = const [
    {'en': 'Male', 'ar': 'ذكر'},
    {'en': 'Female', 'ar': 'أنثى'},
  ];

  final bloodTypes = const [
    {'en': 'A+', 'ar': 'A+'},
    {'en': 'A-', 'ar': 'A-'},
    {'en': 'B+', 'ar': 'B+'},
    {'en': 'B-', 'ar': 'B-'},
    {'en': 'AB+', 'ar': 'AB+'},
    {'en': 'AB-', 'ar': 'AB-'},
    {'en': 'O+', 'ar': 'O+'},
    {'en': 'O-', 'ar': 'O-'},
  ];

  final allergies = const [
    {'en': 'None', 'ar': 'لا يوجد'},
    {'en': 'Food Allergy', 'ar': 'حساسية طعام'},
    {'en': 'Medication Allergy', 'ar': 'حساسية أدوية'},
    {'en': 'Insect Allergy', 'ar': 'حساسية حشرات'},
    {'en': 'Other', 'ar': 'أخرى'},
  ];

  final foodAllergyDetails = const [
    {'en': 'Fish', 'ar': 'سمك'},
    {'en': 'Milk', 'ar': 'حليب'},
    {'en': 'Eggs', 'ar': 'بيض'},
    {'en': 'Peanuts', 'ar': 'فول سوداني'},
    {'en': 'Wheat', 'ar': 'قمح'},
    {'en': 'Other', 'ar': 'أخرى'},
  ];

  final allergyOtherDetails = const [
    {'en': 'Dust', 'ar': 'غبار'},
    {'en': 'Pollen', 'ar': 'حبوب لقاح'},
    {'en': 'Animal Hair', 'ar': 'شعر الحيوانات'},
    {'en': 'Latex', 'ar': 'لاتكس'},
    {'en': 'Perfume', 'ar': 'عطور'},
    {'en': 'Other', 'ar': 'أخرى'},
  ];

  final conditions = const [
    {'en': 'None', 'ar': 'لا يوجد'},
    {'en': 'Asthma', 'ar': 'ربو'},
    {'en': 'Diabetes', 'ar': 'سكري'},
    {'en': 'Heart Disease', 'ar': 'مرض قلب'},
    {'en': 'High Blood Pressure', 'ar': 'ضغط مرتفع'},
    {'en': 'Other', 'ar': 'أخرى'},
  ];

  final conditionDetails = const [
    {'en': 'Mild', 'ar': 'خفيف'},
    {'en': 'Moderate', 'ar': 'متوسط'},
    {'en': 'Severe', 'ar': 'شديد'},
    {'en': 'Under Treatment', 'ar': 'تحت العلاج'},
    {'en': 'No Details', 'ar': 'لا توجد تفاصيل'},
    {'en': 'Other', 'ar': 'أخرى'},
  ];

  final medications = const [
    {'en': 'None', 'ar': 'لا يوجد'},
    {'en': 'Daily Medication', 'ar': 'دواء يومي'},
    {'en': 'Emergency Medication', 'ar': 'دواء طوارئ'},
    {'en': 'Other', 'ar': 'أخرى'},
  ];

  final medicationDetails = const [
    {'en': 'Inhaler', 'ar': 'بخاخ'},
    {'en': 'Insulin', 'ar': 'إنسولين'},
    {'en': 'Blood Pressure Pills', 'ar': 'حبوب ضغط'},
    {'en': 'Heart Medication', 'ar': 'دواء قلب'},
    {'en': 'Painkiller', 'ar': 'مسكن'},
    {'en': 'Other', 'ar': 'أخرى'},
  ];


  final countries = const [
    {'en': 'Jordan', 'ar': 'الأردن', 'code': '+962', 'emergency': '911', 'ambulance': '193', 'fire': '199'},
    {'en': 'Saudi Arabia', 'ar': 'السعودية', 'code': '+966', 'emergency': '911', 'ambulance': '997', 'fire': '998'},
    {'en': 'United Arab Emirates', 'ar': 'الإمارات', 'code': '+971', 'emergency': '999', 'ambulance': '998', 'fire': '997'},
    {'en': 'Palestine', 'ar': 'فلسطين', 'code': '+970', 'emergency': '100', 'ambulance': '101', 'fire': '102'},
    {'en': 'Egypt', 'ar': 'مصر', 'code': '+20', 'emergency': '122', 'ambulance': '123', 'fire': '180'},
    {'en': 'Iraq', 'ar': 'العراق', 'code': '+964', 'emergency': '104', 'ambulance': '122', 'fire': '115'},
    {'en': 'Syria', 'ar': 'سوريا', 'code': '+963', 'emergency': '112', 'ambulance': '110', 'fire': '113'},
    {'en': 'Lebanon', 'ar': 'لبنان', 'code': '+961', 'emergency': '112', 'ambulance': '140', 'fire': '175'},
    {'en': 'Other', 'ar': 'أخرى', 'code': '', 'emergency': '112', 'ambulance': '112', 'fire': '112'},
  ];

  @override
  void initState() {
    super.initState();
    nameCtrl.text = widget.name;
    countryCtrl.text = 'Jordan';
    _detectCountryFromLocation();
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    dobCtrl.dispose();
    notesCtrl.dispose();
    allergyOtherCtrl.dispose();
    conditionOtherCtrl.dispose();
    medicationOtherCtrl.dispose();
    countryCtrl.dispose();
    super.dispose();
  }

  Future<void> _toggleLanguage() async {
    final isArabic = AppLanguage.isArabicContext(context);
    await AppLanguage.setLanguage(isArabic ? 'en' : 'ar');
  }

  int _calculateAge(DateTime dob) {
    final now = DateTime.now();
    int age = now.year - dob.year;

    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }

    return age;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );

    if (picked == null) return;

    setState(() {
      selectedDob = picked;
      dobCtrl.text =
      '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    });
  }

  Future<void> _detectCountryFromLocation() async {
    if (!mounted) return;
    setState(() => isLoadingLocation = true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() => isLoadingLocation = false);
        _showSnack(
          AppLanguage.text(
            context,
            'Location is off. Choose your country manually.',
            'الموقع مغلق. اختر الدولة يدوياً.',
          ),
          isError: true,
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() => isLoadingLocation = false);
        _showSnack(
          AppLanguage.text(
            context,
            'Location denied. Choose your country manually.',
            'تم رفض الموقع. اختر الدولة يدوياً.',
          ),
          isError: true,
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      final detectedCountry =
          placemarks.isNotEmpty ? (placemarks.first.country ?? '') : '';
      final matchedCountry = _countryValueFromDetectedName(detectedCountry);

      if (!mounted) return;
      setState(() {
        countryCtrl.text = matchedCountry;
        isLoadingLocation = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => isLoadingLocation = false);
      _showSnack(
        AppLanguage.text(
          context,
          'Could not detect country. Choose it manually.',
          'تعذر تحديد الدولة. اخترها يدوياً.',
        ),
        isError: true,
      );
    }
  }

  String _countryValueFromDetectedName(String country) {
    final normalized = country.trim().toLowerCase();
    if (normalized.isEmpty) return countryCtrl.text.isEmpty ? 'Jordan' : countryCtrl.text;

    for (final item in countries) {
      final en = item['en']!.toLowerCase();
      final ar = item['ar']!;
      if (normalized == en || country == ar || normalized.contains(en)) {
        return item['en']!;
      }
    }

    if (normalized.contains('jordan')) return 'Jordan';
    if (normalized.contains('saudi')) return 'Saudi Arabia';
    if (normalized.contains('emirates') || normalized.contains('uae')) {
      return 'United Arab Emirates';
    }
    if (normalized.contains('palestine')) return 'Palestine';
    if (normalized.contains('egypt')) return 'Egypt';
    if (normalized.contains('iraq')) return 'Iraq';
    if (normalized.contains('syria')) return 'Syria';
    if (normalized.contains('lebanon')) return 'Lebanon';

    return 'Other';
  }

  Map<String, String> _selectedCountryInfo() {
    return countries.firstWhere(
      (item) => item['en'] == countryCtrl.text.trim(),
      orElse: () => countries.first,
    );
  }

  String _buildGroupedValue(
      String? main,
      String? detail,
      TextEditingController otherController,
      ) {
    if (main == null || main == 'None') return 'None';

    if (detail == 'Other') {
      final other = otherController.text.trim();
      return other.isEmpty ? main : '$main: $other';
    }

    return detail == null || detail.isEmpty ? main : '$main: $detail';
  }

  Future<void> _finish() async {
    if (nameCtrl.text.trim().isEmpty ||
        selectedDob == null ||
        selectedGender == null ||
        selectedBloodType == null ||
        selectedAllergy == null ||
        selectedCondition == null ||
        selectedMedication == null ||
        countryCtrl.text.trim().isEmpty) {
      _showSnack(
        AppLanguage.text(
          context,
          'Fill all required fields and choose your country',
          'عبئ جميع الحقول المطلوبة واختر الدولة',
        ),
        isError: true,
      );
      return;
    }

    if (selectedAllergy != 'None' && selectedAllergyDetail == null) {
      _showSnack(
        AppLanguage.text(context, 'Choose allergy details', 'اختر تفاصيل الحساسية'),
        isError: true,
      );
      return;
    }

    if (selectedAllergyDetail == 'Other' &&
        allergyOtherCtrl.text.trim().isEmpty) {
      _showSnack(
        AppLanguage.text(context, 'Write allergy details', 'اكتب تفاصيل الحساسية'),
        isError: true,
      );
      return;
    }

    if (selectedCondition != 'None' && selectedConditionDetail == null) {
      _showSnack(
        AppLanguage.text(context, 'Choose disease details', 'اختر تفاصيل المرض'),
        isError: true,
      );
      return;
    }

    if (selectedConditionDetail == 'Other' &&
        conditionOtherCtrl.text.trim().isEmpty) {
      _showSnack(
        AppLanguage.text(context, 'Write disease details', 'اكتب تفاصيل المرض'),
        isError: true,
      );
      return;
    }

    if (selectedMedication != 'None' && selectedMedicationDetail == null) {
      _showSnack(
        AppLanguage.text(context, 'Choose medication details', 'اختر تفاصيل الدواء'),
        isError: true,
      );
      return;
    }

    if (selectedMedicationDetail == 'Other' &&
        medicationOtherCtrl.text.trim().isEmpty) {
      _showSnack(
        AppLanguage.text(context, 'Write medication name', 'اكتب اسم الدواء'),
        isError: true,
      );
      return;
    }

    setState(() => isSaving = true);

    final age = _calculateAge(selectedDob!);

    await AppDatabase.instance.saveProfile({
      'full_name': nameCtrl.text.trim(),
      'age': age,
      'sex': selectedGender,
      'blood_type': selectedBloodType,
      'allergies': _buildGroupedValue(
        selectedAllergy,
        selectedAllergyDetail,
        allergyOtherCtrl,
      ),
      'conditions': _buildGroupedValue(
        selectedCondition,
        selectedConditionDetail,
        conditionOtherCtrl,
      ),
      'medications': _buildGroupedValue(
        selectedMedication,
        selectedMedicationDetail,
        medicationOtherCtrl,
      ),
      'notes': notesCtrl.text.trim(),
    });

    final countryInfo = _selectedCountryInfo();
    final currentSettings = await AppDatabase.instance.getSettings();
    await AppDatabase.instance.saveSettings({
      ...currentSettings,
      'country': countryInfo['en'] ?? countryCtrl.text.trim(),
      'country_code': countryInfo['code'] ?? '+962',
      'emergency_number': countryInfo['emergency'] ?? '911',
      'ambulance_number': countryInfo['ambulance'] ?? '193',
      'fire_number': countryInfo['fire'] ?? '199',
    });

    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('isLoggedIn', true);
    await prefs.setBool('isGuest', false);
    await prefs.setBool('profileCompleted', true);
    await prefs.setString('userEmail', widget.email);
    await prefs.setString('registeredName', nameCtrl.text.trim());
    await prefs.setString('birthDate', dobCtrl.text.trim());
    await prefs.setString('country', countryCtrl.text.trim());

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? danger : success,
      ),
    );
  }

  List<Map<String, String>> _allergyDetailsList() {
    if (selectedAllergy == 'Food Allergy') return foodAllergyDetails;
    return allergyOtherDetails;
  }

  String _label(Map<String, String> item) {
    final isArabic = AppLanguage.isArabicContext(context);
    return isArabic ? item['ar']! : item['en']!;
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
            AppLanguage.text(context, 'Medical Information', 'المعلومات الطبية'),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: primary,
          centerTitle: true,
          actions: [
            TextButton(
              onPressed: _toggleLanguage,
              child: Text(
                isArabic ? 'English' : 'العربية',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              _textField(
                label: AppLanguage.text(context, 'Full Name', 'الاسم الكامل'),
                controller: nameCtrl,
                icon: Icons.person,
              ),
              _dateField(),
              _dropdown(
                label: AppLanguage.text(context, 'Gender', 'الجنس'),
                value: selectedGender,
                items: genders,
                icon: Icons.wc,
                onChanged: (v) => setState(() => selectedGender = v),
              ),
              _dropdown(
                label: AppLanguage.text(context, 'Blood Type', 'فصيلة الدم'),
                value: selectedBloodType,
                items: bloodTypes,
                icon: Icons.bloodtype,
                onChanged: (v) => setState(() => selectedBloodType = v),
              ),
              _dropdown(
                label: AppLanguage.text(context, 'Allergies', 'الحساسية'),
                value: selectedAllergy,
                items: allergies,
                icon: Icons.warning_amber,
                onChanged: (v) {
                  setState(() {
                    selectedAllergy = v;
                    selectedAllergyDetail = null;
                    allergyOtherCtrl.clear();
                  });
                },
              ),
              if (selectedAllergy != null && selectedAllergy != 'None')
                _dropdown(
                  label: AppLanguage.text(
                    context,
                    'Allergy Details',
                    'تفاصيل الحساسية',
                  ),
                  value: selectedAllergyDetail,
                  items: _allergyDetailsList(),
                  icon: Icons.restaurant,
                  onChanged: (v) {
                    setState(() {
                      selectedAllergyDetail = v;
                      allergyOtherCtrl.clear();
                    });
                  },
                ),
              if (selectedAllergyDetail == 'Other')
                _textField(
                  label: AppLanguage.text(
                    context,
                    'Write allergy details',
                    'اكتب تفاصيل الحساسية',
                  ),
                  controller: allergyOtherCtrl,
                  icon: Icons.edit_note,
                ),
              _dropdown(
                label: AppLanguage.text(context, 'Medical Conditions', 'الأمراض'),
                value: selectedCondition,
                items: conditions,
                icon: Icons.medical_services,
                onChanged: (v) {
                  setState(() {
                    selectedCondition = v;
                    selectedConditionDetail = null;
                    conditionOtherCtrl.clear();
                  });
                },
              ),
              if (selectedCondition != null && selectedCondition != 'None')
                _dropdown(
                  label: AppLanguage.text(
                    context,
                    'Condition Details',
                    'تفاصيل المرض',
                  ),
                  value: selectedConditionDetail,
                  items: conditionDetails,
                  icon: Icons.monitor_heart,
                  onChanged: (v) {
                    setState(() {
                      selectedConditionDetail = v;
                      conditionOtherCtrl.clear();
                    });
                  },
                ),
              if (selectedConditionDetail == 'Other')
                _textField(
                  label: AppLanguage.text(
                    context,
                    'Write disease details',
                    'اكتب تفاصيل المرض',
                  ),
                  controller: conditionOtherCtrl,
                  icon: Icons.edit_note,
                ),
              _dropdown(
                label: AppLanguage.text(context, 'Medications', 'الأدوية'),
                value: selectedMedication,
                items: medications,
                icon: Icons.medication,
                onChanged: (v) {
                  setState(() {
                    selectedMedication = v;
                    selectedMedicationDetail = null;
                    medicationOtherCtrl.clear();
                  });
                },
              ),
              if (selectedMedication != null && selectedMedication != 'None')
                _dropdown(
                  label: AppLanguage.text(
                    context,
                    'Medication Details',
                    'تفاصيل الدواء',
                  ),
                  value: selectedMedicationDetail,
                  items: medicationDetails,
                  icon: Icons.local_pharmacy,
                  onChanged: (v) {
                    setState(() {
                      selectedMedicationDetail = v;
                      medicationOtherCtrl.clear();
                    });
                  },
                ),
              if (selectedMedicationDetail == 'Other')
                _textField(
                  label: AppLanguage.text(
                    context,
                    'Write medication name',
                    'اكتب اسم الدواء',
                  ),
                  controller: medicationOtherCtrl,
                  icon: Icons.edit_note,
                ),
              _countryDropdown(),
              _textField(
                label: AppLanguage.text(context, 'Notes', 'ملاحظات'),
                controller: notesCtrl,
                icon: Icons.note_alt,
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: isSaving ? null : _finish,
                  child: isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                    AppLanguage.text(context, 'FINISH', 'إنهاء'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dateField() {
    return _textField(
      label: AppLanguage.text(context, 'Date of Birth', 'تاريخ الميلاد'),
      controller: dobCtrl,
      icon: Icons.calendar_month,
      readOnly: true,
      onTap: _pickDate,
    );
  }

  Widget _dropdown({
    required String label,
    required String? value,
    required List<Map<String, String>> items,
    required IconData icon,
    required ValueChanged<String?> onChanged,
  }) {
    final safeValue = value != null && items.any((e) => e['en'] == value)
        ? value
        : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: safeValue,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: primary),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
        items: items.map((item) {
          return DropdownMenuItem<String>(
            value: item['en'],
            child: Text(_label(item)),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _countryDropdown() {
    final safeValue = countries.any((e) => e['en'] == countryCtrl.text)
        ? countryCtrl.text
        : 'Jordan';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: safeValue,
        decoration: InputDecoration(
          labelText: AppLanguage.text(context, 'Country', 'الدولة'),
          prefixIcon: const Icon(Icons.public, color: primary),
          suffixIcon: isLoadingLocation
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.my_location),
                  onPressed: _detectCountryFromLocation,
                ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
        items: countries.map((item) {
          final label = AppLanguage.isArabicContext(context)
              ? item['ar']!
              : item['en']!;
          return DropdownMenuItem<String>(
            value: item['en'],
            child: Text(label),
          );
        }).toList(),
        onChanged: (value) {
          if (value == null) return;
          setState(() => countryCtrl.text = value);
        },
      ),
    );
  }

  Widget _textField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool readOnly = false,
    VoidCallback? onTap,
    Widget? suffix,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        onTap: onTap,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: primary),
          suffixIcon: suffix,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}
