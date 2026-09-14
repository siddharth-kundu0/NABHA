import 'package:flutter/material.dart';
import 'package:ruralcare/app/routes.dart';
import 'package:ruralcare/core/theme/app_theme.dart';
import 'package:ruralcare/data/repositories/facility_repository.dart';
import 'package:ruralcare/features/facility/utils/facility_strings.dart';

/// Dedicated Staff Nurse Workstation
/// When a Staff Nurse logs in, they see STRICTLY and ONLY Inpatient Wards,
/// Bed Allocation, Medication Rounds & Vitals, Shift Handover, and Emergency Triage.
class StaffNurseWorkstationTab extends StatefulWidget {
  const StaffNurseWorkstationTab({super.key});

  @override
  State<StaffNurseWorkstationTab> createState() => _StaffNurseWorkstationTabState();
}

class _StaffNurseWorkstationTabState extends State<StaffNurseWorkstationTab> {
  int _activeSubTab = 0; // 0: Wards & Beds, 1: Medication & Vitals, 2: Shift Handover, 3: Triage

  final List<Map<String, dynamic>> _inpatientRounds = [
    {
      'patient': 'Sunita Bai Gaikwad',
      'bed': 'Bed M-04 (Maternity Ward)',
      'medication': 'IV Ringer Lactate 500ml @ 40 drops/min',
      'scheduled': '10:30 AM',
      'administered': false,
    },
    {
      'patient': 'Rameshwar Patil',
      'bed': 'Bed G-08 (Male Ward)',
      'medication': 'Tab Paracetamol 500mg + Metformin 500mg',
      'scheduled': '11:00 AM',
      'administered': false,
    },
    {
      'patient': 'Kiran Devi',
      'bed': 'Bed F-02 (Female Ward)',
      'medication': 'Inj Ceftriaxone 1g IV Stat',
      'scheduled': '11:30 AM',
      'administered': false,
    },
  ];

  final List<Map<String, String>> _triageCases = [
    {
      'patient': 'Anand Rao (Age 52)',
      'complaint': 'Acute chest pain radiating to left arm • BP 160/100',
      'tag': 'RED',
      'destination': 'Emergency Resuscitation Suite 1',
    },
    {
      'patient': 'Pooja Jadhav (Age 24)',
      'complaint': 'Active labor pains (G1P0) • 3cm dilated',
      'tag': 'YELLOW',
      'destination': 'Maternity Delivery Suite',
    },
    {
      'patient': 'Vishal More (Age 19)',
      'complaint': 'Superficial forearm laceration from agricultural sickle',
      'tag': 'GREEN',
      'destination': 'Minor OT / Dressing Room',
    },
  ];

  final List<String> _handoverTasks = [
    'Medication cabinet keys verified & physically transferred',
    'Cold-chain ILR temperature verified (4.2°C)',
    'Emergency Crash Cart & Defibrillator inspected',
    'Oxygen cylinder manifold pressure verified (150 bar)',
    'Narcotics & Scheduled H drug ledger reconciled',
  ];

