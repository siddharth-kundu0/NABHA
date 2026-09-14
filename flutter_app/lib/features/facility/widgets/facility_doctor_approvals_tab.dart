import 'package:flutter/material.dart';
import 'package:ruralcare/app/routes.dart';
import 'package:ruralcare/core/theme/app_theme.dart';
import 'package:ruralcare/data/models/doctor_verification_request_dto.dart';
import 'package:ruralcare/data/repositories/doctor_repository.dart';
import 'package:ruralcare/data/repositories/facility_repository.dart';

class FacilityDoctorApprovalsTab extends StatefulWidget {
  final String? facilityId;

  const FacilityDoctorApprovalsTab({super.key, this.facilityId});

  @override
  State<FacilityDoctorApprovalsTab> createState() => _FacilityDoctorApprovalsTabState();
}

class _FacilityDoctorApprovalsTabState extends State<FacilityDoctorApprovalsTab> {
  final TextEditingController _rejectionReasonCtrl = TextEditingController();

  @override
  void dispose() {
    _rejectionReasonCtrl.dispose();
    super.dispose();
  }

  void _handleAccept(DoctorVerificationRequestDto request) {
    final session = SessionCoordinator();
    final reviewer = session.isMarathi
        ? 'सिस्टर सरिता पाटील, आर.एन. (प्रशासन)'
        : 'Sister Sarita Patil, RN (Facility Admin)';

    final updated = DoctorRepository().acceptVerificationRequest(
      request.id,
      reviewedBy: reviewer,
    );

    if (updated != null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Color(0xFF15803D)),
              SizedBox(width: 8),
              Text('Doctor Affiliation Approved', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${updated.doctorName} has been officially approved and added to the facility medical roster.'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Generated Doctor ID: ${updated.generatedDoctorId}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF15803D))),
                    const SizedBox(height: 4),
                    Text('Activation OTP Dispatched: ${updated.tempOtp}', style: const TextStyle(fontSize: 13, color: Color(0xFF15803D))),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0A6B56))),
            ),
          ],
        ),
      );
    }
  }

  void _handleReject(DoctorVerificationRequestDto request) {
    _rejectionReasonCtrl.text = 'Credentials could not be verified with State Medical Council.';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reject Verification Request', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Specify the clinical or administrative reason for rejecting ${request.doctorName}:'),
            const SizedBox(height: 10),
            TextField(
              controller: _rejectionReasonCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'e.g. Incomplete registration documents',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              DoctorRepository().rejectVerificationRequest(
                request.id,
                reason: _rejectionReasonCtrl.text.trim(),
                reviewedBy: 'Sister Sarita Patil, RN',
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Request for ${request.doctorName} rejected.')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB91C1C), foregroundColor: Colors.white),
            child: const Text('Confirm Reject'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final docRepo = DoctorRepository();
    final facRepo = FacilityRepository();
    final targetFacilityId = widget.facilityId ?? 'FAC-SC-102';

    return ListenableBuilder(
      listenable: docRepo,
      builder: (context, _) {
        final pendingRequests = docRepo.getPendingRequestsForFacility(targetFacilityId);
        final roster = facRepo.staffRoster.where((s) => s.role == 'Doctor').toList();

        return Scaffold(
          backgroundColor: RuralCareColors.canvas,
          appBar: AppBar(
            backgroundColor: RuralCareColors.surface,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: RuralCareColors.textPrimary),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: const Text('Doctor Verification Desk', style: AppTypography.cardTitle),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Information Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A6B56).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF0A6B56).withOpacity(0.25)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.verified_user_outlined, color: Color(0xFF0A6B56), size: 28),
                      SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Staff & Doctor Credentialing', style: AppTypography.cardTitle),
                            SizedBox(height: 2),
                            Text(
                              'Review incoming doctor affiliation requests. Approving issues an official Doctor ID and authentication OTP.',
                              style: AppTypography.supporting,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Section 1: Pending Verification Requests
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text('Pending Applications', style: AppTypography.sectionTitle),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: pendingRequests.isNotEmpty ? const Color(0xFFB45309) : RuralCareColors.surfaceSubtle,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${pendingRequests.length}',
                            style: TextStyle(
                              color: pendingRequests.isNotEmpty ? Colors.white : RuralCareColors.textSecondary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (pendingRequests.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: AppDecorations.card(),
                    child: const Column(
                      children: [
                        Icon(Icons.check_circle_outline, color: Color(0xFF15803D), size: 36),
                        SizedBox(height: 8),
                        Text('No Pending Requests', style: AppTypography.cardTitle),
                        SizedBox(height: 4),
                        Text(
                          'All doctor registration and affiliation requests for this facility have been reviewed.',
                          style: AppTypography.supporting,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else
                  ...pendingRequests.map((req) => _buildRequestCard(req)),

                const SizedBox(height: 28),

                // Section 2: Active Verified Medical Officers Roster
                const Row(
                  children: [
                    Icon(Icons.medical_services_outlined, color: Color(0xFF0A6B56), size: 20),
                    SizedBox(width: 8),
                    Text('Verified Facility Doctors Roster', style: AppTypography.sectionTitle),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: AppDecorations.card(),
                  child: Column(
                    children: roster.map((doc) {
                      return ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFE8F5F2),
                          child: Icon(Icons.person, color: Color(0xFF0A6B56)),
                        ),
                        title: Text(doc.name, style: AppTypography.cardTitle.copyWith(fontSize: 14)),
                        subtitle: Text('${doc.designation} • ${doc.assignedRoom}', style: AppTypography.supporting),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text('ACTIVE', style: TextStyle(color: Color(0xFF15803D), fontWeight: FontWeight.bold, fontSize: 10)),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRequestCard(DoctorVerificationRequestDto req) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: RuralCareColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFB45309).withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(req.doctorName, style: AppTypography.cardTitle.copyWith(fontSize: 16)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'PENDING REVIEW',
                  style: TextStyle(color: Color(0xFFB45309), fontWeight: FontWeight.bold, fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('${req.specialty} • ${req.qualification}', style: const TextStyle(fontSize: 13, color: Color(0xFF0A6B56), fontWeight: FontWeight.w600)),
          const Divider(height: 20, color: RuralCareColors.border),
          _infoRow('Council Reg No.', req.registrationNumber),
          _infoRow('Medical Council', req.medicalCouncil),
          _infoRow('Mobile', req.doctorMobile),
          _infoRow('Email', req.email),
          _infoRow('Target Facility', req.targetFacilityName),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.close, size: 16, color: Color(0xFFB91C1C)),
                  label: const Text('Reject', style: TextStyle(color: Color(0xFFB91C1C), fontWeight: FontWeight.bold)),
                  onPressed: () => _handleReject(req),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFB91C1C)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Accept & Issue Doctor ID', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  onPressed: () => _handleAccept(req),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A6B56),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.supporting.copyWith(fontSize: 12)),
          Text(value, style: AppTypography.body.copyWith(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
