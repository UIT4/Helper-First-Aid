import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/database/app_database.dart';

class PatientProfileScreen extends StatefulWidget {
  const PatientProfileScreen({super.key});

  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _bloodController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _conditionsController = TextEditingController();
  final _medicationsController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedSex = 'M';
  String? _imagePath;

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _bloodController.dispose();
    _allergiesController.dispose();
    _conditionsController.dispose();
    _medicationsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final profile = await AppDatabase.instance.getProfile();
    final prefs = await SharedPreferences.getInstance();

    if (profile != null) {
      _nameController.text = profile['full_name']?.toString() ?? '';
      _ageController.text = profile['age']?.toString() ?? '';
      _bloodController.text = profile['blood_type']?.toString() ?? '';
      _allergiesController.text = profile['allergies']?.toString() ?? '';
      _conditionsController.text = profile['conditions']?.toString() ?? '';
      _medicationsController.text = profile['medications']?.toString() ?? '';
      _notesController.text = profile['notes']?.toString() ?? '';
      _selectedSex = profile['sex']?.toString() ?? 'M';
    }

    _imagePath = prefs.getString('profile_image_path');

    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  Future<void> _pickImage() async {
    if (!_isEditing) return;

    final picker = ImagePicker();

    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );

    if (image == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_image_path', image.path);

    setState(() {
      _imagePath = image.path;
    });
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty) {
      _showSnackbar('Please enter full name', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    await AppDatabase.instance.saveProfile({
      'full_name': _nameController.text.trim(),
      'age': int.tryParse(_ageController.text.trim()) ?? 0,
      'sex': _selectedSex,
      'blood_type': _bloodController.text.trim(),
      'allergies': _allergiesController.text.trim(),
      'conditions': _conditionsController.text.trim(),
      'medications': _medicationsController.text.trim(),
      'notes': _notesController.text.trim(),
    });

    if (!mounted) return;

    setState(() {
      _isSaving = false;
      _isEditing = false;
    });

    _showSnackbar('Profile updated successfully ✓');
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

  String get _name {
    final name = _nameController.text.trim();
    return name.isEmpty ? 'Your Profile' : name;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF2563EB),
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          TextButton.icon(
            onPressed: () {
              if (_isEditing) {
                _saveProfile();
              } else {
                setState(() => _isEditing = true);
              }
            },
            icon: Icon(
              _isEditing ? Icons.save : Icons.edit,
              color: Colors.white,
              size: 18,
            ),
            label: Text(
              _isEditing ? 'Save' : 'Edit',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(color: Color(0xFF2563EB)),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildHeader(),

            const SizedBox(height: 24),

            if (_isEditing) ...[
              _buildEditCard(),
              const SizedBox(height: 24),
            ],

            _buildQuestionnaireCard(),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
                  radius: 52,
                  backgroundColor: const Color(0xFFDBEAFE),
                  backgroundImage: _imagePath != null &&
                      _imagePath!.isNotEmpty &&
                      File(_imagePath!).existsSync()
                      ? FileImage(File(_imagePath!))
                      : null,
                  child: _imagePath == null || _imagePath!.isEmpty
                      ? const Icon(
                    Icons.person,
                    size: 56,
                    color: Color(0xFF2563EB),
                  )
                      : null,
                ),
                if (_isEditing)
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: const BoxDecoration(
                      color: Color(0xFF2563EB),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            _name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Medical questionnaire summary',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _buildInput('Full Name', _nameController, Icons.person),
          _buildInput(
            'Age',
            _ageController,
            Icons.cake,
            type: TextInputType.number,
          ),
          _buildSexSelector(),
          _buildInput(
            'Blood Type',
            _bloodController,
            Icons.bloodtype,
            hint: 'e.g. A+, O-',
          ),
          _buildInput(
            'Allergies',
            _allergiesController,
            Icons.warning_amber_rounded,
            hint: 'e.g. Penicillin, Peanuts',
          ),
          _buildInput(
            'Conditions',
            _conditionsController,
            Icons.medical_services,
            hint: 'e.g. Diabetes, Asthma',
          ),
          _buildInput(
            'Medications',
            _medicationsController,
            Icons.medication,
            hint: 'e.g. Insulin',
          ),
          _buildInput(
            'Emergency Notes',
            _notesController,
            Icons.note,
            maxLines: 3,
            hint: 'Any extra info',
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
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
                  : const Icon(Icons.save, color: Colors.white),
              label: Text(
                _isSaving ? 'Saving...' : 'Save Changes',
                style: const TextStyle(
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
          const Text(
            'Questionnaire',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2563EB),
            ),
          ),
          const SizedBox(height: 16),

          _infoRow('Age', _ageController.text),
          _infoRow('Sex', _selectedSex),
          _infoRow('Blood Type', _bloodController.text),
          _infoRow('Allergies', _allergiesController.text),
          _infoRow('Conditions', _conditionsController.text),
          _infoRow('Medications', _medicationsController.text),
          _infoRow('Notes', _notesController.text),
        ],
      ),
    );
  }

  Widget _infoRow(String title, String value) {
    final cleanValue = value.trim().isEmpty ? '—' : value.trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              title,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              cleanValue,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput(
      String label,
      TextEditingController controller,
      IconData icon, {
        TextInputType type = TextInputType.text,
        int maxLines = 1,
        String? hint,
      }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        keyboardType: type,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: const Color(0xFF2563EB)),
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _buildSexSelector() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedSex,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down),
          items: const [
            DropdownMenuItem(value: 'Male', child: Text('Male')),
            DropdownMenuItem(value: 'Female', child: Text('Female')),
          ],
          onChanged: (value) {
            if (value == null) return;
            setState(() => _selectedSex = value);
          },
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 12,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }
}