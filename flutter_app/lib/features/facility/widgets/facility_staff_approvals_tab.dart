import 'package:flutter/material.dart';
import 'package:ruralcare/core/theme/app_theme.dart';
import 'package:ruralcare/data/models/facility_dto.dart';
import 'package:ruralcare/data/repositories/facility_repository.dart';
import 'package:ruralcare/features/facility/utils/facility_strings.dart';
import 'package:ruralcare/app/routes.dart';

/// Facility Admin Staff Approvals Desk
/// Displays all pending staff credential access requests (Pharmacists, Nurses, Lab Techs, Intake Clerks).
/// Facility Administrator can review credentials, approve access (assign room), or reject.
class FacilityStaffApprovalsTab extends StatefulWidget {
  const FacilityStaffApprovalsTab({super.key});

  @override
  State<FacilityStaffApprovalsTab> createState() => _FacilityStaffApprovalsTabState();
}

class _FacilityStaffApprovalsTabState extends State<FacilityStaffApprovalsTab> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showApproveDialog(BuildContext context, FacilityStaffRequestDto req, FacilityRepository facRepo) {
    final roomCtrl = TextEditingController(text: req.department);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Approve ${req.staffName}', style: AppTypography.cardTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Assign operational room or wing for ${req.role.displayName}:', style: AppTypography.supporting),
            const SizedBox(height: 12),
            TextField(
              controller: roomCtrl,
              decoration: const InputDecoration(
                labelText: 'Assigned Department / Room',
                prefixIcon: Icon(Icons.meeting_room_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: RuralCareColors.teal,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              facRepo.approveStaffRequest(req.id, assignedRoom: roomCtrl.text.trim());
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Approved ${req.staffName} as active ${req.role.shortName}.'),
                  backgroundColor: RuralCareColors.success,
                ),
              );
            },
            child: const Text('Confirm Approval'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context, FacilityStaffRequestDto req, FacilityRepository facRepo) {
    final reasonCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Reject ${req.staffName}', style: AppTypography.cardTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter reason for rejecting this credential request:', style: AppTypography.supporting),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(
                labelText: 'Reason for Rejection',
                prefixIcon: Icon(Icons.feedback_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: RuralCareColors.critical,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final reason = reasonCtrl.text.trim().isEmpty ? 'Credentials could not be verified' : reasonCtrl.text.trim();
              facRepo.rejectStaffRequest(req.id, reason);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Rejected ${req.staffName}\'s access request.'),
                  backgroundColor: RuralCareColors.critical,
                ),
              );
            },
            child: const Text('Confirm Rejection'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionCoordinator();
    final facRepo = FacilityRepository();
    final strings = FacilityStrings.of(session);
    final targetFacId = session.assignedFacilityId ?? facRepo.currentFacility.id;

    return ListenableBuilder(
      listenable: facRepo,
      builder: (context, _) {
        final allRequests = facRepo.getAllStaffRequestsForFacility(targetFacId);
        final pendingRequests = facRepo.getPendingStaffRequestsForFacility(targetFacId);

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                decoration: AppDecorations.card(),
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: RuralCareColors.teal.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.verified_user_rounded, color: RuralCareColors.teal, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(strings.staffApprovals, style: AppTypography.cardTitle),
                          const SizedBox(height: 2),
                          Text(
                            '${facRepo.currentFacility.name} • Administrative Access Verification',
                            style: AppTypography.supporting,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: pendingRequests.isEmpty ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${pendingRequests.length} PENDING',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: pendingRequests.isEmpty ? RuralCareColors.success : const Color(0xFFB45309),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Pending Requests Section
              const Text('Pending Staff Authorization Requests', style: AppTypography.sectionTitle),
              const SizedBox(height: 10),

              if (pendingRequests.isEmpty)
                Container(
                  width: double.infinity,
                  decoration: AppDecorations.card(),
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    children: [
                      const Icon(Icons.check_circle_outline, color: RuralCareColors.teal, size: 40),
                      const SizedBox(height: 12),
                      const Text(
                        'No Pending Staff Requests',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'All hospital staff credential requests for ${facRepo.currentFacility.name} are reviewed and authorized.',
                        style: AppTypography.supporting,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                ...pendingRequests.map((req) => _buildRequestCard(context, req, facRepo, strings, isPending: true)),

              const SizedBox(height: 24),

              // Verified Staff History
              const Text('Recent Staff Authorization History', style: AppTypography.sectionTitle),
              const SizedBox(height: 10),

              if (allRequests.where((r) => r.status != FacilityApprovalStatus.pendingFacilityAdmin).isEmpty)
                Container(
                  width: double.infinity,
                  decoration: AppDecorations.card(),
                  padding: const EdgeInsets.all(20),
                  child: const Center(
                    child: Text('No historical staff access records yet.', style: AppTypography.supporting),
                  ),
                )
              else
                ...allRequests
                    .where((r) => r.status != FacilityApprovalStatus.pendingFacilityAdmin)
                    .map((req) => _buildRequestCard(context, req, facRepo, strings, isPending: false)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRequestCard(
    BuildContext context,
    FacilityStaffRequestDto req,
    FacilityRepository facRepo,
    FacilityStrings strings, {
    required bool isPending,
  }) {
    final isApproved = req.status == FacilityApprovalStatus.approved;
    final isRejected = req.status == FacilityApprovalStatus.rejected;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppDecorations.card(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF0A6B56).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_getRoleIcon(req.role), color: const Color(0xFF0A6B56), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(req.staffName, style: AppTypography.cardTitle),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isPending
                                ? const Color(0xFFFFFBEB)
                                : (isApproved ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2)),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            req.status.label.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isPending
                                  ? const Color(0xFFB45309)
                                  : (isApproved ? RuralCareColors.success : RuralCareColors.critical),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(req.role.displayName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0A6B56))),
                    const SizedBox(height: 4),
                    Text('Emp / Council ID: ${req.licenseOrEmployeeId} • Phone: +91 ${req.mobile}', style: AppTypography.supporting),
                    Text('Department: ${req.department}', style: AppTypography.supporting),
                    if (isRejected && (req.rejectionReason?.isNotEmpty ?? false)) ...[
                      const SizedBox(height: 4),
                      Text('Reason: ${req.rejectionReason}', style: const TextStyle(fontSize: 11, color: RuralCareColors.critical)),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (isPending) ...[
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => _showRejectDialog(context, req, facRepo),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: RuralCareColors.critical,
                    side: const BorderSide(color: RuralCareColors.critical),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(strings.rejectStaff),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () => _showApproveDialog(context, req, facRepo),
                  icon: const Icon(Icons.check, size: 16),
                  label: Text(strings.approveStaff),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: RuralCareColors.teal,
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
  }

  IconData _getRoleIcon(FacilityStaffRole role) {
    switch (role) {
      case FacilityStaffRole.pharmacist:
        return Icons.medication_outlined;
      case FacilityStaffRole.labTechnician:
        return Icons.biotech_outlined;
      case FacilityStaffRole.staffNurse:
        return Icons.local_hospital_outlined;
      case FacilityStaffRole.receptionClerk:
        return Icons.how_to_reg_outlined;
      case FacilityStaffRole.facilityAdmin:
        return Icons.admin_panel_settings_outlined;
    }
  }
}