  @override
  Widget build(BuildContext context) {
    final session = SessionCoordinator();
    final facRepo = FacilityRepository();
    final strings = FacilityStrings.of(session);
    final staff = facRepo.currentStaffSession;
    final facility = facRepo.currentFacility;

    return ListenableBuilder(
      listenable: facRepo,
      builder: (context, _) {
        final occupiedBeds = facility.totalBeds - facility.availableBeds;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nurse Identity Banner
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
                      child: const Icon(Icons.hotel_rounded, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(strings.nurseWorkstation, style: AppTypography.cardTitle),
                          const SizedBox(height: 2),
                          Text(
                            '${facility.name} • ${staff?.staffName ?? "Sister In-Charge, RN"}',
                            style: AppTypography.supporting,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: AppDecorations.statusBadge(background: const Color(0xFFE8F5F2)),
                                child: Text(
                                  'REG: ${staff?.licenseOrEmployeeId ?? "NURSE-MH-102"}',
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0A6B56)),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: AppDecorations.statusBadge(background: const Color(0xFFECFDF5)),
                                child: Text(
                                  facRepo.currentShift.split(':')[0],
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: RuralCareColors.success),
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
                    child: _metricCard('Occupied Beds', '$occupiedBeds / ${facility.totalBeds}', 'Total Inpatients', RuralCareColors.primary),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _metricCard('Vacant Beds', '${facility.availableBeds}', 'Ready for Intake', RuralCareColors.success),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _metricCard('Vitals Due', '${_inpatientRounds.where((r) => !r["administered"]).length}', 'Scheduled Meds', const Color(0xFFB45309)),
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
                    Expanded(child: _tabButton('Wards & Beds', 0, Icons.bed_outlined)),
                    Expanded(child: _tabButton('Medication Rounds', 1, Icons.medication_liquid_outlined)),
                    Expanded(child: _tabButton('Shift Handover', 2, Icons.fact_check_outlined)),
                    Expanded(child: _tabButton('Triage Queue', 3, Icons.emergency_outlined)),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              if (_activeSubTab == 0)
                _buildWardsAndBeds(context, facility, facRepo, strings)
              else if (_activeSubTab == 1)
                _buildMedicationRounds(context)
              else if (_activeSubTab == 2)
                _buildShiftHandover(context, facRepo)
              else
                _buildTriageQueue(context),
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
        child: Column(
          children: [
            Icon(icon, size: 16, color: isSelected ? const Color(0xFF0A6B56) : RuralCareColors.textSecondary),
            const SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? const Color(0xFF0A6B56) : RuralCareColors.textSecondary,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
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
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(sub, style: const TextStyle(fontSize: 10, color: RuralCareColors.textSecondary), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildWardsAndBeds(
    BuildContext context,
    dynamic facility,
    FacilityRepository facRepo,
    FacilityStrings strings,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Live Bed Stepper
        Container(
          decoration: AppDecorations.card(),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Live Bed Stepper Control', style: AppTypography.cardTitle),
                  Text('${facility.availableBeds} Vacant / ${facility.totalBeds} Total', style: AppTypography.supporting),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: facility.availableBeds > 0
                          ? () {
                              facRepo.updateAvailableBeds(facility.id, facility.availableBeds - 1);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Patient admitted. Bed allocated.')),
                              );
                            }
                          : null,
                      icon: const Icon(Icons.remove, size: 16),
                      label: Text(strings.admitPatient, style: const TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0A6B56),
                        side: const BorderSide(color: Color(0xFF0A6B56)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: facility.availableBeds < facility.totalBeds
                          ? () {
                              facRepo.updateAvailableBeds(facility.id, facility.availableBeds + 1);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Patient discharged. Bed marked clean & vacant.')),
                              );
                            }
                          : null,
                      icon: const Icon(Icons.add, size: 16),
                      label: Text(strings.dischargePatient, style: const TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0A6B56),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Ward Breakdown
        const Text('Inpatient Wards Breakdown', style: AppTypography.sectionTitle),
        const SizedBox(height: 10),
        _wardRow('Maternity & Labor Suite', '4 Occupied / 6 Beds', 0.66, const Color(0xFF0A6B56)),
        _wardRow('Female General Medical Ward', '12 Occupied / 15 Beds', 0.80, RuralCareColors.primary),
        _wardRow('Male General Medical Ward', '14 Occupied / 18 Beds', 0.77, RuralCareColors.teal),
        _wardRow('Emergency Stabilization Suite (24x7)', '4 Occupied / 6 Beds', 0.66, const Color(0xFFB45309)),
      ],
    );
  }

  Widget _wardRow(String name, String occupancy, double ratio, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: AppDecorations.card(),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Text(occupancy, style: AppTypography.supporting),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: RuralCareColors.surfaceSubtle,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationRounds(BuildContext context) {
    return Column(
      children: _inpatientRounds.map((round) {
        final isDone = round['administered'] as bool;
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
                  Text(round['patient'] as String, style: AppTypography.cardTitle),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDone ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isDone ? 'ADMINISTERED' : 'DUE AT ${round["scheduled"]}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isDone ? RuralCareColors.success : const Color(0xFFB45309),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(round['bed'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0A6B56))),
              const SizedBox(height: 4),
              Text('Medication: ${round["medication"]}', style: AppTypography.supporting),
              if (!isDone) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() => round['administered'] = true);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Marked dose administered for ${round["patient"]}.')),
                      );
                    },
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Mark Administered'),
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

  Widget _buildShiftHandover(BuildContext context, FacilityRepository facRepo) {
    return Container(
      decoration: AppDecorations.card(),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Duty Shift Handover Protocol', style: AppTypography.cardTitle),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5F2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  facRepo.currentShift,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0A6B56)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(facRepo.officerInCharge, style: AppTypography.supporting),
          const Divider(height: 24),
          const Text('Verification Protocol Checklist:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          ..._handoverTasks.map((task) {
            final isChecked = facRepo.completedHandoverTasks.contains(task);
            return Material(
              color: Colors.transparent,
              child: CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                value: isChecked,
                activeColor: const Color(0xFF0A6B56),
                title: Text(task, style: const TextStyle(fontSize: 12)),
                onChanged: (_) {
                  facRepo.toggleHandoverTask(task);
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTriageQueue(BuildContext context) {
    return Column(
      children: _triageCases.map((tc) {
        final isRed = tc['tag'] == 'RED';
        final isYellow = tc['tag'] == 'YELLOW';
        final color = isRed ? RuralCareColors.critical : (isYellow ? const Color(0xFFB45309) : RuralCareColors.success);

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
                  Text(tc['patient']!, style: AppTypography.cardTitle),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'TRIAGE ${tc["tag"]}',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(tc['complaint']!, style: AppTypography.supporting),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF0A6B56)),
                  const SizedBox(width: 4),
                  Text('Assigned Wing: ${tc["destination"]}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
