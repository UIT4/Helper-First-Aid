import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/database/app_database.dart';

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() =>
      _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  List<Map<String, dynamic>> _contacts = [];
  bool _isLoading = true;

  // =====================================================
  // LIFECYCLE
  // =====================================================

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  // =====================================================
  // LOAD
  // =====================================================

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

  // =====================================================
  // CALL
  // =====================================================

  Future<void> _makeCall(String phone) async {
    final Uri url = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      _showSnackbar('Cannot make call', isError: true);
    }
  }

  // =====================================================
  // DELETE
  // =====================================================

  Future<void> _deleteContact(int id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Contact',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF475569))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            onPressed: () => Navigator.pop(context, true),
            child:
            const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AppDatabase.instance.deleteContact(id);
      _showSnackbar('Contact deleted');
      await _loadContacts();
    }
  }

  // =====================================================
  // SET PRIMARY
  // =====================================================

  Future<void> _setPrimary(int id) async {
    await AppDatabase.instance.setPrimaryContact(id);
    _showSnackbar('Primary contact updated ✓');
    await _loadContacts();
  }

  // =====================================================
  // ADD / EDIT DIALOG  — FIX: no setState after dispose
  // =====================================================

  Future<void> _showContactDialog({Map<String, dynamic>? existing}) async {
    final nameCtrl     = TextEditingController(text: existing?['name']     ?? '');
    final phoneCtrl    = TextEditingController(text: existing?['phone']    ?? '');
    final relationCtrl = TextEditingController(text: existing?['relation'] ?? '');
    bool isPrimary     = (existing?['is_primary'] ?? 0) == 1;
    final formKey      = GlobalKey<FormState>();
    bool isSaving      = false;

    // FIX: capture result from dialog instead of calling setState inside it
    final bool? saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                  color: const Color(0xFF2563EB),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                existing == null ? 'Add Contact' : 'Edit Contact',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
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

                  // Name
                  _dialogField(
                    controller: nameCtrl,
                    label: 'Full Name',
                    icon: Icons.person,
                    validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Name is required' : null,
                  ),
                  const SizedBox(height: 12),

                  // Phone
                  _dialogField(
                    controller: phoneCtrl,
                    label: 'Phone Number',
                    icon: Icons.phone,
                    type: TextInputType.phone,
                    validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Phone is required' : null,
                  ),
                  const SizedBox(height: 12),

                  // Relation
                  _dialogField(
                    controller: relationCtrl,
                    label: 'Relation (e.g. Father)',
                    icon: Icons.people,
                  ),
                  const SizedBox(height: 8),

                  // Primary toggle
                  SwitchListTile(
                    value: isPrimary,
                    onChanged: (v) => setDialogState(() => isPrimary = v),
                    title: const Text('Set as Primary Contact',
                        style: TextStyle(fontSize: 14)),
                    subtitle: const Text('Will be first to receive SMS',
                        style: TextStyle(fontSize: 12, color: Color(0xFF475569))),
                    activeThumbColor: const Color(0xFF2563EB),
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
                    onPressed: () => Navigator.pop(ctx, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Cancel',
                        style: TextStyle(color: Color(0xFF475569))),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: isSaving
                        ? null
                        : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => isSaving = true);

                      final contactData = {
                        'name':       nameCtrl.text.trim(),
                        'phone':      phoneCtrl.text.trim(),
                        'relation':   relationCtrl.text.trim(),
                        'is_primary': isPrimary ? 1 : 0,
                      };

                      if (existing == null) {
                        await AppDatabase.instance
                            .insertContact(contactData);
                      } else {
                        await AppDatabase.instance
                            .updateContact(existing['id'], contactData);
                      }

                      // FIX: pop with true to signal success
                      if (ctx.mounted) Navigator.pop(ctx, true);
                    },
                    child: isSaving
                        ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                        : Text(
                      existing == null ? 'Add' : 'Save',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    Future<void> showContactDialog({Map<String, dynamic>? existing}) async {
      final nameCtrl     = TextEditingController(text: existing?['name'] ?? '');
      final phoneCtrl    = TextEditingController(text: existing?['phone'] ?? '');
      final relationCtrl = TextEditingController(text: existing?['relation'] ?? '');
      bool isPrimary     = (existing?['is_primary'] ?? 0) == 1;
      final formKey      = GlobalKey<FormState>();
      bool isSaving      = false;

      final bool? saved = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
          ),
        ),
      );

      if (saved == true && mounted) {
        _showSnackbar(existing == null ? 'Contact added ✓' : 'Contact updated ✓');
        await _loadContacts();
      }
    }

    // FIX: reload and show snackbar only after dialog is fully closed
    if (saved == true && mounted) {
      _showSnackbar(existing == null ? 'Contact added ✓' : 'Contact updated ✓');
      await _loadContacts();
    }
  }

  // =====================================================
  // SNACKBAR
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

  // =====================================================
  // BUILD
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Emergency Contacts',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFFDC2626),
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: const [],
      ),
      body: _isLoading
          ? const Center(
          child: CircularProgressIndicator(color: Color(0xFF2563EB)))
          : _contacts.isEmpty
          ? _buildEmptyState()
          : _buildContactsList(),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF2563EB),
        onPressed: () => _showContactDialog(),
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text('Add Contact',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  // =====================================================
  // EMPTY STATE
  // =====================================================

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFFDBEAFE),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.contact_phone,
                size: 60, color: Color(0xFF2563EB)),
          ),
          const SizedBox(height: 20),
          const Text(
            'No Emergency Contacts',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add contacts to notify in emergencies',
            style: TextStyle(fontSize: 14, color: Color(0xFF475569)),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // CONTACTS LIST
  // =====================================================

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
            border: isPrimary
                ? Border.all(color: const Color(0xFF2563EB), width: 1.5)
                : null,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 3))
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Avatar
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: isPrimary
                          ? const Color(0xFFDBEAFE)
                          : const Color(0xFFF1F5F9),
                      child: Text(
                        (contact['name'] ?? '?')[0].toUpperCase(),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isPrimary
                              ? const Color(0xFF2563EB)
                              : const Color(0xFF475569),
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
                            color: Color(0xFF2563EB),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.star,
                              size: 10, color: Colors.white),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 14),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              contact['name'] ?? 'Unknown',
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isPrimary) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2563EB),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text('PRIMARY',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ]
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        contact['phone'] ?? '',
                        style: const TextStyle(
                            fontSize: 14, color: Color(0xFF475569)),
                      ),
                      if ((contact['relation'] ?? '').isNotEmpty)
                        Text(
                          contact['relation'],
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFFCBD5E1)),
                        ),
                    ],
                  ),
                ),

                // Actions
                Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.call,
                          color: Color(0xFF16A34A), size: 26),
                      onPressed: () => _makeCall(contact['phone'] ?? ''),
                      tooltip: 'Call',
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert,
                          color: Color(0xFF475569)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      onSelected: (value) async {
                        if (value == 'edit') {
                          await _showContactDialog(existing: contact);
                        } else if (value == 'primary') {
                          await _setPrimary(contact['id']);
                        } else if (value == 'delete') {
                          await _deleteContact(
                              contact['id'], contact['name'] ?? '');
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(children: [
                            Icon(Icons.edit, size: 18, color: Color(0xFF2563EB)),
                            SizedBox(width: 10),
                            Text('Edit'),
                          ]),
                        ),
                        if (!isPrimary)
                          const PopupMenuItem(
                            value: 'primary',
                            child: Row(children: [
                              Icon(Icons.star,
                                  size: 18, color: Color(0xFFF59E0B)),
                              SizedBox(width: 10),
                              Text('Set as Primary'),
                            ]),
                          ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(children: [
                            Icon(Icons.delete,
                                size: 18, color: Color(0xFFDC2626)),
                            SizedBox(width: 10),
                            Text('Delete',
                                style: TextStyle(color: Color(0xFFDC2626))),
                          ]),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // =====================================================
  // DIALOG FIELD HELPER
  // =====================================================

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
        prefixIcon: Icon(icon, color: const Color(0xFF2563EB), size: 20),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
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
          borderSide:
          const BorderSide(color: Color(0xFF2563EB), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDC2626)),
        ),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}