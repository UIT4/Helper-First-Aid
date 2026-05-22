import 'package:flutter/material.dart';

import '../../core/database/app_database.dart';
import '../../core/language/app_language.dart';
import '../../core/network/sync_service.dart';

class IncidentHistoryScreen extends StatefulWidget {
  const IncidentHistoryScreen({super.key});

  @override
  State<IncidentHistoryScreen> createState() => _IncidentHistoryScreenState();
}

class _IncidentHistoryScreenState extends State<IncidentHistoryScreen> {
  List<Map<String, dynamic>> _incidents = [];
  List<Map<String, dynamic>> _filtered = [];

  bool _isLoading = true;
  String _filterUrgency = 'all';

  static const Color primary = Color(0xFF2563EB);
  static const Color danger = Color(0xFFDC2626);
  static const Color warning = Color(0xFFF97316);
  static const Color success = Color(0xFF16A34A);
  static const Color background = Color(0xFFF8FAFC);
  static const Color textDark = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    _loadIncidents();
  }

  Future<void> _loadIncidents() async {
    setState(() => _isLoading = true);

    final data = await AppDatabase.instance.getIncidents();

    if (!mounted) return;

    setState(() {
      _incidents = data;
      _applyFilterWithoutSetState(_filterUrgency, data);
      _isLoading = false;
    });
  }

  void _applyFilterWithoutSetState(
      String urgency,
      List<Map<String, dynamic>> source,
      ) {
    if (urgency == 'all') {
      _filtered = source;
    } else {
      _filtered = source.where((i) => i['urgency'] == urgency).toList();
    }
  }

  void _applyFilter(String urgency) {
    setState(() {
      _filterUrgency = urgency;

      if (urgency == 'all') {
        _filtered = _incidents;
      } else {
        _filtered = _incidents.where((i) => i['urgency'] == urgency).toList();
      }
    });
  }

  Future<void> _syncNow() async {
    await SyncService.syncIncidents();
    await _loadIncidents();

    if (!mounted) return;

    _showSnackbar(
      AppLanguage.text(
        context,
        'Sync completed ✓',
        'تمت المزامنة ✓',
      ),
    );
  }

  void _showSnackbar(String msg, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? danger : success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Color _urgencyColor(String? urgency) {
    switch (urgency) {
      case 'high':
        return danger;
      case 'med':
        return warning;
      case 'low':
        return success;
      default:
        return textMuted;
    }
  }

  String _urgencyLabel(String? urgency) {
    switch (urgency) {
      case 'high':
        return AppLanguage.text(context, 'HIGH', 'عالي');
      case 'med':
        return AppLanguage.text(context, 'MEDIUM', 'متوسط');
      case 'low':
        return AppLanguage.text(context, 'LOW', 'منخفض');
      default:
        return AppLanguage.text(context, 'UNKNOWN', 'غير معروف');
    }
  }

  String _categoryDisplay(String? code) {
    final isArabic = AppLanguage.isArabicContext(context);

    final map = {
      'adult_choking': {
        'en': 'Adult Choking',
        'ar': 'اختناق بالغ',
      },
      'child_choking': {
        'en': 'Child Choking',
        'ar': 'اختناق طفل',
      },
      'asthma': {
        'en': 'Asthma Attack',
        'ar': 'نوبة ربو',
      },
      'anaphylaxis': {
        'en': 'Severe Allergy',
        'ar': 'حساسية شديدة',
      },
      'unconscious_breathing': {
        'en': 'Unconscious Breathing',
        'ar': 'فاقد الوعي ويتنفس',
      },
      'not_breathing_cpr': {
        'en': 'Not Breathing / CPR',
        'ar': 'لا يتنفس / إنعاش',
      },
      'bleeding': {
        'en': 'Heavy Bleeding',
        'ar': 'نزيف شديد',
      },
      'burns': {
        'en': 'Burn Injury',
        'ar': 'حروق',
      },
      'fracture': {
        'en': 'Fracture',
        'ar': 'كسر',
      },
      'seizure': {
        'en': 'Seizure',
        'ar': 'تشنج',
      },
      'stroke': {
        'en': 'Stroke',
        'ar': 'سكتة دماغية',
      },
      'unknown': {
        'en': 'Unknown',
        'ar': 'غير معروف',
      },
    };

    final item = map[code];

    if (item == null) {
      return code ?? AppLanguage.text(context, 'Unknown', 'غير معروف');
    }

    return isArabic ? item['ar']! : item['en']!;
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null || isoDate.trim().isEmpty) {
      return AppLanguage.text(context, 'Unknown time', 'وقت غير معروف');
    }

    try {
      final dt = DateTime.parse(isoDate).toLocal();

      final monthsEn = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];

      final monthsAr = [
        'يناير',
        'فبراير',
        'مارس',
        'أبريل',
        'مايو',
        'يونيو',
        'يوليو',
        'أغسطس',
        'سبتمبر',
        'أكتوبر',
        'نوفمبر',
        'ديسمبر',
      ];

      final isArabic = AppLanguage.isArabicContext(context);
      final months = isArabic ? monthsAr : monthsEn;

      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');

      return '${dt.day} ${months[dt.month - 1]} ${dt.year} • $hour:$minute';
    } catch (_) {
      return isoDate;
    }
  }

  String _confidenceText(dynamic value) {
    if (value == null) return '—';

    final double confidence = value is num
        ? value.toDouble()
        : double.tryParse(value.toString()) ?? 0.0;

    return '${(confidence * 100).clamp(0, 100).toStringAsFixed(0)}%';
  }

  bool _isSynced(Map<String, dynamic> incident) {
    final synced = incident['synced'];
    final serverId = incident['server_id'];

    return synced == 1 || synced == true || serverId != null;
  }

  int get _syncedCount => _incidents.where(_isSynced).length;

  int get _unsyncedCount => _incidents.length - _syncedCount;

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
              'Incident History',
              'سجل الحوادث',
            ),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: primary,
          centerTitle: true,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              tooltip: AppLanguage.text(context, 'Sync', 'مزامنة'),
              icon: const Icon(
                Icons.cloud_upload_rounded,
                color: Colors.white,
              ),
              onPressed: _syncNow,
            ),
            IconButton(
              tooltip: AppLanguage.text(context, 'Refresh', 'تحديث'),
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _loadIncidents,
            ),
          ],
        ),
        body: _isLoading
            ? const Center(
          child: CircularProgressIndicator(color: primary),
        )
            : RefreshIndicator(
          color: primary,
          onRefresh: _loadIncidents,
          child: Column(
            children: [
              _buildSummaryHeader(),
              _buildFilterBar(),
              _buildCountRow(),
              Expanded(
                child: _filtered.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding:
                  const EdgeInsets.fromLTRB(16, 0, 16, 18),
                  itemCount: _filtered.length,
                  itemBuilder: (context, index) {
                    return _buildIncidentCard(_filtered[index]);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: const BoxDecoration(
        color: primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _summaryBox(
              title: AppLanguage.text(context, 'Total', 'الإجمالي'),
              value: _incidents.length.toString(),
              icon: Icons.history_rounded,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _summaryBox(
              title: AppLanguage.text(context, 'Synced', 'تمت المزامنة'),
              value: _syncedCount.toString(),
              icon: Icons.cloud_done_rounded,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _summaryBox(
              title: AppLanguage.text(context, 'Pending', 'قيد الانتظار'),
              value: _unsyncedCount.toString(),
              icon: Icons.cloud_upload_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryBox({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    final filters = [
      {
        'value': 'all',
        'label': AppLanguage.text(context, 'All', 'الكل'),
      },
      {
        'value': 'high',
        'label': AppLanguage.text(context, 'High', 'عالي'),
      },
      {
        'value': 'med',
        'label': AppLanguage.text(context, 'Medium', 'متوسط'),
      },
      {
        'value': 'low',
        'label': AppLanguage.text(context, 'Low', 'منخفض'),
      },
    ];

    return Container(
      color: background,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((filter) {
            final value = filter['value']!;
            final label = filter['label']!;
            final selected = _filterUrgency == value;

            return GestureDetector(
              onTap: () => _applyFilter(value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsetsDirectional.only(end: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: selected ? primary : Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: selected ? primary : const Color(0xFFE2E8F0),
                  ),
                  boxShadow: [
                    if (selected)
                      BoxShadow(
                        color: primary.withValues(alpha: 0.20),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                  ],
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: selected ? Colors.white : textMuted,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCountRow() {
    final countText = _filtered.length == 1
        ? AppLanguage.text(context, '1 incident', 'حادث واحد')
        : AppLanguage.text(
      context,
      '${_filtered.length} incidents',
      '${_filtered.length} حوادث',
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Row(
        children: [
          Text(
            countText,
            style: const TextStyle(
              fontSize: 13,
              color: textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            AppLanguage.text(
              context,
              'Pull down to refresh',
              'اسحب للأسفل للتحديث',
            ),
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncidentCard(Map<String, dynamic> incident) {
    final urgency = incident['urgency']?.toString();
    final color = _urgencyColor(urgency);
    final synced = _isSynced(incident);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildIncidentTopRow(incident, color),
            const SizedBox(height: 14),
            _buildStatusRow(incident, urgency, color, synced),
            _buildInputTextBox(incident),
            _buildLocationRow(incident),
          ],
        ),
      ),
    );
  }

  Widget _buildIncidentTopRow(Map<String, dynamic> incident, Color color) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(
            Icons.health_and_safety_rounded,
            color: color,
            size: 26,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _categoryDisplay(
                  incident['predicted_category_code']?.toString(),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: textDark,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatDate(incident['created_at']?.toString()),
                style: const TextStyle(
                  color: textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusRow(
      Map<String, dynamic> incident,
      String? urgency,
      Color color,
      bool synced,
      ) {
    return Row(
      children: [
        _statusChip(
          label: _urgencyLabel(urgency),
          icon: Icons.priority_high_rounded,
          color: color,
        ),
        const SizedBox(width: 8),
        _statusChip(
          label: synced
              ? AppLanguage.text(context, 'SYNCED', 'تمت المزامنة')
              : AppLanguage.text(context, 'PENDING', 'قيد الانتظار'),
          icon: synced ? Icons.cloud_done_rounded : Icons.cloud_upload_rounded,
          color: synced ? success : warning,
        ),
        const SizedBox(width: 8),
        _statusChip(
          label: _confidenceText(incident['confidence']),
          icon: Icons.speed_rounded,
          color: primary,
        ),
      ],
    );
  }

  Widget _buildInputTextBox(Map<String, dynamic> incident) {
    final input = (incident['input_text'] ?? '').toString().trim();

    if (input.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            input,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF334155),
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationRow(Map<String, dynamic> incident) {
    final lat = incident['lat'];
    final lng = incident['lng'];

    if (lat == null || lng == null) return const SizedBox.shrink();

    return Column(
      children: [
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(
              Icons.location_on_rounded,
              size: 18,
              color: textMuted,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '$lat, $lng',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: textMuted,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _statusChip({
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final bool hasIncidents = _incidents.isNotEmpty;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
      children: [
        Container(
          width: 110,
          height: 110,
          decoration: const BoxDecoration(
            color: Color(0xFFEFF6FF),
            shape: BoxShape.circle,
          ),
          child: Icon(
            hasIncidents ? Icons.filter_alt_off_rounded : Icons.history_rounded,
            color: primary,
            size: 56,
          ),
        ),
        const SizedBox(height: 22),
        Text(
          hasIncidents
              ? AppLanguage.text(
            context,
            'No incidents match this filter',
            'لا توجد حوادث تطابق هذا الفلتر',
          )
              : AppLanguage.text(
            context,
            'No incidents yet',
            'لا توجد حوادث بعد',
          ),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: textDark,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          hasIncidents
              ? AppLanguage.text(
            context,
            'Try choosing another urgency filter.',
            'جرّب اختيار فلتر خطورة آخر.',
          )
              : AppLanguage.text(
            context,
            'When you describe an emergency, saved incidents will appear here even offline.',
            'عندما تصف حالة طارئة، ستظهر الحوادث المحفوظة هنا حتى دون إنترنت.',
          ),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: textMuted,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: _loadIncidents,
          icon: const Icon(Icons.refresh_rounded),
          label: Text(
            AppLanguage.text(context, 'Refresh', 'تحديث'),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: primary,
            side: const BorderSide(color: primary),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ],
    );
  }
}
