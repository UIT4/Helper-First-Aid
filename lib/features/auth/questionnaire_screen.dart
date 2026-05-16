import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/database/app_database.dart';
import '../onboarding/onboarding_screen.dart';

class QuestionnaireScreen extends StatefulWidget {
  const QuestionnaireScreen({super.key});

  @override
  State<QuestionnaireScreen> createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<QuestionnaireScreen> {
  final nameCtrl = TextEditingController();
  final ageCtrl = TextEditingController();
  final sexCtrl = TextEditingController();
  final bloodCtrl = TextEditingController();
  final allergiesCtrl = TextEditingController();
  final conditionsCtrl = TextEditingController();
  final medicationsCtrl = TextEditingController();
  final notesCtrl = TextEditingController();

  bool isSaving = false;

  @override
  void dispose() {
    nameCtrl.dispose();
    ageCtrl.dispose();
    sexCtrl.dispose();
    bloodCtrl.dispose();
    allergiesCtrl.dispose();
    conditionsCtrl.dispose();
    medicationsCtrl.dispose();
    notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Full name is required')),
      );
      return;
    }

    setState(() => isSaving = true);

    await AppDatabase.instance.saveProfile({
      'full_name': nameCtrl.text.trim(),
      'age': int.tryParse(ageCtrl.text.trim()) ?? 0,
      'sex': sexCtrl.text.trim(),
      'blood_type': bloodCtrl.text.trim(),
      'allergies': allergiesCtrl.text.trim(),
      'conditions': conditionsCtrl.text.trim(),
      'medications': medicationsCtrl.text.trim(),
      'notes': notesCtrl.text.trim(),
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setBool('profileCompleted', true);

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const OnboardingScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Medical Information',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF2563EB),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _field('Full Name', nameCtrl),
            _field('Age', ageCtrl, keyboard: TextInputType.number),
            _field('Gender', sexCtrl),
            _field('Blood Type', bloodCtrl),
            _field('Allergies', allergiesCtrl),
            _field('Medical Conditions', conditionsCtrl),
            _field('Medications', medicationsCtrl),
            _field('Notes', notesCtrl, maxLines: 3),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                ),
                onPressed: isSaving ? null : _finish,
                child: Text(
                  isSaving ? 'Saving...' : 'Finish',
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
      String title,
      TextEditingController controller, {
        TextInputType keyboard = TextInputType.text,
        int maxLines = 1,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: keyboard,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: title,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }
}