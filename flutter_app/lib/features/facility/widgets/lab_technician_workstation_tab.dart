import 'package:flutter/material.dart';
import 'package:ruralcare/app/routes.dart';
import 'package:ruralcare/core/theme/app_theme.dart';
import 'package:ruralcare/data/models/facility_dto.dart';
import 'package:ruralcare/data/repositories/facility_repository.dart';
import 'package:ruralcare/features/facility/utils/facility_strings.dart';

/// Dedicated Lab Technician Workstation
/// When a Lab Technician logs in, they see STRICTLY and ONLY Diagnostic Worklist,
/// Sample Tracking, Test Result Entry, and Lab Reagents/Kits.
class LabTechnicianWorkstationTab extends StatefulWidget {
  const LabTechnicianWorkstationTab({super.key});

  @override
  State<LabTechnicianWorkstationTab> createState() => _LabTechnicianWorkstationTabState();
}

class _LabTechnicianWorkstationTabState extends State<LabTechnicianWorkstationTab> {
  int _activeSubTab = 0; // 0: Diagnostic Worklist, 1: Reagents & Kits

  void _showEnterResultDialog(BuildContext context, DiagnosticOrderDto order, FacilityRepository facRepo) {
    final resultCtrl = TextEditingController();
    String flag = 'Normal';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Enter Results: ${order.testName}', style: AppTypography.cardTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Patient: ${order.patientName} (${order.patientRuralCareId})', style: AppTypography.supporting),
              const SizedBox(height: 12),
              TextField(
                controller: resultCtrl,
                decoration: const InputDecoration(
                  labelText: 'Diagnostic Observation / Value',
                  hintText: 'e.g. 13.5 g/dL or Non-Reactive',
                ),
              ),
              const SizedBox(height: 14),
              const Text('Clinical Flag', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Row(
                children: ['Normal', 'Elevated', 'Critical'].map((val) {
                  final isSelected = flag == val;
                  return InkWell(
                    onTap: () => setModalState(() => flag = val),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (val == 'Critical' ? RuralCareColors.critical : const Color(0xFF0A6B56))
                            : RuralCareColors.surfaceSubtle,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        val,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : RuralCareColors.textPrimary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0A6B56),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final res = resultCtrl.text.trim().isEmpty ? 'Verified Normal' : '${resultCtrl.text.trim()} ($flag)';
                facRepo.updateDiagnosticOrderStatus(order.id, 'COMPLETED', result: res);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Report generated and certified for ${order.patientName}.'),
                    backgroundColor: RuralCareColors.success,
                  ),
                );
              },
              child: const Text('Certify & Sign Off'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionCoordinator();
    final facRepo = FacilityRepository();
    final strings = FacilityStrings.of(session);
    final staff = facRepo.currentStaffSession;

    return ListenableBuilder(
      listenable: facRepo,
      builder: (context, _) {
        final diagnosticItems = facRepo.inventory.where((i) => i.category == 'DIAGNOSTICS').toList();
        final diagnosticOrders = facRepo.diagnosticOrders;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Lab Tech Identity Banner
              Container(
                decoration: AppDecorations.card(),
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: RuralCareColors.teal,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.biotech_rounded, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(strings.labWorkstation, style: AppTypography.cardTitle),
                          const SizedBox(height: 2),
                          Text(
                            '${facRepo.currentFacility.name} • ${staff?.staffName ?? "Lab Diagnostics Officer"}',
                            style: AppTypography.supporting,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: AppDecorations.statusBadge(background: const Color(0xFFE8F5F2)),
                                child: Text(
                                  'REG: ${staff?.licenseOrEmployeeId ?? "LAB-TECH-202"}',
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: RuralCareColors.teal),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: AppDecorations.statusBadge(background: const Color(0xFFECFDF5)),
                                child: const Text(
                                  'Analyzers Calibrated • Verified',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: RuralCareColors.success),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // KPI Metrics
              Row(
                children: [
                  Expanded(
                    child: _metricCard(
                      'Worklist Queue',
                      '${diagnosticOrders.where((d) => d.status != "COMPLETED").length}',
                      'Pending Investigations',
                      RuralCareColors.teal,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _metricCard(
                      'Analyzing',
                      '${diagnosticOrders.where((d) => d.status == "ANALYZING").length}',
                      'In Processing',
                      const Color(0xFFB45309),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _metricCard(
                      'Certified Today',
                      '${diagnosticOrders.where((d) => d.status == "COMPLETED").length}',
                      'ABDM Signed Reports',
                      RuralCareColors.success,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Sub Tabs
              Container(
                decoration: BoxDecoration(
                  color: RuralCareColors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(child: _tabButton('Investigation Worklist', 0, Icons.assignment_outlined)),
                    Expanded(child: _tabButton('Reagents & Test Kits', 1, Icons.science_outlined)),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              if (_activeSubTab == 0)
                _buildWorklist(context, diagnosticOrders, facRepo, strings)
              else
                _buildReagentsList(context, diagnosticItems, facRepo, strings),
            ],
          ),
        );
      },
    );
  }

  Widget _tabButton(String title, int index, IconData icon) {
    final isSelected = _activeSubTab == index;
    return InkWell(
      onTap: () => setState(() => _activeSubTab = index),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: isSelected ? RuralCareColors.teal : RuralCareColors.textSecondary),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? RuralCareColors.teal : RuralCareColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricCard(String label, String value, String sub, Color color) {
    return Container(
      decoration: AppDecorations.card(),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: RuralCareColors.textSecondary)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(sub, style: const TextStyle(fontSize: 10, color: RuralCareColors.textSecondary), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildWorklist(
    BuildContext context,
    List<DiagnosticOrderDto> orders,
    FacilityRepository facRepo,
    FacilityStrings strings,
  ) {
    if (orders.isEmpty) {
      return Container(
        width: double.infinity,
        decoration: AppDecorations.card(),
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            const Icon(Icons.check_circle_outline, color: RuralCareColors.teal, size: 40),
            const SizedBox(height: 12),
            const Text('Lab Worklist Queue Clear', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 4),
            Text(
              'No pending diagnostic orders awaiting processing at ${facRepo.currentFacility.name}.',
              style: AppTypography.supporting,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: orders.map((order) {
        final isCompleted = order.status == 'COMPLETED';
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: AppDecorations.card(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(order.testName, style: AppTypography.cardTitle),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? const Color(0xFFECFDF5)
                          : (order.urgency == 'Urgent' ? const Color(0xFFFEF2F2) : const Color(0xFFFFFBEB)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isCompleted ? 'COMPLETED' : order.status,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isCompleted
                            ? RuralCareColors.success
                            : (order.urgency == 'Urgent' ? RuralCareColors.critical : const Color(0xFFB45309)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text('Patient: ${order.patientName} • ID: ${order.patientRuralCareId}', style: AppTypography.supporting),
              Text('Urgency: ${order.urgency} • Ordered: ${order.orderedAt.hour}:${order.orderedAt.minute.toString().padLeft(2, "0")}', style: AppTypography.supporting),
              if (order.resultValue != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified, size: 16, color: RuralCareColors.success),
                      const SizedBox(width: 8),
                      Text('Result: ${order.resultValue!}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: RuralCareColors.success)),
                    ],
                  ),
                ),
              ],
              if (!isCompleted) ...[
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (order.status == 'ORDERED')
                      ElevatedButton.icon(
                        onPressed: () => facRepo.updateDiagnosticOrderStatus(order.id, 'SAMPLE_COLLECTED'),
                        icon: const Icon(Icons.bloodtype_outlined, size: 16),
                        label: const Text('Collect Sample'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: RuralCareColors.teal,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      )
                    else if (order.status == 'SAMPLE_COLLECTED')
                      ElevatedButton.icon(
                        onPressed: () => facRepo.updateDiagnosticOrderStatus(order.id, 'ANALYZING'),
                        icon: const Icon(Icons.play_arrow_outlined, size: 16),
                        label: const Text('Start Analyzer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFB45309),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      )
                    else if (order.status == 'ANALYZING')
                      ElevatedButton.icon(
                        onPressed: () => _showEnterResultDialog(context, order, facRepo),
                        icon: const Icon(Icons.rate_review_outlined, size: 16),
                        label: Text(strings.enterResult),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0A6B56),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildReagentsList(
    BuildContext context,
    List<FacilityInventoryItem> diagnostics,
    FacilityRepository facRepo,
    FacilityStrings strings,
  ) {
    return Column(
      children: diagnostics.map((item) {
        final isLow = item.stockOnHand <= item.reorderThreshold;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: AppDecorations.card(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(item.name, style: AppTypography.cardTitle)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isLow ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isLow ? 'LOW STOCK' : 'AVAILABLE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isLow ? RuralCareColors.critical : RuralCareColors.success,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(item.description, style: AppTypography.supporting),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Batch: ${item.batchNumber}', style: AppTypography.supporting),
                  Text('Exp: ${item.expiryDate}', style: AppTypography.supporting),
                  Text(
                    '${item.stockOnHand} Tests',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isLow ? RuralCareColors.critical : RuralCareColors.teal,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
