import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_colors.dart';
import '../../core/database/app_database.dart';
import '../../core/language/app_language.dart';
import '../../core/network/auth_service.dart';
import '../../core/network/sync_service.dart';
import '../home/home_screen.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _pageController = PageController();

  int currentPage = 0;
  bool isSaving = false;
  bool isLoadingLocation = false;
  bool showPassword = false;
  bool showConfirmPassword = false;

  final _firstCtrl = TextEditingController();
  final _middleCtrl = TextEditingController();
  final _lastCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  final dobCtrl = TextEditingController();
  final notesCtrl = TextEditingController();
  final allergyOtherCtrl = TextEditingController();
  final conditionOtherCtrl = TextEditingController();
  final medicationOtherCtrl = TextEditingController();
  final countryCtrl = TextEditingController(text: 'Jordan');

  DateTime? selectedDob;
  String? selectedGender;
  String? selectedBloodType;
  final Set<String> selectedAllergies = {};
  String? selectedCondition;
  String? selectedConditionDetail;
  String? selectedMedication;
  String? selectedMedicationDetail;
  String? selectedConditionSubDetail;
  String? selectedMedicationSubDetail;

  final Set<String> selectedAllergyDetails = {};
  final Map<String, Set<String>> selectedAllergySubDetailsMap = {};
  final Set<String> selectedConditionDetails = {};
  final Set<String> selectedConditionSubDetails = {};
  final Set<String> selectedMedicationDetails = {};
  final Set<String> selectedMedicationSubDetails = {};

  String _selectedThemeColor = 'blue';

  static const Color danger = Color(0xFFDC2626);
  static const Color success = Color(0xFF16A34A);
  static const Color background = Color(0xFFF8FAFC);

  Color get primary => _themeColor(_selectedThemeColor);

  Color _themeColor(String value) {
    switch (value) {
      case 'orange':
        return AppColors.orange;
      case 'purple':
        return AppColors.purple;
      case 'blue':
      default:
        return AppColors.blue;
    }
  }

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
  ];

  final foodAllergyDetails = const [
    {'en': 'Fish', 'ar': 'سمك'},
    {'en': 'Milk', 'ar': 'حليب'},
    {'en': 'Eggs', 'ar': 'بيض'},
    {'en': 'Peanuts', 'ar': 'فول سوداني'},
    {'en': 'Wheat', 'ar': 'قمح'},
  ];

  final allergySubDetails = const <String, List<Map<String, String>>>{
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
  };

  final allergyOtherSubDetails = const <String, List<Map<String, String>>>{
    'Dust': [
      {'en': 'House Dust', 'ar': 'غبار المنزل'},
      {'en': 'Street Dust', 'ar': 'غبار الشارع'},
    ],
    'Pollen': [
      {'en': 'Spring Pollen', 'ar': 'حبوب لقاح الربيع'},
      {'en': 'Tree Pollen', 'ar': 'حبوب لقاح الأشجار'},
    ],
  };

  final allergyOtherDetails = const [
    {'en': 'Dust', 'ar': 'غبار'},
    {'en': 'Pollen', 'ar': 'حبوب لقاح'},
    {'en': 'Animal Hair', 'ar': 'شعر الحيوانات'},
    {'en': 'Latex', 'ar': 'لاتكس'},
    {'en': 'Perfume', 'ar': 'عطور'},
  ];

  final conditions = const [
    {'en': 'None', 'ar': 'لا يوجد'},
    {'en': 'Asthma', 'ar': 'ربو'},
    {'en': 'Diabetes', 'ar': 'سكري'},
    {'en': 'Heart Disease', 'ar': 'مرض قلب'},
    {'en': 'High Blood Pressure', 'ar': 'ضغط مرتفع'},
  ];

  final conditionDetails = const [
    {'en': 'Mild', 'ar': 'خفيف'},
    {'en': 'Moderate', 'ar': 'متوسط'},
    {'en': 'Severe', 'ar': 'شديد'},
    {'en': 'Under Treatment', 'ar': 'تحت العلاج'},
    {'en': 'No Details', 'ar': 'لا توجد تفاصيل'},
  ];

  final conditionSubDetails = const <String, List<Map<String, String>>>{
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

  final medications = const [
    {'en': 'None', 'ar': 'لا يوجد'},
    {'en': 'Daily Medication', 'ar': 'دواء يومي'},
    {'en': 'Emergency Medication', 'ar': 'دواء طوارئ'},
  ];

  final medicationDetails = const [
    {'en': 'Inhaler', 'ar': 'بخاخ'},
    {'en': 'Insulin', 'ar': 'إنسولين'},
    {'en': 'Blood Pressure Pills', 'ar': 'حبوب ضغط'},
    {'en': 'Heart Medication', 'ar': 'دواء قلب'},
    {'en': 'Painkiller', 'ar': 'مسكن'},
  ];

  final medicationSubDetails = const <String, List<Map<String, String>>>{
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
    _detectCountryFromLocation();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _firstCtrl.dispose();
    _middleCtrl.dispose();
    _lastCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _phoneCtrl.dispose();
    dobCtrl.dispose();
    notesCtrl.dispose();
    allergyOtherCtrl.dispose();
    conditionOtherCtrl.dispose();
    medicationOtherCtrl.dispose();
    countryCtrl.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) => RegExp(r'^[A-Za-z0-9._%+-]+@gmail\.com$').hasMatch(email);

  bool _isValidPassword(String password) {
    return RegExp(r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[@$!%*#?&])[A-Za-z\d@$!%*#?&]{8,}$').hasMatch(password);
  }

  bool _isValidPhone(String phone) => RegExp(r'^07[0-9]{8}$').hasMatch(phone);

  void _showSnack(String msg, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: isError ? danger : success),
    );
  }

  bool _validateCurrentPage() {
    final isArabic = AppLanguage.isArabicContext(context);

    if (currentPage == 0) return true;

    if (currentPage == 1) {
      if (_firstCtrl.text.trim().isEmpty || _middleCtrl.text.trim().isEmpty || _lastCtrl.text.trim().isEmpty) {
        _showSnack(isArabic ? 'عبّئ الاسم كامل' : 'Fill your full name');
        return false;
      }
    }

    if (currentPage == 2) {
      final email = _emailCtrl.text.trim().toLowerCase();
      if (email.isEmpty) {
        _showSnack(isArabic ? 'أدخل الإيميل' : 'Enter your email');
        return false;
      }
      if (!_isValidEmail(email)) {
        _showSnack(isArabic ? 'الإيميل يجب أن يكون Gmail صحيح' : 'Email must be a valid Gmail');
        return false;
      }
    }

    if (currentPage == 3) {
      final password = _passwordCtrl.text.trim();
      final confirm = _confirmPasswordCtrl.text.trim();

      if (password.isEmpty || confirm.isEmpty) {
        _showSnack(
          isArabic
              ? 'أدخل كلمة المرور وتأكيدها'
              : 'Enter and confirm password',
        );
        return false;
      }

      if (password.length < 8) {
        _showSnack(
          isArabic
              ? 'كلمة المرور يجب أن تكون 8 أحرف أو أكثر'
              : 'Password must be at least 8 characters',
        );
        return false;
      }

      if (!RegExp(r'[A-Z]').hasMatch(password)) {
        _showSnack(
          isArabic
              ? 'يجب أن تحتوي كلمة المرور على حرف كبير'
              : 'Password must contain an uppercase letter',
        );
        return false;
      }

      if (!RegExp(r'[a-z]').hasMatch(password)) {
        _showSnack(
          isArabic
              ? 'يجب أن تحتوي كلمة المرور على حرف صغير'
              : 'Password must contain a lowercase letter',
        );
        return false;
      }

      if (!RegExp(r'[0-9]').hasMatch(password)) {
        _showSnack(
          isArabic
              ? 'يجب أن تحتوي كلمة المرور على رقم'
              : 'Password must contain a number',
        );
        return false;
      }

      if (!RegExp(r'[@$!%*?&.#_\-]').hasMatch(password)) {
        _showSnack(
          isArabic
              ? 'يجب أن تحتوي كلمة المرور على رمز خاص'
              : 'Password must contain a special character',
        );
        return false;
      }

      if (password != confirm) {
        _showSnack(
          isArabic
              ? 'كلمة المرور غير متطابقة'
              : 'Passwords do not match',
        );
        return false;
      }
    }


    if (currentPage == 4) {
      final phone = _phoneCtrl.text.trim();
      if (phone.isEmpty) {
        _showSnack(isArabic ? 'أدخل رقم الهاتف' : 'Enter phone number');
        return false;
      }
      if (!_isValidPhone(phone)) {
        _showSnack(isArabic ? 'رقم الهاتف الأردني لازم يبدأ بـ 07 ويتكون من 10 أرقام' : 'Jordan phone number must start with 07 and be exactly 10 digits');
        return false;
      }
    }

    if (currentPage == 5) return selectedDob != null ? true : _missing(AppLanguage.text(context, 'Choose date of birth', 'اختر تاريخ الميلاد'));
    if (currentPage == 6) return selectedGender != null ? true : _missing(AppLanguage.text(context, 'Choose gender', 'اختر الجنس'));
    if (currentPage == 7) return selectedBloodType != null ? true : _missing(AppLanguage.text(context, 'Choose blood type', 'اختر فصيلة الدم'));
    if (currentPage == 8) return _validateAllergyPage();
    if (currentPage == 9) return _validateConditionPage();
    if (currentPage == 10) return _validateMedicationPage();
    if (currentPage == 11) return countryCtrl.text.trim().isNotEmpty ? true : _missing(AppLanguage.text(context, 'Choose your country', 'اختر الدولة'));
    return true;
  }

  bool _missing(String message) {
    _showSnack(message);
    return false;
  }

  bool _validateAllergyPage() {
    if (selectedAllergies.isEmpty) {
      return _missing(AppLanguage.text(context, 'Choose allergies', 'اختر الحساسية'));
    }

    if (selectedAllergies.contains('None')) return true;

    final selectedNeedsDetails = selectedAllergies.any((item) => item != 'None');
    if (selectedNeedsDetails && selectedAllergyDetails.isEmpty) {
      return _missing(AppLanguage.text(context, 'Choose allergy details', 'اختر تفاصيل الحساسية'));
    }

    return true;
  }

  bool _validateConditionPage() {
    if (selectedCondition == null) {
      return _missing(AppLanguage.text(context, 'Choose medical condition', 'اختر المرض'));
    }

    if (selectedCondition == 'None') return true;

    if (selectedCondition == 'Other') {
      return conditionOtherCtrl.text.trim().isNotEmpty
          ? true
          : _missing(AppLanguage.text(context, 'Write disease details', 'اكتب تفاصيل المرض'));
    }

    if (selectedConditionDetails.isEmpty) {
      return _missing(AppLanguage.text(context, 'Choose disease details', 'اختر تفاصيل المرض'));
    }

    if ((selectedConditionDetails.contains('Other') || selectedConditionSubDetails.contains('Other')) &&
        conditionOtherCtrl.text.trim().isEmpty) {
      return _missing(AppLanguage.text(context, 'Write disease details', 'اكتب تفاصيل المرض'));
    }

    return true;
  }

  bool _validateMedicationPage() {
    if (selectedMedication == null) {
      return _missing(AppLanguage.text(context, 'Choose medication', 'اختر الدواء'));
    }

    if (selectedMedication == 'None') return true;

    if (selectedMedication == 'Other') {
      return medicationOtherCtrl.text.trim().isNotEmpty
          ? true
          : _missing(AppLanguage.text(context, 'Write medication name', 'اكتب اسم الدواء'));
    }

    if (selectedMedicationDetails.isEmpty) {
      return _missing(AppLanguage.text(context, 'Choose medication details', 'اختر تفاصيل الدواء'));
    }

    if ((selectedMedicationDetails.contains('Other') || selectedMedicationSubDetails.contains('Other')) &&
        medicationOtherCtrl.text.trim().isEmpty) {
      return _missing(AppLanguage.text(context, 'Write medication name', 'اكتب اسم الدواء'));
    }

    return true;
  }

  bool _validateMedicalPage() {
    if (selectedDob == null ||
        selectedGender == null ||
        selectedBloodType == null ||
        selectedAllergies.isEmpty ||
        selectedCondition == null ||
        selectedMedication == null ||
        countryCtrl.text.trim().isEmpty) {
      _showSnack(AppLanguage.text(context, 'Fill all medical fields and choose your country', 'عبئ كل المعلومات الطبية واختر الدولة'));
      return false;
    }

    return _validateAllergyPage() && _validateConditionPage() && _validateMedicationPage();
  }

  void _nextPage() {
    if (!_validateCurrentPage()) return;
    if (currentPage < 11) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      _finishSignup();
    }
  }

  Future<void> _finishSignup() async {
    if (isSaving) return;
    setState(() => isSaving = true);

    try {
      final first = _firstCtrl.text.trim();
      final middle = _middleCtrl.text.trim();
      final last = _lastCtrl.text.trim();
      final fullName = '$first $middle $last'.replaceAll(RegExp(r'\s+'), ' ').trim();
      final email = _emailCtrl.text.trim().toLowerCase();
      final password = _passwordCtrl.text.trim();
      final phone = _phoneCtrl.text.trim();

      final existingUser = await AppDatabase.instance.getUserByEmail(email);
      if (existingUser != null) {
        setState(() => isSaving = false);
        _showSnack(AppLanguage.text(context, 'This email is already registered on this device', 'هذا الإيميل مسجل مسبقاً على هذا الجهاز'));
        return;
      }

      final serverResult = await AuthService.register(
        fullName: fullName,
        email: email,
        phone: phone,
        password: password,
      );

      if (serverResult.serverReached && !serverResult.ok) {
        setState(() => isSaving = false);
        _showSnack(serverResult.message, isError: true);
        return;
      }

      await AppDatabase.instance.insertUser(fullName: fullName, email: email, phone: phone, password: password);
      if (serverResult.serverReached && serverResult.ok) {
        await AppDatabase.instance.markUserSynced(email);
      }

      await AppColors.changeTheme(_selectedThemeColor);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isGuest', false);
      await prefs.setBool('isLoggedIn', true);
      await prefs.setBool('profileCompleted', true);
      await prefs.setString('userEmail', email);
      await prefs.setString('registeredName', fullName);

      await _saveMedicalInformation(fullName, email);

      // Upload all saved signup/profile/settings data now when XAMPP is reachable.
      // If offline, SyncService keeps local data and silently retries from Home/History later.
      await SyncService.syncProfile();
      await SyncService.syncIncidents();

      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    } catch (e) {
      if (mounted) setState(() => isSaving = false);
      _showSnack('Signup error: $e', isError: true);
    }
  }

  Future<void> _saveMedicalInformation(String fullName, String email) async {
    final age = _calculateAge(selectedDob!);

    await AppDatabase.instance.saveProfile({
      'full_name': fullName,
      'age': age,
      'sex': selectedGender,
      'blood_type': selectedBloodType,
      'allergies': _buildAllergyGroupedValue(),
      'conditions': _buildMultiGroupedValue(selectedCondition, selectedConditionDetails, conditionOtherCtrl, selectedConditionSubDetails),
      'medications': _buildMultiGroupedValue(selectedMedication, selectedMedicationDetails, medicationOtherCtrl, selectedMedicationSubDetails),
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
    await prefs.setString('userEmail', email);
    await prefs.setString('birthDate', dobCtrl.text.trim());
    await prefs.setString('country', countryCtrl.text.trim());
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primary,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: primary),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked == null) return;
    setState(() {
      selectedDob = picked;
      dobCtrl.text = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
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
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() => isLoadingLocation = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      final detectedCountry = placemarks.isNotEmpty ? (placemarks.first.country ?? '') : '';

      if (!mounted) return;
      setState(() {
        countryCtrl.text = _countryValueFromDetectedName(detectedCountry);
        isLoadingLocation = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => isLoadingLocation = false);
    }
  }

  int _calculateAge(DateTime dob) {
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) age--;
    return age;
  }

  String _countryValueFromDetectedName(String country) {
    final normalized = country.trim().toLowerCase();
    if (normalized.isEmpty) return countryCtrl.text.isEmpty ? 'Jordan' : countryCtrl.text;
    for (final item in countries) {
      final en = item['en']!.toLowerCase();
      final ar = item['ar']!;
      if (normalized == en || country == ar || normalized.contains(en)) return item['en']!;
    }
    if (normalized.contains('jordan')) return 'Jordan';
    if (normalized.contains('saudi')) return 'Saudi Arabia';
    if (normalized.contains('emirates') || normalized.contains('uae')) return 'United Arab Emirates';
    if (normalized.contains('palestine')) return 'Palestine';
    if (normalized.contains('egypt')) return 'Egypt';
    if (normalized.contains('iraq')) return 'Iraq';
    if (normalized.contains('syria')) return 'Syria';
    if (normalized.contains('lebanon')) return 'Lebanon';
    return 'Other';
  }

  Map<String, String> _selectedCountryInfo() {
    return countries.firstWhere((item) => item['en'] == countryCtrl.text.trim(), orElse: () => countries.first);
  }

  String _buildMultiGroupedValue(
      String? main,
      Set<String> details,
      TextEditingController otherController,
      Set<String> subDetails,
      ) {
    if (main == null || main == 'None') return 'None';

    final other = otherController.text.trim();
    if (main == 'Other') return other.isEmpty ? main : other;

    final cleanedDetails = details.where((item) => item != 'Other').toList();
    final cleanedSubDetails = subDetails.where((item) => item != 'Other').toList();

    final parts = <String>[];
    if (cleanedDetails.isNotEmpty) parts.add(cleanedDetails.join(', '));
    if (cleanedSubDetails.isNotEmpty) parts.add(cleanedSubDetails.join(', '));
    if ((details.contains('Other') || subDetails.contains('Other')) && other.isNotEmpty) parts.add(other);

    return parts.isEmpty ? main : '$main: ${parts.join(' - ')}';
  }

  List<Map<String, String>> _allergyDetailsForType(String type) {
    if (type == 'Food Allergy') return foodAllergyDetails;
    if (type == 'Medication Allergy') return medicationDetails;
    if (type == 'Insect Allergy' || type == 'Other') return allergyOtherDetails;
    return const [];
  }

  List<Map<String, String>> _allergySubDetailsFor(String parentKey) {
    return allergySubDetails[parentKey] ??
        allergyOtherSubDetails[parentKey] ??
        medicationSubDetails[parentKey] ??
        const [];
  }

  bool _hasSelectedAllergyOther() {
    if (selectedAllergies.contains('Other') || selectedAllergyDetails.contains('Other')) return true;
    for (final values in selectedAllergySubDetailsMap.values) {
      if (values.contains('Other')) return true;
    }
    return false;
  }

  void _removeAllergyDetailsForType(String type) {
    final details = _allergyDetailsForType(type).map((item) => item['en']!).toSet();
    for (final detail in details) {
      selectedAllergyDetails.remove(detail);
      selectedAllergySubDetailsMap.remove(detail);
    }
  }

  String _buildAllergyGroupedValue() {
    if (selectedAllergies.isEmpty || selectedAllergies.contains('None')) return 'None';

    final parts = <String>[];
    final otherText = allergyOtherCtrl.text.trim();

    for (final type in selectedAllergies) {
      if (type == 'None') continue;
      if (type == 'Other') {
        parts.add(otherText.isEmpty ? 'Other' : 'Other: $otherText');
        continue;
      }

      final detailsForType = _allergyDetailsForType(type).map((item) => item['en']!).toSet();
      final selectedDetailsForType = selectedAllergyDetails.where(detailsForType.contains).toList();

      if (selectedDetailsForType.isEmpty) {
        parts.add(type);
        continue;
      }

      final detailParts = <String>[];
      for (final detail in selectedDetailsForType) {
        if (detail == 'Other') {
          detailParts.add(otherText.isEmpty ? 'Other' : 'Other: $otherText');
          continue;
        }

        final subValues = selectedAllergySubDetailsMap[detail] ?? <String>{};
        final cleanedSubValues = subValues.where((item) => item != 'Other').toList();
        final hasOtherSub = subValues.contains('Other');

        if (cleanedSubValues.isEmpty && !hasOtherSub) {
          detailParts.add(detail);
        } else {
          final subTextParts = <String>[...cleanedSubValues];
          if (hasOtherSub && otherText.isNotEmpty) subTextParts.add(otherText);
          detailParts.add('$detail (${subTextParts.join(', ')})');
        }
      }

      parts.add('$type: ${detailParts.join(', ')}');
    }

    return parts.join(' | ');
  }

  List<Map<String, String>> _conditionSubDetailsList() {
    return conditionSubDetails[selectedCondition] ?? const [];
  }

  List<Map<String, String>> _medicationSubDetailsList() {
    return _mergedSubDetails(selectedMedicationDetails, medicationSubDetails);
  }

  List<Map<String, String>> _mergedSubDetails(
      Set<String> selectedItems,
      Map<String, List<Map<String, String>>> source,
      ) {
    final result = <Map<String, String>>[];
    final used = <String>{};

    for (final item in selectedItems) {
      for (final detail in source[item] ?? const <Map<String, String>>[]) {
        final key = detail['en'] ?? '';
        if (key.isNotEmpty && used.add(key)) {
          result.add(detail);
        }
      }
    }

    return result;
  }

  String _label(Map<String, String> item) {
    final isArabic = AppLanguage.isArabicContext(context);
    return isArabic ? item['ar']! : item['en']!;
  }


  bool _isCompactLayout(BuildContext context) {
    final media = MediaQuery.of(context);
    return media.orientation == Orientation.landscape || media.size.height < 720;
  }

  double _screenPadding(BuildContext context) => _isCompactLayout(context) ? 14 : 24;

  double _pageTopPadding(BuildContext context) => _isCompactLayout(context) ? 14 : 50;

  double _pageBottomPadding(BuildContext context) => _isCompactLayout(context) ? 12 : 24;

  double _titleFontSize(BuildContext context) => _isCompactLayout(context) ? 24 : 34;

  double _subtitleFontSize(BuildContext context) => _isCompactLayout(context) ? 14 : 17;

  double _contentGap(BuildContext context) => _isCompactLayout(context) ? 20 : 42;

  double _buttonHeight(BuildContext context) => _isCompactLayout(context) ? 48 : 60;

  double _buttonRadius(BuildContext context) => _isCompactLayout(context) ? 16 : 20;

  @override
  Widget build(BuildContext context) {
    final isArabic = AppLanguage.isArabicContext(context);
    final compactLayout = _isCompactLayout(context);
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final hideBottomActions = compactLayout && keyboardOpen;

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: background,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(_screenPadding(context)),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: isArabic ? Alignment.centerRight : Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                          ),
                          icon: Icon(Icons.arrow_back_ios_new, color: primary, size: 18),
                          label: Text(
                            AppLanguage.text(context, 'Cancel', 'إلغاء'),
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: primary, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          AppLanguage.text(context, 'Create Account', 'إنشاء حساب'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ),
                    const Expanded(child: SizedBox.shrink()),
                  ],
                ),
                SizedBox(height: _isCompactLayout(context) ? 6 : 12),
                LinearProgressIndicator(
                  value: (currentPage + 1) / 12,
                  borderRadius: BorderRadius.circular(20),
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade300,
                  color: primary,
                ),
                SizedBox(height: _isCompactLayout(context) ? 8 : 20),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (i) => setState(() => currentPage = i),
                    children: [
                      SignupColorStep(
                        selectedThemeColor: _selectedThemeColor,
                        primary: primary,
                        onChanged: (value) => setState(() => _selectedThemeColor = value),
                      ),
                      _page(
                        title: AppLanguage.text(context, 'Your Full Name', 'اسمك الكامل'),
                        subtitle: AppLanguage.text(context, 'Enter your full name', 'أدخل اسمك الكامل'),
                        children: [
                          _field(controller: _firstCtrl, hint: AppLanguage.text(context, 'First Name', 'الاسم الأول'), icon: Icons.person_outline),
                          _field(controller: _middleCtrl, hint: AppLanguage.text(context, 'Middle Name', 'الاسم الثاني'), icon: Icons.person_outline),
                          _field(controller: _lastCtrl, hint: AppLanguage.text(context, 'Last Name', 'الاسم الأخير'), icon: Icons.person_outline),
                        ],
                      ),
                      _page(
                        title: AppLanguage.text(context, 'Your Email', 'إيميلك'),
                        subtitle: AppLanguage.text(context, 'Use your Gmail account', 'استخدم حساب Gmail'),
                        children: [_field(controller: _emailCtrl, hint: 'example@gmail.com', icon: Icons.email_outlined, keyboard: TextInputType.emailAddress)],
                      ),
                      _page(
                        title: AppLanguage.text(context, 'Create Password', 'أنشئ كلمة مرور'),
                        subtitle: AppLanguage.text(context, 'Use a strong password', 'استخدم كلمة مرور قوية'),
                        children: [
                          _field(controller: _passwordCtrl, hint: AppLanguage.text(context, 'Password', 'كلمة المرور'), icon: Icons.lock_outline, obscure: !showPassword, suffixIcon: IconButton(icon: Icon(showPassword ? Icons.visibility_off : Icons.visibility, color: primary), onPressed: () => setState(() => showPassword = !showPassword))),
                          _field(controller: _confirmPasswordCtrl, hint: AppLanguage.text(context, 'Confirm Password', 'تأكيد كلمة المرور'), icon: Icons.lock_reset, obscure: !showConfirmPassword, suffixIcon: IconButton(icon: Icon(showConfirmPassword ? Icons.visibility_off : Icons.visibility, color: primary), onPressed: () => setState(() => showConfirmPassword = !showConfirmPassword))),
                        ],
                      ),
                      _page(
                        title: AppLanguage.text(context, 'Phone Number', 'رقم الهاتف'),
                        subtitle: AppLanguage.text(context, 'Used for password recovery', 'يستخدم لاسترجاع كلمة المرور'),
                        children: [_field(controller: _phoneCtrl, hint: '07XXXXXXXX', icon: Icons.phone_outlined, keyboard: TextInputType.phone, maxLength: 10, digitsOnly: true)],
                      ),
                      _page(
                        title: AppLanguage.text(context, 'Date of Birth', 'تاريخ الميلاد'),
                        subtitle: AppLanguage.text(context, 'Tell us your age for emergency info', 'أدخل تاريخ ميلادك لملف الطوارئ'),
                        children: [_dateField()],
                      ),
                      _page(
                        title: AppLanguage.text(context, 'Gender', 'الجنس'),
                        subtitle: AppLanguage.text(context, 'Choose one option', 'اختر خياراً واحداً'),
                        children: [_optionGrid(value: selectedGender, items: genders, icon: Icons.wc, onSelected: (v) => setState(() => selectedGender = v), columns: 2)],
                      ),
                      _page(
                        title: AppLanguage.text(context, 'Blood Type', 'فصيلة الدم'),
                        subtitle: AppLanguage.text(context, 'Important for emergency cases', 'مهم في حالات الطوارئ'),
                        children: [_optionGrid(value: selectedBloodType, items: bloodTypes, icon: Icons.bloodtype, onSelected: (v) => setState(() => selectedBloodType = v), columns: 4)],
                      ),
                      _page(
                        title: AppLanguage.text(context, 'Allergy Details', 'تفاصيل الحساسية'),
                        subtitle: AppLanguage.text(context, 'Choose your allergy and its details', 'اختر الحساسية وتفاصيلها'),
                        children: _allergyPageFields(),
                      ),
                      _page(
                        title: AppLanguage.text(context, 'Medical Conditions', 'الأمراض'),
                        subtitle: AppLanguage.text(context, 'Choose your medical condition details', 'اختر تفاصيل المرض'),
                        children: _conditionPageFields(),
                      ),
                      _page(
                        title: AppLanguage.text(context, 'Medications', 'الأدوية'),
                        subtitle: AppLanguage.text(context, 'Choose medication details', 'اختر تفاصيل الدواء'),
                        children: _medicationPageFields(),
                      ),
                      _page(
                        title: AppLanguage.text(context, 'Country & Notes', 'الدولة والملاحظات'),
                        subtitle: AppLanguage.text(context, 'Emergency numbers will be set by country', 'أرقام الطوارئ ستتغير حسب الدولة'),
                        children: [_countryDropdown(), _infoMessage(AppLanguage.text(context, 'Do you have any other conditions that were not mentioned?', 'هل يوجد عندك أي حالات أخرى لم تُذكر؟')), _textField(label: AppLanguage.text(context, 'Notes', 'ملاحظات'), controller: notesCtrl, icon: Icons.note_alt, maxLines: 3)],
                      ),
                    ],
                  ),
                ),
                if (!hideBottomActions) ...[
                  SizedBox(height: compactLayout ? 6 : 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: currentPage == 0 || isSaving ? null : () => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: primary,
                            side: BorderSide(color: primary, width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_buttonRadius(context))),
                            minimumSize: Size.fromHeight(_buttonHeight(context)),
                          ),
                          icon: const Icon(Icons.arrow_back),
                          label: Text(AppLanguage.text(context, 'BACK', 'رجوع'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: isSaving ? null : _nextPage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_buttonRadius(context))),
                            minimumSize: Size.fromHeight(_buttonHeight(context)),
                          ),
                          icon: Icon(currentPage == 11 ? Icons.check : Icons.arrow_forward, color: Colors.white),
                          label: isSaving
                              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Text(
                            currentPage == 11 ? AppLanguage.text(context, 'FINISH', 'إنهاء') : AppLanguage.text(context, 'NEXT', 'التالي'),
                            style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _allergyPageFields() {
    final activeTypes = selectedAllergies
        .where((item) => item != 'None')
        .toList();

    final rows = <Widget>[
      _medicalCircleSection(
        title: AppLanguage.text(context, 'Choose allergy type', 'اختر نوع الحساسية'),
        icon: Icons.warning_amber_rounded,
        child: _multiCircleGrid(
          selectedValues: selectedAllergies,
          items: allergies,
          icon: Icons.warning_amber_rounded,
          onToggle: (v) => setState(() {
            if (v == 'None') {
              selectedAllergies
                ..clear()
                ..add('None');
              selectedAllergyDetails.clear();
              selectedAllergySubDetailsMap.clear();
              allergyOtherCtrl.clear();
              return;
            }

            selectedAllergies.remove('None');

            if (selectedAllergies.contains(v)) {
              selectedAllergies.remove(v);
              _removeAllergyDetailsForType(v);
            } else {
              selectedAllergies.add(v);
            }
          }),
        ),
      ),
    ];

    for (final type in activeTypes) {
      final details = _allergyDetailsForType(type);
      if (details.isEmpty) continue;

      rows.add(
        _medicalCircleSection(
          title: AppLanguage.text(
            context,
            type == 'Food Allergy'
                ? 'Food allergy items'
                : type == 'Medication Allergy'
                ? 'Medication allergy items'
                : 'Insect allergy items',
            type == 'Food Allergy'
                ? 'اختيارات حساسية الطعام'
                : type == 'Medication Allergy'
                ? 'اختيارات حساسية الأدوية'
                : 'اختيارات حساسية الحشرات',
          ),
          icon: type == 'Food Allergy'
              ? Icons.restaurant_rounded
              : type == 'Medication Allergy'
              ? Icons.local_pharmacy_rounded
              : Icons.bug_report_rounded,
          child: _multiCircleGrid(
            selectedValues: selectedAllergyDetails,
            items: details,
            icon: type == 'Food Allergy'
                ? Icons.restaurant_rounded
                : type == 'Medication Allergy'
                ? Icons.local_pharmacy_rounded
                : Icons.bug_report_rounded,
            onToggle: (v) => setState(() {
              if (selectedAllergyDetails.contains(v)) {
                selectedAllergyDetails.remove(v);
                selectedAllergySubDetailsMap.remove(v);
              } else {
                selectedAllergyDetails.add(v);
              }
            }),
          ),
        ),
      );

      final detailsForType = details.map((item) => item['en']!).toSet();
      final selectedDetailsForType = selectedAllergyDetails
          .where((detail) => detailsForType.contains(detail))
          .toList();

      for (final detail in selectedDetailsForType) {
        final subItems = _allergySubDetailsFor(detail);
        if (subItems.isEmpty) continue;

        rows.add(
          _medicalCircleSection(
            title: AppLanguage.text(
              context,
              '$detail details',
              'تفاصيل $detail',
            ),
            icon: Icons.menu_open_rounded,
            child: _multiCircleGrid(
              selectedValues: selectedAllergySubDetailsMap[detail] ?? <String>{},
              items: subItems,
              icon: Icons.menu_open_rounded,
              small: true,
              onToggle: (v) => setState(() {
                final currentSet =
                selectedAllergySubDetailsMap.putIfAbsent(detail, () => <String>{});

                if (currentSet.contains(v)) {
                  currentSet.remove(v);
                } else {
                  currentSet.add(v);
                }

                if (currentSet.isEmpty) {
                  selectedAllergySubDetailsMap.remove(detail);
                }
              }),
            ),
          ),
        );
      }
    }

    return rows;
  }

  List<Widget> _conditionPageFields() {
    final subItems = _conditionSubDetailsList();

    return [
      _medicalCircleSection(
        title: AppLanguage.text(context, 'Choose condition type', 'اختر نوع المرض'),
        icon: Icons.medical_services_rounded,
        child: _singleCircleGrid(
          value: selectedCondition,
          items: conditions,
          icon: Icons.medical_services_rounded,
          large: true,
          onSelected: (v) => setState(() {
            selectedCondition = v;
            selectedConditionDetail = null;
            selectedConditionSubDetail = null;
            selectedConditionDetails.clear();
            selectedConditionSubDetails.clear();
            conditionOtherCtrl.clear();
          }),
        ),
      ),
      if (selectedCondition != null && selectedCondition != 'None' && selectedCondition != 'Other')
        _medicalCircleSection(
          title: AppLanguage.text(context, 'Choose condition level', 'اختر تفاصيل المرض'),
          icon: Icons.monitor_heart_rounded,
          child: _multiCircleGrid(
            selectedValues: selectedConditionDetails,
            items: conditionDetails,
            icon: Icons.monitor_heart_rounded,
            onToggle: (v) => setState(() {
              if (selectedConditionDetails.contains(v)) {
                selectedConditionDetails.remove(v);
              } else {
                selectedConditionDetails.add(v);
              }
            }),
          ),
        ),
      if (subItems.isNotEmpty && selectedCondition != null && selectedCondition != 'None' && selectedCondition != 'Other')
        _medicalCircleSection(
          title: AppLanguage.text(context, 'Choose more details', 'اختر تفاصيل أكثر'),
          icon: Icons.menu_open_rounded,
          child: _multiCircleGrid(
            selectedValues: selectedConditionSubDetails,
            items: subItems,
            icon: Icons.menu_open_rounded,
            small: true,
            onToggle: (v) => setState(() {
              if (selectedConditionSubDetails.contains(v)) {
                selectedConditionSubDetails.remove(v);
              } else {
                selectedConditionSubDetails.add(v);
              }
            }),
          ),
        ),
      if (selectedCondition == 'Other' ||
          selectedConditionDetails.contains('Other') ||
          selectedConditionSubDetails.contains('Other'))
        _textField(
          label: AppLanguage.text(context, 'Write disease details', 'اكتب تفاصيل المرض'),
          controller: conditionOtherCtrl,
          icon: Icons.edit_note,
        ),
    ];
  }

  List<Widget> _medicationPageFields() {
    final subItems = _medicationSubDetailsList();

    return [
      _medicalCircleSection(
        title: AppLanguage.text(context, 'Choose medication type', 'اختر نوع الدواء'),
        icon: Icons.medication_rounded,
        child: _singleCircleGrid(
          value: selectedMedication,
          items: medications,
          icon: Icons.medication_rounded,
          large: true,
          onSelected: (v) => setState(() {
            selectedMedication = v;
            selectedMedicationDetail = null;
            selectedMedicationSubDetail = null;
            selectedMedicationDetails.clear();
            selectedMedicationSubDetails.clear();
            medicationOtherCtrl.clear();
          }),
        ),
      ),
      if (selectedMedication != null && selectedMedication != 'None' && selectedMedication != 'Other')
        _medicalCircleSection(
          title: AppLanguage.text(context, 'Choose medication name', 'اختر اسم الدواء'),
          icon: Icons.local_pharmacy_rounded,
          child: _multiCircleGrid(
            selectedValues: selectedMedicationDetails,
            items: medicationDetails,
            icon: Icons.local_pharmacy_rounded,
            onToggle: (v) => setState(() {
              if (selectedMedicationDetails.contains(v)) {
                selectedMedicationDetails.remove(v);
                selectedMedicationSubDetails.removeWhere((sub) {
                  final related = medicationSubDetails[v] ?? const [];
                  return related.any((item) => item['en'] == sub);
                });
              } else {
                selectedMedicationDetails.add(v);
              }
            }),
          ),
        ),
      if (subItems.isNotEmpty)
        _medicalCircleSection(
          title: AppLanguage.text(context, 'Choose more details', 'اختر تفاصيل أكثر'),
          icon: Icons.menu_open_rounded,
          child: _multiCircleGrid(
            selectedValues: selectedMedicationSubDetails,
            items: subItems,
            icon: Icons.menu_open_rounded,
            small: true,
            onToggle: (v) => setState(() {
              if (selectedMedicationSubDetails.contains(v)) {
                selectedMedicationSubDetails.remove(v);
              } else {
                selectedMedicationSubDetails.add(v);
              }
            }),
          ),
        ),
      if (selectedMedication == 'Other' ||
          selectedMedicationDetails.contains('Other') ||
          selectedMedicationSubDetails.contains('Other'))
        _textField(
          label: AppLanguage.text(context, 'Write medication name', 'اكتب اسم الدواء'),
          controller: medicationOtherCtrl,
          icon: Icons.edit_note,
        ),
    ];
  }

  Widget _buildThemeColorPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppLanguage.text(context, 'Choose the app theme ', 'اختر سمة التطبيق'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 14),
        Row(children: [_colorOption('blue', AppColors.blue), const SizedBox(width: 14), _colorOption('orange', AppColors.orange), const SizedBox(width: 14), _colorOption('purple', AppColors.purple)]),
      ],
    );
  }

  Widget _colorOption(String value, Color color) {
    final isSelected = _selectedThemeColor == value;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedThemeColor = value);
      },
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: isSelected ? Colors.black : Colors.transparent, width: 3),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 12)],
        ),
        child: isSelected ? const Icon(Icons.check, color: Colors.white) : null,
      ),
    );
  }

  Widget _page({required String title, required String subtitle, required List<Widget> children}) {
    final topPadding = _pageTopPadding(context);
    final bottomPadding = _pageBottomPadding(context);
    final gap = _contentGap(context);
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Padding(
        padding: EdgeInsets.only(top: topPadding, bottom: bottomPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: _titleFontSize(context), fontWeight: FontWeight.w900, color: Colors.black)),
            const SizedBox(height: 12),
            Text(subtitle, style: TextStyle(fontSize: _subtitleFontSize(context), color: Colors.grey.shade600, height: 1.4)),
            SizedBox(height: gap),
            ...children.map((e) => Padding(padding: EdgeInsets.only(bottom: _isCompactLayout(context) ? 10 : 16), child: e)),
          ],
        ),
      ),
    );
  }

  Widget _field({required TextEditingController controller, required String hint, required IconData icon, bool obscure = false, TextInputType keyboard = TextInputType.text, Widget? suffixIcon, int? maxLength, bool digitsOnly = false}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboard,
      maxLength: maxLength,
      inputFormatters: digitsOnly ? [FilteringTextInputFormatter.digitsOnly] : null,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: primary),
        suffixIcon: suffixIcon,
        counterText: '',
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: _isCompactLayout(context) ? 16 : 22),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _dateField() {
    return _textField(label: AppLanguage.text(context, 'Date of Birth', 'تاريخ الميلاد'), controller: dobCtrl, icon: Icons.calendar_month, readOnly: true, onTap: _pickDate);
  }


  Widget _infoMessage(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primary.withValues(alpha: 0.25)),
      ),
      child: Text(
        message,
        style: TextStyle(color: Colors.grey.shade800, fontSize: 15, fontWeight: FontWeight.w600, height: 1.4),
      ),
    );
  }


  Widget _medicalCircleSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: primary.withValues(alpha: 0.16), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: primary.withValues(alpha: 0.10),
                child: Icon(icon, color: primary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: primary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _singleCircleGrid({
    required String? value,
    required List<Map<String, String>> items,
    required IconData icon,
    required ValueChanged<String?> onSelected,
    bool large = false,
  }) {
    return _rectangleChoiceGrid(
      items: items,
      selectedValues: value == null ? <String>{} : <String>{value},
      icon: icon,
      compact: !large,
      onTap: (itemValue) => onSelected(itemValue),
    );
  }

  Widget _multiCircleGrid({
    required Set<String> selectedValues,
    required List<Map<String, String>> items,
    required IconData icon,
    required ValueChanged<String> onToggle,
    bool small = false,
  }) {
    return _rectangleChoiceGrid(
      items: items,
      selectedValues: selectedValues,
      icon: icon,
      compact: small,
      onTap: onToggle,
    );
  }

  Widget _rectangleChoiceGrid({
    required List<Map<String, String>> items,
    required Set<String> selectedValues,
    required IconData icon,
    required ValueChanged<String> onTap,
    bool compact = false,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 10.0;
        final itemWidth = compact
            ? ((constraints.maxWidth - gap) / 2).clamp(130.0, 170.0)
            : ((constraints.maxWidth - gap) / 2).clamp(145.0, 190.0);

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: items.map((item) {
            final itemValue = item['en']!;
            final selected = selectedValues.contains(itemValue);

            return SizedBox(
              width: itemWidth,
              child: _rectangleChoice(
                label: _label(item),
                icon: icon,
                selected: selected,
                compact: compact,
                onTap: () => onTap(itemValue),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _rectangleChoice({
    required String label,
    required IconData icon,
    required bool selected,
    required bool compact,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        constraints: BoxConstraints(
          minHeight: compact ? 54 : 64,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 12,
          vertical: compact ? 9 : 12,
        ),
        decoration: BoxDecoration(
          color: selected ? primary : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? primary : const Color(0xFFDDE7F3),
            width: 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: selected
                  ? primary.withValues(alpha: 0.20)
                  : Colors.black.withValues(alpha: 0.035),
              blurRadius: selected ? 14 : 8,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: compact ? 28 : 32,
              height: compact ? 28 : 32,
              decoration: BoxDecoration(
                color: selected ? Colors.white.withValues(alpha: 0.20) : primary.withValues(alpha: 0.10),
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
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? Colors.white : const Color(0xFF0F172A),
                  fontWeight: FontWeight.w800,
                  fontSize: compact ? 11 : 12.5,
                  height: 1.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _optionGrid({
    required String? value,
    required List<Map<String, String>> items,
    required IconData icon,
    required ValueChanged<String?> onSelected,
    int columns = 2,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = 12.0;
        final itemWidth = (constraints.maxWidth - ((columns - 1) * gap)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: items.map((item) {
            final itemValue = item['en']!;
            final selected = value == itemValue;
            return SizedBox(
              width: itemWidth,
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: () => onSelected(itemValue),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  decoration: BoxDecoration(
                    color: selected ? primary : Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: selected ? primary : Colors.grey.shade300, width: 1.4),
                    boxShadow: [
                      BoxShadow(
                        color: selected ? primary.withValues(alpha: 0.22) : Colors.black.withValues(alpha: 0.04),
                        blurRadius: selected ? 14 : 8,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, color: selected ? Colors.white : primary, size: 24),
                      const SizedBox(height: 8),
                      Text(
                        _label(item),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: selected ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
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

  Widget _dropdown({required String label, required String? value, required List<Map<String, String>> items, required IconData icon, required ValueChanged<String?> onChanged}) {
    final safeValue = value != null && items.any((e) => e['en'] == value) ? value : null;
    return DropdownButtonFormField<String>(
      value: safeValue,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, color: primary), filled: true, fillColor: Colors.white, contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: _isCompactLayout(context) ? 14 : 20), border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none)),
      items: items.map((item) => DropdownMenuItem<String>(value: item['en'], child: Text(_label(item)))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _countryDropdown() {
    final safeValue = countries.any((e) => e['en'] == countryCtrl.text) ? countryCtrl.text : 'Jordan';
    return DropdownButtonFormField<String>(
      value: safeValue,
      decoration: InputDecoration(
        labelText: AppLanguage.text(context, 'Country', 'الدولة'),
        prefixIcon: Icon(Icons.public, color: primary),
        suffixIcon: isLoadingLocation
            ? const Padding(padding: EdgeInsets.all(14), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)))
            : IconButton(icon: const Icon(Icons.my_location), onPressed: _detectCountryFromLocation),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: _isCompactLayout(context) ? 14 : 20), border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
      ),
      items: countries.map((item) => DropdownMenuItem<String>(value: item['en'], child: Text(AppLanguage.isArabicContext(context) ? item['ar']! : item['en']!))).toList(),
      onChanged: (value) {
        if (value == null) return;
        setState(() => countryCtrl.text = value);
      },
    );
  }

  Widget _textField({required String label, required TextEditingController controller, required IconData icon, bool readOnly = false, VoidCallback? onTap, int maxLines = 1}) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      maxLines: maxLines,
      cursorColor: primary,
      style: TextStyle(
        color: primary,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: primary.withValues(alpha: 0.80), fontWeight: FontWeight.w700),
        prefixIcon: Icon(icon, color: primary),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: _isCompactLayout(context) ? 14 : 20),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: primary.withValues(alpha: 0.14)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class SignupColorStep extends StatelessWidget {
  const SignupColorStep({
    super.key,
    required this.selectedThemeColor,
    required this.primary,
    required this.onChanged,
  });

  final String selectedThemeColor;
  final Color primary;
  final ValueChanged<String> onChanged;

  Color _themeColor(String value) {
    switch (value) {
      case 'orange':
        return AppColors.orange;
      case 'purple':
        return AppColors.purple;
      case 'blue':
      default:
        return AppColors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final compact = media.orientation == Orientation.landscape || media.size.height < 720;
    final titleSize = compact ? 24.0 : 34.0;
    final subtitleSize = compact ? 14.0 : 17.0;
    final topPadding = compact ? 14.0 : 50.0;
    final bottomPadding = compact ? 12.0 : 24.0;
    final gap = compact ? 20.0 : 42.0;

    final options = [
      {'value': 'blue', 'en': 'Blue', 'ar': 'أزرق'},
      {'value': 'orange', 'en': 'Orange', 'ar': 'برتقالي'},
      {'value': 'purple', 'en': 'Purple', 'ar': 'بنفسجي'},
    ];

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(top: topPadding, bottom: bottomPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLanguage.text(context, 'Do you have color blindness?', 'هل تعاني من عمى الالوان ؟'),
              style: TextStyle(fontSize: titleSize, fontWeight: FontWeight.w900, color: Colors.black),
            ),
            const SizedBox(height: 12),
            Text(
              AppLanguage.text(context, 'Choose the app theme', 'اختر سمة التطبيق'),
              style: TextStyle(fontSize: subtitleSize, color: Colors.grey.shade600, height: 1.4),
            ),
            SizedBox(height: gap),
            ...options.map((item) {
              final value = item['value']!;
              final color = _themeColor(value);
              final selected = selectedThemeColor == value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () => onChanged(value),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: selected ? color : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: selected ? color : Colors.grey.shade300, width: 1.5),
                      boxShadow: [BoxShadow(color: color.withValues(alpha: selected ? 0.24 : 0.08), blurRadius: 14, offset: const Offset(0, 7))],
                    ),
                    child: Row(
                      children: [
                        Container(width: 34, height: 34, decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3))),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            AppLanguage.isArabicContext(context) ? item['ar']! : item['en']!,
                            style: TextStyle(color: selected ? Colors.white : Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Icon(selected ? Icons.check_circle : Icons.circle_outlined, color: selected ? Colors.white : color),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

