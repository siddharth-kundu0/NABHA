import 'package:flutter/material.dart';
import 'package:ruralcare/app/routes.dart';
import 'package:ruralcare/core/theme/app_theme.dart';
import 'package:ruralcare/data/repositories/facility_repository.dart';
import 'package:ruralcare/data/repositories/patient_repository.dart';
import 'package:ruralcare/data/repositories/referral_repository.dart';
import 'package:ruralcare/features/facility/utils/facility_strings.dart';

/// Dedicated Reception & Referral Intake Clerk Workstation
/// When an Intake Clerk logs in, they see STRICTLY and ONLY Patient Check-In,
/// 108 Emergency Pre-Alerts, and Inter-Facility Referral Intake.
class ReceptionIntakeWorkstationTab extends StatefulWidget {
  const ReceptionIntakeWorkstationTab({super.key});

  @override
  State<ReceptionIntakeWorkstationTab> createState() => _ReceptionIntakeWorkstationTabState();
}

class _ReceptionIntakeWorkstationTabState extends State<ReceptionIntakeWorkstationTab> {
  int _activeSubTab = 0; // 0: Check-In, 1: 108 Emergency Pre-Alerts, 2: Referral Intake
  final TextEditingController _searchCtrl = TextEditingController();

  final List<Map<String, String>> _ambulancePreAlerts = [
    {
      'vehicle': 'Ambulance 108 (MH-12-G-4402)',
      'driver': 'Ganesh Shinde (+91 98221 44021)',
      'eta': '7 mins',
      'condition': 'Acute respiratory distress • O2 mask at 6 L/min',
      'patient': 'Kiran Patil (Age 46)',
      'origin': 'Kashti Sub-Centre',
    },
    {
      'vehicle': 'Ambulance 108 (MH-12-F-1108)',
      'driver': 'Santosh Pawar (+91 98221 11082)',
      'eta': '18 mins',
      'condition': 'Obstetric triage • Active labor pains with mild preeclampsia',
      'patient': 'Sunita Bai Gaikwad (Age 26)',
      'origin': 'Rampur Sub-Centre',
    },
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showTokenIssuedDialog(BuildContext context, String patientName, String id) {
    final token = 'OPD-${DateTime.now().millisecondsSinceEpoch % 900 + 100}';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('OPD Arrival Token Issued', style: AppTypography.cardTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5F2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF0A6B56)),
                ),
                child: Text(
                  token,
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF0A6B56), letterSpacing: 1),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Patient: $patientName', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('RuralCare ID: $id', style: AppTypography.supporting),
            const SizedBox(height: 4),
            const Text('Routing: General OPD Consultation Room 2', style: AppTypography.supporting),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A6B56),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionCoordinator();
    final facRepo = FacilityRepository();
    final patientRepo = PatientRepository();
    final refRepo = ReferralRepository();
    final strings = FacilityStrings.of(session);
    final staff = facRepo.currentStaffSession;
    final facility = facRepo.currentFacility;

    return ListenableBuilder(
      listenable: Listenable.merge([patientRepo, refRepo, facRepo]),
      builder: (context, _) {
        final patients = patientRepo.patients;
        final referrals = refRepo.referrals;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Reception Identity Banner
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
                      child: const Icon(Icons.how_to_reg_rounded, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(strings.intakeWorkstation, style: AppTypography.cardTitle),
                          const SizedBox(height: 2),
                          Text(
                            '${facility.name} • ${staff?.staffName ?? "Reception Officer"}',
                            style: AppTypography.supporting,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: AppDecorations.statusBadge(background: const Color(0xFFE8F5F2)),
                            child: Text(
                              'REG: ${staff?.licenseOrEmployeeId ?? "REC-MH-842"}',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0A6B56)),
                            ),
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
                    child: _metricCard('Patients', '${patients.length}', 'Registered Today', const Color(0xFF0A6B56)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _metricCard('108 Inbound', '${_ambulancePreAlerts.length}', 'Incoming Alerts', RuralCareColors.critical),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _metricCard('Referrals', '${referrals.length}', 'Care Transfers', RuralCareColors.teal),
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
                    Expanded(child: _tabButton('Check-In Desk', 0, Icons.how_to_reg_outlined)),
                    Expanded(child: _tabButton('108 Ambulances', 1, Icons.emergency_outlined)),
                    Expanded(child: _tabButton('Referral Intake', 2, Icons.transfer_within_a_station_outlined)),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              if (_activeSubTab == 0)
                _buildCheckInDesk(context, patients)
              else if (_activeSubTab == 1)
                _buildAmbulanceDesk(context)
              else
                _buildReferralIntakeDesk(context, referrals),
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
            const SizedBox(width: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
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

  Widget _buildCheckInDesk(BuildContext context, List<dynamic> patients) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Fast ABHA / RuralCare Lookup
        Container(
          decoration: AppDecorations.card(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Fast-Track Arrival Token Issuance', style: AppTypography.cardTitle),
              const SizedBox(height: 4),
              const Text('Lookup by ABHA ID, RuralCare ID or Mobile to issue queue token.', style: AppTypography.supporting),
              const SizedBox(height: 12),
              TextField(
                controller: _searchCtrl,
                decoration: const InputDecoration(
                  hintText: 'Enter ABHA ID, Patient Name or Mobile Number',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        const Text('Arrived Citizens & Queue Routing', style: AppTypography.sectionTitle),
        const SizedBox(height: 10),

        ...patients.map((pat) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: AppDecorations.card(),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5F2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.person_rounded, color: Color(0xFF0A6B56)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(pat.fullName as String, style: AppTypography.cardTitle),
                      Text('ABHA: ${pat.abhaId} • ${pat.gender}, ${pat.age}y', style: AppTypography.supporting),
                      Text('Village: ${pat.village}', style: AppTypography.supporting),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showTokenIssuedDialog(context, pat.fullName as String, pat.ruralCareId as String),
                  icon: const Icon(Icons.confirmation_number_outlined, size: 16),
                  label: const Text('Issue Token'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A6B56),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildAmbulanceDesk(BuildContext context) {
    return Column(
      children: _ambulancePreAlerts.map((amb) {
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
                      const Icon(Icons.emergency_rounded, color: RuralCareColors.critical, size: 22),
                      const SizedBox(width: 8),
                      Text(amb['vehicle']!, style: AppTypography.cardTitle),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: RuralCareColors.critical.withOpacity(0.3)),
                    ),
                    child: Text(
                      'ETA ${amb["eta"]}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: RuralCareColors.critical),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text('Patient: ${amb["patient"]} • Origin: ${amb["origin"]}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 2),
              Text('Condition: ${amb["condition"]}', style: AppTypography.supporting),
              Text('Driver Contact: ${amb["driver"]}', style: AppTypography.supporting),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Calling ${amb["driver"]}...')),
                      );
                    },
                    icon: const Icon(Icons.call, size: 16),
                    label: const Text('Call Driver'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Emergency Suite 1 prepped for ${amb["patient"]}. Crash cart on standby.'),
                          backgroundColor: RuralCareColors.success,
                        ),
                      );
                    },
                    icon: const Icon(Icons.check_circle_outline, size: 16),
                    label: const Text('Prep Resuscitation Bay'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: RuralCareColors.critical,
                      foregroundColor: Colors.white,
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

  Widget _buildReferralIntakeDesk(BuildContext context, List<dynamic> referrals) {
    if (referrals.isEmpty) {
      return Container(
        width: double.infinity,
        decoration: AppDecorations.card(),
        padding: const EdgeInsets.all(24),
        child: const Center(
          child: Text('No active inter-facility referrals pending intake.', style: AppTypography.supporting),
        ),
      );
    }

    return Column(
      children: referrals.map((ref) {
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
                  Text('Referral Token #${ref.id}', style: AppTypography.cardTitle),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5F2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      ref.priority as String,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0A6B56)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text('Patient ID: ${ref.patientId}', style: AppTypography.supporting),
              Text('Clinical Indication: ${ref.reason}', style: AppTypography.supporting),
              const Divider(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Intake complete for referral #${ref.id}. Handed over to Inpatient Ward.'),
                        backgroundColor: RuralCareColors.success,
                      ),
                    );
                  },
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Verify & Intake Patient'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A6B56),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
