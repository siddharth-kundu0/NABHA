import 'package:flutter/material.dart';
import 'package:ruralcare/app/routes.dart';
import 'package:ruralcare/core/theme/app_theme.dart';
import 'package:ruralcare/data/models/facility_dto.dart';
import 'package:ruralcare/data/repositories/facility_repository.dart';
import 'package:ruralcare/features/facility/utils/facility_strings.dart';

/// Dedicated Pharmacist Workstation
/// When a Pharmacist logs in, they see STRICTLY and ONLY Pharmacy, Drug Ledger,
/// Dispensing Queue, Expiry Tracking, and Stock Discrepancy info.
class PharmacistWorkstationTab extends StatefulWidget {
  const PharmacistWorkstationTab({super.key});

  @override
  State<PharmacistWorkstationTab> createState() => _PharmacistWorkstationTabState();
}

class _PharmacistWorkstationTabState extends State<PharmacistWorkstationTab> {
  int _activeSubTab = 0; // 0: Prescriptions Queue, 1: Medicine Stock Ledger, 2: Cold Chain & Safety
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showReportDiscrepancyModal(BuildContext context, FacilityInventoryItem item, FacilityRepository facRepo) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Report Discrepancy: ${item.name}', style: AppTypography.cardTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current recorded stock: ${item.stockOnHand} units.', style: AppTypography.supporting),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(
                labelText: 'Observed Discrepancy / Reason',
                hintText: 'e.g. Broken vial, batch count mismatch',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: RuralCareColors.critical,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final reason = reasonCtrl.text.trim().isEmpty ? 'Physical count mismatch' : reasonCtrl.text.trim();
              facRepo.reportDiscrepancy(
                itemId: item.id,
                itemName: item.name,
                reason: reason,
                reporter: facRepo.currentStaffSession?.staffName ?? 'Chief Pharmacist',
              );
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Reported discrepancy for ${item.name}. Facility Admin notified.'),
                  backgroundColor: RuralCareColors.critical,
                ),
              );
            },
            child: const Text('Submit Discrepancy'),
          ),
        ],
      ),
    );
  }

  void _handleDispense(PrescriptionOrderDto order, FacilityRepository facRepo) {
    facRepo.dispensePrescription(order.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Prescription ${order.id} for ${order.patientName} dispensed successfully!'),
        backgroundColor: RuralCareColors.success,
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
        final medicines = facRepo.inventory.where((i) => i.category == 'MEDICINES').toList();
        final lowStockMeds = medicines.where((i) => i.stockOnHand <= i.reorderThreshold).toList();
        final prescriptions = facRepo.prescriptionOrders;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pharmacist Identity Banner
              Container(
                decoration: AppDecorations.card(),
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A6B56),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.local_pharmacy_rounded, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(strings.pharmacyWorkstation, style: AppTypography.cardTitle),
                          const SizedBox(height: 2),
                          Text(
                            '${facRepo.currentFacility.name} • ${staff?.staffName ?? "Chief Pharmacist"}',
                            style: AppTypography.supporting,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: AppDecorations.statusBadge(background: const Color(0xFFE8F5F2)),
                                child: Text(
                                  'REG: ${staff?.licenseOrEmployeeId ?? "PHARM-MH-8421"}',
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0A6B56)),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: AppDecorations.statusBadge(background: const Color(0xFFECFDF5)),
                                child: const Text(
                                  'Cold-Chain ILR: 4.2°C (OK)',
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

              // KPI Metrics Row
              Row(
                children: [
                  Expanded(
                    child: _metricCard(
                      'Prescriptions',
                      '${prescriptions.where((p) => p.status == "PENDING").length}',
                      'Pending Dispensing',
                      const Color(0xFF0A6B56),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _metricCard(
                      'Formulations',
                      '${medicines.length}',
                      'Active Medicines',
                      RuralCareColors.teal,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _metricCard(
                      'Reorder Alerts',
                      '${lowStockMeds.length}',
                      'Low Stock Items',
                      lowStockMeds.isEmpty ? RuralCareColors.success : const Color(0xFFB45309),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Sub-Tab Switcher
              Container(
                decoration: BoxDecoration(
                  color: RuralCareColors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: _tabButton('E-Prescriptions', 0, Icons.receipt_long_outlined),
                    ),
                    Expanded(
                      child: _tabButton('Drug Inventory', 1, Icons.inventory_2_outlined),
                    ),
                    Expanded(
                      child: _tabButton('Cold Chain & Safety', 2, Icons.thermostat_outlined),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Active Sub-Tab View
              if (_activeSubTab == 0)
                _buildPrescriptionsQueue(context, prescriptions, facRepo, strings)
              else if (_activeSubTab == 1)
                _buildMedicineInventory(context, medicines, facRepo, strings)
              else
                _buildColdChainAndDiscrepancies(context, medicines, facRepo, strings),
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
            Icon(icon, size: 16, color: isSelected ? const Color(0xFF0A6B56) : RuralCareColors.textSecondary),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? const Color(0xFF0A6B56) : RuralCareColors.textSecondary,
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

  Widget _buildPrescriptionsQueue(
    BuildContext context,
    List<PrescriptionOrderDto> prescriptions,
    FacilityRepository facRepo,
    FacilityStrings strings,
  ) {
    if (prescriptions.isEmpty) {
      return Container(
        width: double.infinity,
        decoration: AppDecorations.card(),
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            const Icon(Icons.check_circle_outline, color: RuralCareColors.teal, size: 40),
            const SizedBox(height: 12),
            const Text('Prescription Queue Clear', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 4),
            Text(
              'No pending doctor prescriptions awaiting dispensing at ${facRepo.currentFacility.name}.',
              style: AppTypography.supporting,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: prescriptions.map((order) {
        final isDispensed = order.status == 'DISPENSED';
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
                  Row(
                    children: [
                      const Icon(Icons.person_pin_circle_outlined, color: Color(0xFF0A6B56), size: 20),
                      const SizedBox(width: 8),
                      Text(order.patientName, style: AppTypography.cardTitle),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDispensed ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      order.status,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isDispensed ? RuralCareColors.success : const Color(0xFFB45309),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text('ID: ${order.patientRuralCareId} • Prescribed by: ${order.doctorName}', style: AppTypography.supporting),
              const Divider(height: 20),
              const Text('Prescribed Medicines:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              ...order.prescribedMedicines.map(
                (med) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(
                    children: [
                      const Icon(Icons.circle, size: 6, color: Color(0xFF0A6B56)),
                      const SizedBox(width: 8),
                      Text(med, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text('Instructions: ${order.dosageInstructions}', style: AppTypography.supporting),
              if (!isDispensed) ...[
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: () => _handleDispense(order, facRepo),
                    icon: const Icon(Icons.check, size: 16),
                    label: Text(strings.dispenseAction),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0A6B56),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMedicineInventory(
    BuildContext context,
    List<FacilityInventoryItem> medicines,
    FacilityRepository facRepo,
    FacilityStrings strings,
  ) {
    return Column(
      children: medicines.map((item) {
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
                  Expanded(
                    child: Text(item.name, style: AppTypography.cardTitle),
                  ),
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
                    '${item.stockOnHand} Units',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isLow ? RuralCareColors.critical : const Color(0xFF0A6B56),
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: () => _showReportDiscrepancyModal(context, item, facRepo),
                    icon: const Icon(Icons.report_problem_outlined, size: 16, color: RuralCareColors.critical),
                    label: const Text('Report Discrepancy', style: TextStyle(color: RuralCareColors.critical, fontSize: 12)),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Automated replenishment order raised for ${item.name}.')),
                      );
                    },
                    icon: const Icon(Icons.add_shopping_cart, size: 16),
                    label: const Text('Reorder Stock', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0A6B56),
                      side: const BorderSide(color: Color(0xFF0A6B56)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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

  Widget _buildColdChainAndDiscrepancies(
    BuildContext context,
    List<FacilityInventoryItem> medicines,
    FacilityRepository facRepo,
    FacilityStrings strings,
  ) {
    final discrepancies = facRepo.discrepancies;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cold Chain ILR Card
        Container(
          decoration: AppDecorations.card(),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.ac_unit_rounded, color: Color(0xFF0A6B56), size: 22),
                  SizedBox(width: 10),
                  Text('Ice-Lined Refrigerator (ILR) Telemetry', style: AppTypography.cardTitle),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Current Sensor Temp', style: TextStyle(fontSize: 12, color: RuralCareColors.textSecondary)),
                      SizedBox(height: 2),
                      Text('4.2°C', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: RuralCareColors.success)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle, size: 16, color: RuralCareColors.success),
                        SizedBox(width: 6),
                        Text(
                          'SAFE RANGE (2°C - 8°C)',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: RuralCareColors.success),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Monitored Vaccines: Rabies Vaccine, TT, Hepatitis B, Rotavirus, Polio. Refrigerator logger operating on solar battery backup.',
                style: AppTypography.supporting,
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Discrepancy Log
        const Text('Reported Discrepancy Log', style: AppTypography.sectionTitle),
        const SizedBox(height: 10),

        if (discrepancies.isEmpty)
          Container(
            width: double.infinity,
            decoration: AppDecorations.card(),
            padding: const EdgeInsets.all(20),
            child: const Center(
              child: Text('No active inventory discrepancies reported.', style: AppTypography.supporting),
            ),
          )
        else
          ...discrepancies.map(
            (d) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: AppDecorations.card(),
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: RuralCareColors.critical, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${d.itemName}: ${d.reason}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Text('Reported by ${d.reporter} • ${d.timestamp.hour}:${d.timestamp.minute.toString().padLeft(2, "0")}', style: AppTypography.supporting),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
