import 'package:flutter/material.dart';
import 'package:ruralcare/app/routes.dart';
import 'package:ruralcare/core/theme/app_theme.dart';
import 'package:ruralcare/data/models/facility_dto.dart';
import 'package:ruralcare/data/repositories/facility_repository.dart';
import 'package:ruralcare/features/facility/screens/facility_dashboard_screen.dart';
import 'package:ruralcare/features/facility/utils/facility_strings.dart';

class FacilityApprovalWaitingScreen extends StatefulWidget {
  final FacilityStaffRequestDto request;

  const FacilityApprovalWaitingScreen({super.key, required this.request});

  @override
  State<FacilityApprovalWaitingScreen> createState() => _FacilityApprovalWaitingScreenState();
}

class _FacilityApprovalWaitingScreenState extends State<FacilityApprovalWaitingScreen> {
  late FacilityStaffRequestDto _currentRequest;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _currentRequest = widget.request;
  }

  void _checkStatus() async {
    setState(() => _isChecking = true);
    await Future.delayed(const Duration(milliseconds: 500));

    final facRepo = FacilityRepository();
    final updated = facRepo.getRequestById(_currentRequest.id);

    if (mounted) {
      if (updated != null) {
        setState(() {
          _currentRequest = updated;
          _isChecking = false;
        });

        if (updated.status == FacilityApprovalStatus.approved) {
          _enterWorkspace(updated);
        } else if (updated.status == FacilityApprovalStatus.rejected) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Application rejected: ${updated.rejectionReason ?? "Please contact administration"}'),
              backgroundColor: RuralCareColors.critical,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Request is currently under administrative review.')),
          );
        }
      } else {
        setState(() => _isChecking = false);
      }
    }
  }

  void _simulateFastTrackApproval() {
    final facRepo = FacilityRepository();
    if (_currentRequest.role == FacilityStaffRole.facilityAdmin) {
      facRepo.approveFacilityAdminRequest(_currentRequest.id);
    } else {
      facRepo.approveStaffRequest(_currentRequest.id);
    }

    final updated = facRepo.getRequestById(_currentRequest.id);
    if (updated != null) {
      setState(() => _currentRequest = updated);
      _enterWorkspace(updated);
    }
  }

  void _enterWorkspace(FacilityStaffRequestDto approvedRequest) {
    final facRepo = FacilityRepository();
    facRepo.setCurrentStaffSession(approvedRequest);

    final session = SessionCoordinator();
    session.switchRole(AppRole.facilityStaff);
    session.completeOnboarding();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Access Authorized! Welcome to ${approvedRequest.role.displayName}.'),
        backgroundColor: RuralCareColors.success,
      ),
    );

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const FacilityDashboardScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionCoordinator();
    final strings = FacilityStrings.of(session);
    final isFacilityAdmin = _currentRequest.role == FacilityStaffRole.facilityAdmin;
    final isApproved = _currentRequest.status == FacilityApprovalStatus.approved;
    final isRejected = _currentRequest.status == FacilityApprovalStatus.rejected;

    return Scaffold(
      backgroundColor: RuralCareColors.canvas,
      appBar: AppBar(
        backgroundColor: RuralCareColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: RuralCareColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(strings.waitingApprovalTitle, style: AppTypography.cardTitle),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Status Card
              Container(
                width: double.infinity,
                decoration: AppDecorations.card(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: isApproved
                            ? RuralCareColors.success.withOpacity(0.12)
                            : (isRejected
                                ? RuralCareColors.critical.withOpacity(0.12)
                                : const Color(0xFFD97706).withOpacity(0.12)),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isApproved
                            ? Icons.verified_user_rounded
                            : (isRejected ? Icons.cancel_outlined : Icons.hourglass_top_rounded),
                        color: isApproved
                            ? RuralCareColors.success
                            : (isRejected ? RuralCareColors.critical : const Color(0xFFD97706)),
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isApproved
                          ? 'Application Approved & Verified'
                          : (isRejected ? 'Application Rejected' : 'Access Authorization Pending'),
                      style: AppTypography.cardTitle.copyWith(fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isApproved
                            ? const Color(0xFFECFDF5)
                            : (isRejected ? const Color(0xFFFEF2F2) : const Color(0xFFFFFBEB)),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isApproved
                              ? RuralCareColors.success.withOpacity(0.3)
                              : (isRejected
                                  ? RuralCareColors.critical.withOpacity(0.3)
                                  : const Color(0xFFD97706).withOpacity(0.3)),
                        ),
                      ),
                      child: Text(
                        _currentRequest.status.label.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isApproved
                              ? RuralCareColors.success
                              : (isRejected ? RuralCareColors.critical : const Color(0xFFB45309)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      isFacilityAdmin ? strings.waitingAdminDesc : strings.waitingStaffDesc,
                      style: AppTypography.supporting,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Application Credentials Summary
              const Text('Submitted Credentials', style: AppTypography.sectionTitle),
              const SizedBox(height: 10),
              Container(
                decoration: AppDecorations.card(),
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    _buildRow('Application ID', _currentRequest.id),
                    const Divider(height: 20),
                    _buildRow('Full Name', _currentRequest.staffName),
                    const Divider(height: 20),
                    _buildRow('Designation / Role', _currentRequest.role.displayName),
                    const Divider(height: 20),
                    _buildRow('Healthcare Facility', _currentRequest.facilityName),
                    const Divider(height: 20),
                    _buildRow('Registration / Emp ID', _currentRequest.licenseOrEmployeeId),
                    const Divider(height: 20),
                    _buildRow('Mobile Number', '+91 ${_currentRequest.mobile}'),
                    const Divider(height: 20),
                    _buildRow(
                      'Reviewing Authority',
                      isFacilityAdmin
                          ? 'District Health Office (CMHO / Pune Collectorate)'
                          : 'Medical Superintendent / Facility Admin',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Action Buttons
              if (isApproved)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () => _enterWorkspace(_currentRequest),
                    icon: const Icon(Icons.login_rounded),
                    label: const Text('Enter Workspace', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: RuralCareColors.teal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                )
              else ...[
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _isChecking ? null : _checkStatus,
                    icon: _isChecking
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh_rounded),
                    label: Text(strings.checkStatus, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: RuralCareColors.teal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: _simulateFastTrackApproval,
                    icon: const Icon(Icons.flash_on_rounded, color: Color(0xFF0A6B56), size: 18),
                    label: Text(
                      strings.fastTrackDemo,
                      style: const TextStyle(color: Color(0xFF0A6B56), fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF0A6B56), width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.supporting),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: RuralCareColors.textPrimary),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
