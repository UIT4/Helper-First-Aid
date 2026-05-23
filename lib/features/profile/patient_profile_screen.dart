import 'dart:io';

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  final _notesController = TextEditingController();

  final _allergyOtherController = TextEditingController();
  final _conditionOtherController = TextEditingController();
  final _medicationOtherController = TextEditingController();

  String _selectedSex = 'Male';
  String? _selectedBloodType;

  String? _selectedAllergy;
  String? _selectedAllergyDetail;

  String? _selectedCondition;
  String? _selectedConditionDetail;

  String? _selectedMedication;
  String? _selectedMedicationDetail;

  String _birthDate = '—';
  String _country = '—';
  String _email = '—';
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
    {'en': 'Other', 'ar': 'أخرى'},
  ];

  final List<Map<String, String>> _foodAllergyDetails = const [
    {'en': 'Fish', 'ar': 'سمك'},
    {'en': 'Milk', 'ar': 'حليب'},
    {'en': 'Eggs', 'ar': 'بيض'},
    {'en': 'Peanuts', 'ar': 'فول سوداني'},
    {'en': 'Wheat', 'ar': 'قمح'},
    {'en': 'Other', 'ar': 'أخرى'},
  ];

  final List<Map<String, String>> _allergyOtherDetails = const [
    {'en': 'Dust', 'ar': 'غبار'},
    {'en': 'Pollen', 'ar': 'حبوب لقاح'},
    {'en': 'Animal Hair', 'ar': 'شعر الحيوانات'},
    {'en': 'Latex', 'ar': 'لاتكس'},
    {'en': 'Perfume', 'ar': 'عطور'},
    {'en': 'Other', 'ar': 'أخرى'},
  ];

  final List<Map<String, String>> _conditions = const [
    {'en': 'None', 'ar': 'لا يوجد'},
    {'en': 'Asthma', 'ar': 'ربو'},
    {'en': 'Diabetes', 'ar': 'سكري'},
    {'en': 'Heart Disease', 'ar': 'مرض قلب'},
    {'en': 'High Blood Pressure', 'ar': 'ضغط مرتفع'},
    {'en': 'Other', 'ar': 'أخرى'},
  ];

  final List<Map<String, String>> _conditionDetails = const [
    {'en': 'Mild', 'ar': 'خفيف'},
    {'en': 'Moderate', 'ar': 'متوسط'},
    {'en': 'Severe', 'ar': 'شديد'},
    {'en': 'Under Treatment', 'ar': 'تحت العلاج'},
    {'en': 'No Details', 'ar': 'لا توجد تفاصيل'},
    {'en': 'Other', 'ar': 'أخرى'},
  ];

  final List<Map<String, String>> _medications = const [
    {'en': 'None', 'ar': 'لا يوجد'},
    {'en': 'Daily Medication', 'ar': 'دواء يومي'},
    {'en': 'Emergency Medication', 'ar': 'دواء طوارئ'},
    {'en': 'Other', 'ar': 'أخرى'},
  ];

  final List<Map<String, String>> _medicationDetails = const [
    {'en': 'Inhaler', 'ar': 'بخاخ'},
    {'en': 'Insulin', 'ar': 'إنسولين'},
    {'en': 'Blood Pressure Pills', 'ar': 'حبوب ضغط'},
    {'en': 'Heart Medication', 'ar': 'دواء قلب'},
    {'en': 'Painkiller', 'ar': 'مسكن'},
    {'en': 'Other', 'ar': 'أخرى'},
  ];

  @override
  void initState() {
    super.initState();
    _loadQuestionnaireData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _notesController.dispose();
    _allergyOtherController.dispose();
    _conditionOtherController.dispose();
    _medicationOtherController.dispose();
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
      _selectedAllergy = 'None';
      _selectedCondition = 'None';
      _selectedMedication = 'None';
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
    _selectedAllergy = 'None';
    _selectedAllergyDetail = null;
    _allergyOtherController.clear();

    if (value.trim().isEmpty || value == 'None') return;

    final parts = value.split(':');
    final main = parts.first.trim();
    final detail = parts.length > 1 ? parts.sublist(1).join(':').trim() : null;

    _selectedAllergy = _containsValue(_allergies, main) ? main : 'Other';

    if (detail != null && detail.isNotEmpty) {
      final detailsList = _selectedAllergy == 'Food Allergy'
          ? _foodAllergyDetails
          : _allergyOtherDetails;

      if (_containsValue(detailsList, detail)) {
        _selectedAllergyDetail = detail;
      } else {
        _selectedAllergyDetail = 'Other';
        _allergyOtherController.text = detail;
      }
    }
  }

  void _parseCondition(String value) {
    _selectedCondition = 'None';
    _selectedConditionDetail = null;
    _conditionOtherController.clear();

    if (value.trim().isEmpty || value == 'None') return;

    final parts = value.split(':');
    final main = parts.first.trim();
    final detail = parts.length > 1 ? parts.sublist(1).join(':').trim() : null;

    _selectedCondition = _containsValue(_conditions, main) ? main : 'Other';

    if (detail != null && detail.isNotEmpty) {
      if (_containsValue(_conditionDetails, detail)) {
        _selectedConditionDetail = detail;
      } else {
        _selectedConditionDetail = 'Other';
        _conditionOtherController.text = detail;
      }
    }
  }

  void _parseMedication(String value) {
    _selectedMedication = 'None';
    _selectedMedicationDetail = null;
    _medicationOtherController.clear();

    if (value.trim().isEmpty || value == 'None') return;

    final parts = value.split(':');
    final main = parts.first.trim();
    final detail = parts.length > 1 ? parts.sublist(1).join(':').trim() : null;

    _selectedMedication = _containsValue(_medications, main) ? main : 'Other';

    if (detail != null && detail.isNotEmpty) {
      if (_containsValue(_medicationDetails, detail)) {
        _selectedMedicationDetail = detail;
      } else {
        _selectedMedicationDetail = 'Other';
        _medicationOtherController.text = detail;
      }
    }
  }

  List<Map<String, String>> _allergyDetailsList() {
    if (_selectedAllergy == 'Food Allergy') return _foodAllergyDetails;
    return _allergyOtherDetails;
  }

  String _buildAllergyValue() {
    if (_selectedAllergy == null || _selectedAllergy == 'None') return 'None';

    final detail = _selectedAllergyDetail == 'Other'
        ? _allergyOtherController.text.trim()
        : (_selectedAllergyDetail ?? '');

    return detail.isEmpty ? _selectedAllergy! : '${_selectedAllergy!}: $detail';
  }

  String _buildConditionValue() {
    if (_selectedCondition == null || _selectedCondition == 'None') {
      return 'None';
    }

    final detail = _selectedConditionDetail == 'Other'
        ? _conditionOtherController.text.trim()
        : (_selectedConditionDetail ?? '');

    return detail.isEmpty
        ? _selectedCondition!
        : '${_selectedCondition!}: $detail';
  }

  String _buildMedicationValue() {
    if (_selectedMedication == null || _selectedMedication == 'None') {
      return 'None';
    }

    final detail = _selectedMedicationDetail == 'Other'
        ? _medicationOtherController.text.trim()
        : (_selectedMedicationDetail ?? '');

    return detail.isEmpty
        ? _selectedMedication!
        : '${_selectedMedication!}: $detail';
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

    if (_selectedAllergy != 'None' && _selectedAllergyDetail == null) {
      _showSnackbar(AppLanguage.text(context, 'Choose allergy details', 'اختر تفاصيل الحساسية'), isError: true);
      return;
    }

    if (_selectedAllergyDetail == 'Other' &&
        _allergyOtherController.text.trim().isEmpty) {
      _showSnackbar(AppLanguage.text(context, 'Write allergy details', 'اكتب تفاصيل الحساسية'), isError: true);
      return;
    }

    if (_selectedCondition != 'None' && _selectedConditionDetail == null) {
      _showSnackbar(AppLanguage.text(context, 'Choose condition details', 'اختر تفاصيل المرض'), isError: true);
      return;
    }

    if (_selectedConditionDetail == 'Other' &&
        _conditionOtherController.text.trim().isEmpty) {
      _showSnackbar(AppLanguage.text(context, 'Write condition details', 'اكتب تفاصيل المرض'), isError: true);
      return;
    }

    if (_selectedMedication != 'None' && _selectedMedicationDetail == null) {
      _showSnackbar(AppLanguage.text(context, 'Choose medication details', 'اختر تفاصيل الدواء'), isError: true);
      return;
    }

    if (_selectedMedicationDetail == 'Other' &&
        _medicationOtherController.text.trim().isEmpty) {
      _showSnackbar(AppLanguage.text(context, 'Write medication name', 'اكتب اسم الدواء'), isError: true);
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

    if (!mounted) return;

    setState(() {
      _isSaving = false;
      _isEditing = false;
    });

    await _loadQuestionnaireData();

    _showSnackbar(AppLanguage.text(context, 'Profile updated successfully ✓', 'تم تحديث الملف الشخصي ✓'));
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
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: primary,
          centerTitle: true,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
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
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
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
              if (_isEditing) ...[
                _buildEditCard(),
              ] else ...[
                _buildQuestionnaireCard(),
              ],
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
                  backgroundImage:
                  _validImageFile() ? FileImage(File(_imagePath!)) : null,
                  child: _validImageFile()
                      ? null
                      : Icon(
                    Icons.person_rounded,
                    size: 62,
                    color: primary,
                  ),
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
            style: TextStyle(
              color: textDark,
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _email,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
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
          Text(
            AppLanguage.text(context, 'Edit Questionnaire Data', 'تعديل بيانات الاستبيان'),
            style: TextStyle(
              color: primary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: AppLanguage.text(context, 'Full Name', 'الاسم الكامل'),
            controller: _nameController,
            icon: Icons.person_rounded,
          ),
          _buildTextField(
            label: AppLanguage.text(context, 'Age', 'العمر'),
            controller: _ageController,
            icon: Icons.cake_rounded,
            keyboardType: TextInputType.number,
          ),
          _buildSexSelector(),
          _buildDropdown(
            label: AppLanguage.text(context, 'Blood Type', 'فصيلة الدم'),
            value: _selectedBloodType,
            items: _bloodTypes,
            icon: Icons.bloodtype_rounded,
            onChanged: (v) => setState(() => _selectedBloodType = v),
          ),
          _buildDropdown(
            label: AppLanguage.text(context, 'Allergies', 'الحساسية'),
            value: _selectedAllergy,
            items: _allergies,
            icon: Icons.warning_amber_rounded,
            onChanged: (v) {
              setState(() {
                _selectedAllergy = v;
                _selectedAllergyDetail = null;
                _allergyOtherController.clear();
              });
            },
          ),
          if (_selectedAllergy != null && _selectedAllergy != 'None')
            _buildDropdown(
              label: AppLanguage.text(context, 'Allergy Details', 'تفاصيل الحساسية'),
              value: _selectedAllergyDetail,
              items: _allergyDetailsList(),
              icon: Icons.restaurant_rounded,
              onChanged: (v) {
                setState(() {
                  _selectedAllergyDetail = v;
                  _allergyOtherController.clear();
                });
              },
            ),
          if (_selectedAllergyDetail == 'Other')
            _buildTextField(
              label: AppLanguage.text(context, 'Write allergy or food name', 'اكتب الحساسية أو اسم الطعام'),
              controller: _allergyOtherController,
              icon: Icons.edit_note_rounded,
            ),
          _buildDropdown(
            label: AppLanguage.text(context, 'Medical Conditions', 'الأمراض'),
            value: _selectedCondition,
            items: _conditions,
            icon: Icons.medical_services_rounded,
            onChanged: (v) {
              setState(() {
                _selectedCondition = v;
                _selectedConditionDetail = null;
                _conditionOtherController.clear();
              });
            },
          ),
          if (_selectedCondition != null && _selectedCondition != 'None')
            _buildDropdown(
              label: AppLanguage.text(context, 'Condition Details', 'تفاصيل المرض'),
              value: _selectedConditionDetail,
              items: _conditionDetails,
              icon: Icons.monitor_heart_rounded,
              onChanged: (v) {
                setState(() {
                  _selectedConditionDetail = v;
                  _conditionOtherController.clear();
                });
              },
            ),
          if (_selectedConditionDetail == 'Other')
            _buildTextField(
              label: AppLanguage.text(context, 'Write condition details', 'اكتب تفاصيل المرض'),
              controller: _conditionOtherController,
              icon: Icons.edit_note_rounded,
            ),
          _buildDropdown(
            label: AppLanguage.text(context, 'Medications', 'الأدوية'),
            value: _selectedMedication,
            items: _medications,
            icon: Icons.medication_rounded,
            onChanged: (v) {
              setState(() {
                _selectedMedication = v;
                _selectedMedicationDetail = null;
                _medicationOtherController.clear();
              });
            },
          ),
          if (_selectedMedication != null && _selectedMedication != 'None')
            _buildDropdown(
              label: AppLanguage.text(context, 'Medication Details', 'تفاصيل الدواء'),
              value: _selectedMedicationDetail,
              items: _medicationDetails,
              icon: Icons.local_pharmacy_rounded,
              onChanged: (v) {
                setState(() {
                  _selectedMedicationDetail = v;
                  _medicationOtherController.clear();
                });
              },
            ),
          if (_selectedMedicationDetail == 'Other')
            _buildTextField(
              label: AppLanguage.text(context, 'Write medication name', 'اكتب اسم الدواء'),
              controller: _medicationOtherController,
              icon: Icons.edit_note_rounded,
            ),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: _isSaving ? null : _saveProfile,
              icon: _isSaving
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
                  : Icon(Icons.save_rounded, color: Colors.white),
              label: Text(
                _isSaving ? AppLanguage.text(context, 'Saving...', 'جاري الحفظ...') : AppLanguage.text(context, 'Save Changes', 'حفظ التغييرات'),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
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
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  AppLanguage.text(context, 'Questionnaire Data', 'بيانات الاستبيان'),
                  style: TextStyle(
                    color: primary,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
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
            title: 'Conditions',
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
              style: TextStyle(
                color: textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: textDark,
                fontWeight: FontWeight.bold,
                height: 1.4,
              ),
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
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: primary),
          filled: true,
          fillColor: background,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<Map<String, String>> items,
    required IconData icon,
    required Function(String?) onChanged,
  }) {
    final safeValue = value != null && _containsValue(items, value)
        ? value
        : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<String>(
        value: safeValue,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: primary),
          filled: true,
          fillColor: background,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        items: items.map((item) {
          final en = item['en']!;
          return DropdownMenuItem<String>(
            value: en,
            child: Text(
              AppLanguage.isArabicContext(context)
                  ? (item['ar'] ?? en)
                  : en,
            ),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildSexSelector() {
    const allowedValues = ['Male', 'Female'];
    final safeValue = allowedValues.contains(_selectedSex)
        ? _selectedSex
        : 'Male';

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<String>(
        value: safeValue,
        decoration: InputDecoration(
          labelText: AppLanguage.text(context, 'Sex', 'الجنس'),
          prefixIcon: Icon(Icons.wc_rounded, color: primary),
          filled: true,
          fillColor: background,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        items: [
          DropdownMenuItem(
            value: 'Male',
            child: Text(AppLanguage.text(context, 'Male', 'ذكر')),
          ),
          DropdownMenuItem(
            value: 'Female',
            child: Text(AppLanguage.text(context, 'Female', 'أنثى')),
          ),
        ],
        onChanged: (value) {
          if (value == null) return;
          setState(() => _selectedSex = value);
        },
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
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
