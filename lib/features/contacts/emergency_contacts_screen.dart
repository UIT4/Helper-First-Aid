import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import '../../core/constants/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/database/app_database.dart';
import '../../core/language/app_language.dart';

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() =>
      _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  List<Map<String, dynamic>> _contacts = [];
  bool _isLoading = true;

  static Color get primary => AppColors.primary;
  static const Color danger = Color(0xFFDC2626);
  static const Color success = Color(0xFF16A34A);
  static const Color background = Color(0xFFF8FAFC);
  static const Color textDark = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF475569);

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    final data = await AppDatabase.instance.getContacts();

    if (!mounted) return;

    setState(() {
      _contacts = data;
      _isLoading = false;
    });
  }

  Future<void> _makeCall(String phone) async {
    final Uri url = Uri(scheme: 'tel', path: phone);

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      _showSnackbar(
        AppLanguage.text(context, 'Cannot make call', 'تعذر إجراء الاتصال'),
        isError: true,
      );
    }
  }

  Future<void> _deleteContact(int id, String name) async {
    final isArabic = AppLanguage.isArabicContext(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => Directionality(
        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            AppLanguage.text(context, 'Delete Contact', 'حذف جهة الاتصال'),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            AppLanguage.text(
              context,
              'Are you sure you want to delete "$name"?',
              'هل أنت متأكد أنك تريد حذف "$name"؟',
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF1F5F9), // لون رمادي فاتح متناسق مع الخلفية والنص
                      foregroundColor: textMuted,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(color: Color(0xFFCBD5E1)), // حدود خفيفة لتحديد الزر
                      ),
                    ),
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(
                      AppLanguage.text(context, 'Cancel', 'إلغاء'),
                      style: TextStyle(
                        color: textMuted,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: danger,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(
                      AppLanguage.text(context, 'Delete', 'حذف'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (!mounted) return;

    if (confirm == true) {
      await AppDatabase.instance.deleteContact(id);
      if (!mounted) return;

      _showSnackbar(
        AppLanguage.text(context, 'Contact deleted', 'تم حذف جهة الاتصال'),
      );

      await _loadContacts();
    }
  }

  Future<void> _setPrimary(int id) async {
    await AppDatabase.instance.setPrimaryContact(id);
    if (!mounted) return;

    _showSnackbar(
      AppLanguage.text(
        context,
        'Primary contact updated ✓',
        'تم تحديث جهة الاتصال الأساسية ✓',
      ),
    );

    await _loadContacts();
  }

  Future<void> _showContactDialog({Map<String, dynamic>? existing}) async {
    final bool? saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => _ContactFormPage(existing: existing),
      ),
    );

    if (!mounted) return;

    if (saved == true) {
      _showSnackbar(
        existing == null
            ? AppLanguage.text(
          context,
          'Contact added ✓',
          'تمت إضافة جهة الاتصال ✓',
        )
            : AppLanguage.text(
          context,
          'Contact updated ✓',
          'تم تحديث جهة الاتصال ✓',
        ),
      );

      await _loadContacts();
    }
  }

  void _showSnackbar(String msg, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? danger : success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
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
            AppLanguage.text(
              context,
              'Emergency Contacts',
              'جهات اتصال الطوارئ',
            ),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: danger,
          centerTitle: true,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body:
        _isLoading
            ? Center(child: CircularProgressIndicator(color: primary))
            : _contacts.isEmpty
            ? _buildEmptyState()
            : _buildContactsList(),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: primary,
          onPressed: () => _showContactDialog(),
          icon: const Icon(Icons.person_add, color: Colors.white),
          label: Text(
            AppLanguage.text(context, 'Add Contact', 'إضافة جهة'),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFFDBEAFE),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.contact_phone, size: 60, color: primary),
            ),
            const SizedBox(height: 20),
            Text(
              AppLanguage.text(
                context,
                'No Emergency Contacts',
                'لا توجد جهات طوارئ',
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLanguage.text(
                context,
                'Add contacts to notify in emergencies',
                'أضف جهات اتصال لإشعارهم في حالات الطوارئ',
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactsList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: _contacts.length,
      itemBuilder: (context, index) {
        final contact = _contacts[index];
        final bool isPrimary = contact['is_primary'] == 1;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: isPrimary ? Border.all(color: primary, width: 1.5) : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                _buildAvatar(contact, isPrimary),
                const SizedBox(width: 14),
                _buildContactInfo(contact, isPrimary),
                _buildContactActions(contact, isPrimary),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAvatar(Map<String, dynamic> contact, bool isPrimary) {
    final name = contact['name']?.toString() ?? '?';
    final firstLetter = name.trim().isEmpty ? '?' : name.trim()[0];

    return Stack(
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor:
          isPrimary ? const Color(0xFFDBEAFE) : const Color(0xFFF1F5F9),
          child: Text(
            firstLetter.toUpperCase(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isPrimary ? primary : textMuted,
            ),
          ),
        ),
        if (isPrimary)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.star, size: 10, color: Colors.white),
            ),
          ),
      ],
    );
  }

  Widget _buildContactInfo(Map<String, dynamic> contact, bool isPrimary) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  contact['name']?.toString() ?? 'Unknown',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isPrimary) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    AppLanguage.text(context, 'PRIMARY', 'أساسي'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            contact['phone']?.toString() ?? '',
            style: const TextStyle(fontSize: 14, color: textMuted),
          ),
          if ((contact['relation']?.toString() ?? '').isNotEmpty)
            Text(
              contact['relation'].toString(),
              style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
            ),
        ],
      ),
    );
  }

  Widget _buildContactActions(Map<String, dynamic> contact, bool isPrimary) {
    return Column(
      children: [
        IconButton(
          icon: const Icon(Icons.call, color: success, size: 26),
          onPressed: () => _makeCall(contact['phone']?.toString() ?? ''),
          tooltip: AppLanguage.text(context, 'Call', 'اتصال'),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: textMuted),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onSelected: (value) async {
            if (value == 'edit') {
              await _showContactDialog(existing: contact);
            } else if (value == 'primary') {
              await _setPrimary(contact['id']);
            } else if (value == 'delete') {
              await _deleteContact(
                contact['id'],
                contact['name']?.toString() ?? '',
              );
            }
          },
          itemBuilder:
              (_) => [
            PopupMenuItem(
              value: 'edit',
              child: _popupItem(
                icon: Icons.edit,
                color: primary,
                text: AppLanguage.text(context, 'Edit', 'تعديل'),
              ),
            ),
            if (!isPrimary)
              PopupMenuItem(
                value: 'primary',
                child: _popupItem(
                  icon: Icons.star,
                  color: const Color(0xFFF59E0B),
                  text: AppLanguage.text(
                    context,
                    'Set as Primary',
                    'تعيين كجهة أساسية',
                  ),
                ),
              ),
            PopupMenuItem(
              value: 'delete',
              child: _popupItem(
                icon: Icons.delete,
                color: danger,
                text: AppLanguage.text(context, 'Delete', 'حذف'),
                dangerText: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _popupItem({
    required IconData icon,
    required Color color,
    required String text,
    bool dangerText = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Text(text, style: TextStyle(color: dangerText ? danger : textDark)),
      ],
    );
  }
}

class _ContactFormPage extends StatefulWidget {
  final Map<String, dynamic>? existing;

  const _ContactFormPage({this.existing});

  @override
  State<_ContactFormPage> createState() => _ContactFormPageState();
}

class _ContactFormPageState extends State<_ContactFormPage> {
  static Color get primary => AppColors.primary;
  static const Color danger = Color(0xFFDC2626);
  static const Color background = Color(0xFFF8FAFC);
  static const Color textDark = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF475569);

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _relationCtrl;
  late bool _isPrimary;
  bool _isSaving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(
      text: widget.existing?['name']?.toString() ?? '',
    );
    _phoneCtrl = TextEditingController(
      text: widget.existing?['phone']?.toString() ?? '',
    );
    _relationCtrl = TextEditingController(
      text: widget.existing?['relation']?.toString() ?? '',
    );
    
    _isPrimary = (widget.existing?['is_primary'] ?? 0) == 1;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _relationCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final contactData = {
      'name': _nameCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'relation': _relationCtrl.text.trim(),
      'is_primary': _isPrimary ? 1 : 0,
    };

    try {
      if (_isEdit) {
        await AppDatabase.instance.updateContact(
          widget.existing!['id'],
          contactData,
        );
      } else {
        await AppDatabase.instance.insertContact(contactData);
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLanguage.text(
              context,
              'Could not save contact. Please try again.',
              'تعذر حفظ جهة الاتصال. حاول مرة أخرى.',
            ),
          ),
          backgroundColor: danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
            _isEdit
                ? AppLanguage.text(context, 'Edit Contact', 'تعديل جهة الاتصال')
                : AppLanguage.text(context, 'Add Contact', 'إضافة جهة اتصال'),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: danger,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _field(
                    controller: _nameCtrl,
                    label: AppLanguage.text(context, 'Full Name', 'الاسم الكامل'),
                    icon: Icons.person,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return AppLanguage.text(context, 'Name is required', 'الاسم مطلوب');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  _field(
                    controller: _phoneCtrl,
                    label: AppLanguage.text(context, 'Phone Number', 'رقم الهاتف'),
                    icon: Icons.phone,
                    type: TextInputType.phone,
                    maxLength: 10,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                    ],
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return AppLanguage.text(context, 'Phone is required', 'رقم الهاتف مطلوب');
                      }
                      if (v.trim().length != 10) {
                        return AppLanguage.text(
                          context,
                          'Phone number must be exactly 10 digits',
                          'يجب أن يتكون رقم الهاتف من 10 أرقام تماماً',
                        );
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  _field(
                    controller: _relationCtrl,
                    label: AppLanguage.text(context, 'Relation (e.g. Father)', 'صلة القرابة مثل الأب'),
                    icon: Icons.people,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: SwitchListTile(
                      value: _isPrimary,
                      onChanged: (v) => setState(() => _isPrimary = v),
                      title: Text(
                        AppLanguage.text(context, 'Set as Primary Contact', 'تعيين كجهة أساسية'),
                        style: const TextStyle(
                          color: textDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        AppLanguage.text(context, 'Will be first to receive SMS', 'سيكون أول من تصله رسالة الطوارئ'),
                        style: const TextStyle(color: textMuted),
                      ),
                      activeThumbColor: primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _save,
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
                      _isSaving
                          ? AppLanguage.text(context, 'Saving...', 'جارٍ الحفظ...')
                          : (_isEdit
                          ? AppLanguage.text(context, 'Save', 'حفظ')
                          : AppLanguage.text(context, 'Add Contact', 'إضافة جهة الاتصال')),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType type = TextInputType.text,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: primary),
        filled: true,
        fillColor: Colors.white,
        counterText: "", 
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: danger),
        ),
      ),
    );
  }
}