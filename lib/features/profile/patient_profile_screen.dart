import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_colors.dart';
import '../../core/database/app_database.dart';
import '../../core/language/app_language.dart';

class PatientProfileScreen extends StatefulWidget {
  const PatientProfileScreen({super.key});

  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedSex = 'Male';
  String? _selectedBloodType;

  final Set<String> _selectedAllergies = {};
  final Set<String> _selectedAllergyDetails = {};
  final Map<String, Set<String>> _selectedAllergySubDetails = {};

  final Set<String> _selectedConditions = {};
  final Set<String> _selectedConditionDetails = {};
  final Map<String, Set<String>> _selectedConditionSubDetails = {};

  final Set<String> _selectedMedications = {};
  final Set<String> _selectedMedicationDetails = {};
  final Map<String, Set<String>> _selectedMedicationSubDetails = {};

  String _birthDate = '—';
  String _country = '—';
  String _email = '—';
  String _phone = '—';
  String? _imagePath;

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditing = false;

  static Color get primary => AppColors.primary;
  static const Color background = Color(0xFFF8FAFC);
  static const Color danger = Color(0xFFDC2626);
  static const Color success = Color(0xFF16A34A);
  static const Color textDark = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);

  final List<Map<String, String>> _sexItems = const [
    {'en': 'Male', 'ar': 'ذكر'},
    {'en': 'Female', 'ar': 'أنثى'},
  ];

  final List<Map<String, String>> _bloodTypes = const [
    {'en': 'A+', 'ar': 'A+'},
    {'en': 'A-', 'ar': 'A-'},
    {'en': 'B+', 'ar': 'B+'},
    {'en': 'B-', 'ar': 'B-'},
    {'en': 'AB+', 'ar': 'AB+'},
    {'en': 'AB-', 'ar': 'AB-'},
    {'en': 'O+', 'ar': 'O+'},
    {'en': 'O-', 'ar': 'O-'},
  ];

  final List<Map<String, String>> _allergies = const [
    {'en': 'None', 'ar': 'لا يوجد'},
    {'en': 'Food Allergy', 'ar': 'حساسية طعام'},
    {'en': 'Medication Allergy', 'ar': 'حساسية أدوية'},
    {'en': 'Insect Allergy', 'ar': 'حساسية حشرات'},
  ];

  final List<Map<String, String>> _foodAllergyDetails = const [
    {'en': 'Fish', 'ar': 'سمك'},
    {'en': 'Milk', 'ar': 'حليب'},
    {'en': 'Eggs', 'ar': 'بيض'},
    {'en': 'Peanuts', 'ar': 'فول سوداني'},
    {'en': 'Wheat', 'ar': 'قمح'},
  ];

  final List<Map<String, String>> _allergyOtherDetails = const [
    {'en': 'Dust', 'ar': 'غبار'},
    {'en': 'Pollen', 'ar': 'حبوب لقاح'},
    {'en': 'Animal Hair', 'ar': 'شعر الحيوانات'},
    {'en': 'Latex', 'ar': 'لاتكس'},
    {'en': 'Perfume', 'ar': 'عطور'},
  ];

  final Map<String, List<Map<String, String>>> _allergySubDetails = const {
    'Milk': [
      {'en': 'Cow Milk', 'ar': 'حليب البقر'},
      {'en': 'Cheese', 'ar': 'جبنة'},
      {'en': 'Yogurt', 'ar': 'لبن'},
      {'en': 'Butter', 'ar': 'زبدة'},
      {'en': 'Cream', 'ar': 'قشطة'},
    ],
    'Eggs': [
      {'en': 'Boiled Eggs', 'ar': 'بيض مسلوق'},
      {'en': 'Fried Eggs', 'ar': 'بيض مقلي'},
      {'en': 'Food containing eggs', 'ar': 'أطعمة تحتوي على البيض'},
    ],
    'Fish': [
      {'en': 'White Fish', 'ar': 'سمك أبيض'},
      {'en': 'Tuna', 'ar': 'تونة'},
      {'en': 'Seafood', 'ar': 'مأكولات بحرية'},
    ],
    'Peanuts': [
      {'en': 'Peanut Butter', 'ar': 'زبدة الفول السوداني'},
      {'en': 'Mixed Nuts', 'ar': 'مكسرات مشكلة'},
      {'en': 'Food containing peanuts', 'ar': 'أطعمة تحتوي على فول سوداني'},
    ],
    'Wheat': [
      {'en': 'Bread', 'ar': 'خبز'},
      {'en': 'Pasta', 'ar': 'معكرونة'},
      {'en': 'Flour', 'ar': 'طحين'},
    ],
    'Dust': [
      {'en': 'House Dust', 'ar': 'غبار المنزل'},
      {'en': 'Street Dust', 'ar': 'غبار الشارع'},
    ],
    'Pollen': [
      {'en': 'Spring Pollen', 'ar': 'حبوب لقاح الربيع'},
      {'en': 'Tree Pollen', 'ar': 'حبوب لقاح الأشجار'},
    ],
    'Inhaler': [
      {'en': 'Blue Reliever Inhaler', 'ar': 'بخاخ أزرق إسعافي'},
      {'en': 'Preventer Inhaler', 'ar': 'بخاخ وقائي'},
      {'en': 'Nebulizer', 'ar': 'جهاز تبخيرة'},
    ],
    'Insulin': [
      {'en': 'Rapid Acting', 'ar': 'سريع المفعول'},
      {'en': 'Long Acting', 'ar': 'طويل المفعول'},
      {'en': 'Insulin Pen', 'ar': 'قلم إنسولين'},
    ],
  };

  final List<Map<String, String>> _conditions = const [
    {'en': 'None', 'ar': 'لا يوجد'},
    {'en': 'Asthma', 'ar': 'ربو'},
    {'en': 'Diabetes', 'ar': 'سكري'},
    {'en': 'Heart Disease', 'ar': 'مرض قلب'},
    {'en': 'High Blood Pressure', 'ar': 'ضغط مرتفع'},
  ];

  final List<Map<String, String>> _conditionDetails = const [
    {'en': 'Mild', 'ar': 'خفيف'},
    {'en': 'Moderate', 'ar': 'متوسط'},
    {'en': 'Severe', 'ar': 'شديد'},
    {'en': 'Under Treatment', 'ar': 'تحت العلاج'},
    {'en': 'No Details', 'ar': 'لا توجد تفاصيل'},
  ];

  final Map<String, List<Map<String, String>>> _conditionSubDetails = const {
    'Asthma': [
      {'en': 'Exercise Triggered', 'ar': 'يحدث مع الجهد'},
      {'en': 'Allergy Triggered', 'ar': 'يحدث بسبب الحساسية'},
      {'en': 'Uses Inhaler', 'ar': 'يستخدم بخاخ'},
    ],
    'Diabetes': [
      {'en': 'Type 1', 'ar': 'النوع الأول'},
      {'en': 'Type 2', 'ar': 'النوع الثاني'},
      {'en': 'Uses Insulin', 'ar': 'يستخدم إنسولين'},
    ],
    'Heart Disease': [
      {'en': 'Chest Pain History', 'ar': 'تاريخ ألم صدر'},
      {'en': 'Heart Medication', 'ar': 'دواء قلب'},
      {'en': 'Previous Surgery', 'ar': 'عملية سابقة'},
    ],
    'High Blood Pressure': [
      {'en': 'Controlled', 'ar': 'مسيطر عليه'},
      {'en': 'Not Controlled', 'ar': 'غير مسيطر عليه'},
      {'en': 'Uses Pills', 'ar': 'يستخدم حبوب'},
    ],
  };

  final List<Map<String, String>> _medications = const [
    {'en': 'None', 'ar': 'لا يوجد'},
    {'en': 'Daily Medication', 'ar': 'دواء يومي'},
    {'en': 'Emergency Medication', 'ar': 'دواء طوارئ'},
  ];

  final List<Map<String, String>> _medicationDetails = const [
    {'en': 'Inhaler', 'ar': 'بخاخ'},
    {'en': 'Insulin', 'ar': 'إنسولين'},
    {'en': 'Blood Pressure Pills', 'ar': 'حبوب ضغط'},
    {'en': 'Heart Medication', 'ar': 'دواء قلب'},
    {'en': 'Painkiller', 'ar': 'مسكن'},
  ];

  final Map<String, List<Map<String, String>>> _medicationSubDetails = const {
    'Inhaler': [
      {'en': 'Blue Reliever Inhaler', 'ar': 'بخاخ أزرق إسعافي'},
      {'en': 'Preventer Inhaler', 'ar': 'بخاخ وقائي'},
      {'en': 'Nebulizer', 'ar': 'جهاز تبخيرة'},
    ],
    'Insulin': [
      {'en': 'Rapid Acting', 'ar': 'سريع المفعول'},
      {'en': 'Long Acting', 'ar': 'طويل المفعول'},
      {'en': 'Insulin Pen', 'ar': 'قلم إنسولين'},
    ],
    'Blood Pressure Pills': [
      {'en': 'Morning Dose', 'ar': 'جرعة صباحية'},
      {'en': 'Evening Dose', 'ar': 'جرعة مسائية'},
      {'en': 'Unknown Name', 'ar': 'الاسم غير معروف'},
    ],
    'Heart Medication': [
      {'en': 'Aspirin', 'ar': 'أسبرين'},
      {'en': 'Nitroglycerin', 'ar': 'نيتروغليسرين'},
      {'en': 'Unknown Name', 'ar': 'الاسم غير معروف'},
    ],
    'Painkiller': [
      {'en': 'Paracetamol', 'ar': 'باراسيتامول'},
      {'en': 'Ibuprofen', 'ar': 'آيبوبروفين'},
    ],
  };

  @override
  void initState() {
    super.initState();
    _loadQuestionnaireData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<String> _imageStorageKey() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('userEmail') ?? 'guest';
    return 'profile_image_path_$email';
  }

  Future<void> _loadQuestionnaireData() async {
    final prefs = await SharedPreferences.getInstance();
    final profile = await AppDatabase.instance.getProfile();
    final imageKey = await _imageStorageKey();

    _email = prefs.getString('userEmail') ?? '—';
    _phone = prefs.getString('userPhone') ??
        prefs.getString('registeredPhone') ??
        prefs.getString('phone') ??
        prefs.getString('phoneNumber') ??
        '—';
    _phoneController.text = _phone == '—' ? '' : _phone;
    _birthDate = prefs.getString('birthDate') ?? '—';
    _country = prefs.getString('country') ?? '—';
    _imagePath = prefs.getString(imageKey);

    if (profile != null) {
      _nameController.text =
      profile['full_name']?.toString().trim().isNotEmpty == true
          ? profile['full_name'].toString()
          : (prefs.getString('registeredName') ?? '');

      _ageController.text = profile['age']?.toString() ?? '';
      _selectedSex = _normalizeSex(profile['sex']?.toString() ?? 'Male');

      final blood = profile['blood_type']?.toString();
      _selectedBloodType = _containsValue(_bloodTypes, blood) ? blood : null;

      _parseAllergy(profile['allergies']?.toString() ?? 'None');
      _parseCondition(profile['conditions']?.toString() ?? 'None');
      _parseMedication(profile['medications']?.toString() ?? 'None');

      _notesController.text = profile['notes']?.toString() ?? '';
    } else {
      _nameController.text = prefs.getString('registeredName') ?? '';
      _selectedAllergies.add('None');
      _selectedConditions.add('None');
      _selectedMedications.add('None');
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  bool _containsValue(List<Map<String, String>> items, String? value) {
    if (value == null) return false;
    return items.any((e) => e['en'] == value);
  }

  String _normalizeSex(String value) {
    final v = value.trim().toLowerCase();
    if (v == 'f' || v == 'female' || v == 'أنثى') return 'Female';
    return 'Male';
  }

  void _parseAllergy(String value) {
    _selectedAllergies.clear();
    _selectedAllergyDetails.clear();
    _selectedAllergySubDetails.clear();

    if (value.trim().isEmpty || value == 'None') {
      _selectedAllergies.add('None');
      return;
    }

    _parseGroupValue(
      value,
      mainItems: _allergies,
      selectedMain: _selectedAllergies,
      detailResolver: _allergyDetailsForType,
      selectedDetails: _selectedAllergyDetails,
      subResolver: _allergySubDetailsFor,
      selectedSub: _selectedAllergySubDetails,
    );
  }

  void _parseCondition(String value) {
    _selectedConditions.clear();
    _selectedConditionDetails.clear();
    _selectedConditionSubDetails.clear();

    if (value.trim().isEmpty || value == 'None') {
      _selectedConditions.add('None');
      return;
    }

    _parseGroupValue(
      value,
      mainItems: _conditions,
      selectedMain: _selectedConditions,
      detailResolver: (_) => _conditionDetails,
      selectedDetails: _selectedConditionDetails,
      subResolver: _conditionSubDetailsFor,
      selectedSub: _selectedConditionSubDetails,
    );
  }

  void _parseMedication(String value) {
    _selectedMedications.clear();
    _selectedMedicationDetails.clear();
    _selectedMedicationSubDetails.clear();

    if (value.trim().isEmpty || value == 'None') {
      _selectedMedications.add('None');
      return;
    }

    _parseGroupValue(
      value,
      mainItems: _medications,
      selectedMain: _selectedMedications,
      detailResolver: (_) => _medicationDetails,
      selectedDetails: _selectedMedicationDetails,
      subResolver: _medicationSubDetailsFor,
      selectedSub: _selectedMedicationSubDetails,
    );
  }

  void _parseGroupValue(
      String raw, {
        required List<Map<String, String>> mainItems,
        required Set<String> selectedMain,
        required List<Map<String, String>> Function(String main) detailResolver,
        required Set<String> selectedDetails,
        required List<Map<String, String>> Function(String parent) subResolver,
        required Map<String, Set<String>> selectedSub,
      }) {
    final normalized = raw.toLowerCase();

    for (final main in mainItems) {
      final mainValue = main['en']!;
      if (mainValue == 'None') continue;
      if (normalized.contains(mainValue.toLowerCase())) {
        selectedMain.add(mainValue);

        for (final detail in detailResolver(mainValue)) {
          final detailValue = detail['en']!;
          if (normalized.contains(detailValue.toLowerCase())) {
            selectedDetails.add(detailValue);

            for (final sub in subResolver(detailValue)) {
              final subValue = sub['en']!;
              if (normalized.contains(subValue.toLowerCase())) {
                selectedSub.putIfAbsent(detailValue, () => <String>{}).add(subValue);
              }
            }
          }
        }
      }
    }

    if (selectedMain.isEmpty) selectedMain.add('None');
  }

  List<Map<String, String>> _allergyDetailsForType(String type) {
    if (type == 'Food Allergy') return _foodAllergyDetails;
    if (type == 'Medication Allergy') return _medicationDetails;
    if (type == 'Insect Allergy') return _allergyOtherDetails;
    return const [];
  }

  List<Map<String, String>> _allergySubDetailsFor(String parent) {
    return _allergySubDetails[parent] ?? _medicationSubDetails[parent] ?? const [];
  }

  List<Map<String, String>> _conditionSubDetailsFor(String parent) {
    return _conditionSubDetails[parent] ?? const [];
  }

  List<Map<String, String>> _medicationSubDetailsFor(String parent) {
    return _medicationSubDetails[parent] ?? const [];
  }

  Future<void> _pickImage() async {
    if (!_isEditing) {
      _showSnackbar(AppLanguage.text(context, 'Press Edit first to change the image', 'اضغط تعديل أولاً لتغيير الصورة'));
      return;
    }

    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (image == null) return;

    final prefs = await SharedPreferences.getInstance();
    final imageKey = await _imageStorageKey();

    await prefs.setString(imageKey, image.path);

    if (!mounted) return;
    setState(() => _imagePath = image.path);
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty) {
      _showSnackbar(AppLanguage.text(context, 'Please enter full name', 'أدخل الاسم الكامل'), isError: true);
      return;
    }

    if (_selectedBloodType == null) {
      _showSnackbar(AppLanguage.text(context, 'Choose blood type', 'اختر فصيلة الدم'), isError: true);
      return;
    }

    if (_selectedAllergies.isEmpty) {
      _showSnackbar(AppLanguage.text(context, 'Choose allergies', 'اختر الحساسية'), isError: true);
      return;
    }

    if (_selectedConditions.isEmpty) {
      _showSnackbar(AppLanguage.text(context, 'Choose medical conditions', 'اختر الأمراض'), isError: true);
      return;
    }

    if (_selectedMedications.isEmpty) {
      _showSnackbar(AppLanguage.text(context, 'Choose medications', 'اختر الأدوية'), isError: true);
      return;
    }

    setState(() => _isSaving = true);

    await AppDatabase.instance.saveProfile({
      'full_name': _nameController.text.trim(),
      'age': int.tryParse(_ageController.text.trim()) ?? 0,
      'sex': _selectedSex,
      'blood_type': _selectedBloodType,
      'allergies': _buildAllergyValue(),
      'conditions': _buildConditionValue(),
      'medications': _buildMedicationValue(),
      'notes': _notesController.text.trim(),
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('registeredName', _nameController.text.trim());
    await prefs.setString('userPhone', _phoneController.text.trim());
    await prefs.setString('registeredPhone', _phoneController.text.trim());
    _phone = _phoneController.text.trim().isEmpty ? '—' : _phoneController.text.trim();

    if (!mounted) return;

    setState(() {
      _isSaving = false;
      _isEditing = false;
    });

    await _loadQuestionnaireData();

    _showSnackbar(AppLanguage.text(context, 'Profile updated successfully ✓', 'تم تحديث الملف الشخصي ✓'));
  }

  String _buildAllergyValue() {
    return _buildGroupedValue(
      mains: _selectedAllergies,
      detailsByMain: _allergyDetailsForType,
      selectedDetails: _selectedAllergyDetails,
      subByDetail: _allergySubDetailsFor,
      selectedSub: _selectedAllergySubDetails,
    );
  }

  String _buildConditionValue() {
    return _buildGroupedValue(
      mains: _selectedConditions,
      detailsByMain: (_) => _conditionDetails,
      selectedDetails: _selectedConditionDetails,
      subByDetail: _conditionSubDetailsFor,
      selectedSub: _selectedConditionSubDetails,
    );
  }

  String _buildMedicationValue() {
    return _buildGroupedValue(
      mains: _selectedMedications,
      detailsByMain: (_) => _medicationDetails,
      selectedDetails: _selectedMedicationDetails,
      subByDetail: _medicationSubDetailsFor,
      selectedSub: _selectedMedicationSubDetails,
    );
  }

  String _buildGroupedValue({
    required Set<String> mains,
    required List<Map<String, String>> Function(String main) detailsByMain,
    required Set<String> selectedDetails,
    required List<Map<String, String>> Function(String detail) subByDetail,
    required Map<String, Set<String>> selectedSub,
  }) {
    if (mains.isEmpty || mains.contains('None')) return 'None';

    final result = <String>[];

    for (final main in mains) {
      if (main == 'None') continue;

      final allowedDetails = detailsByMain(main).map((e) => e['en']!).toSet();
      final detailsForMain = selectedDetails.where(allowedDetails.contains).toList();

      if (detailsForMain.isEmpty) {
        result.add(main);
        continue;
      }

      final detailTexts = <String>[];
      for (final detail in detailsForMain) {
        final subs = selectedSub[detail] ?? <String>{};
        detailTexts.add(subs.isEmpty ? detail : '$detail (${subs.join(', ')})');
      }

      result.add('$main: ${detailTexts.join(', ')}');
    }

    return result.join(' | ');
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

  String get _profileName {
    final name = _nameController.text.trim();
    return name.isEmpty ? AppLanguage.text(context, 'Your Profile', 'ملفك الشخصي') : name;
  }

  String _clean(String? value) {
    final v = value?.trim() ?? '';
    return v.isEmpty ? '—' : v;
  }

  bool _validImageFile() {
    if (_imagePath == null || _imagePath!.trim().isEmpty) return false;
    return File(_imagePath!).existsSync();
  }

  String get _allergyDisplay => _buildAllergyValue();
  String get _conditionDisplay => _buildConditionValue();
  String get _medicationDisplay => _buildMedicationValue();

  String _label(Map<String, String> item) {
    return AppLanguage.isArabicContext(context) ? item['ar']! : item['en']!;
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
            AppLanguage.text(context, 'Profile', 'الملف الشخصي'),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: primary,
          centerTitle: true,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            TextButton.icon(
              onPressed: _isSaving
                  ? null
                  : () {
                if (_isEditing) {
                  _saveProfile();
                } else {
                  setState(() => _isEditing = true);
                }
              },
              icon: Icon(
                _isEditing ? Icons.save_rounded : Icons.edit_rounded,
                color: Colors.white,
                size: 18,
              ),
              label: Text(
                _isEditing
                    ? AppLanguage.text(context, 'Save', 'حفظ')
                    : AppLanguage.text(context, 'Edit', 'تعديل'),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator(color: primary))
            : SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildProfileHeader(),
              const SizedBox(height: 22),
              if (_isEditing) _buildEditCard() else _buildQuestionnaireCard(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 56,
                  backgroundColor: const Color(0xFFDBEAFE),
                  backgroundImage: _validImageFile() ? FileImage(File(_imagePath!)) : null,
                  child: _validImageFile()
                      ? null
                      : Icon(Icons.person_rounded, size: 62, color: primary),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _isEditing ? primary : textMuted,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Icon(
                    _isEditing ? Icons.camera_alt_rounded : Icons.lock_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _profileName,
            textAlign: TextAlign.center,
            style: const TextStyle(color: textDark, fontSize: 23, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            _email,
            textAlign: TextAlign.center,
            style: const TextStyle(color: textMuted, fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildEditCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _editHeader(),
          const SizedBox(height: 18),
          _buildTextField(
            label: AppLanguage.text(context, 'Full Name', 'الاسم الكامل'),
            controller: _nameController,
            icon: Icons.person_rounded,
          ),
          _buildTextField(
            label: AppLanguage.text(context, 'Phone Number', 'رقم الهاتف'),
            controller: _phoneController,
            icon: Icons.phone_rounded,
            keyboardType: TextInputType.phone,
          ),
          _buildTextField(
            label: AppLanguage.text(context, 'Age', 'العمر'),
            controller: _ageController,
            icon: Icons.cake_rounded,
            keyboardType: TextInputType.number,
          ),
          _editSection(
            title: AppLanguage.text(context, 'Sex', 'الجنس'),
            icon: Icons.wc_rounded,
            child: _singleRectGrid(
              value: _selectedSex,
              items: _sexItems,
              icon: Icons.wc_rounded,
              onSelected: (v) => setState(() => _selectedSex = v),
            ),
          ),
          _editSection(
            title: AppLanguage.text(context, 'Blood Type', 'فصيلة الدم'),
            icon: Icons.bloodtype_rounded,
            child: _singleRectGrid(
              value: _selectedBloodType,
              items: _bloodTypes,
              icon: Icons.bloodtype_rounded,
              compact: true,
              onSelected: (v) => setState(() => _selectedBloodType = v),
            ),
          ),
          _allergyEditSection(),
          _conditionEditSection(),
          _medicationEditSection(),
          _buildTextField(
            label: AppLanguage.text(context, 'Notes', 'ملاحظات'),
            controller: _notesController,
            icon: Icons.note_alt_rounded,
            maxLines: 3,
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              onPressed: _isSaving ? null : _saveProfile,
              icon: _isSaving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.save_rounded, color: Colors.white),
              label: Text(
                _isSaving
                    ? AppLanguage.text(context, 'Saving...', 'جاري الحفظ...')
                    : AppLanguage.text(context, 'Save Changes', 'حفظ التغييرات'),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _editHeader() {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(Icons.edit_note_rounded, color: primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            AppLanguage.text(context, 'Edit Questionnaire Data', 'تعديل بيانات الاستبيان'),
            style: TextStyle(color: primary, fontSize: 19, fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }

  Widget _allergyEditSection() {
    final activeTypes = _selectedAllergies.where((e) => e != 'None').toList();

    return Column(
      children: [
        _editSection(
          title: AppLanguage.text(context, 'Allergies', 'الحساسية'),
          icon: Icons.warning_amber_rounded,
          child: _multiRectGrid(
            selectedValues: _selectedAllergies,
            items: _allergies,
            icon: Icons.warning_amber_rounded,
            onToggle: (v) {
              setState(() {
                if (v == 'None') {
                  _selectedAllergies
                    ..clear()
                    ..add('None');
                  _selectedAllergyDetails.clear();
                  _selectedAllergySubDetails.clear();
                  return;
                }

                _selectedAllergies.remove('None');

                if (_selectedAllergies.contains(v)) {
                  _selectedAllergies.remove(v);
                  _removeDetailsForMain(v, _allergyDetailsForType, _selectedAllergyDetails, _selectedAllergySubDetails);
                } else {
                  _selectedAllergies.add(v);
                }
              });
            },
          ),
        ),
        for (final type in activeTypes) ...[
          _editSection(
            title: _titleForAllergyType(type),
            icon: type == 'Food Allergy'
                ? Icons.restaurant_rounded
                : type == 'Medication Allergy'
                ? Icons.local_pharmacy_rounded
                : Icons.bug_report_rounded,
            child: _multiRectGrid(
              selectedValues: _selectedAllergyDetails,
              items: _allergyDetailsForType(type),
              icon: Icons.checklist_rounded,
              compact: true,
              onToggle: (v) {
                setState(() {
                  if (_selectedAllergyDetails.contains(v)) {
                    _selectedAllergyDetails.remove(v);
                    _selectedAllergySubDetails.remove(v);
                  } else {
                    _selectedAllergyDetails.add(v);
                  }
                });
              },
            ),
          ),
          for (final detail in _selectedDetailsForType(type, _allergyDetailsForType, _selectedAllergyDetails))
            if (_allergySubDetailsFor(detail).isNotEmpty)
              _editSection(
                title: AppLanguage.text(context, '$detail details', 'تفاصيل $detail'),
                icon: Icons.menu_open_rounded,
                child: _multiRectGrid(
                  selectedValues: _selectedAllergySubDetails[detail] ?? <String>{},
                  items: _allergySubDetailsFor(detail),
                  icon: Icons.subdirectory_arrow_right_rounded,
                  compact: true,
                  onToggle: (v) {
                    setState(() {
                      final set = _selectedAllergySubDetails.putIfAbsent(detail, () => <String>{});
                      set.contains(v) ? set.remove(v) : set.add(v);
                      if (set.isEmpty) _selectedAllergySubDetails.remove(detail);
                    });
                  },
                ),
              ),
        ],
      ],
    );
  }

  Widget _conditionEditSection() {
    final activeConditions = _selectedConditions.where((e) => e != 'None').toList();

    return Column(
      children: [
        _editSection(
          title: AppLanguage.text(context, 'Medical Conditions', 'الأمراض'),
          icon: Icons.medical_services_rounded,
          child: _multiRectGrid(
            selectedValues: _selectedConditions,
            items: _conditions,
            icon: Icons.medical_services_rounded,
            onToggle: (v) {
              setState(() {
                if (v == 'None') {
                  _selectedConditions
                    ..clear()
                    ..add('None');
                  _selectedConditionDetails.clear();
                  _selectedConditionSubDetails.clear();
                  return;
                }

                _selectedConditions.remove('None');

                if (_selectedConditions.contains(v)) {
                  _selectedConditions.remove(v);
                  _removeDetailsForMain(v, (_) => _conditionDetails, _selectedConditionDetails, _selectedConditionSubDetails);
                } else {
                  _selectedConditions.add(v);
                }
              });
            },
          ),
        ),
        for (final condition in activeConditions) ...[
          _editSection(
            title: AppLanguage.text(context, '$condition level', 'تفاصيل $condition'),
            icon: Icons.monitor_heart_rounded,
            child: _multiRectGrid(
              selectedValues: _selectedConditionDetails,
              items: _conditionDetails,
              icon: Icons.monitor_heart_rounded,
              compact: true,
              onToggle: (v) {
                setState(() {
                  _selectedConditionDetails.contains(v)
                      ? _selectedConditionDetails.remove(v)
                      : _selectedConditionDetails.add(v);
                });
              },
            ),
          ),
          if (_conditionSubDetailsFor(condition).isNotEmpty)
            _editSection(
              title: AppLanguage.text(context, '$condition details', 'تفاصيل $condition'),
              icon: Icons.menu_open_rounded,
              child: _multiRectGrid(
                selectedValues: _selectedConditionSubDetails[condition] ?? <String>{},
                items: _conditionSubDetailsFor(condition),
                icon: Icons.subdirectory_arrow_right_rounded,
                compact: true,
                onToggle: (v) {
                  setState(() {
                    final set = _selectedConditionSubDetails.putIfAbsent(condition, () => <String>{});
                    set.contains(v) ? set.remove(v) : set.add(v);
                    if (set.isEmpty) _selectedConditionSubDetails.remove(condition);
                  });
                },
              ),
            ),
        ],
      ],
    );
  }

  Widget _medicationEditSection() {
    final activeMedications = _selectedMedications.where((e) => e != 'None').toList();

    return Column(
      children: [
        _editSection(
          title: AppLanguage.text(context, 'Medications', 'الأدوية'),
          icon: Icons.medication_rounded,
          child: _multiRectGrid(
            selectedValues: _selectedMedications,
            items: _medications,
            icon: Icons.medication_rounded,
            onToggle: (v) {
              setState(() {
                if (v == 'None') {
                  _selectedMedications
                    ..clear()
                    ..add('None');
                  _selectedMedicationDetails.clear();
                  _selectedMedicationSubDetails.clear();
                  return;
                }

                _selectedMedications.remove('None');

                if (_selectedMedications.contains(v)) {
                  _selectedMedications.remove(v);
                  _removeDetailsForMain(v, (_) => _medicationDetails, _selectedMedicationDetails, _selectedMedicationSubDetails);
                } else {
                  _selectedMedications.add(v);
                }
              });
            },
          ),
        ),
        for (final medicationType in activeMedications) ...[
          _editSection(
            title: AppLanguage.text(context, '$medicationType names', 'أسماء $medicationType'),
            icon: Icons.local_pharmacy_rounded,
            child: _multiRectGrid(
              selectedValues: _selectedMedicationDetails,
              items: _medicationDetails,
              icon: Icons.local_pharmacy_rounded,
              compact: true,
              onToggle: (v) {
                setState(() {
                  if (_selectedMedicationDetails.contains(v)) {
                    _selectedMedicationDetails.remove(v);
                    _selectedMedicationSubDetails.remove(v);
                  } else {
                    _selectedMedicationDetails.add(v);
                  }
                });
              },
            ),
          ),
          for (final detail in _selectedMedicationDetails)
            if (_medicationSubDetailsFor(detail).isNotEmpty)
              _editSection(
                title: AppLanguage.text(context, '$detail details', 'تفاصيل $detail'),
                icon: Icons.menu_open_rounded,
                child: _multiRectGrid(
                  selectedValues: _selectedMedicationSubDetails[detail] ?? <String>{},
                  items: _medicationSubDetailsFor(detail),
                  icon: Icons.subdirectory_arrow_right_rounded,
                  compact: true,
                  onToggle: (v) {
                    setState(() {
                      final set = _selectedMedicationSubDetails.putIfAbsent(detail, () => <String>{});
                      set.contains(v) ? set.remove(v) : set.add(v);
                      if (set.isEmpty) _selectedMedicationSubDetails.remove(detail);
                    });
                  },
                ),
              ),
        ],
      ],
    );
  }

  String _titleForAllergyType(String type) {
    if (type == 'Food Allergy') {
      return AppLanguage.text(context, 'Food allergy items', 'اختيارات حساسية الطعام');
    }
    if (type == 'Medication Allergy') {
      return AppLanguage.text(context, 'Medication allergy items', 'اختيارات حساسية الأدوية');
    }
    return AppLanguage.text(context, 'Insect allergy items', 'اختيارات حساسية الحشرات');
  }

  List<String> _selectedDetailsForType(
      String main,
      List<Map<String, String>> Function(String main) resolver,
      Set<String> selectedDetails,
      ) {
    final allowed = resolver(main).map((e) => e['en']!).toSet();
    return selectedDetails.where(allowed.contains).toList();
  }

  void _removeDetailsForMain(
      String main,
      List<Map<String, String>> Function(String main) resolver,
      Set<String> selectedDetails,
      Map<String, Set<String>> selectedSub,
      ) {
    final details = resolver(main).map((e) => e['en']!).toSet();
    for (final detail in details) {
      selectedDetails.remove(detail);
      selectedSub.remove(detail);
    }
  }

  Widget _editSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: primary.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: primary.withValues(alpha: 0.10),
                child: Icon(icon, color: primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(color: primary, fontSize: 16.5, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _singleRectGrid({
    required String? value,
    required List<Map<String, String>> items,
    required IconData icon,
    required ValueChanged<String> onSelected,
    bool compact = false,
  }) {
    return _rectChoiceGrid(
      selectedValues: value == null ? <String>{} : <String>{value},
      items: items,
      icon: icon,
      compact: compact,
      onTap: onSelected,
    );
  }

  Widget _multiRectGrid({
    required Set<String> selectedValues,
    required List<Map<String, String>> items,
    required IconData icon,
    required ValueChanged<String> onToggle,
    bool compact = false,
  }) {
    return _rectChoiceGrid(
      selectedValues: selectedValues,
      items: items,
      icon: icon,
      compact: compact,
      onTap: onToggle,
    );
  }

  Widget _rectChoiceGrid({
    required Set<String> selectedValues,
    required List<Map<String, String>> items,
    required IconData icon,
    required ValueChanged<String> onTap,
    bool compact = false,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 10.0;
        final itemWidth = compact
            ? ((constraints.maxWidth - gap) / 2).clamp(128.0, 170.0)
            : ((constraints.maxWidth - gap) / 2).clamp(145.0, 195.0);

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: items.map((item) {
            final value = item['en']!;
            final selected = selectedValues.contains(value);
            return SizedBox(
              width: itemWidth,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => onTap(value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  constraints: BoxConstraints(minHeight: compact ? 54 : 64),
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 10 : 12,
                    vertical: compact ? 9 : 12,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? primary : background,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: selected ? primary : const Color(0xFFDDE7F3),
                      width: 1.3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: selected
                            ? primary.withValues(alpha: 0.20)
                            : Colors.black.withValues(alpha: 0.025),
                        blurRadius: selected ? 12 : 7,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: compact ? 28 : 32,
                        height: compact ? 28 : 32,
                        decoration: BoxDecoration(
                          color: selected
                              ? Colors.white.withValues(alpha: 0.20)
                              : primary.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          selected ? Icons.check_rounded : icon,
                          color: selected ? Colors.white : primary,
                          size: compact ? 17 : 19,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _label(item),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: selected ? Colors.white : textDark,
                            fontWeight: FontWeight.w800,
                            fontSize: compact ? 11 : 12.5,
                            height: 1.1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildQuestionnaireCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.assignment_rounded, color: primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  AppLanguage.text(context, 'Questionnaire Data', 'بيانات الاستبيان'),
                  style: TextStyle(color: primary, fontSize: 19, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _infoRow(
            icon: Icons.calendar_month_rounded,
            title: AppLanguage.text(context, 'Birth Date', 'تاريخ الميلاد'),
            value: _clean(_birthDate),
          ),
          _infoRow(
            icon: Icons.public_rounded,
            title: AppLanguage.text(context, 'Country', 'الدولة'),
            value: _clean(_country),
          ),
          _infoRow(
            icon: Icons.phone_rounded,
            title: AppLanguage.text(context, 'Phone Number', 'رقم الهاتف'),
            value: _clean(_phoneController.text),
          ),
          _infoRow(
            icon: Icons.cake_rounded,
            title: AppLanguage.text(context, 'Age', 'العمر'),
            value: _clean(_ageController.text),
          ),
          _infoRow(
            icon: Icons.wc_rounded,
            title: AppLanguage.text(context, 'Sex', 'الجنس'),
            value: _clean(_selectedSex),
          ),
          _infoRow(
            icon: Icons.bloodtype_rounded,
            title: AppLanguage.text(context, 'Blood Type', 'فصيلة الدم'),
            value: _clean(_selectedBloodType),
          ),
          _infoRow(
            icon: Icons.warning_amber_rounded,
            title: AppLanguage.text(context, 'Allergies', 'الحساسية'),
            value: _clean(_allergyDisplay),
          ),
          _infoRow(
            icon: Icons.medical_services_rounded,
            title: AppLanguage.text(context, 'Conditions', 'الأمراض'),
            value: _clean(_conditionDisplay),
          ),
          _infoRow(
            icon: Icons.medication_rounded,
            title: AppLanguage.text(context, 'Medications', 'الأدوية'),
            value: _clean(_medicationDisplay),
          ),
          _infoRow(
            icon: Icons.note_alt_rounded,
            title: AppLanguage.text(context, 'Notes', 'ملاحظات'),
            value: _clean(_notesController.text),
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String title,
    required String value,
    bool isLast = false,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: primary, size: 22),
          const SizedBox(width: 12),
          SizedBox(
            width: 95,
            child: Text(
              title,
              style: const TextStyle(color: textMuted, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: textDark, fontWeight: FontWeight.bold, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        cursorColor: primary,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: primary.withValues(alpha: 0.75), fontWeight: FontWeight.w700),
          prefixIcon: Icon(icon, color: primary),
          filled: true,
          fillColor: background,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: primary.withValues(alpha: 0.14)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: primary, width: 1.6),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 12,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }
}
