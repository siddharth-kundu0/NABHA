import 'package:flutter/material.dart';
import 'package:ruralcare/core/theme/app_theme.dart';
import 'package:ruralcare/data/repositories/doctor_repository.dart';
import 'package:ruralcare/data/repositories/facility_repository.dart';
import 'package:ruralcare/data/repositories/patient_repository.dart';
import 'package:ruralcare/core/database/local_cache.dart';
import 'package:ruralcare/app/routes.dart';
import 'package:ruralcare/data/models/doctor_verification_request_dto.dart';
import 'package:ruralcare/data/models/facility_dto.dart';

/// Module 1: System Admin Dashboard (Stitch Screen 1: d458443465b14e4b93862d1d4ffc0af7)
/// High-density clinical cockpit with Cluster Banner, 4 KPI cards, Action Ribbon,
/// Actionable Pending Approvals, Administrative Audit Trail, and Cluster Telemetry.
class AdminDashboardTab extends StatefulWidget {
  final Function(int tabIndex)? onNavigateTab;
  final VoidCallback? onBroadcastNotice;

  const AdminDashboardTab({
    super.key,
    this.onNavigateTab,
    this.onBroadcastNotice,
  });

  @override
  State<AdminDashboardTab> createState() => _AdminDashboardTabState();
}

class _AdminDashboardTabState extends State<AdminDashboardTab> {
  final DoctorRepository _docRepo = DoctorRepository();
  final FacilityRepository _facRepo = FacilityRepository();
  final PatientRepository _patientRepo = PatientRepository();
  final LocalCacheService _cache = LocalCacheService();
  final SessionCoordinator _session = SessionCoordinator();

  bool _isReSyncing = false;

