import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  bool isArabic = false;
  bool isSaving = false;

  DateTime? selectedDob;

  String? selectedGender;
  String? selectedBloodType;
  String? selectedAllergy;
  String? selectedCondition;
  String? selectedMedication;
  String? selectedCountry;

  final genders = ['Male', 'Female'];
  final bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
  final allergies = ['None', 'Food Allergy', 'Medication Allergy', 'Insect Allergy', 'Other'];
  final conditions = ['None', 'Asthma', 'Diabetes', 'Heart Disease', 'High Blood Pressure', 'Other'];
  final medications = ['None', 'Daily Medication', 'Emergency Medication', 'Other'];
  final countries = ['Jordan', 'Saudi Arabia', 'UAE', 'Egypt', 'Other'];

  @override
  void initState() {
    super.initState();
    nameCtrl.text = widget.name;
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    dobCtrl.dispose();
    notesCtrl.dispose();
    super.dispose();
  }

  int _calculateAge(DateTime dob) {
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
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
        dobCtrl.text = '${picked.year}-${picked.month}-${picked.day}';
      });
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
        selectedCountry == null) {
      _showSnack(
        isArabic ? 'عبئ جميع الحقول المطلوبة' : 'Fill all required fields',
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
      'allergies': selectedAllergy,
      'conditions': selectedCondition,
      'medications': selectedMedication,
      'notes': notesCtrl.text.trim(),
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setBool('isGuest', false);
    await prefs.setBool('profileCompleted', true);
    await prefs.setString('userEmail', widget.email);
    await prefs.setString('registeredName', nameCtrl.text.trim());
    await prefs.setString('birthDate', dobCtrl.text.trim());
    await prefs.setString('country', selectedCountry!);

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor:
        isError ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
      ),
    );
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
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF2563EB),
          centerTitle: true,
          actions: [
            TextButton(
              onPressed: () => setState(() => isArabic = !isArabic),
              child: Text(
                isArabic ? 'English' : 'العربية',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                onChanged: (v) => setState(() => selectedAllergy = v),
              ),

              _dropdown(
                label: isArabic ? 'الأمراض المزمنة' : 'Medical Conditions',
                value: selectedCondition,
                items: conditions,
                icon: Icons.medical_services,
                onChanged: (v) => setState(() => selectedCondition = v),
              ),

              _dropdown(
                label: isArabic ? 'الأدوية' : 'Medications',
                value: selectedMedication,
                items: medications,
                icon: Icons.medication,
                onChanged: (v) => setState(() => selectedMedication = v),
              ),

              _dropdown(
                label: isArabic ? 'الدولة' : 'Country',
                value: selectedCountry,
                items: countries,
                icon: Icons.public,
                onChanged: (v) => setState(() => selectedCountry = v),
              ),

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
                    style: const TextStyle(color: Colors.white, fontSize: 18),
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

  Widget _dropdown({
    required String label,
    required String? value,
    required List<String> items,
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
          return DropdownMenuItem(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}