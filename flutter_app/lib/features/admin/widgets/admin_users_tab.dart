import 'package:flutter/material.dart';
import 'package:ruralcare/core/theme/app_theme.dart';
import 'package:ruralcare/data/repositories/doctor_repository.dart';
import 'package:ruralcare/data/repositories/facility_repository.dart';
import 'package:ruralcare/data/repositories/patient_repository.dart';
import 'package:ruralcare/app/routes.dart';
import 'package:ruralcare/data/models/doctor_verification_request_dto.dart';

/// Module 2: User & Role Management (Stitch Screen 2: e22f160b30a3437ca842468de6ecdbb0)
/// Comprehensive administrative workforce cockpit with 5 role tabs, search/filters,
/// "+ Invite Staff" modal, live directory table, and role/credential management.
class AdminUsersTab extends StatefulWidget {
  const AdminUsersTab({super.key});

  @override
  State<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends State<AdminUsersTab> {
  final DoctorRepository _docRepo = DoctorRepository();
  final FacilityRepository _facRepo = FacilityRepository();
  final PatientRepository _patientRepo = PatientRepository();
  final SessionCoordinator _session = SessionCoordinator();

  int _selectedRoleTab = 0; // 0: All, 1: Patients, 2: Health Workers, 3: Doctors, 4: Facility Staff
  String _searchQuery = '';
  String _selectedFacilityFilter = 'ALL';
  String _selectedStatusFilter = 'ALL';

  final Set<String> _deactivatedUserIds = {};

  void _showInviteStaffModal() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final specialtyCtrl = TextEditingController(text: 'General Medicine');
    final regNumCtrl = TextEditingController();
    String selectedRole = 'Doctor';
    String selectedFacId = _facRepo.facilities.first.id;
    String selectedFacName = _facRepo.facilities.first.name;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.person_add_alt_1_rounded, color: Color(0xFF005140)),
                SizedBox(width: 8),
                Text('Invite / Register Staff', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Assign verified clinical or administrative credentials to Rampur cluster workforce.',
                    style: TextStyle(fontSize: 12, color: RuralCareColors.textSecondary),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Full Name *',
                      hintText: 'e.g. Dr. Rajesh Kulkarni',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Mobile Number *',
                      hintText: '+91 98765 43210',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'Designated Role',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Doctor', child: Text('Doctor / Specialist')),
                      DropdownMenuItem(value: 'HealthWorker', child: Text('Community Health Officer (CHO)')),
                      DropdownMenuItem(value: 'Nurse', child: Text('Staff Nurse / Auxiliary')),
                      DropdownMenuItem(value: 'Admin', child: Text('Facility Administrator')),
                    ],
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedRole = val);
                    },
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: selectedFacId,
                    decoration: const InputDecoration(
                      labelText: 'Primary Facility Affiliation',
                      border: OutlineInputBorder(),
                    ),
                    items: _facRepo.facilities.map((fac) {
                      return DropdownMenuItem(
                        value: fac.id,
                        child: Text(fac.name, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          selectedFacId = val;
                          selectedFacName = _facRepo.facilities.firstWhere((f) => f.id == val).name;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: specialtyCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Specialty / Department',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: regNumCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Medical Council / Registration #',
                      hintText: 'MMC-2026-9912',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF005140),
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  if (nameCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter name and mobile number.')),
                    );
                    return;
                  }

                  if (selectedRole == 'Doctor') {
                    _docRepo.registerDoctorDirectly(
                      name: nameCtrl.text.trim(),
                      mobile: phoneCtrl.text.trim(),
                      specialty: specialtyCtrl.text.trim().isEmpty ? 'General Medicine' : specialtyCtrl.text.trim(),
                      qualification: 'MBBS / MD',
                      registrationNumber: regNumCtrl.text.trim().isEmpty ? 'MMC-${DateTime.now().millisecondsSinceEpoch % 10000}' : regNumCtrl.text.trim(),
                      facilityId: selectedFacId,
                      facilityName: selectedFacName,
                    );
                  } else {
                    _facRepo.addStaffMember(
                      FacilityStaffMember(
                        id: 'STF-${DateTime.now().millisecondsSinceEpoch % 10000}',
                        name: nameCtrl.text.trim(),
                        role: selectedRole,
                        designation: '${specialtyCtrl.text.trim()} ($selectedRole)',
                        assignedRoom: 'Clinical Block A',
                        onDutyStatus: 'On Duty',
                      ),
                    );
                  }

                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Registered and credentialed ${nameCtrl.text.trim()} successfully!'),
                      backgroundColor: const Color(0xFF005140),
                    ),
                  );
                },
                child: const Text('Complete Onboarding'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showUserDetailsModal(_UnifiedAdminUser user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: user.badgeColor.withOpacity(0.15),
              child: Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U', style: TextStyle(color: user.badgeColor, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(user.id, style: const TextStyle(fontSize: 12, color: RuralCareColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _row('Role Category', user.roleDisplay),
            _row('Affiliation', user.facilityName),
            _row('Contact Info', user.contact),
            _row('System Status', user.status),
            _row('ABDM Compliance', 'Biometric Verified • Level 2'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lock_clock_outlined, size: 16, color: Color(0xFF33647B)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Session audit trail active. Cryptographic activity logs stored in Rampur cluster node.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF33647B)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _deactivatedUserIds.contains(user.id) ? const Color(0xFF15803D) : RuralCareColors.critical,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              setState(() {
                if (_deactivatedUserIds.contains(user.id)) {
                  _deactivatedUserIds.remove(user.id);
                } else {
                  _deactivatedUserIds.add(user.id);
                }
              });
              Navigator.pop(ctx);
            },
            child: Text(_deactivatedUserIds.contains(user.id) ? 'Reactivate User' : 'Deactivate User'),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: RuralCareColors.textSecondary)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMr = _session.isMr;
    final isHi = _session.isHi;

    return ListenableBuilder(
      listenable: Listenable.merge([_docRepo, _facRepo, _patientRepo, _session]),
      builder: (context, _) {
        // Collect unified user list from real repositories
        final unifiedUsers = <_UnifiedAdminUser>[];

        // 1. Patients from PatientRepository
        for (final p in _patientRepo.patients) {
          unifiedUsers.add(
            _UnifiedAdminUser(
              id: p.ruralCareId.isNotEmpty ? p.ruralCareId : 'RC-PT-${p.id}',
              name: p.fullName,
              roleDisplay: isMr ? 'नागरिक / रुग्ण' : (isHi ? 'नागरिक / मरीज' : 'Patient / Citizen'),
              roleType: 'PATIENT',
              facilityName: p.subCentre.isNotEmpty ? p.subCentre : 'Kashti Sub-Centre',
              contact: p.phoneNumber,
              status: _deactivatedUserIds.contains(p.ruralCareId) ? 'Deactivated' : 'Active',
              badgeColor: const Color(0xFF2563EB),
            ),
          );
        }

        // 2. Health Workers (Assigned ASHAs from patient profiles or default CHOs)
        unifiedUsers.add(
          _UnifiedAdminUser(
            id: 'ASHA-KSH-102',
            name: 'Sunita Gaikwad',
            roleDisplay: isMr ? 'आशा कार्यकर्ती' : (isHi ? 'आशा कार्यकर्ता' : 'ASHA Worker'),
            roleType: 'HEALTH_WORKER',
            facilityName: 'Kashti Sub-Centre',
            contact: '+91 98220 11223',
            status: _deactivatedUserIds.contains('ASHA-KSH-102') ? 'Deactivated' : 'Active',
            badgeColor: const Color(0xFF7C3AED),
          ),
        );
        unifiedUsers.add(
          _UnifiedAdminUser(
            id: 'CHO-RMP-204',
            name: 'Dr. Anand Deshmukh',
            roleDisplay: isMr ? 'समुदाय आरोग्य अधिकारी (CHO)' : (isHi ? 'सामुदायिक स्वास्थ्य अधिकारी' : 'Community Health Officer'),
            roleType: 'HEALTH_WORKER',
            facilityName: 'Rampur Sub-Centre',
            contact: '+91 98220 44556',
            status: _deactivatedUserIds.contains('CHO-RMP-204') ? 'Deactivated' : 'Active',
            badgeColor: const Color(0xFF7C3AED),
          ),
        );

        // 3. Doctors from DoctorRepository
        for (final doc in _docRepo.registeredDoctors) {
          unifiedUsers.add(
            _UnifiedAdminUser(
              id: doc.doctorId,
              name: doc.name,
              roleDisplay: '${doc.specialty} (MD/MBBS)',
              roleType: 'DOCTOR',
              facilityName: doc.facilityName,
              contact: doc.mobile,
              status: _deactivatedUserIds.contains(doc.doctorId) ? 'Deactivated' : 'Active',
              badgeColor: const Color(0xFF005140),
            ),
          );
        }

        // 4. Facility Staff & Admins from FacilityRepository
        for (final staff in _facRepo.staffRoster) {
          unifiedUsers.add(
            _UnifiedAdminUser(
              id: staff.id,
              name: staff.name,
              roleDisplay: staff.designation,
              roleType: 'FACILITY_STAFF',
              facilityName: 'Baramati Sub-District Hospital',
              contact: '+91 2112 224003',
              status: _deactivatedUserIds.contains(staff.id) ? 'Deactivated' : staff.onDutyStatus,
              badgeColor: const Color(0xFFD97706),
            ),
          );
        }

        // Pending doctors and facility admin review
        final pendingRequests = _docRepo.verificationRequests
            .where((r) => r.status == DoctorVerificationStatus.pending)
            .toList();
        final pendingAdminRequests = _facRepo.getPendingFacilityAdminRequests();
        final totalPendingCount = pendingRequests.length + pendingAdminRequests.length;

        // Filtering
        final filteredUsers = unifiedUsers.where((u) {
          // Tab role filter
          if (_selectedRoleTab == 1 && u.roleType != 'PATIENT') return false;
          if (_selectedRoleTab == 2 && u.roleType != 'HEALTH_WORKER') return false;
          if (_selectedRoleTab == 3 && u.roleType != 'DOCTOR') return false;
          if (_selectedRoleTab == 4 && u.roleType != 'FACILITY_STAFF') return false;

          // Search query
          if (_searchQuery.isNotEmpty) {
            final q = _searchQuery.toLowerCase();
            final match = u.name.toLowerCase().contains(q) ||
                u.id.toLowerCase().contains(q) ||
                u.contact.toLowerCase().contains(q) ||
                u.facilityName.toLowerCase().contains(q);
            if (!match) return false;
          }

          // Facility filter
          if (_selectedFacilityFilter != 'ALL') {
            if (!u.facilityName.toLowerCase().contains(_selectedFacilityFilter.toLowerCase())) {
              return false;
            }
          }

          // Status filter
          if (_selectedStatusFilter != 'ALL') {
            if (_selectedStatusFilter == 'ACTIVE' && u.status == 'Deactivated') return false;
            if (_selectedStatusFilter == 'DEACTIVATED' && u.status != 'Deactivated') return false;
          }

          return true;
        }).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header & Command Bar
              _buildHeader(unifiedUsers.length, isHi, isMr),
              const SizedBox(height: 16),

              // 2. Pending Verification Notification Banner
              if (totalPendingCount > 0) ...[
                _buildPendingBanner(totalPendingCount, isHi, isMr),
                const SizedBox(height: 16),
              ],

              // 3. 5-Tab Role Navigation Strip
              _buildRoleTabs(unifiedUsers, isHi, isMr),
              const SizedBox(height: 16),

              // 4. Search & Jurisdiction Filter Bar
              _buildFilterBar(isHi, isMr),
              const SizedBox(height: 16),

              // 5. User Directory Table / Card List
              _buildUserDirectory(filteredUsers, isHi, isMr),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(int totalCount, bool isHi, bool isMr) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isMr ? 'वापरकर्ते व अधिकार व्यवस्थापन' : (isHi ? 'उपयोगकर्ता एवं भूमिका प्रबंधन' : 'User & Role Management'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: RuralCareColors.textPrimary),
            ),
            const SizedBox(height: 2),
            Text(
              isMr
                  ? 'एकूण $totalCount नोंदणीकृत आरोग्य कर्मचारी व नागरिक'
                  : (isHi
                      ? 'कुल $totalCount पंजीकृत स्वास्थ्य कार्यकर्ता व नागरिक'
                      : '$totalCount credentialed health workforce & citizens active'),
              style: const TextStyle(fontSize: 12, color: RuralCareColors.textSecondary),
            ),
          ],
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF005140),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: _showInviteStaffModal,
          icon: const Icon(Icons.person_add_rounded, size: 16),
          label: Text(
            isMr ? '+ कर्मचारी नोंदवा' : (isHi ? '+ स्टाफ आमंत्रित करें' : '+ Invite Staff'),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildPendingBanner(int pendingCount, bool isHi, bool isMr) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDBA74)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.notification_important_rounded, color: Color(0xFFC05621), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMr
                      ? '$pendingCount नवीन डॉक्टर/कर्मचारी पडताळणी प्रलंबित आहेत'
                      : (isHi
                          ? '$pendingCount नए डॉक्टर/स्टाफ आवेदन सत्यापन हेतु लंबित हैं'
                          : '$pendingCount practitioner credential applications awaiting review'),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFC05621)),
                ),
                Text(
                  isMr ? 'सत्यापन पूर्ण करण्यासाठी समीक्षा करा' : (isHi ? 'सत्यापन पूर्ण करने हेतु समीक्षा करें' : 'Review council certificates and assign facility rights.'),
                  style: const TextStyle(fontSize: 11, color: Color(0xFF9A3412)),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC05621),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              setState(() => _selectedRoleTab = 3);
            },
            child: const Text('Review Now', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleTabs(List<_UnifiedAdminUser> allUsers, bool isHi, bool isMr) {
    final patientCount = allUsers.where((u) => u.roleType == 'PATIENT').length;
    final workerCount = allUsers.where((u) => u.roleType == 'HEALTH_WORKER').length;
    final doctorCount = allUsers.where((u) => u.roleType == 'DOCTOR').length;
    final staffCount = allUsers.where((u) => u.roleType == 'FACILITY_STAFF').length;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _roleTabItem(0, isMr ? 'सर्व डिरेक्टरी' : (isHi ? 'सभी निर्देशिका' : 'Total Directory'), allUsers.length),
          const SizedBox(width: 8),
          _roleTabItem(1, isMr ? 'नागरिक / रुग्ण' : (isHi ? 'नागरिक / मरीज' : 'Patients'), patientCount),
          const SizedBox(width: 8),
          _roleTabItem(2, isMr ? 'आशा व CHO' : (isHi ? 'आशा व CHO' : 'Health Workers'), workerCount),
          const SizedBox(width: 8),
          _roleTabItem(3, isMr ? 'डॉक्टर्स व तज्ज्ञ' : (isHi ? 'डॉक्टर्स व विशेषज्ञ' : 'Doctors & Specialists'), doctorCount),
          const SizedBox(width: 8),
          _roleTabItem(4, isMr ? 'रुग्णालय कर्मचारी' : (isHi ? 'अस्पताल स्टाफ' : 'Facility Staff'), staffCount),
        ],
      ),
    );
  }

  Widget _roleTabItem(int index, String title, int count) {
    final isSelected = _selectedRoleTab == index;
    return InkWell(
      onTap: () => setState(() => _selectedRoleTab = index),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF005140) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF005140) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : RuralCareColors.textPrimary,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withOpacity(0.25) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : RuralCareColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar(bool isHi, bool isMr) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 260,
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
              decoration: InputDecoration(
                isDense: true,
                hintText: isMr ? 'नाव, आयडी किंवा फोन शोधा...' : (isHi ? 'नाम, आईडी या फोन खोजें...' : 'Search name, ID, phone...'),
                hintStyle: const TextStyle(fontSize: 12),
                prefixIcon: const Icon(Icons.search_rounded, size: 18),
                contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          DropdownButton<String>(
            value: _selectedFacilityFilter,
            underline: const SizedBox(),
            style: const TextStyle(fontSize: 12, color: RuralCareColors.textPrimary),
            items: const [
              DropdownMenuItem(value: 'ALL', child: Text('All Facilities')),
              DropdownMenuItem(value: 'Baramati', child: Text('Baramati SDH')),
              DropdownMenuItem(value: 'Aundh', child: Text('Aundh District Hospital')),
              DropdownMenuItem(value: 'Kashti', child: Text('Kashti Sub-Centre')),
              DropdownMenuItem(value: 'Rampur', child: Text('Rampur Sub-Centre')),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _selectedFacilityFilter = val);
            },
          ),
          DropdownButton<String>(
            value: _selectedStatusFilter,
            underline: const SizedBox(),
            style: const TextStyle(fontSize: 12, color: RuralCareColors.textPrimary),
            items: const [
              DropdownMenuItem(value: 'ALL', child: Text('All Status')),
              DropdownMenuItem(value: 'ACTIVE', child: Text('Active Only')),
              DropdownMenuItem(value: 'DEACTIVATED', child: Text('Deactivated')),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _selectedStatusFilter = val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUserDirectory(List<_UnifiedAdminUser> users, bool isHi, bool isMr) {
    if (users.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Column(
          children: [
            Icon(Icons.search_off_rounded, size: 40, color: RuralCareColors.textSecondary),
            SizedBox(height: 8),
            Text('No users matching criteria', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            Text('Try changing your search query or role filter.', style: TextStyle(fontSize: 12, color: RuralCareColors.textSecondary)),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: users.length,
        separatorBuilder: (ctx, i) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
        itemBuilder: (ctx, i) {
          final user = users[i];
          final isDeactivated = user.status == 'Deactivated';

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: user.badgeColor.withOpacity(0.12),
              child: Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                style: TextStyle(color: user.badgeColor, fontWeight: FontWeight.bold),
              ),
            ),
            title: Row(
              children: [
                Text(
                  user.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    decoration: isDeactivated ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: user.badgeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    user.roleDisplay,
                    style: TextStyle(fontSize: 10, color: user.badgeColor, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  '${user.id} • ${user.facilityName} • ${user.contact}',
                  style: const TextStyle(fontSize: 11, color: RuralCareColors.textSecondary),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDeactivated ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    user.status,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isDeactivated ? RuralCareColors.critical : const Color(0xFF15803D),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.more_vert_rounded, size: 20, color: RuralCareColors.textSecondary),
                  onPressed: () => _showUserDetailsModal(user),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _UnifiedAdminUser {
  final String id;
  final String name;
  final String roleDisplay;
  final String roleType; // PATIENT, HEALTH_WORKER, DOCTOR, FACILITY_STAFF
  final String facilityName;
  final String contact;
  final String status;
  final Color badgeColor;

  const _UnifiedAdminUser({
    required this.id,
    required this.name,
    required this.roleDisplay,
    required this.roleType,
    required this.facilityName,
    required this.contact,
    required this.status,
    required this.badgeColor,
  });
}
