import 'package:flutter/material.dart';
import 'package:ruralcare/core/theme/app_theme.dart';
import 'package:ruralcare/data/repositories/facility_repository.dart';
import 'package:ruralcare/features/facility/utils/facility_strings.dart';
import 'package:ruralcare/app/routes.dart';

/// Facility Profile & Administration Tab (Desktop Facility Management & DESIGN.md)
/// Features:
/// 1. Facility identity profile card with HFR registry code and verified status.
/// 2. Interactive Duty Shift & Handover Checklist with real repository state.
/// 3. Live On-Duty Staff Roster with Room Reassignment workflow.
/// 4. Offline Resilient Cluster Sync with live sync animation and feedback toast.
/// 5. Trilingual language selector (EN, HI, MR).
/// 6. System controls: Offline Simulation toggle and Demo Role Switcher.
class FacilityProfileTab extends StatefulWidget {
  const FacilityProfileTab({super.key});

  @override
  State<FacilityProfileTab> createState() => _FacilityProfileTabState();
}

class _FacilityProfileTabState extends State<FacilityProfileTab> {
  final List<String> _allHandoverTasks = [
    'Medication cabinet keys verified',
    'Cold-chain ILR temperature verified (4.2°C)',
    'Emergency Crash Cart inspected',
    'Narcotics & Controlled Substances count reconciled',
    'OPD triage logbook signed off',
  ];

