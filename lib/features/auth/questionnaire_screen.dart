import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../../core/database/app_database.dart';
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

  bool isArabic = false;
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

  final genders = [
    {'en': 'Male', 'ar': 'ذكر'},
    {'en': 'Female', 'ar': 'أنثى'},
  ];

  final bloodTypes = [
    {'en': 'A+', 'ar': 'A+'},
    {'en': 'A-', 'ar': 'A-'},
    {'en': 'B+', 'ar': 'B+'},
    {'en': 'B-', 'ar': 'B-'},
    {'en': 'AB+', 'ar': 'AB+'},
    {'en': 'AB-', 'ar': 'AB-'},
    {'en': 'O+', 'ar': 'O+'},
    {'en': 'O-', 'ar': 'O-'},
  ];

  final allergies = [
    {'en': 'None', 'ar': 'لا يوجد'},
    {'en': 'Food Allergy', 'ar': 'حساسية طعام'},
    {'en': 'Medication Allergy', 'ar': 'حساسية أدوية'},
    {'en': 'Insect Allergy', 'ar': 'حساسية حشرات'},
    {'en': 'Other', 'ar': 'أخرى'},
  ];

  final foodAllergyDetails = [
    {'en': 'Fish', 'ar': 'سمك'},
    {'en': 'Milk', 'ar': 'حليب'},
    {'en': 'Eggs', 'ar': 'بيض'},
    {'en': 'Peanuts', 'ar': 'فول سوداني'},
    {'en': 'Wheat', 'ar': 'قمح'},
    {'en': 'Other', 'ar': 'أخرى'},
  ];

  final allergyOtherDetails = [
    {'en': 'Dust', 'ar': 'غبار'},
    {'en': 'Pollen', 'ar': 'حبوب لقاح'},
    {'en': 'Animal Hair', 'ar': 'شعر الحيوانات'},
    {'en': 'Latex', 'ar': 'لاتكس'},
    {'en': 'Perfume', 'ar': 'عطور'},
    {'en': 'Other', 'ar': 'أخرى'},
  ];

  final conditions = [
    {'en': 'None', 'ar': 'لا يوجد'},
    {'en': 'Asthma', 'ar': 'ربو'},
    {'en': 'Diabetes', 'ar': 'سكري'},
    {'en': 'Heart Disease', 'ar': 'مرض قلب'},
    {'en': 'High Blood Pressure', 'ar': 'ضغط مرتفع'},
    {'en': 'Other', 'ar': 'أخرى'},
  ];

  final conditionDetails = [
    {'en': 'Mild', 'ar': 'خفيف'},
    {'en': 'Moderate', 'ar': 'متوسط'},
    {'en': 'Severe', 'ar': 'شديد'},
    {'en': 'Under Treatment', 'ar': 'تحت العلاج'},
    {'en': 'No Details', 'ar': 'لا توجد تفاصيل'},
    {'en': 'Other', 'ar': 'أخرى'},
  ];

  final medications = [
    {'en': 'None', 'ar': 'لا يوجد'},
    {'en': 'Daily Medication', 'ar': 'دواء يومي'},
    {'en': 'Emergency Medication', 'ar': 'دواء طوارئ'},
    {'en': 'Other', 'ar': 'أخرى'},
  ];

  final medicationDetails = [
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
    nameCtrl.text = widget.name;
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

    if (picked != null) {
      setState(() {
        selectedDob = picked;
        dobCtrl.text =
        '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _detectCountryFromLocation() async {
    setState(() => isLoadingLocation = true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        _showSnack(
          isArabic
              ? 'فعّل خدمة الموقع لتحديد الدولة'
              : 'Enable location service to detect country',
          isError: true,
        );
        setState(() => isLoadingLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showSnack(
          isArabic
              ? 'الموقع مطلوب لإكمال التسجيل'
              : 'Location permission is required to continue',
          isError: true,
        );
        setState(() => isLoadingLocation = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      final country = placemarks.isNotEmpty
          ? (placemarks.first.country ?? '')
          : '';

      setState(() {
        countryCtrl.text = country.isEmpty ? 'Unknown' : country;
        isLoadingLocation = false;
      });
    } catch (e) {
      setState(() => isLoadingLocation = false);

      _showSnack(
        isArabic
            ? 'تعذر تحديد الدولة من الموقع'
            : 'Could not detect country from location',
        isError: true,
      );
    }
  }

  Future<void> _finish() async {
    if (nameCtrl.text.trim().isEmpty ||
        selectedDob == null ||
        selectedGender == null ||
        selectedBloodType == null ||
        selectedAllergy == null ||
        selectedCondition == null ||
        selectedMedication == null ||
        countryCtrl.text.trim().isEmpty ||
        countryCtrl.text.trim() == 'Unknown') {
      _showSnack(
        isArabic
            ? 'عبئ جميع الحقول المطلوبة وتأكد من تفعيل الموقع'
            : 'Fill all required fields and enable location',
        isError: true,
      );
      return;
    }

    if (selectedAllergy != null &&
        selectedAllergy != 'None' &&
        selectedAllergyDetail == null) {
      _showSnack(
        isArabic ? 'اختر تفاصيل الحساسية' : 'Choose allergy details',
        isError: true,
      );
      return;
    }

    if (selectedAllergyDetail == 'Other' &&
        allergyOtherCtrl.text.trim().isEmpty) {
      _showSnack(
        isArabic ? 'اكتب تفاصيل الحساسية' : 'Write allergy details',
        isError: true,
      );
      return;
    }

    if (selectedCondition != null &&
        selectedCondition != 'None' &&
        selectedConditionDetail == null) {
      _showSnack(
        isArabic ? 'اختر تفاصيل المرض' : 'Choose disease details',
        isError: true,
      );
      return;
    }

    if (selectedConditionDetail == 'Other' &&
        conditionOtherCtrl.text.trim().isEmpty) {
      _showSnack(
        isArabic ? 'اكتب تفاصيل المرض' : 'Write disease details',
        isError: true,
      );
      return;
    }

    if (selectedMedication != null &&
        selectedMedication != 'None' &&
        selectedMedicationDetail == null) {
      _showSnack(
        isArabic ? 'اختر تفاصيل الدواء' : 'Choose medication details',
        isError: true,
      );
      return;
    }

    if (selectedMedicationDetail == 'Other' &&
        medicationOtherCtrl.text.trim().isEmpty) {
      _showSnack(
        isArabic ? 'اكتب اسم الدواء' : 'Write medication name',
        isError: true,
      );
      return;
    }

    setState(() => isSaving = true);

    final age = _calculateAge(selectedDob!);

    final allergyValue = selectedAllergy == 'None'
        ? 'None'
        : selectedAllergyDetail == 'Other'
        ? '$selectedAllergy: ${allergyOtherCtrl.text.trim()}'
        : '$selectedAllergy: $selectedAllergyDetail';

    final conditionValue = selectedCondition == 'None'
        ? 'None'
        : selectedConditionDetail == 'Other'
        ? '$selectedCondition: ${conditionOtherCtrl.text.trim()}'
        : '$selectedCondition: $selectedConditionDetail';

    final medicationValue = selectedMedication == 'None'
        ? 'None'
        : selectedMedicationDetail == 'Other'
        ? '$selectedMedication: ${medicationOtherCtrl.text.trim()}'
        : '$selectedMedication: $selectedMedicationDetail';

    await AppDatabase.instance.saveProfile({
      'full_name': nameCtrl.text.trim(),
      'age': age,
      'sex': selectedGender,
      'blood_type': selectedBloodType,
      'allergies': allergyValue,
      'conditions': conditionValue,
      'medications': medicationValue,
      'notes': notesCtrl.text.trim(),
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
      MaterialPageRoute(
        builder: (_) => const HomeScreen(),
      ),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor:
        isError ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
      ),
    );
  }

  List<Map<String, String>> _allergyDetailsList() {
    if (selectedAllergy == 'Food Allergy') {
      return foodAllergyDetails;
    }
    return allergyOtherDetails;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: Text(
            isArabic ? 'المعلومات الطبية' : 'Medical Information',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: const Color(0xFF2563EB),
          centerTitle: true,
          actions: [
            TextButton(
              onPressed: () => setState(() => isArabic = !isArabic),
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
                label: isArabic ? 'الاسم الكامل' : 'Full Name',
                controller: nameCtrl,
                icon: Icons.person,
              ),

              _dateField(),

              _dropdown(
                label: isArabic ? 'الجنس' : 'Gender',
                value: selectedGender,
                items: genders,
                icon: Icons.wc,
                onChanged: (v) => setState(() => selectedGender = v),
              ),

              _dropdown(
                label: isArabic ? 'فصيلة الدم' : 'Blood Type',
                value: selectedBloodType,
                items: bloodTypes,
                icon: Icons.bloodtype,
                onChanged: (v) => setState(() => selectedBloodType = v),
              ),

              _dropdown(
                label: isArabic ? 'الحساسية' : 'Allergies',
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
                  label: isArabic ? 'تفاصيل الحساسية' : 'Allergy Details',
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
                  label: isArabic
                      ? 'اكتب اسم الحساسية أو الطعام'
                      : 'Write allergy or food name',
                  controller: allergyOtherCtrl,
                  icon: Icons.edit_note,
                ),

              _dropdown(
                label: isArabic ? 'الأمراض المزمنة' : 'Medical Conditions',
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
                  label: isArabic ? 'تفاصيل المرض' : 'Disease Details',
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
                  label: isArabic
                      ? 'اكتب تفاصيل المرض'
                      : 'Write disease details',
                  controller: conditionOtherCtrl,
                  icon: Icons.edit_note,
                ),

              _dropdown(
                label: isArabic ? 'الأدوية' : 'Medications',
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
                  label: isArabic ? 'تفاصيل الدواء' : 'Medication Details',
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
                  label:
                  isArabic ? 'اكتب اسم الدواء' : 'Write medication name',
                  controller: medicationOtherCtrl,
                  icon: Icons.edit_note,
                ),

              _locationField(),

              _textField(
                label: isArabic ? 'ملاحظات' : 'Notes',
                controller: notesCtrl,
                icon: Icons.note_alt,
                maxLines: 3,
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: isSaving ? null : _finish,
                  child: Text(
                    isSaving
                        ? (isArabic ? 'جاري الحفظ...' : 'Saving...')
                        : (isArabic ? 'إنهاء' : 'Finish'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
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

  Widget _textField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        decoration: InputDecoration(
          hintText: label,
          prefixIcon: Icon(icon),
          filled: true,
          fillColor: const Color(0xFFF1F5F9),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }

  Widget _dateField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: dobCtrl,
        readOnly: true,
        onTap: _pickDate,
        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        decoration: InputDecoration(
          hintText: isArabic ? 'تاريخ الميلاد' : 'Date of Birth',
          prefixIcon: const Icon(Icons.calendar_month),
          suffixIcon: const Icon(Icons.arrow_drop_down),
          filled: true,
          fillColor: const Color(0xFFF1F5F9),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }

  Widget _locationField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: countryCtrl,
        readOnly: true,
        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        decoration: InputDecoration(
          hintText: isArabic ? 'الدولة من الموقع' : 'Country from Location',
          prefixIcon: isLoadingLocation
              ? const Padding(
            padding: EdgeInsets.all(12),
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
              : const Icon(Icons.location_on),
          suffixIcon: IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _detectCountryFromLocation,
          ),
          filled: true,
          fillColor: const Color(0xFFF1F5F9),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }

  Widget _dropdown({
    required String label,
    required String? value,
    required List<Map<String, String>> items,
    required IconData icon,
    required Function(String?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          hintText: label,
          prefixIcon: Icon(icon),
          filled: true,
          fillColor: const Color(0xFFF1F5F9),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        items: items.map((item) {
          final en = item['en']!;
          final ar = item['ar']!;

          return DropdownMenuItem(
            value: en,
            child: Text(isArabic ? ar : en),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}