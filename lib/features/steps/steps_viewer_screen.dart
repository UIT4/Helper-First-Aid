import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/database/app_database.dart';

class StepsViewerScreen extends StatefulWidget {
  final String categoryCode;
  final String lang;

  const StepsViewerScreen({
    super.key,
    required this.categoryCode,
    this.lang = 'en',
  });

  @override
  State<StepsViewerScreen> createState() => _StepsViewerScreenState();
}

class _StepsViewerScreenState extends State<StepsViewerScreen> {
  List<Map<String, dynamic>> _steps = [];
  int _currentStep = 0;
  bool _isLoading = true;
  String _categoryName = '';

  // =====================================================
  // LIFECYCLE
  // =====================================================

  @override
  void initState() {
    super.initState();
    _loadSteps();
  }

  // =====================================================
  // LOAD
  // =====================================================

  Future<void> _loadSteps() async {
    final steps =
    await AppDatabase.instance.getStepsByCategory(widget.categoryCode);

    // Get category name
    final categories = await AppDatabase.instance.getCategories();
    final cat = categories.firstWhere(
          (c) => c['code'] == widget.categoryCode,
      orElse: () => {},
    );

    setState(() {
      _steps = steps;
      _categoryName = widget.lang == 'ar'
          ? (cat['name_ar'] ?? widget.categoryCode)
          : (cat['name_en'] ?? widget.categoryCode);
      _isLoading = false;
    });
  }

  // =====================================================
  // NAVIGATION
  // =====================================================

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      setState(() => _currentStep++);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  // =====================================================
  // EMERGENCY ACTIONS
  // =====================================================