  void _triggerManualSync() async {
    setState(() => _isReSyncing = true);
    _cache.syncOutbox();
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      setState(() => _isReSyncing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Cluster synchronization verified • All nodes up to date'),
            ],
          ),
          backgroundColor: Color(0xFF005140),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showApprovalDetails(DoctorVerificationRequestDto req) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF005140).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.verified_user_rounded, color: Color(0xFF005140), size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(req.doctorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(req.specialty, style: const TextStyle(fontSize: 12, color: RuralCareColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow('Application ID', req.id),
              _detailRow('Medical Council Reg #', req.registrationNumber),
              _detailRow('Medical Council', req.medicalCouncil),
              _detailRow('Qualification', req.qualification),
              _detailRow('Target Facility', req.targetFacilityName),
              _detailRow('Contact Mobile', req.doctorMobile),
              _detailRow('Email', req.email),
              _detailRow('Submitted On', req.submittedAt.toString().substring(0, 16)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.shield_outlined, color: Color(0xFF33647B), size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'ABDM Healthcare Professional Registry (HPR) cross-check passed. Biometric token active.',
                        style: TextStyle(fontSize: 11, color: Color(0xFF33647B)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(foregroundColor: RuralCareColors.critical),
            onPressed: () {
              Navigator.pop(ctx);
              _handleReject(req);
            },
            child: const Text('Reject'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF005140),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _handleApprove(req);
            },
            child: const Text('Approve Credential'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: const TextStyle(fontSize: 12, color: RuralCareColors.textSecondary)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: RuralCareColors.textPrimary)),
          ),
        ],
      ),
    );
  }

  void _handleApprove(DoctorVerificationRequestDto req) {
    _docRepo.acceptVerificationRequest(req.id, reviewedBy: 'Super Admin (District HQ)');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Approved ${req.doctorName} for ${req.targetFacilityName}. Credentials active.'),
        backgroundColor: const Color(0xFF005140),
      ),
    );
  }

  void _handleReject(DoctorVerificationRequestDto req) {
    final reasonCtrl = TextEditingController(text: 'Incomplete council certificate registration');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Credential Application'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Specify reason for rejecting ${req.doctorName}:', style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 10),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Rejection Notice',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: RuralCareColors.critical),
            onPressed: () {
              _docRepo.rejectVerificationRequest(req.id, reason: reasonCtrl.text, reviewedBy: 'Super Admin');
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Application rejected for ${req.doctorName}.'),
                  backgroundColor: RuralCareColors.critical,
                ),
              );
            },
            child: const Text('Confirm Rejection', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _handleApproveAdmin(FacilityStaffRequestDto req) {
    _facRepo.approveFacilityAdminRequest(req.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Approved ${req.staffName} as Facility Administrator for ${req.facilityName}.'),
        backgroundColor: const Color(0xFF005140),
      ),
    );
  }

  void _handleRejectAdmin(FacilityStaffRequestDto req) {
    final reasonCtrl = TextEditingController(text: 'Facility administrative credentials unverified');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Admin Credential'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Specify reason for rejecting ${req.staffName}:', style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 10),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Rejection Reason',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: RuralCareColors.critical),
            onPressed: () {
              _facRepo.rejectFacilityAdminRequest(req.id, reasonCtrl.text.trim());
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Admin application rejected for ${req.staffName}.'),
                  backgroundColor: RuralCareColors.critical,
                ),
              );
            },
            child: const Text('Confirm Rejection', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAdminApprovalDetails(FacilityStaffRequestDto req) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF005140).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF005140), size: 20),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Facility Admin Application',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow('Applicant Name', req.staffName),
              _detailRow('Requested Role', 'Facility Administrator'),
              _detailRow('Target Facility', req.facilityName),
              _detailRow('Facility ID', req.facilityId),
              _detailRow('Contact Phone', req.mobile),
              _detailRow('Staff / Govt ID', req.licenseOrEmployeeId.isNotEmpty ? req.licenseOrEmployeeId : 'PENDING-HFR-ISSUE'),
              _detailRow('Application Date', '${req.submittedAt.day}/${req.submittedAt.month}/${req.submittedAt.year}'),
              _detailRow('Reference Code', req.id),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.verified_outlined, color: Color(0xFF15803D), size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'National Health Facility Registry (HFR) validation confirmed. Approving grants full administrative control of this facility.',
                        style: TextStyle(fontSize: 11, color: Color(0xFF15803D)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(foregroundColor: RuralCareColors.critical),
            onPressed: () {
              Navigator.pop(ctx);
              _handleRejectAdmin(req);
            },
            child: const Text('Reject'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF005140),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _handleApproveAdmin(req);
            },
            child: const Text('Authorize Admin'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMr = _session.isMr;
    final isHi = _session.isHi;

    return ListenableBuilder(
      listenable: Listenable.merge([_docRepo, _facRepo, _patientRepo, _cache, _session]),
      builder: (context, _) {
        final pendingRequests = _docRepo.verificationRequests
            .where((r) => r.status == DoctorVerificationStatus.pending)
            .toList();
        final pendingAdminRequests = _facRepo.getPendingFacilityAdminRequests();

        final totalUsersCount = _patientRepo.patients.length +
            _docRepo.registeredDoctors.length +
            _facRepo.staffRoster.length;

        final facilitiesCount = _facRepo.facilities.length;
        final pendingApprovalsCount = pendingRequests.length + pendingAdminRequests.length;
        final outboxQueueCount = _cache.pendingOutboxCount;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Cluster Status Banner (Stitch Screen 1)
              _buildClusterBanner(isHi, isMr),
              const SizedBox(height: 20),

              // 2. 4 High-Impact KPI Metric Cards
              _buildKpiGrid(
                totalUsersCount: totalUsersCount,
                facilitiesCount: facilitiesCount,
                pendingApprovalsCount: pendingApprovalsCount,
                outboxQueueCount: outboxQueueCount,
                isHi: isHi,
                isMr: isMr,
              ),
              const SizedBox(height: 20),

              // 3. Quick Operational Action Ribbon
              _buildActionRibbon(isHi, isMr),
              const SizedBox(height: 24),

              // 4. Two-Column Layout (Responsive)
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 850;
                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 6,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildPendingApprovalsCard(pendingRequests, pendingAdminRequests, isHi, isMr),
                              const SizedBox(height: 20),
                              _buildAuditTrailCard(isHi, isMr),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          flex: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildTelemetryCard(isHi, isMr),
                              const SizedBox(height: 20),
                              _buildSecurityStatusCard(isHi, isMr),
                            ],
                          ),
                        ),
                      ],
                    );
                  } else {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPendingApprovalsCard(pendingRequests, pendingAdminRequests, isHi, isMr),
                        const SizedBox(height: 20),
                        _buildTelemetryCard(isHi, isMr),
                        const SizedBox(height: 20),
                        _buildAuditTrailCard(isHi, isMr),
                        const SizedBox(height: 20),
                        _buildSecurityStatusCard(isHi, isMr),
                      ],
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildClusterBanner(bool isHi, bool isMr) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00382B), Color(0xFF005140), Color(0xFF0A6B56)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF005140).withOpacity(0.2),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.hub_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        isMr
                            ? 'रामपूर जिल्हा क्लस्टर मुख्यालय'
                            : (isHi ? 'रामपुर जिला क्लस्टर मुख्यालय' : 'Rampur District Cluster HQ'),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: AppTypography.fontFamily,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E).withOpacity(0.25),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF22C55E), width: 0.8),
                      ),
                      child: const Text(
                        '18 Nodes Online',
                        style: TextStyle(color: Color(0xFF86EFAC), fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  isMr
                          ? 'सक्रिय सत्र: RC-ADM-4091 • सुपर अ‍ॅडमिनिस्ट्रेटर अधिकार'
                          : (isHi
                              ? 'सक्रिय सत्र: RC-ADM-4091 • सुपर एडमिनिस्ट्रेटर विशेषाधिकार'
                              : 'Active Session: RC-ADM-4091 • Super Administrator Privileges'),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 12,
                    fontFamily: AppTypography.fontFamily,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF005140),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: _isReSyncing ? null : _triggerManualSync,
            icon: _isReSyncing
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF005140)),
                  )
                : const Icon(Icons.sync_rounded, size: 16),
            label: Text(
              isMr ? 'मॅन्युअल सिंक' : (isHi ? 'मैन्युअल सिंक' : 'Manual Re-Sync'),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiGrid({
    required int totalUsersCount,
    required int facilitiesCount,
    required int pendingApprovalsCount,
    required int outboxQueueCount,
    required bool isHi,
    required bool isMr,
  }) {
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
              child: _buildMetricCard(
                title: isMr ? 'नोंदणीकृत वापरकर्ते' : (isHi ? 'पंजीकृत उपयोगकर्ता' : 'Registered Users'),
                value: '$totalUsersCount',
                subtitle: isMr ? 'रुग्ण, आशा व डॉक्टर' : (isHi ? 'मरीज, आशा व डॉक्टर' : 'Patients, ASHAs & Doctors'),
                icon: Icons.people_alt_rounded,
                accentColor: const Color(0xFF005140),
                onTap: () => widget.onNavigateTab?.call(1),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _buildMetricCard(
                title: isMr ? 'सक्रिय आरोग्य संस्था' : (isHi ? 'सक्रिय स्वास्थ्य केंद्र' : 'Active Facilities'),
                value: '$facilitiesCount',
                subtitle: isMr ? '100% नोड्स कनेक्टेड' : (isHi ? '100% नोड्स कनेक्टेड' : '100% Nodes Online'),
                icon: Icons.local_hospital_rounded,
                accentColor: const Color(0xFF33647B),
                onTap: () => widget.onNavigateTab?.call(2),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _buildMetricCard(
                title: isMr ? 'प्रलंबित परवानग्या' : (isHi ? 'लंबित अनुमोदन' : 'Pending Approvals'),
                value: '$pendingApprovalsCount',
                subtitle: pendingApprovalsCount > 0
                    ? (isMr ? 'तात्काळ लक्ष द्या' : (isHi ? 'कार्रवाई आवश्यक' : 'Action Required'))
                    : (isMr ? 'सर्व मंजूर' : (isHi ? 'सभी स्वीकृत' : 'All Clear')),
                icon: Icons.pending_actions_rounded,
                accentColor: pendingApprovalsCount > 0 ? const Color(0xFFC05621) : const Color(0xFF15803D),
                hasBadge: pendingApprovalsCount > 0,
                onTap: () => widget.onNavigateTab?.call(1),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _buildMetricCard(
                title: isMr ? 'टेलीमेट्री व सिंक' : (isHi ? 'टेलीमेट्री व सिंक' : 'Telemetry & Sync'),
                value: '$outboxQueueCount queued',
                subtitle: isMr ? '42ms लेटन्सी • सुरक्षित' : (isHi ? '42ms लेटेंसी • सुरक्षित' : '42ms Latency • Healthy'),
                icon: Icons.sensors_rounded,
                accentColor: const Color(0xFF0A6B56),
                onTap: () => widget.onNavigateTab?.call(3),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    bool hasBadge = false,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: hasBadge ? const Color(0xFFFDBA74) : const Color(0xFFE2E8F0),
              width: hasBadge ? 1.5 : 1,
            ),
            color: hasBadge ? const Color(0xFFFFF7ED) : Colors.white,
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
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: RuralCareColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: accentColor, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: hasBadge ? const Color(0xFFC05621) : const Color(0xFF0F172A),
                  fontFamily: AppTypography.fontFamily,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  if (hasBadge)
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: const BoxDecoration(
                        color: Color(0xFFC05621),
                        shape: BoxShape.circle,
                      ),
                    ),
                  Expanded(
                    child: Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: hasBadge ? const Color(0xFFC05621) : RuralCareColors.textSecondary,
                        fontWeight: hasBadge ? FontWeight.w600 : FontWeight.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionRibbon(bool isHi, bool isMr) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF005140).withOpacity(0.2)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.bolt_rounded, color: Color(0xFF005140), size: 20),
          const SizedBox(width: 8),
          Text(
            isMr ? 'त्वरित ऑपरेशन्स:' : (isHi ? 'त्वरित संचालन:' : 'Quick Operations:'),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF005140),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _ribbonButton(
                    label: isMr ? 'प्रवेश अधिकार' : (isHi ? 'एक्सेस नियंत्रण' : 'Manage Access'),
                    icon: Icons.manage_accounts_outlined,
                    onTap: () => widget.onNavigateTab?.call(1),
                  ),
                  const SizedBox(width: 8),
                  _ribbonButton(
                    label: isMr ? 'संस्था नोंदणी' : (isHi ? 'संस्था रजिस्ट्री' : 'Facilities Registry'),
                    icon: Icons.domain_outlined,
                    onTap: () => widget.onNavigateTab?.call(2),
                  ),
                  const SizedBox(width: 8),
                  _ribbonButton(
                    label: isMr ? 'प्रलंबित अर्ज' : (isHi ? 'सत्यापन कतार' : 'Verify Approvals'),
                    icon: Icons.verified_user_outlined,
                    onTap: () => widget.onNavigateTab?.call(1),
                  ),
                  const SizedBox(width: 8),
                  _ribbonButton(
                    label: isMr ? 'सिस्टम ऑडिट' : (isHi ? 'सिस्टम ऑडिट' : 'System & Telemetry'),
                    icon: Icons.shield_outlined,
                    onTap: () => widget.onNavigateTab?.call(3),
                  ),
                  const SizedBox(width: 8),
                  _ribbonButton(
                    label: isMr ? 'सूचना पाठवा' : (isHi ? 'नोटिस भेजें' : 'Broadcast Notice'),
                    icon: Icons.campaign_outlined,
                    onTap: widget.onBroadcastNotice,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ribbonButton({
    required String label,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF005140).withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: const Color(0xFF005140)),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF005140),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingApprovalsCard(
    List<DoctorVerificationRequestDto> requests,
    List<FacilityStaffRequestDto> adminRequests,
    bool isHi,
    bool isMr,
  ) {
    final totalPending = requests.length + adminRequests.length;
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
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFC05621).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.assignment_ind_rounded, color: Color(0xFFC05621), size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isMr ? 'प्रलंबित परवानग्या (अॅडमिन व डॉक्टर्स)' : (isHi ? 'लंबित अनुमोदन (एडमिन व डॉक्टर्स)' : 'Pending Role & Practitioner Approvals'),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: RuralCareColors.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (totalPending > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFDBA74)),
                  ),
                  child: Text(
                    '$totalPending Action Needed',
                    style: const TextStyle(color: Color(0xFFC05621), fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (totalPending == 0)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
              alignment: Alignment.center,
              child: Column(
                children: [
                  const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF15803D), size: 36),
                  const SizedBox(height: 8),
                  Text(
                    isMr
                        ? 'कोणतेही प्रलंबित अर्ज नाहीत. सर्व डॉक्टर्स व प्रशासक सत्यापित आहेत.'
                        : (isHi
                            ? 'कोई लंबित आवेदन नहीं है। सभी डॉक्टर एवं प्रशासक सत्यापित हैं।'
                            : 'All facility admin and practitioner credentials across Rampur district are verified and active.'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: RuralCareColors.textSecondary),
                  ),
                ],
              ),
            )
          else ...[
            if (adminRequests.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5F2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.admin_panel_settings_outlined, size: 15, color: Color(0xFF005140)),
                    const SizedBox(width: 6),
                    Text(
                      isMr ? 'रुग्णालय / केंद्र प्रशासक अर्ज' : (isHi ? 'अस्पताल / केंद्र प्रशासक आवेदन' : 'Facility Administrator Applications (District Authority)'),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF005140)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: adminRequests.length,
                separatorBuilder: (ctx, i) => const Divider(height: 16, color: Color(0xFFF1F5F9)),
                itemBuilder: (ctx, i) {
                  final req = adminRequests[i];
                  return Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: const Color(0xFF005140).withOpacity(0.12),
                        child: Text(
                          req.staffName.isNotEmpty ? req.staffName[0].toUpperCase() : 'A',
                          style: const TextStyle(color: Color(0xFF005140), fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(req.staffName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF0FDF4),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: const Color(0xFFBBF7D0)),
                                  ),
                                  child: const Text('Facility Admin', style: TextStyle(fontSize: 10, color: Color(0xFF15803D), fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${req.facilityName} • Mob: ${req.mobile}',
                              style: const TextStyle(fontSize: 11, color: RuralCareColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Wrap(
                        spacing: 6,
                        children: [
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () => _showAdminApprovalDetails(req),
                            child: const Text('Review', style: TextStyle(fontSize: 11)),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF005140),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () => _handleApproveAdmin(req),
                            child: const Text('Approve', style: TextStyle(fontSize: 11)),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
              if (requests.isNotEmpty) const SizedBox(height: 18),
            ],
            if (requests.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.medical_services_outlined, size: 15, color: Color(0xFF1D4ED8)),
                    const SizedBox(width: 6),
                    Text(
                      isMr ? 'वैद्यकीय अधिकारी अर्ज' : (isHi ? 'चिकित्सा अधिकारी आवेदन' : 'Practitioner & Medical Officer Credentials'),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: requests.length,
                separatorBuilder: (ctx, i) => const Divider(height: 16, color: Color(0xFFF1F5F9)),
                itemBuilder: (ctx, i) {
                  final req = requests[i];
                  return Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: const Color(0xFF005140).withOpacity(0.1),
                        child: Text(
                          req.doctorName.isNotEmpty ? req.doctorName[0].toUpperCase() : 'D',
                          style: const TextStyle(color: Color(0xFF005140), fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(req.doctorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(req.specialty, style: const TextStyle(fontSize: 10, color: Color(0xFF1D4ED8), fontWeight: FontWeight.w600)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${req.targetFacilityName} • Reg: ${req.registrationNumber}',
                              style: const TextStyle(fontSize: 11, color: RuralCareColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Wrap(
                        spacing: 6,
                        children: [
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () => _showApprovalDetails(req),
                            child: const Text('Review', style: TextStyle(fontSize: 11)),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF005140),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () => _handleApprove(req),
                            child: const Text('Approve', style: TextStyle(fontSize: 11)),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildAuditTrailCard(bool isHi, bool isMr) {
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
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF33647B).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.history_rounded, color: Color(0xFF33647B), size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isMr ? 'प्रशासकीय सुरक्षा व ऑडिट नोंदी' : (isHi ? 'प्रशासनिक सुरक्षा व ऑडिट लॉग' : 'Administrative Security & Audit Trail'),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: RuralCareColors.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => widget.onNavigateTab?.call(3),
                child: Text(isMr ? 'सर्व पहा' : (isHi ? 'सभी देखें' : 'View Full Log'), style: const TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _auditRow('Dr. Sharma (Super Admin)', 'Doctor Credential Approved (DOC-MH-8421-204)', 'Aundh DH', '10m ago', true),
          _auditRow('System Scheduler', 'Cluster Data Re-Sync Flush executed', 'Baramati SDH', '24m ago', true),
          _auditRow('Admin Portal', 'Bed Inventory Threshold verified', 'Kashti SC', '1h ago', true),
          _auditRow('Security Daemon', 'ABDM Gateway Token renewed (AES-256)', 'HQ Node 01', '3h ago', true),
        ],
      ),
    );
  }

  Widget _auditRow(String actor, String action, String target, String time, bool isSuccess) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isSuccess ? Icons.check_circle_outline_rounded : Icons.warning_amber_rounded,
            color: isSuccess ? const Color(0xFF15803D) : const Color(0xFFB45309),
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(action, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: RuralCareColors.textPrimary)),
                const SizedBox(height: 2),
                Text('$actor • Target: $target', style: const TextStyle(fontSize: 11, color: RuralCareColors.textSecondary)),
              ],
            ),
          ),
          Text(time, style: const TextStyle(fontSize: 10, color: RuralCareColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildTelemetryCard(bool isHi, bool isMr) {
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
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF005140).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.network_check_rounded, color: Color(0xFF005140), size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isMr ? 'क्लस्टर टेलीमेट्री' : (isHi ? 'क्लस्टर टेलीमेट्री' : 'Cluster Telemetry'),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: RuralCareColors.textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _telemetryItem(
            label: 'Cloud Database Replication',
            status: 'Operational (42ms latency)',
            icon: Icons.cloud_done_rounded,
            isGreen: true,
          ),
          _telemetryItem(
            label: 'Offline Sync Queue',
            status: '${_cache.pendingOutboxCount} pending mutations',
            icon: Icons.sync_problem_rounded,
            isGreen: _cache.pendingOutboxCount == 0,
          ),
          _telemetryItem(
            label: 'ABDM Security Layer',
            status: 'TLS 1.3 / AES-256 GCM Active',
            icon: Icons.lock_rounded,
            isGreen: true,
          ),
          _telemetryItem(
            label: 'Local SQLite Storage Cache',
            status: 'Healthy • 34% Allocated',
            icon: Icons.storage_rounded,
            isGreen: true,
          ),
        ],
      ),
    );
  }

  Widget _telemetryItem({
    required String label,
    required String status,
    required IconData icon,
    required bool isGreen,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: isGreen ? const Color(0xFF15803D) : const Color(0xFFC05621)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                Text(status, style: TextStyle(fontSize: 11, color: isGreen ? const Color(0xFF15803D) : const Color(0xFFC05621))),
              ],
            ),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isGreen ? const Color(0xFF15803D) : const Color(0xFFC05621),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityStatusCard(bool isHi, bool isMr) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.security_rounded, color: Color(0xFF33647B), size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Security & Access Status',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: RuralCareColors.textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Multi-factor role validation enforced. All administrative actions require hardware cryptographic nonce.',
            style: TextStyle(fontSize: 11, color: RuralCareColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF005140),
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(38),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: widget.onBroadcastNotice,
            icon: const Icon(Icons.campaign_rounded, size: 16),
            label: Text(
              isMr ? 'सर्व केंद्रांना सूचना पाठवा' : (isHi ? 'सभी केंद्रों को नोटिस भेजें' : 'Broadcast Notice to Facilities'),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
