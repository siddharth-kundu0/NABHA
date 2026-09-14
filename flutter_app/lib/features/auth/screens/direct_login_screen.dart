import 'package:flutter/material.dart';
import 'package:ruralcare/app/routes.dart';
import 'package:ruralcare/core/theme/app_theme.dart';
import 'package:ruralcare/data/models/facility_dto.dart';
import 'package:ruralcare/data/repositories/doctor_repository.dart';
import 'package:ruralcare/data/repositories/facility_repository.dart';
import 'package:ruralcare/data/repositories/patient_repository.dart';
import 'package:ruralcare/features/auth/screens/facility_approval_waiting_screen.dart';
import 'package:ruralcare/core/services/firebase_auth_service.dart';

class DirectLoginScreen extends StatefulWidget {
  final VoidCallback? onLoginSuccess;

  const DirectLoginScreen({super.key, this.onLoginSuccess});

  @override
  State<DirectLoginScreen> createState() => _DirectLoginScreenState();
}

class _DirectLoginScreenState extends State<DirectLoginScreen> {
  AppRole _selectedRole = AppRole.patient;
  final TextEditingController _identifierCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  String? _selectedFacilityId;
  FacilityStaffRole _selectedFacilityRole = FacilityStaffRole.pharmacist;

  @override
  void dispose() {
    _identifierCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _onRoleChanged(AppRole role) {
    setState(() {
      _selectedRole = role;
      _errorMessage = null;
      _identifierCtrl.clear();
      _passwordCtrl.clear();
    });
  }

  void _handleLogin() async {
    final identifier = _identifierCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    final session = SessionCoordinator();
    final isHi = session.isHindi;
    final isMr = session.isMarathi;

    if (identifier.isEmpty) {
      setState(() => _errorMessage = isHi
          ? 'कृपया अपनी आईडी या मोबाइल नंबर दर्ज करें।'
          : (isMr ? 'कृपया आपला आयडी किंवा मोबाइल क्रमांक प्रविष्ट करा.' : 'Please enter your ID or mobile number.'));
      return;
    }

    if (_selectedRole == AppRole.patient) {
      final isDigitsOnly = RegExp(r'^[0-9]+$').hasMatch(identifier);
      if (isDigitsOnly && identifier.length != 10) {
        setState(() => _errorMessage = isHi
            ? 'अमान्य प्रविष्टि: मोबाइल नंबर ठीक 10 अंकों का होना चाहिए।'
            : (isMr ? 'अवैध नोंद: मोबाइल क्रमांक नेमका १० अंकांचा असणे आवश्यक आहे.' : 'Invalid entry: Mobile number must be exactly 10 digits.'));
        return;
      }
    }

    if (password.isEmpty) {
      setState(() => _errorMessage = isHi
          ? 'कृपया अपना पासवर्ड या ओटीपी दर्ज करें।'
          : (isMr ? 'कृपया आपला पासवर्ड किंवा ओटीपी प्रविष्ट करा.' : 'Please enter your password or OTP.'));
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    await Future.delayed(const Duration(milliseconds: 600));

    // Authenticate with Firebase Authentication
    var authResult = await FirebaseAuthService().signInWithIdentifierAndPassword(
      identifier: identifier,
      password: password,
      expectedRole: _selectedRole,
    );

    if (!mounted) return;

    if (_selectedRole == AppRole.patient) {
      final patient = PatientRepository().getOrCreatePatientForIdentifier(identifier);
      if (patient == null && !authResult.isSuccess) {
         setState(() {
           _isLoading = false;
           _errorMessage = 'Patient not found. Please register first.';
         });
         return;
      }
      session.setAuthenticatedUser(
        uid: authResult.user?.uid ?? patient?.id ?? identifier,
        email: authResult.user?.email ?? '$identifier@ruralcare.nabha.gov.in',
        role: AppRole.patient,
        displayName: patient?.fullName ?? authResult.user?.displayName ?? 'Registered Beneficiary',
      );
    } else if (_selectedRole == AppRole.doctor) {
      final docRepo = DoctorRepository();
      var doc = docRepo.directLogin(
        identifier: identifier,
        password: password,
      );
      if (doc == null && authResult.isSuccess) {
        final user = authResult.user;
        final docName = user?.displayName ?? 'Dr. $identifier';
        doc = RegisteredDoctorAccount(
          doctorId: user?.uid ?? 'DOC-$identifier',
          name: docName,
          mobile: identifier,
          password: password,
          qualification: 'MBBS, MD',
          specialty: 'General Medicine',
          registrationNumber: 'MCI-REG-VERIFIED',
          facilityId: 'FAC-SDH-301',
          facilityName: 'Baramati Sub-District Hospital',
        );
        docRepo.setActiveDoctor(doc);
      }
      if (doc == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = authResult.errorMessage ?? (isHi
              ? 'डॉक्टर क्रेडेंशियल अमान्य हैं। कृपया डॉक्टर आईडी या मोबाइल का उपयोग करें।'
              : (isMr ? 'डॉक्टर क्रेडेन्शियल्स अवैध आहेत. डॉक्टर आयडी किंवा मोबाइल वापरा.' : 'Doctor credentials invalid. Use Doctor ID or Mobile.'));
        });
        return;
      }
      session.setAuthenticatedUser(
        uid: doc.doctorId,
        email: doc.mobile.contains('@') ? doc.mobile : '${doc.mobile}@ruralcare.nabha.gov.in',
        role: AppRole.doctor,
        displayName: doc.name,
        catchment: doc.facilityName,
        facilityId: doc.facilityId,
      );
    } else if (_selectedRole == AppRole.healthWorker) {
      final user = authResult.user;
      final workerName = user?.displayName?.isNotEmpty == true ? user!.displayName! : 'ASHA Worker ($identifier)';
      session.setAuthenticatedUser(
        uid: user?.uid ?? 'HW-$identifier',
        email: user?.email ?? '$identifier@ruralcare.nabha.gov.in',
        role: AppRole.healthWorker,
        displayName: workerName,
        catchment: 'Kashti Sub-Centre',
        facilityId: 'FAC-SC-101',
      );
    } else if (_selectedRole == AppRole.admin) {
      final user = authResult.user;
      session.setAuthenticatedUser(
        uid: user?.uid ?? 'ADMIN-$identifier',
        email: user?.email ?? '$identifier@ruralcare.nabha.gov.in',
        role: AppRole.admin,
        displayName: user?.displayName ?? 'District Administrator ($identifier)',
        catchment: 'Pune Rural District Administration',
      );
    } else if (!authResult.isSuccess) {
      setState(() {
        _isLoading = false;
        _errorMessage = authResult.errorMessage;
      });
      return;
    }

    if (_selectedRole == AppRole.facilityStaff) {
      final facRepo = FacilityRepository();
      final targetFacId = _selectedFacilityId ?? facRepo.currentFacility.id;
      final existing = facRepo.findStaffByMobileOrId(
        mobileOrId: identifier,
        facilityId: targetFacId,
        role: _selectedFacilityRole,
      );

      if (existing != null) {
        if (existing.status == FacilityApprovalStatus.approved) {
          facRepo.setCurrentStaffSession(existing);
        } else {
          setState(() => _isLoading = false);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => FacilityApprovalWaitingScreen(request: existing),
            ),
          );
          return;
        }
      } else {
        // Auto-generate request for approval
        final reqId = 'REQ-FAC-${DateTime.now().millisecondsSinceEpoch % 90000 + 10000}';
        final facility = facRepo.getFacilityById(targetFacId) ?? facRepo.currentFacility;
        final isFacilityAdmin = _selectedFacilityRole == FacilityStaffRole.facilityAdmin;

        final newReq = FacilityStaffRequestDto(
          id: reqId,
          facilityId: facility.id,
          facilityName: facility.name,
          staffName: identifier.length == 10 ? 'Staff ($identifier)' : identifier,
          mobile: identifier.length == 10 ? identifier : '9876543210',
          role: _selectedFacilityRole,
          licenseOrEmployeeId: identifier,
          department: _selectedFacilityRole.defaultDepartment,
          status: isFacilityAdmin
              ? FacilityApprovalStatus.pendingDistrictAdmin
              : FacilityApprovalStatus.pendingFacilityAdmin,
          submittedAt: DateTime.now(),
        );

        if (isFacilityAdmin) {
          facRepo.submitFacilityAdminRequest(newReq);
        } else {
          facRepo.submitStaffRequest(newReq);
        }

        setState(() => _isLoading = false);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => FacilityApprovalWaitingScreen(request: newReq),
          ),
        );
        return;
      }
    }

    session.switchRole(_selectedRole);
    session.completeOnboarding();

    setState(() => _isLoading = false);

    if (widget.onLoginSuccess != null) {
      widget.onLoginSuccess!();
    } else {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionCoordinator();

    return Scaffold(
      backgroundColor: RuralCareColors.canvas,
      appBar: AppBar(
        backgroundColor: RuralCareColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: RuralCareColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          session.isHindi ? 'सीधा प्रवेश / लॉगिन' : (session.isMarathi ? 'थेट लॉगिन' : 'Direct Sign In'),
          style: AppTypography.cardTitle,
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5F2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF0A6B56).withOpacity(0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _langBtn('en', 'EN', session.isEnglish, session),
                _langBtn('hi', 'हि', session.isHindi, session),
                _langBtn('mr', 'म', session.isMarathi, session),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Brand Badge
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A6B56).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.lock_person_outlined, color: Color(0xFF0A6B56), size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.isHindi ? 'खाता लॉगिन' : (session.isMarathi ? 'खाते लॉगिन' : 'Account Sign In'),
                          style: AppTypography.sectionTitle,
                        ),
                        Text(
                          session.isHindi
                              ? 'सत्यापित साखळीत थेट प्रवेश करा'
                              : (session.isMarathi ? 'नोंदणीकृत खात्यात थेट प्रवेश' : 'Existing registered users bypass onboarding'),
                          style: AppTypography.supporting,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Role Selector Tabs
              Text(
                session.isHindi ? 'अपनी भूमिका चुनें' : (session.isMarathi ? 'आपली भूमिका निवडा' : 'Select your profile role'),
                style: AppTypography.cardTitle,
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _roleChip(AppRole.patient, session.isHindi ? 'नागरिक / मरीज़' : (session.isMarathi ? 'नागरिक / रुग्ण' : 'Patient / Citizen'), Icons.person_outline),
                    const SizedBox(width: 8),
                    _roleChip(AppRole.doctor, session.isHindi ? 'डॉक्टर' : (session.isMarathi ? 'डॉक्टर' : 'Doctor'), Icons.medical_services_outlined),
                    const SizedBox(width: 8),
                    _roleChip(AppRole.healthWorker, session.isHindi ? 'आशा / कार्यकर्ता' : (session.isMarathi ? 'आशा / सेविका' : 'ASHA / Health Worker'), Icons.volunteer_activism_outlined),
                    const SizedBox(width: 8),
                    _roleChip(AppRole.facilityStaff, session.isHindi ? 'अस्पताल' : (session.isMarathi ? 'रुग्णालय' : 'Facility Staff'), Icons.local_hospital_outlined),
                    const SizedBox(width: 8),
                    _roleChip(AppRole.admin, session.isHindi ? 'जिला प्रशासन' : (session.isMarathi ? 'जिल्हा प्रशासन' : 'District Admin'), Icons.admin_panel_settings_outlined),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Form Container
              Container(
                decoration: AppDecorations.card(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRoleHint(session),
                    if (_selectedRole == AppRole.facilityStaff) ...[
                      const SizedBox(height: 16),
                      Text(session.isHindi ? 'संबद्ध स्वास्थ्य केंद्र' : 'Affiliated Healthcare Facility', style: AppTypography.supporting),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: _selectedFacilityId ?? FacilityRepository().facilities.first.id,
                        isExpanded: true,
                        items: FacilityRepository().facilities.map((fac) {
                          return DropdownMenuItem<String>(
                            value: fac.id,
                            child: Text(
                              '${fac.name} (${fac.typeDisplay})',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedFacilityId = val),
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.apartment_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(session.isHindi ? 'आपकी अधिकृत भूमिका' : 'Your Operational Role', style: AppTypography.supporting),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<FacilityStaffRole>(
                        value: _selectedFacilityRole,
                        isExpanded: true,
                        items: FacilityStaffRole.values.map((r) {
                          return DropdownMenuItem<FacilityStaffRole>(
                            value: r,
                            child: Text(
                              r.displayName,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedFacilityRole = val);
                        },
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Text(_getIdentifierLabel(session), style: AppTypography.supporting),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _identifierCtrl,
                      decoration: InputDecoration(
                        prefixIcon: Icon(_getIdentifierIcon(), color: RuralCareColors.textSecondary),
                        hintText: _getIdentifierHint(session),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(_getPasswordLabel(session), style: AppTypography.supporting),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _passwordCtrl,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.password_rounded, color: RuralCareColors.textSecondary),
                        hintText: session.isHindi
                            ? 'पासवर्ड या 6-अंकीय कोड दर्ज करें'
                            : (session.isMarathi ? 'पासवर्ड किंवा ६-अंकी कोड प्रविष्ट करा' : 'Enter password or 6-digit code'),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.error_outline, color: RuralCareColors.critical, size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: AppTypography.supporting.copyWith(color: RuralCareColors.critical),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Sign In Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A6B56),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          session.isHindi ? 'प्रवेश करें (लॉगिन)' : (session.isMarathi ? 'प्रवेश करा' : 'Sign In to Profile'),
                          style: AppTypography.button,
                        ),
                ),
              ),

              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    session.isHindi
                        ? 'नया उपयोगकर्ता? पंजीकरण करें'
                        : (session.isMarathi ? 'नवीन खाते? ऑनबोर्डिंग सुरू करा' : 'New user? Start registration onboarding'),
                    style: AppTypography.supporting.copyWith(
                      color: const Color(0xFF0A6B56),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _langBtn(String code, String label, bool isSelected, SessionCoordinator session) {
    return InkWell(
      onTap: () => session.switchLanguage(code),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0A6B56) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : const Color(0xFF0A6B56),
          ),
        ),
      ),
    );
  }

  Widget _roleChip(AppRole role, String label, IconData icon) {
    final isSelected = _selectedRole == role;
    return InkWell(
      onTap: () => _onRoleChanged(role),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0A6B56) : RuralCareColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF0A6B56) : RuralCareColors.border,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? Colors.white : RuralCareColors.textPrimary, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.supporting.copyWith(
                color: isSelected ? Colors.white : RuralCareColors.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleHint(SessionCoordinator session) {
    final isHi = session.isHindi;
    final isMr = session.isMarathi;
    String text;
    switch (_selectedRole) {
      case AppRole.patient:
        text = isHi
            ? 'पंजीकृत मरीज़ मोबाइल नंबर और ओटीपी या पिन से लॉगिन कर सकते हैं।'
            : (isMr
                ? 'नोंदणीकृत रुग्ण मोबाइल क्रमांक आणि ओटीपी किंवा पिनद्वारे लॉगिन करू शकतात.'
                : 'Registered patients can sign in via mobile number & OTP or saved PIN.');
        break;
      case AppRole.doctor:
        text = isHi
            ? 'सत्यापित डॉक्टर अपनी डॉक्टर आईडी (उदा. DOC-MH-8421-101) एवं पासवर्ड से प्रवेश करें।'
            : (isMr
                ? 'सत्यापित वैद्यकीय अधिकारी डॉक्टर आयडी (उदा. DOC-MH-8421-101) व पासवर्ड वापरून प्रवेश करा.'
                : 'Verified medical officers sign in using Unique Doctor ID (e.g. DOC-MH-8421-101) & password.');
        break;
      case AppRole.healthWorker:
        text = isHi
            ? 'आशा / सीएचओ कार्यकर्ता अपनी आईडी या पंजीकृत मोबाइल से लॉगिन करें।'
            : (isMr
                ? 'आशा / सीएचओ सेविका आपल्या आयडी किंवा नोंदणीकृत मोबाइलने लॉगिन करा.'
                : 'ASHA/CHO workers sign in with worker ID or registered mobile.');
        break;
      case AppRole.facilityStaff:
        text = isHi
            ? 'अस्पताल कर्मी अपने एचएफआर कोड (उदा. FAC-SC-102) व पासवर्ड से प्रवेश करें।'
            : (isMr
                ? 'रुग्णालय कर्मचारी एचएफआर कोड (उदा. FAC-SC-102) व पासवर्डने लॉगिन करा.'
                : 'Facility personnel sign in with Facility HFR Code (e.g. FAC-SC-102) & access key.');
        break;
      case AppRole.admin:
        text = isHi
            ? 'प्रशासनिक अधिकारी जिला सिस्टम आईडी व पासकी से लॉगिन करें।'
            : (isMr
                ? 'प्रशासकीय अधिकारी जिल्हा सिस्टीम आयडी व पासकीने लॉगिन करा.'
                : 'Administrative personnel sign in with District System ID & passkey.');
        break;
    }
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5F2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF0A6B56), size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: AppTypography.supporting.copyWith(fontSize: 12))),
        ],
      ),
    );
  }

  String _getIdentifierLabel(SessionCoordinator session) {
    final isHi = session.isHindi;
    final isMr = session.isMarathi;
    switch (_selectedRole) {
      case AppRole.doctor:
        return isHi ? 'डॉक्टर आईडी या पंजीकृत मोबाइल' : (isMr ? 'डॉक्टर आयडी किंवा नोंदणीकृत मोबाइल' : 'Doctor ID or Registered Mobile');
      case AppRole.facilityStaff:
        return isHi ? 'अस्पताल कोड (HFR ID)' : (isMr ? 'रुग्णालय कोड (HFR ID)' : 'Facility Code (HFR ID)');
      case AppRole.healthWorker:
        return isHi ? 'आशा / कार्यकर्ता आईडी या मोबाइल' : (isMr ? 'आशा / सेविका आयडी किंवा मोबाइल' : 'ASHA / Worker ID or Mobile');
      default:
        return isHi ? 'मोबाइल नंबर' : (isMr ? 'मोबाइल क्रमांक' : 'Mobile Number');
    }
  }

  String _getIdentifierHint(SessionCoordinator session) {
    final isHi = session.isHindi;
    final isMr = session.isMarathi;
    switch (_selectedRole) {
      case AppRole.doctor:
        return 'e.g. DOC-MH-8421-101 or 9822014490';
      case AppRole.facilityStaff:
        return 'e.g. FAC-SC-102 or FAC-PHC-201';
      case AppRole.healthWorker:
        return 'e.g. ASHA-MH-401';
      default:
        return isHi ? '10-अंकीय मोबाइल नंबर' : (isMr ? '१०-अंकी मोबाइल क्रमांक' : '10-digit mobile number');
    }
  }

  IconData _getIdentifierIcon() {
    switch (_selectedRole) {
      case AppRole.doctor:
        return Icons.badge_outlined;
      case AppRole.facilityStaff:
        return Icons.apartment_outlined;
      case AppRole.healthWorker:
        return Icons.perm_identity_outlined;
      default:
        return Icons.phone_android_outlined;
    }
  }

  String _getPasswordLabel(SessionCoordinator session) {
    final isHi = session.isHindi;
    final isMr = session.isMarathi;
    switch (_selectedRole) {
      case AppRole.patient:
        return isHi ? '6-अंकीय ओटीपी / पिन' : (isMr ? '६-अंकी ओटीपी / पिन' : '6-Digit OTP / PIN');
      default:
        return isHi ? 'पासवर्ड / एक्सेस की' : (isMr ? 'पासवर्ड / प्रवेश की' : 'Password / Access Key');
    }
  }
}