  Future<void> _call911() async {
    final settings = await AppDatabase.instance.getSettings();
    final number   = settings['emergency_number'] ?? '911';
    final Uri url  = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  Future<void> _sendSms() async {
    final profile  = await AppDatabase.instance.getProfile();
    final contacts = await AppDatabase.instance.getContacts();
    final settings = await AppDatabase.instance.getSettings();

    if (contacts.isEmpty) {
      _showSnackbar('No emergency contacts found', isError: true);
      return;
    }

    final primary = contacts.firstWhere(
          (c) => c['is_primary'] == 1,
      orElse: () => contacts.first,
    );

    final phone       = primary['phone'] ?? '';
    final countryCode = settings['country_code'] ?? '+962';
    final fullPhone   = phone.startsWith('+') ? phone : '$countryCode$phone';

    final age        = profile?['age']?.toString()        ?? '—';
    final sex        = profile?['sex']?.toString()        ?? '—';
    final allergies  = profile?['allergies']?.toString()  ?? 'None';
    final conditions = profile?['conditions']?.toString() ?? 'None';

    final isAr = widget.lang == 'ar';

    final locationText = 'Location unavailable';
    final notes =
        profile?['notes']?.toString() ?? 'None';

    final body = isAr
        ? 'طارئ: $_categoryName\n'
        'المريض: $age/$sex حساسية:$allergies أمراض:$conditions\n'
        'الموقع: $locationText\n'
        'ملاحظات:$notes'
        : 'EMERGENCY: $_categoryName\n'
        'Patient: $age/$sex Allergies:$allergies Conditions:$conditions\n'
        'Location: $locationText\n'
        'Notes: $notes';

    _showSmsBottomSheet(fullPhone, body);
  }

  void _showSmsBottomSheet(String phone, String body) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Send Emergency SMS',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('To: $phone',
                style: const TextStyle(color: Color(0xFF475569))),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(body,
                  style: const TextStyle(fontSize: 13, height: 1.5)),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: body));
                      Navigator.pop(context);
                      _showSnackbar('Message copied ✓');
                    },
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('Copy'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      final encoded = Uri.encodeComponent(body);
                      final Uri url = Uri.parse('sms:$phone?body=$encoded');
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url);
                      } else {
                        _showSnackbar('Cannot open SMS app', isError: true);
                      }
                    },
                    icon: const Icon(Icons.send, size: 18, color: Colors.white),
                    label: const Text('Send SMS',
                        style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // DONE
  // =====================================================

  void _markDone() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 28),
            SizedBox(width: 10),
            Text('Well Done!',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
            'You have completed all first aid steps.\n\nMake sure emergency services have been contacted.'),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              minimumSize: const Size(double.infinity, 48),
            ),
            onPressed: () {
              Navigator.pop(context); // close dialog
              Navigator.pop(context); // go back
            },
            child: const Text('Done',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // HELPERS
  // =====================================================

  void _showSnackbar(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor:
      isError ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  String _stepTitle(Map<String, dynamic> step) =>
      widget.lang == 'ar' ? (step['title_ar'] ?? '') : (step['title_en'] ?? '');

  String _stepBody(Map<String, dynamic> step) =>
      widget.lang == 'ar' ? (step['body_ar'] ?? '') : (step['body_en'] ?? '');

  // =====================================================
  // BUILD
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          _categoryName,
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF2563EB),
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(
          child: CircularProgressIndicator(color: Color(0xFF2563EB)))
          : _steps.isEmpty
          ? const Center(child: Text('No steps found'))
          : Column(
        children: [
          // Progress bar
          _buildProgressBar(),

          // Steps list
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              children: [
                // Current step card (big)
                _buildCurrentStepCard(),
                const SizedBox(height: 16),

                // All steps overview
                _buildStepsOverview(),
              ],
            ),
          ),

          // Bottom action bar
          _buildBottomBar(),
        ],
      ),
    );
  }

  // =====================================================
  // WIDGETS
  // =====================================================

  Widget _buildProgressBar() {
    final progress = (_currentStep + 1) / _steps.length;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Step ${_currentStep + 1} of ${_steps.length}',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569)),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2563EB)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor:
              const AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
              minHeight: 7,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStepCard() {
    final step = _steps[_currentStep];
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: const BoxDecoration(
              color: Color(0xFF2563EB),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${_currentStep + 1}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _stepTitle(step),
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 17),
                  ),
                ),
              ],
            ),
          ),

          // Step body
          Padding(
            padding: const EdgeInsets.all(18),
            child: Text(
              _stepBody(step),
              style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF0F172A),
                  height: 1.6),
            ),
          ),

          // Step image (if exists)
          if ((step['image_asset'] ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  step['image_asset'],
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),

          // Prev / Next buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            child: Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _prevStep,
                      icon: const Icon(Icons.arrow_back,
                          size: 18, color: Color(0xFF475569)),
                      label: const Text('Previous',
                          style: TextStyle(color: Color(0xFF475569))),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                if (_currentStep > 0) const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _currentStep < _steps.length - 1
                        ? _nextStep
                        : _markDone,
                    icon: Icon(
                      _currentStep < _steps.length - 1
                          ? Icons.arrow_forward
                          : Icons.check_circle,
                      color: Colors.white,
                      size: 18,
                    ),
                    label: Text(
                      _currentStep < _steps.length - 1
                          ? 'Next Step'
                          : "I'm Done",
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      _currentStep < _steps.length - 1
                          ? const Color(0xFF2563EB)
                          : const Color(0xFF16A34A),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepsOverview() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text('All Steps',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF475569))),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          ...List.generate(_steps.length, (index) {
            final step     = _steps[index];
            final isDone   = index < _currentStep;
            final isCurrent = index == _currentStep;

            return InkWell(
              onTap: () => setState(() => _currentStep = index),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isCurrent
                      ? const Color(0xFFEFF6FF)
                      : Colors.transparent,
                  border: Border(
                    bottom: BorderSide(
                        color: index < _steps.length - 1
                            ? const Color(0xFFF1F5F9)
                            : Colors.transparent),
                  ),
                ),
                child: Row(
                  children: [
                    // Step number circle
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: isDone
                            ? const Color(0xFF16A34A)
                            : isCurrent
                            ? const Color(0xFF2563EB)
                            : const Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: isDone
                          ? const Icon(Icons.check,
                          size: 16, color: Colors.white)
                          : Text(
                        '${index + 1}',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isCurrent
                                ? Colors.white
                                : const Color(0xFF475569)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _stepTitle(step),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isCurrent
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isCurrent
                              ? const Color(0xFF2563EB)
                              : isDone
                              ? const Color(0xFF16A34A)
                              : const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    if (isCurrent)
                      const Icon(Icons.chevron_right,
                          color: Color(0xFF2563EB), size: 20),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Persistent bottom bar ──
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, -3))
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Call button
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _call911,
                icon: const Icon(Icons.call, color: Colors.white, size: 20),
                label: const Text('Call 911',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
              ),
            ),
            const SizedBox(width: 10),
            // SMS button
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _sendSms,
                icon: const Icon(Icons.sms, color: Colors.white, size: 20),
                label: const Text('Send SMS',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}