import 'package:flutter/material.dart';
import '../../core/database/app_database.dart';
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

  @override
  void initState() {
    super.initState();
    _loadIncidents();
  }

  Future<void> _loadIncidents() async {
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

  Color _urgencyColor(String? urgency) {
    switch (urgency) {
      case 'high':
        return const Color(0xFFDC2626);
      case 'med':
        return const Color(0xFFF97316);
      case 'low':
        return const Color(0xFF16A34A);
      default:
        return const Color(0xFF64748B);
    }
  }

  String _urgencyLabel(String? urgency) {
    switch (urgency) {
      case 'high':
        return 'HIGH';
      case 'med':
        return 'MEDIUM';
      case 'low':
        return 'LOW';
      default:
        return 'UNKNOWN';
    }
  }

  String _categoryDisplay(String? code) {
    const map = {
      'adult_choking': 'Adult Choking',
      'child_choking': 'Child Choking',
      'asthma': 'Asthma Attack',
      'anaphylaxis': 'Severe Allergy',
      'unconscious_breathing': 'Unconscious Breathing',
      'not_breathing_cpr': 'Not Breathing / CPR',
      'bleeding': 'Heavy Bleeding',
      'burns': 'Burn Injury',
      'fracture': 'Fracture',
      'seizure': 'Seizure',
      'stroke': 'Stroke',
      'unknown': 'Unknown',
    };

    return map[code] ?? (code ?? 'Unknown');
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null || isoDate.trim().isEmpty) return 'Unknown time';

    try {
      final dt = DateTime.parse(isoDate).toLocal();
      final months = [
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

      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');

      return '${dt.day} ${months[dt.month - 1]} ${dt.year} • $h:$m';
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Incident History',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF2563EB),
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [

          IconButton(
            tooltip: 'Sync',
            icon: const Icon(
              Icons.cloud_upload_rounded,
              color: Colors.white,
            ),
            onPressed: () async {
              await SyncService.syncIncidents();
              await _loadIncidents();
            },
          ),

          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadIncidents,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(color: Color(0xFF2563EB)),
      )
          : RefreshIndicator(
        color: const Color(0xFF2563EB),
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
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                itemCount: _filtered.length,
                itemBuilder: (context, index) {
                  return _buildIncidentCard(_filtered[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: const BoxDecoration(
        color: Color(0xFF2563EB),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _summaryBox(
              title: 'Total',
              value: _incidents.length.toString(),
              icon: Icons.history_rounded,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _summaryBox(
              title: 'Synced',
              value: _syncedCount.toString(),
              icon: Icons.cloud_done_rounded,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _summaryBox(
              title: 'Pending',
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
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    final filters = [
      {'value': 'all', 'label': 'All'},
      {'value': 'high', 'label': 'High'},
      {'value': 'med', 'label': 'Medium'},
      {'value': 'low', 'label': 'Low'},
    ];

    return Container(
      color: const Color(0xFFF8FAFC),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((f) {
            final selected = _filterUrgency == f['value'];

            return GestureDetector(
              onTap: () => _applyFilter(f['value']!),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFF2563EB) : Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: selected
                        ? const Color(0xFF2563EB)
                        : const Color(0xFFE2E8F0),
                  ),
                  boxShadow: [
                    if (selected)
                      BoxShadow(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.20),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                  ],
                ),
                child: Text(
                  f['label']!,
                  style: TextStyle(
                    color: selected ? Colors.white : const Color(0xFF475569),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Row(
        children: [
          Text(
            '${_filtered.length} incident${_filtered.length == 1 ? '' : 's'}',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          const Text(
            'Pull down to refresh',
            style: TextStyle(
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
            Row(
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
                          color: Color(0xFF0F172A),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(incident['created_at']?.toString()),
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            Row(
              children: [
                _statusChip(
                  label: _urgencyLabel(urgency),
                  icon: Icons.priority_high_rounded,
                  color: color,
                ),
                const SizedBox(width: 8),
                _statusChip(
                  label: synced ? 'SYNCED' : 'PENDING',
                  icon: synced
                      ? Icons.cloud_done_rounded
                      : Icons.cloud_upload_rounded,
                  color: synced
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFF97316),
                ),
                const SizedBox(width: 8),
                _statusChip(
                  label: _confidenceText(incident['confidence']),
                  icon: Icons.speed_rounded,
                  color: const Color(0xFF2563EB),
                ),
              ],
            ),

            if ((incident['input_text'] ?? '').toString().trim().isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  incident['input_text'].toString(),
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

            if (incident['lat'] != null && incident['lng'] != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    size: 18,
                    color: Color(0xFF64748B),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${incident['lat']}, ${incident['lng']}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
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
            color: const Color(0xFF2563EB),
            size: 56,
          ),
        ),

        const SizedBox(height: 22),

        Text(
          hasIncidents ? 'No incidents match this filter' : 'No incidents yet',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 10),

        Text(
          hasIncidents
              ? 'Try choosing another urgency filter.'
              : 'When you describe an emergency, saved incidents will appear here even offline.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 14,
            height: 1.5,
          ),
        ),

        const SizedBox(height: 24),

        OutlinedButton.icon(
          onPressed: _loadIncidents,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Refresh'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF2563EB),
            side: const BorderSide(color: Color(0xFF2563EB)),
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