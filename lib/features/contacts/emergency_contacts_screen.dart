import 'package:flutter/material.dart';
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

  static const Color primary = Color(0xFF2563EB);
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
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(
                    AppLanguage.text(context, 'Cancel', 'إلغاء'),
                    style: const TextStyle(color: textMuted),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: danger,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(
                    AppLanguage.text(context, 'Delete', 'حذف'),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
    );

    if (confirm == true) {
      await AppDatabase.instance.deleteContact(id);

      _showSnackbar(
        AppLanguage.text(context, 'Contact deleted', 'تم حذف جهة الاتصال'),
      );

      await _loadContacts();
    }
  }

  Future<void> _setPrimary(int id) async {
    await AppDatabase.instance.setPrimaryContact(id);

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
    final isArabic = AppLanguage.isArabicContext(context);

    final nameCtrl = TextEditingController(
      text: existing?['name']?.toString() ?? '',
    );

    final phoneCtrl = TextEditingController(
      text: existing?['phone']?.toString() ?? '',
    );

    final relationCtrl = TextEditingController(
      text: existing?['relation']?.toString() ?? '',
    );

    bool isPrimary = (existing?['is_primary'] ?? 0) == 1;
    bool isSaving = false;

    final formKey = GlobalKey<FormState>();

    final bool? saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Directionality(
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: StatefulBuilder(
            builder: (ctx, setDialogState) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDBEAFE),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        existing == null ? Icons.person_add : Icons.edit,
                        color: primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        existing == null
                            ? AppLanguage.text(
                              context,
                              'Add Contact',
                              'إضافة جهة اتصال',
                            )
                            : AppLanguage.text(
                              context,
                              'Edit Contact',
                              'تعديل جهة الاتصال',
                            ),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                content: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 8),
                        _dialogField(
                          controller: nameCtrl,
                          label: AppLanguage.text(
                            context,
                            'Full Name',
                            'الاسم الكامل',
                          ),
                          icon: Icons.person,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return AppLanguage.text(
                                context,
                                'Name is required',
                                'الاسم مطلوب',
                              );
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        _dialogField(
                          controller: phoneCtrl,
                          label: AppLanguage.text(
                            context,
                            'Phone Number',
                            'رقم الهاتف',
                          ),
                          icon: Icons.phone,
                          type: TextInputType.phone,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return AppLanguage.text(
                                context,
                                'Phone is required',
                                'رقم الهاتف مطلوب',
                              );
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        _dialogField(
                          controller: relationCtrl,
                          label: AppLanguage.text(
                            context,
                            'Relation (e.g. Father)',
                            'صلة القرابة مثل الأب',
                          ),
                          icon: Icons.people,
                        ),
                        const SizedBox(height: 8),
                        SwitchListTile(
                          value: isPrimary,
                          onChanged: (v) {
                            setDialogState(() {
                              isPrimary = v;
                            });
                          },
                          title: Text(
                            AppLanguage.text(
                              context,
                              'Set as Primary Contact',
                              'تعيين كجهة أساسية',
                            ),
                            style: const TextStyle(fontSize: 14),
                          ),
                          subtitle: Text(
                            AppLanguage.text(
                              context,
                              'Will be first to receive SMS',
                              'سيكون أول من تصله رسالة الطوارئ',
                            ),
                            style: const TextStyle(
                              fontSize: 12,
                              color: textMuted,
                            ),
                          ),
                          activeThumbColor: primary,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed:
                              isSaving ? null : () => Navigator.pop(ctx, false),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            AppLanguage.text(context, 'Cancel', 'إلغاء'),
                            style: const TextStyle(color: textMuted),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed:
                              isSaving
                                  ? null
                                  : () async {
                                    if (!formKey.currentState!.validate()) {
                                      return;
                                    }

                                    setDialogState(() => isSaving = true);

                                    final contactData = {
                                      'name': nameCtrl.text.trim(),
                                      'phone': phoneCtrl.text.trim(),
                                      'relation': relationCtrl.text.trim(),
                                      'is_primary': isPrimary ? 1 : 0,
                                    };

                                    if (existing == null) {
                                      await AppDatabase.instance.insertContact(
                                        contactData,
                                      );
                                    } else {
                                      await AppDatabase.instance.updateContact(
                                        existing['id'],
                                        contactData,
                                      );
                                    }

                                    if (ctx.mounted) {
                                      Navigator.pop(ctx, true);
                                    }
                                  },
                          child:
                              isSaving
                                  ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : Text(
                                    existing == null
                                        ? AppLanguage.text(
                                          context,
                                          'Add',
                                          'إضافة',
                                        )
                                        : AppLanguage.text(
                                          context,
                                          'Save',
                                          'حفظ',
                                        ),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        );
      },
    );

    nameCtrl.dispose();
    phoneCtrl.dispose();
    relationCtrl.dispose();

    if (saved == true && mounted) {
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
                ? const Center(child: CircularProgressIndicator(color: primary))
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
              child: const Icon(Icons.contact_phone, size: 60, color: primary),
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
              decoration: const BoxDecoration(
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

  Widget _dialogField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType type = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: primary, size: 20),
        filled: true,
        fillColor: background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: danger),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
    );
  }
}
