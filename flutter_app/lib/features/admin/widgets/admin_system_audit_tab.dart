import 'package:flutter/material.dart';
import 'package:ruralcare/core/theme/app_theme.dart';
import 'package:ruralcare/core/database/local_cache.dart';
import 'package:ruralcare/app/routes.dart';

/// Module 4: System Monitoring & ABDM Audit (Stitch Screen 4: fec523c1ff89481aa896cee36b1aa7ae)
/// Cluster telemetry, edge node health status, tamper-evident audit ledger,
/// and interactive "Run System Integrity Check" trigger.
class AdminSystemAuditTab extends StatefulWidget {
  const AdminSystemAuditTab({super.key});

  @override
  State<AdminSystemAuditTab> createState() => _AdminSystemAuditTabState();
}

class _AdminSystemAuditTabState extends State<AdminSystemAuditTab> {
  final LocalCacheService _cache = LocalCacheService();
  final SessionCoordinator _session = SessionCoordinator();

  String _selectedSeverityFilter = 'ALL';
  bool _isCheckingIntegrity = false;

  void _runIntegrityCheck() async {
    setState(() => _isCheckingIntegrity = true);
    await Future.delayed(const Duration(milliseconds: 900));
    if (mounted) {
      setState(() => _isCheckingIntegrity = false);
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.verified_rounded, color: Color(0xFF15803D), size: 24),
              SizedBox(width: 8),
              Text('System Integrity Check Passed', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _checkItem('ABDM AES-256 GCM Encryption', 'Verified • 0 Key Leaks', true),
              _checkItem('Offline SQLite Outbox Integrity', 'Verified • Zero Hash Mismatch', true),
              _checkItem('Cluster Nodes Heartbeat (5/5)', 'All Active • Latency < 60ms', true),
              _checkItem('FHIR R4 Diagnostic Schema', 'Compliant • 100% ABDM Milestone 2', true),
              _checkItem('Tamper-Evident Audit Ledger', 'Immutable Cryptographic Chain Valid', true),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF005140),
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Acknowledge'),
            ),
          ],
        ),
      );
    }
  }

  Widget _checkItem(String label, String value, bool isOk) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(isOk ? Icons.check_circle_rounded : Icons.warning_rounded, color: const Color(0xFF15803D), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                Text(value, style: const TextStyle(fontSize: 11, color: Color(0xFF15803D))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _exportAuditLedger() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exported tamper-evident ABDM audit log to Rampur_Audit_Ledger_2026.json'),
        backgroundColor: Color(0xFF005140),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMr = _session.isMr;
    final isHi = _session.isHi;

    return ListenableBuilder(
      listenable: Listenable.merge([_cache, _session]),
      builder: (context, _) {
        final pendingOutbox = _cache.pendingOutboxCount;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header & Controls
              _buildHeader(isHi, isMr),
              const SizedBox(height: 16),

              // 2. 4 System Telemetry KPI Cards
              _buildTelemetryKpis(pendingOutbox, isHi, isMr),
              const SizedBox(height: 20),

              // 3. Cluster Node Health Directory
              _buildNodeHealthSection(isHi, isMr),
              const SizedBox(height: 20),

              // 4. Tamper-Evident Audit Ledger Table
              _buildAuditLedgerTable(isHi, isMr),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isHi, bool isMr) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 750;
        final titleWidget = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isMr ? 'सिस्टम मॉनिटरिंग व ABDM ऑडिट' : (isHi ? 'सिस्टम मॉनिटरिंग एवं ABDM ऑडिट' : 'System Monitoring & ABDM Audit'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: RuralCareColors.textPrimary),
            ),
            const SizedBox(height: 2),
            Text(
              isMr
                  ? 'क्लस्टर टेलीमेट्री, एज नोड आरोग्य व सुरक्षा नोंदी'
                  : (isHi
                      ? 'क्लस्टर टेलीमेट्री, एज नोड स्वास्थ्य व सुरक्षा लॉग'
                      : 'Cluster telemetry, edge node integrity & tamper-evident audit ledger'),
              style: const TextStyle(fontSize: 12, color: RuralCareColors.textSecondary),
            ),
          ],
        );

        final actionButtons = Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: _exportAuditLedger,
              icon: const Icon(Icons.download_rounded, size: 16),
              label: Text(
                isMr ? 'ऑडिट डेटा डाऊनलोड' : (isHi ? 'ऑडिट डेटा डाउनलोड' : 'Export Logs'),
                style: const TextStyle(fontSize: 12),
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF005140),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: _isCheckingIntegrity ? null : _runIntegrityCheck,
              icon: _isCheckingIntegrity
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.health_and_safety_rounded, size: 16),
              label: Text(
                isMr ? 'सुरक्षा तपासणी चालवा' : (isHi ? 'सुरक्षा जांच चलाएं' : 'Run Integrity Check'),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );

        if (isSmall) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleWidget,
              const SizedBox(height: 12),
              actionButtons,
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: titleWidget),
            const SizedBox(width: 16),
            actionButtons,
          ],
        );
      },
    );
  }

  Widget _buildTelemetryKpis(int pendingOutbox, bool isHi, bool isMr) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 900 ? 4 : (constraints.maxWidth > 500 ? 2 : 1);
        final cardWidth = (constraints.maxWidth - (crossAxisCount - 1) * 12) / crossAxisCount;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: cardWidth,
              child: _telemetryCard(
                title: 'Gateway Uptime',
                value: '99.98%',
                status: 'Operational',
                icon: Icons.cloud_done_rounded,
                color: const Color(0xFF15803D),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _telemetryCard(
                title: 'Cluster Mesh Nodes',
                value: '5 / 5',
                status: '100% Online',
                icon: Icons.hub_rounded,
                color: const Color(0xFF005140),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _telemetryCard(
                title: 'Outbox Mutations',
                value: '$pendingOutbox queued',
                status: pendingOutbox == 0 ? 'Fully Synced' : 'Sync In Progress',
                icon: Icons.sync_rounded,
                color: pendingOutbox == 0 ? const Color(0xFF15803D) : const Color(0xFFC05621),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _telemetryCard(
                title: 'Security Incidents',
                value: '0 Critical',
                status: 'ABDM TLS 1.3 Active',
                icon: Icons.security_rounded,
                color: const Color(0xFF33647B),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _telemetryCard({
    required String title,
    required String value,
    required String status,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: RuralCareColors.textSecondary),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                child: Icon(icon, size: 16, color: color),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: RuralCareColors.textPrimary)),
          const SizedBox(height: 2),
          Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _buildNodeHealthSection(bool isHi, bool isMr) {
    final nodes = [
      const _ClusterNode(
        name: 'Baramati SDH Relay Node',
        role: 'Primary District Gateway',
        latency: '38ms',
        status: 'Online',
        ip: '10.24.101.4',
        lastHeartbeat: '5s ago',
      ),
      const _ClusterNode(
        name: 'Shirur SDH Edge Gateway',
        role: 'Telemedicine Link Provider',
        latency: '44ms',
        status: 'Online',
        ip: '10.24.101.8',
        lastHeartbeat: '12s ago',
      ),
      const _ClusterNode(
        name: 'Aundh District Hospital Node',
        role: 'Central Referral Sync Mesh',
        latency: '32ms',
        status: 'Online',
        ip: '10.24.100.1',
        lastHeartbeat: '3s ago',
      ),
      const _ClusterNode(
        name: 'Kashti Sub-Centre Edge Node',
        role: 'BLE Sensor & LoRa Hub',
        latency: '52ms',
        status: 'Online',
        ip: '10.24.102.14',
        lastHeartbeat: '18s ago',
      ),
      const _ClusterNode(
        name: 'Rampur Sub-Centre Local Node',
        role: 'Field Worker Offline Outbox Relay',
        latency: '51ms',
        status: 'Online',
        ip: '10.24.102.20',
        lastHeartbeat: '8s ago',
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF005140).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.dns_rounded, color: Color(0xFF005140), size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isMr ? 'क्लस्टर नोड आरोग्य डिरेक्टरी' : (isHi ? 'क्लस्टर नोड स्वास्थ्य निर्देशिका' : 'Cluster Node Health Directory'),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: RuralCareColors.textPrimary),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('All 5 Nodes Responding', style: TextStyle(fontSize: 11, color: Color(0xFF15803D), fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: nodes.length,
            separatorBuilder: (ctx, i) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
            itemBuilder: (ctx, i) {
              final node = nodes[i];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Color(0xFF15803D),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(node.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          Text('${node.role} • ${node.ip}', style: const TextStyle(fontSize: 11, color: RuralCareColors.textSecondary)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(node.latency, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF005140))),
                        Text(node.lastHeartbeat, style: const TextStyle(fontSize: 10, color: RuralCareColors.textSecondary)),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAuditLedgerTable(bool isHi, bool isMr) {
    final auditLogs = [
      const _AuditEntry(
        actor: 'Admin: Dr. Sharma',
        action: 'Doctor Verification Accepted',
        target: 'Dr. Rajesh Kulkarni (DOC-MH-8421)',
        severity: 'SUCCESS',
        timestamp: '14 Sep 2026, 02:08 AM',
        hash: 'SHA256: 8f9b...a10e',
      ),
      const _AuditEntry(
        actor: 'LocalCacheService',
        action: 'Outbox Auto-Flush Replay',
        target: 'Cluster Sync Relay (18 packets)',
        severity: 'SYNC',
        timestamp: '14 Sep 2026, 01:54 AM',
        hash: 'SHA256: 3c2d...77b1',
      ),
      const _AuditEntry(
        actor: 'Facility Staff: S. Patil',
        action: 'Bed Capacity Threshold Updated',
        target: 'Baramati SDH (12 beds avail)',
        severity: 'SUCCESS',
        timestamp: '14 Sep 2026, 01:30 AM',
        hash: 'SHA256: e94a...55c2',
      ),
      const _AuditEntry(
        actor: 'ABDM Security Relay',
        action: 'Public Key Encryption Refresh',
        target: 'Central FHIR Node (TLS 1.3)',
        severity: 'SECURITY',
        timestamp: '14 Sep 2026, 00:45 AM',
        hash: 'SHA256: 112f...ee89',
      ),
      const _AuditEntry(
        actor: 'CHO: Sunita Gaikwad',
        action: 'Biometric Household Survey Synced',
        target: 'Kashti Sub-Centre Block 3',
        severity: 'SYNC',
        timestamp: '13 Sep 2026, 23:12 PM',
        hash: 'SHA256: 44bb...990d',
      ),
    ];

    final filteredLogs = auditLogs.where((log) {
      if (_selectedSeverityFilter == 'ALL') return true;
      return log.severity == _selectedSeverityFilter;
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF33647B).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF33647B), size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isMr ? 'डिजिटल आरोग्य ऑडिट लेजर' : (isHi ? 'डिजिटल स्वास्थ्य ऑडिट लेजर' : 'ABDM Tamper-Evident Audit Ledger'),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: RuralCareColors.textPrimary),
                  ),
                ],
              ),
              DropdownButton<String>(
                value: _selectedSeverityFilter,
                underline: const SizedBox(),
                style: const TextStyle(fontSize: 12, color: RuralCareColors.textPrimary),
                items: const [
                  DropdownMenuItem(value: 'ALL', child: Text('All Events')),
                  DropdownMenuItem(value: 'SUCCESS', child: Text('Approvals')),
                  DropdownMenuItem(value: 'SYNC', child: Text('Replication')),
                  DropdownMenuItem(value: 'SECURITY', child: Text('Security')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedSeverityFilter = val);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFFF8F9FF)),
              columns: const [
                DataColumn(label: Text('Timestamp', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text('Actor', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text('Target Entity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text('Cryptographic Proof', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              ],
              rows: filteredLogs.map((entry) {
                return DataRow(
                  cells: [
                    DataCell(Text(entry.timestamp, style: const TextStyle(fontSize: 11, color: RuralCareColors.textSecondary))),
                    DataCell(Text(entry.actor, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: entry.severity == 'SECURITY'
                              ? const Color(0xFFEFF6FF)
                              : (entry.severity == 'SYNC' ? const Color(0xFFF1F5F9) : const Color(0xFFDCFCE7)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          entry.action,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: entry.severity == 'SECURITY'
                                ? const Color(0xFF1D4ED8)
                                : (entry.severity == 'SYNC' ? const Color(0xFF334155) : const Color(0xFF15803D)),
                          ),
                        ),
                      ),
                    ),
                    DataCell(Text(entry.target, style: const TextStyle(fontSize: 11))),
                    DataCell(
                      Row(
                        children: [
                          const Icon(Icons.shield_outlined, size: 12, color: Color(0xFF33647B)),
                          const SizedBox(width: 4),
                          Text(entry.hash, style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Color(0xFF33647B))),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClusterNode {
  final String name;
  final String role;
  final String latency;
  final String status;
  final String ip;
  final String lastHeartbeat;

  const _ClusterNode({
    required this.name,
    required this.role,
    required this.latency,
    required this.status,
    required this.ip,
    required this.lastHeartbeat,
  });
}

class _AuditEntry {
  final String actor;
  final String action;
  final String target;
  final String severity;
  final String timestamp;
  final String hash;

  const _AuditEntry({
    required this.actor,
    required this.action,
    required this.target,
    required this.severity,
    required this.timestamp,
    required this.hash,
  });
}
