import 'package:flutter/material.dart';
import '../../core/database/app_database.dart';

class PatientProfileScreen extends StatefulWidget {
  const PatientProfileScreen({super.key});

  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
  final _nameController        = TextEditingController();
  final _ageController         = TextEditingController();
  final _bloodController       = TextEditingController();
  final _allergiesController   = TextEditingController();
  final _conditionsController  = TextEditingController();
  final _medicationsController = TextEditingController();
  final _notesController       = TextEditingController();

  String _selectedSex = 'M';
  bool _isLoading = true;
  bool _isSaving = false;

  // =====================================================
  // LIFECYCLE
  // =====================================================

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

  // =====================================================
  // LOAD
  // =====================================================

  Future<void> _loadProfile() async {
    final profile = await AppDatabase.instance.getProfile();
    if (profile != null) {
      _nameController.text        = profile['full_name']?.toString()   ?? '';
      _ageController.text         = profile['age']?.toString()          ?? '';
      _bloodController.text       = profile['blood_type']?.toString()   ?? '';
      _allergiesController.text   = profile['allergies']?.toString()    ?? '';
      _conditionsController.text  = profile['conditions']?.toString()   ?? '';
      _medicationsController.text = profile['medications']?.toString()  ?? '';
      _notesController.text       = profile['notes']?.toString()        ?? '';
      _selectedSex = profile['sex']?.toString() ?? 'M';
    }
    setState(() => _isLoading = false);
  }

  // =====================================================
  // SAVE
  // =====================================================

  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty) {
      _showSnackbar('Please enter full name', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    await AppDatabase.instance.saveProfile({
      'full_name':   _nameController.text.trim(),
      'age':         int.tryParse(_ageController.text) ?? 0,
      'sex':         _selectedSex,
      'blood_type':  _bloodController.text.trim(),
      'allergies':   _allergiesController.text.trim(),
      'conditions':  _conditionsController.text.trim(),
      'medications': _medicationsController.text.trim(),
      'notes':       _notesController.text.trim(),
    });

    setState(() => _isSaving = false);
    _showSnackbar('Profile saved successfully ✓');
  }

  void _showSnackbar(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // =====================================================
  // BUILD
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Medical Profile',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF2563EB),
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(
          child: CircularProgressIndicator(color: Color(0xFF2563EB)))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ── Avatar ──
            _buildAvatar(),
            const SizedBox(height: 28),

            // ── Personal Info Section ──
            _sectionTitle('Personal Information'),
            const SizedBox(height: 12),
            _buildInput('Full Name', _nameController, Icons.person),
            _buildInput('Age', _ageController, Icons.cake,
                type: TextInputType.number),
            _buildSexSelector(),
            _buildInput('Blood Type', _bloodController, Icons.bloodtype,
                hint: 'e.g. A+, O-'),

            const SizedBox(height: 20),

            // ── Medical Info Section ──
            _sectionTitle('Medical Information'),
            const SizedBox(height: 12),
            _buildInput('Allergies', _allergiesController,
                Icons.warning_amber_rounded,
                hint: 'e.g. Penicillin, Peanuts'),
            _buildInput('Conditions', _conditionsController,
                Icons.medical_services,
                hint: 'e.g. Diabetes, Asthma'),
            _buildInput('Medications', _medicationsController,
                Icons.medication,
                hint: 'e.g. Insulin 10mg'),
            _buildInput('Emergency Notes', _notesController, Icons.note,
                maxLines: 3,
                hint: 'Any extra info for paramedics'),

            const SizedBox(height: 28),

            // ── Emergency Card Preview ──
            _buildEmergencyCard(),

            const SizedBox(height: 24),

            // ── Save Button ──
            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
                onPressed: _isSaving ? null : _saveProfile,
                icon: _isSaving
                    ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.save, color: Colors.white),
                label: Text(
                  _isSaving ? 'Saving...' : 'SAVE PROFILE',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // WIDGETS
  // =====================================================

  Widget _buildAvatar() {
    return Column(
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            color: const Color(0xFFDBEAFE),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF2563EB), width: 2),
          ),
          child: const Icon(Icons.person, size: 50, color: Color(0xFF2563EB)),
        ),
        const SizedBox(height: 10),
        Text(
          _nameController.text.isEmpty ? 'Your Profile' : _nameController.text,
          style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A)),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2563EB)),
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: type,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 14),
          prefixIcon: Icon(icon, color: const Color(0xFF2563EB)),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildSexSelector() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.person_outline, color: Color(0xFF2563EB)),
          const SizedBox(width: 12),
          const Text('Sex',
              style: TextStyle(color: Color(0xFF475569), fontSize: 16)),
          const Spacer(),
          _sexChip('M', 'Male'),
          const SizedBox(width: 8),
          _sexChip('F', 'Female'),
          const SizedBox(width: 8),
          _sexChip('Other', 'Other'),
        ],
      ),
    );
  }

  Widget _sexChip(String value, String label) {
    final bool selected = _selectedSex == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedSex = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2563EB) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
              color: selected ? Colors.white : const Color(0xFF475569),
              fontSize: 13,
              fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // ── Emergency Card Preview ──
  Widget _buildEmergencyCard() {
    final name       = _nameController.text.trim();
    final age        = _ageController.text.trim();
    final blood      = _bloodController.text.trim();
    final allergies  = _allergiesController.text.trim();
    final conditions = _conditionsController.text.trim();
    final meds       = _medicationsController.text.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDC2626), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.emergency, color: Color(0xFFDC2626), size: 20),
            const SizedBox(width: 8),
            const Text('Emergency Card Preview',
                style: TextStyle(
                    color: Color(0xFFDC2626),
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
          ]),
          const Divider(color: Color(0xFFDC2626), height: 16),
          _cardRow('Name', name.isEmpty ? '—' : name),
          _cardRow('Age / Sex',
              '${age.isEmpty ? "—" : age} / $_selectedSex'),
          _cardRow('Blood Type', blood.isEmpty ? '—' : blood),
          _cardRow('Allergies', allergies.isEmpty ? 'None' : allergies),
          _cardRow('Conditions', conditions.isEmpty ? 'None' : conditions),
          _cardRow('Medications', meds.isEmpty ? 'None' : meds),
        ],
      ),
    );
  }

  Widget _cardRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text('$label:',
                style: const TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: Color(0xFF0F172A), fontSize: 13)),
          ),
        ],
      ),
    );
  }
}