  @override
  Widget build(BuildContext context) {
    final session = SessionCoordinator();
    final facRepo = FacilityRepository();

    return ListenableBuilder(
      listenable: Listenable.merge([facRepo, session]),
      builder: (context, _) {
        final strings = FacilityStrings.of(session);
        final facilities = facRepo.facilities;
        final facility = facilities.firstWhere(
          (f) => f.id == 'FAC-SDH-301',
          orElse: () => facilities.first,
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Facility Identity Profile Card
              _buildFacilityIdentityCard(context, facility, strings),

              const SizedBox(height: 16),

              // 2. Duty Shift & Handover Manager
              _buildShiftManager(context, facRepo, strings),

              const SizedBox(height: 16),

              // 3. On-Duty Staff Roster with Reassignment
              _buildStaffRoster(context, facRepo, strings),

              const SizedBox(height: 16),

              // 4. Cluster Sync & Local Node Status
              _buildClusterSyncCard(context, facRepo, strings),

              const SizedBox(height: 16),

              // 5. Multilingual Language Preferences
              _buildLanguageSelector(context, session, strings),

              const SizedBox(height: 16),

              // 6. System Controls: Offline Simulation & Role Switcher
              _buildSystemControls(context, session, strings),

              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFacilityIdentityCard(BuildContext context, dynamic facility, FacilityStrings strings) {
    return Container(
      decoration: AppDecorations.card(),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: RuralCareColors.teal,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.local_hospital_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(facility.name as String, style: AppTypography.cardTitle),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: AppDecorations.statusBadge(background: RuralCareColors.tealSoft),
                          child: const Text(
                            'SDH • HFR: MH-PUN-SDH-0891',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: RuralCareColors.teal),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: AppDecorations.statusBadge(background: RuralCareColors.surfaceSubtle),
                          child: const Text(
                            'NABH Registered',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: RuralCareColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          _buildInfoRow(Icons.location_on_rounded, 'Address', facility.address as String),
          const SizedBox(height: 10),
          _buildInfoRow(Icons.phone_rounded, 'Emergency Hotline', facility.contactPhone as String),
          const SizedBox(height: 10),
          _buildInfoRow(Icons.access_time_rounded, 'Operating Hours', '24x7 Emergency & Inpatient Care'),
          const SizedBox(height: 10),
          _buildInfoRow(
            Icons.hotel_rounded,
            'Approved Bed Strength',
            '${facility.totalBeds} Operational Beds (${facility.availableBeds} Free)',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: RuralCareColors.teal),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: RuralCareColors.textSecondary)),
              Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: RuralCareColors.textPrimary)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildShiftManager(BuildContext context, FacilityRepository facRepo, FacilityStrings strings) {
    final shifts = [
      'Morning Shift: 08:00 - 16:00',
      'Evening Shift: 16:00 - 00:00',
      'Night Shift: 00:00 - 08:00',
    ];

    return Container(
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
                  const Icon(Icons.schedule, size: 18, color: RuralCareColors.teal),
                  const SizedBox(width: 6),
                  Text(strings.dutyShift, style: AppTypography.cardTitle),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: RuralCareColors.tealSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  strings.shiftActive,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: RuralCareColors.teal),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(facRepo.officerInCharge, style: AppTypography.supporting),
          const SizedBox(height: 12),
          ...shifts.map((s) {
            final isSelected = facRepo.currentShift.contains(s.split(':')[0]);
            return InkWell(
              onTap: () {
                facRepo.performHandover(
                  shift: s,
                  officerInCharge: facRepo.officerInCharge,
                  checklistCompleted: facRepo.completedHandoverTasks,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Active operational shift changed to $s')),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? RuralCareColors.tealSoft : RuralCareColors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? RuralCareColors.teal : RuralCareColors.border,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      s,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? RuralCareColors.teal : RuralCareColors.textPrimary,
                      ),
                    ),
                    if (isSelected) const Icon(Icons.check_circle, color: RuralCareColors.teal, size: 18),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 12),
          const Text('Shift Handover Protocol Checklist', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          ..._allHandoverTasks.map((task) {
            final isChecked = facRepo.completedHandoverTasks.contains(task);
            return Material(
              color: Colors.transparent,
              child: CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                value: isChecked,
                activeColor: RuralCareColors.teal,
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

  Widget _buildStaffRoster(BuildContext context, FacilityRepository facRepo, FacilityStrings strings) {
    final staff = facRepo.staffRoster;

    return Container(
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
                  const Icon(Icons.badge_outlined, size: 18, color: RuralCareColors.teal),
                  const SizedBox(width: 6),
                  Text(strings.staffRoster, style: AppTypography.cardTitle),
                ],
              ),
              Text('${staff.length} Verified On Duty', style: AppTypography.supporting),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Live staff station allocation & room assignments', style: AppTypography.supporting),
          const SizedBox(height: 12),
          ...staff.map((s) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: RuralCareColors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: RuralCareColors.border),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: RuralCareColors.tealSoft,
                      child: Text(
                        s.name.substring(0, 1),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: RuralCareColors.teal),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          Text('${s.designation} • ${s.assignedRoom}', style: AppTypography.supporting),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => _showReassignStaffModal(context, s, facRepo, strings),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        strings.reassignStaff,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: RuralCareColors.teal),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildClusterSyncCard(BuildContext context, FacilityRepository facRepo, FacilityStrings strings) {
    return Container(
      decoration: AppDecorations.card(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.sync_rounded, size: 18, color: RuralCareColors.teal),
                  SizedBox(width: 6),
                  Text('Facility Cluster Telemetry', style: AppTypography.cardTitle),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: RuralCareColors.tealSoft,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Mesh Active',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: RuralCareColors.teal),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Direct peer-to-peer sync with Kalyanpur Sub-Center & District Hospital Aundh over hybrid RF/Wi-Fi mesh.',
            style: AppTypography.supporting,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: RuralCareColors.surfaceSubtle,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Local Cache Node', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                Text('SQLite v3.45 • 0 Unsynced Diffs', style: TextStyle(fontSize: 11, color: RuralCareColors.teal)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: facRepo.isClusterSyncing
                  ? null
                  : () async {
                      await facRepo.forceClusterSync();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(strings.toastLedgerRefreshed),
                          backgroundColor: RuralCareColors.teal,
                        ),
                      );
                    },
              icon: facRepo.isClusterSyncing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: RuralCareColors.teal),
                    )
                  : const Icon(Icons.refresh_rounded, size: 18),
              label: Text(facRepo.isClusterSyncing ? 'Synchronizing Cluster...' : strings.forceSync),
              style: OutlinedButton.styleFrom(
                foregroundColor: RuralCareColors.teal,
                side: const BorderSide(color: RuralCareColors.teal),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector(
    BuildContext context,
    SessionCoordinator session,
    FacilityStrings strings,
  ) {
    final current = session.activeLanguage;

    return Container(
      decoration: AppDecorations.card(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.language_rounded, size: 18, color: RuralCareColors.teal),
              const SizedBox(width: 6),
              Text(strings.languageSettings, style: AppTypography.cardTitle),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Switch system language across triage & clinical views', style: AppTypography.supporting),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildLangChip('English (EN)', 'en', current, session),
              const SizedBox(width: 8),
              _buildLangChip('हिन्दी (HI)', 'hi', current, session),
              const SizedBox(width: 8),
              _buildLangChip('मराठी (MR)', 'mr', current, session),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLangChip(String label, String code, String current, SessionCoordinator session) {
    final isSelected = current == code ||
        (code == 'en' && (current == 'English' || current == 'en')) ||
        (code == 'hi' && (current == 'Hindi' || current == 'हिन्दी')) ||
        (code == 'mr' && (current == 'Marathi' || current == 'मराठी'));

    return Expanded(
      child: InkWell(
        onTap: () => session.setLanguage(code),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? RuralCareColors.teal : RuralCareColors.surfaceSubtle,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSelected ? RuralCareColors.teal : RuralCareColors.border),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.white : RuralCareColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSystemControls(
    BuildContext context,
    SessionCoordinator session,
    FacilityStrings strings,
  ) {
    return Container(
      decoration: AppDecorations.card(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.settings_suggest_rounded, size: 18, color: RuralCareColors.teal),
              SizedBox(width: 6),
              Text('System & Role Controls', style: AppTypography.cardTitle),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(strings.offlineSimulation, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    const Text('Simulate disconnected rural network with local SQLite cache queue', style: AppTypography.supporting),
                  ],
                ),
              ),
              Switch.adaptive(
                value: session.isOffline,
                onChanged: (_) => session.toggleOffline(),
                activeColor: RuralCareColors.teal,
              ),
            ],
          ),
          const Divider(height: 24),
          InkWell(
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(session.isHi ? 'साइन आउट करें?' : (session.isMr ? 'साइन आउट करायचे?' : 'Sign Out?')),
                  content: Text(session.isHi
                      ? 'क्या आप सुरक्षित रूप से सुविधा सत्र समाप्त करना चाहते हैं?'
                      : (session.isMr ? 'आपण सुरक्षितपणे सुविधा सत्र समाप्त करू इच्छिता?' : 'Are you sure you want to end this facility workstation session?')),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: Text(session.isHi ? 'रद्द करें' : (session.isMr ? 'रद्द करा' : 'Cancel')),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        session.clearAuthenticatedUser();
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      },
                      child: Text(session.isHi ? 'साइन आउट' : (session.isMr ? 'साइन आउट' : 'Sign Out'),
                          style: const TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.logout_rounded, color: Color(0xFFDC2626)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.isHi ? 'सुविधा से साइन आउट करें' : (session.isMr ? 'सुविधेतून साइन आउट करा' : 'Sign Out from Facility'),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFDC2626)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          session.isHi ? 'प्रशासनिक और स्टाफ सत्र समाप्त करें' : (session.isMr ? 'प्रशासकीय आणि कर्मचारी सत्र समाप्त करा' : 'End facility administration & staff session'),
                          style: AppTypography.supporting,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: RuralCareColors.textSecondary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showReassignStaffModal(
    BuildContext context,
    FacilityStaffMember member,
    FacilityRepository facRepo,
    FacilityStrings strings,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: RuralCareColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Reassign ${member.name}', style: AppTypography.sectionTitle),
                    Text('Current: ${member.assignedRoom}', style: AppTypography.supporting),
                  ],
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.meeting_room, color: RuralCareColors.teal),
              title: const Text('Room 1 • MCH & Immunization Wing'),
              onTap: () {
                facRepo.reassignStaff(staffId: member.id, newRoom: 'Room 1 • MCH & Immunization');
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${member.name} reassigned to Room 1.')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.meeting_room, color: RuralCareColors.primary),
              title: const Text('Room 2 • NCD & General OPD'),
              onTap: () {
                facRepo.reassignStaff(staffId: member.id, newRoom: 'Room 2 • NCD & General OPD');
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${member.name} reassigned to Room 2.')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.emergency_outlined, color: RuralCareColors.critical),
              title: const Text('Emergency Stabilization Suite (24x7)'),
              onTap: () {
                facRepo.reassignStaff(staffId: member.id, newRoom: 'Emergency Suite (24x7)');
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${member.name} reassigned to Emergency.')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.local_pharmacy_outlined, color: RuralCareColors.warning),
              title: const Text('Dispensary Counter A & Stock Ledger'),
              onTap: () {
                facRepo.reassignStaff(staffId: member.id, newRoom: 'Dispensary Counter A');
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${member.name} reassigned to Dispensary.')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
