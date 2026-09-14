import 'package:flutter/material.dart';
import 'package:ruralcare/app/routes.dart';
import 'package:ruralcare/core/theme/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ruralcare/core/services/firebase_auth_service.dart';
import 'package:ruralcare/data/models/doctor_verification_request_dto.dart';
import 'package:ruralcare/data/models/facility_dto.dart';
import 'package:ruralcare/data/repositories/doctor_repository.dart';
import 'package:ruralcare/data/repositories/facility_repository.dart';

class DoctorRegistrationFlowScreen extends StatefulWidget {
  final VoidCallback? onComplete;

  const DoctorRegistrationFlowScreen({super.key, this.onComplete});

  @override
  State<DoctorRegistrationFlowScreen> createState() => _DoctorRegistrationFlowScreenState();
}

class _DoctorRegistrationFlowScreenState extends State<DoctorRegistrationFlowScreen> {
  int _step = 0; // 0: Form Details, 1: Select Facility, 2: Pending/Status, 3: OTP, 4: Set Password & ID Card

  // Form Controllers: Zero pre-filled mock data
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _mobileCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _regNoCtrl = TextEditingController();
  final TextEditingController _councilCtrl = TextEditingController();
  final TextEditingController _qualificationCtrl = TextEditingController();
  String _selectedSpecialty = 'General Medicine';

  FacilityDto? _selectedFacility;
  DoctorVerificationRequestDto? _activeRequest;

  // OTP & Password
  final TextEditingController _otpCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  final TextEditingController _confirmPasswordCtrl = TextEditingController();
  bool _obscurePassword = true;
  String? _errorMessage;

  final List<String> _specialties = [
    'General Medicine',
    'Pediatrics',
    'Obstetrics & Gynaecology',
    'General Surgery',
    'Chest & Pulmonary',
    'Cardiology',
    'Community Health',
  ];

  @override
  void initState() {
    super.initState();
    final facilities = FacilityRepository().facilities;
    if (facilities.isNotEmpty) {
      _selectedFacility = facilities.first;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _mobileCtrl.dispose();
    _emailCtrl.dispose();
    _regNoCtrl.dispose();
    _councilCtrl.dispose();
    _qualificationCtrl.dispose();
    _otpCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  void _submitRequest() {
    if (_nameCtrl.text.trim().isEmpty ||
        _mobileCtrl.text.trim().isEmpty ||
        _regNoCtrl.text.trim().isEmpty ||
        _selectedFacility == null) {
      setState(() => _errorMessage = 'Please complete all required fields.');
      return;
    }

    final req = DoctorRepository().submitVerificationRequest(
      doctorName: _nameCtrl.text.trim(),
      doctorMobile: _mobileCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      qualification: _qualificationCtrl.text.trim(),
      registrationNumber: _regNoCtrl.text.trim(),
      medicalCouncil: _councilCtrl.text.trim(),
      specialty: _selectedSpecialty,
      targetFacilityId: _selectedFacility!.id,
      targetFacilityName: _selectedFacility!.name,
    );

    setState(() {
      _activeRequest = req;
      _step = 2; // Jump to Verification Pending Screen
      _errorMessage = null;
    });
  }

  void _checkStatus() {
    if (_activeRequest == null) return;
    final all = DoctorRepository().verificationRequests;
    final updated = all.firstWhere(
      (r) => r.id == _activeRequest!.id,
      orElse: () => _activeRequest!,
    );

    setState(() {
      _activeRequest = updated;
      if (updated.status == DoctorVerificationStatus.accepted) {
        _otpCtrl.text = updated.tempOtp ?? '849201';
        _step = 3; // Jump to OTP screen
      }
    });

    if (updated.status == DoctorVerificationStatus.pending) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Request is still pending review with ${_activeRequest!.targetFacilityName}.'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _simulateFacilityAcceptance() {
    if (_activeRequest == null) return;
    final accepted = DoctorRepository().acceptVerificationRequest(
      _activeRequest!.id,
      reviewedBy: 'Sister Sarita Patil, RN (Admin)',
    );
    if (accepted != null) {
      setState(() {
        _activeRequest = accepted;
        _otpCtrl.text = accepted.tempOtp ?? '849201';
        _step = 3; // OTP verification
      });
    }
  }

  void _verifyOtp() {
    final otp = _otpCtrl.text.trim();
    if (otp.isEmpty || otp.length < 4) {
      setState(() => _errorMessage = 'Please enter the 6-digit OTP.');
      return;
    }

    final ok = DoctorRepository().verifyOtp(_activeRequest!.id, otp);
    if (!ok) {
      setState(() => _errorMessage = 'Invalid OTP code. Please re-enter.');
      return;
    }

    setState(() {
      _errorMessage = null;
      _step = 4; // Set password and view Doctor ID card
    });
  }

  void _finalizeAndLogin() async {
    final pass = _passwordCtrl.text.trim();
    final confirm = _confirmPasswordCtrl.text.trim();

    if (pass.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters.');
      return;
    }
    if (pass != confirm) {
      setState(() => _errorMessage = 'Passwords do not match.');
      return;
    }

    final req = _activeRequest;
    if (req == null) return;

    final docAccount = DoctorRepository().finalizeRegistration(
      requestId: req.id,
      password: pass,
    );

    // Register user in Firebase Authentication & Firestore
    final mobile = req.doctorMobile;
    final email = req.email.isNotEmpty ? req.email : '$mobile@ruralcare.nabha.gov.in';
    await FirebaseAuthService().registerUser(
      identifier: mobile,
      password: pass,
      role: AppRole.doctor,
      profileData: {
        'doctorId': docAccount.doctorId,
        'fullName': docAccount.name,
        'name': docAccount.name,
        'phoneNumber': docAccount.mobile,
        'email': email,
        'role': 'doctor',
        'specialty': docAccount.specialty,
        'qualification': docAccount.qualification,
        'registrationNumber': docAccount.registrationNumber,
        'medicalCouncil': req.medicalCouncil,
        'facilityId': docAccount.facilityId,
        'facilityName': docAccount.facilityName,
      },
    );

    // Persist directly to Firestore 'doctors' collection
    try {
      await FirebaseFirestore.instance.collection('doctors').doc(docAccount.doctorId).set({
        'doctorId': docAccount.doctorId,
        'fullName': docAccount.name,
        'name': docAccount.name,
        'phoneNumber': docAccount.mobile,
        'email': email,
        'role': 'doctor',
        'specialty': docAccount.specialty,
        'qualification': docAccount.qualification,
        'registrationNumber': docAccount.registrationNumber,
        'medicalCouncil': req.medicalCouncil,
        'facilityId': docAccount.facilityId,
        'facilityName': docAccount.facilityName,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Notice persisting doctor: $e');
    }

    final session = SessionCoordinator();
    session.setAuthenticatedUser(
      uid: docAccount.doctorId,
      email: email,
      role: AppRole.doctor,
      displayName: docAccount.name,
      catchment: docAccount.facilityName,
      facilityId: docAccount.facilityId,
    );
    session.switchRole(AppRole.doctor);
    session.completeOnboarding();

    if (!mounted) return;
    if (widget.onComplete != null) {
      widget.onComplete!();
    } else {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RuralCareColors.canvas,
      appBar: AppBar(
        backgroundColor: RuralCareColors.surface,
        elevation: 0,
        leading: _step > 0 && _step < 4
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: RuralCareColors.textPrimary),
                onPressed: () => setState(() => _step--),
              )
            : IconButton(
                icon: const Icon(Icons.close, color: RuralCareColors.textPrimary),
                onPressed: () => Navigator.of(context).pop(),
              ),
        title: Text(_getStepTitle(), style: AppTypography.cardTitle),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: LinearProgressIndicator(
            value: (_step + 1) / 5,
            backgroundColor: RuralCareColors.border,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0A6B56)),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: _buildCurrentStep(),
        ),
      ),
    );
  }

  String _getStepTitle() {
    switch (_step) {
      case 0:
        return 'Doctor Credentials (Step 1/5)';
      case 1:
        return 'Select Facility (Step 2/5)';
      case 2:
        return 'Verification Pending (Step 3/5)';
      case 3:
        return 'OTP Authentication (Step 4/5)';
      case 4:
        return 'Set Password & ID Card (Step 5/5)';
      default:
        return 'Doctor Registration';
    }
  }

  Widget _buildCurrentStep() {
    switch (_step) {
      case 0:
        return _step0Credentials();
      case 1:
        return _step1FacilitySelection();
      case 2:
        return _step2VerificationPending();
      case 3:
        return _step3OtpVerification();
      case 4:
        return _step4PasswordAndIdCard();
      default:
        return const SizedBox.shrink();
    }
  }

  // Step 0: Doctor Details
  Widget _step0Credentials() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF0A6B56).withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.badge_outlined, color: Color(0xFF0A6B56), size: 24),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Medical Practitioner Details', style: AppTypography.sectionTitle),
                  Text('State Council registered doctors only', style: AppTypography.supporting),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          decoration: AppDecorations.card(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Full Name (with Title)', style: AppTypography.supporting),
              const SizedBox(height: 6),
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.person_outline),
                  hintText: 'e.g. Dr. Rajesh Sharma',
                ),
              ),
              const SizedBox(height: 16),
              const Text('Mobile Number (for OTP & Login)', style: AppTypography.supporting),
              const SizedBox(height: 6),
              TextField(
                controller: _mobileCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.phone_android_outlined),
                  hintText: '10-digit mobile number',
                ),
              ),
              const SizedBox(height: 16),
              const Text('Official Email Address', style: AppTypography.supporting),
              const SizedBox(height: 6),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.email_outlined),
                  hintText: 'e.g. doctor@health.gov.in',
                ),
              ),
              const SizedBox(height: 16),
              const Text('Medical Council Registration No.', style: AppTypography.supporting),
              const SizedBox(height: 6),
              TextField(
                controller: _regNoCtrl,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.verified_outlined),
                  hintText: 'e.g. MMC/2019/06/6120',
                ),
              ),
              const SizedBox(height: 16),
              const Text('Primary Clinical Specialty', style: AppTypography.supporting),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _selectedSpecialty,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.medical_services_outlined),
                ),
                items: _specialties
                    .map((s) => DropdownMenuItem(value: s, child: Text(s, style: AppTypography.body)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedSpecialty = val);
                },
              ),
              const SizedBox(height: 16),
              const Text('Degrees & Qualification', style: AppTypography.supporting),
              const SizedBox(height: 6),
              TextField(
                controller: _qualificationCtrl,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.school_outlined),
                  hintText: 'e.g. MBBS, DCH, MD',
                ),
              ),
            ],
          ),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(_errorMessage!, style: AppTypography.supporting.copyWith(color: RuralCareColors.critical)),
        ],
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () => setState(() => _step = 1),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A6B56),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Proceed to Select Facility', style: AppTypography.button),
          ),
        ),
      ],
    );
  }

  // Step 1: Select Facility
  Widget _step1FacilitySelection() {
    final facilities = FacilityRepository().facilities;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select Working Facility', style: AppTypography.sectionTitle),
        const SizedBox(height: 6),
        const Text(
          'Choose the primary hospital or PHC where your clinical affiliation request will be verified.',
          style: AppTypography.supporting,
        ),
        const SizedBox(height: 20),
        ...facilities.map((fac) {
          final isSelected = _selectedFacility?.id == fac.id;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: AppDecorations.card(
              borderColor: isSelected ? const Color(0xFF0A6B56) : RuralCareColors.border,
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFE8F5F2) : RuralCareColors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.local_hospital_outlined,
                  color: isSelected ? const Color(0xFF0A6B56) : RuralCareColors.textSecondary,
                ),
              ),
              title: Text(fac.name, style: AppTypography.cardTitle),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text('${fac.typeLabel} • ${fac.address}', style: AppTypography.supporting),
                  Text('Available beds: ${fac.availableBeds}/${fac.totalBeds}',
                      style: AppTypography.supporting.copyWith(fontSize: 12)),
                ],
              ),
              trailing: Radio<FacilityDto>(
                value: fac,
                groupValue: _selectedFacility,
                activeColor: const Color(0xFF0A6B56),
                onChanged: (val) => setState(() => _selectedFacility = val),
              ),
              onTap: () => setState(() => _selectedFacility = fac),
            ),
          );
        }),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _submitRequest,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A6B56),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Submit Affiliation Request', style: AppTypography.button),
          ),
        ),
      ],
    );
  }

  // Step 2: Verification Pending Screen
  Widget _step2VerificationPending() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 16),
        // Pulse Status Circle
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3CD),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFCA8A04), width: 2),
          ),
          child: const Icon(Icons.hourglass_top_rounded, color: Color(0xFFCA8A04), size: 40),
        ),
        const SizedBox(height: 20),
        const Text(
          'Verification Request Dispatched',
          style: AppTypography.sectionTitle,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Your affiliation request has been routed to the administration desk of ${_activeRequest?.targetFacilityName}.',
          style: AppTypography.body,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),

        // Summary Card
        Container(
          decoration: AppDecorations.card(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Request ID', style: AppTypography.supporting),
                  Text(_activeRequest?.id ?? '', style: AppTypography.cardTitle),
                ],
              ),
              const Divider(color: RuralCareColors.border, height: 20),
              _itemRow('Doctor Name', _activeRequest?.doctorName ?? ''),
              _itemRow('Specialty', _activeRequest?.specialty ?? ''),
              _itemRow('Council Reg No.', _activeRequest?.registrationNumber ?? ''),
              _itemRow('Assigned Facility', _activeRequest?.targetFacilityName ?? ''),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3CD),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFCA8A04)),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'STATUS: PENDING REVIEW / सत्यापन लंबित',
                      style: AppTypography.supporting.copyWith(
                        color: const Color(0xFF8A5300),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Check Status Button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF0A6B56)),
            label: const Text('Check Approval Status', style: AppTypography.button),
            onPressed: _checkStatus,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF0A6B56), width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Instant Acceptance Button for pairwise review
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5F2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF0A6B56).withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Text(
                'Facility Administration Desk Integration:',
                style: AppTypography.supporting.copyWith(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                'Facility administrators can review this in the "Staff & Doctor Approvals" tab in Facility Profile.',
                style: AppTypography.supporting.copyWith(fontSize: 11),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.verified_user_outlined, size: 18),
                  label: const Text('Accept & Generate Doctor ID Now', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A6B56),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _simulateFacilityAcceptance,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Step 3: OTP Verification
  Widget _step3OtpVerification() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFDCFCE7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF15803D).withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Color(0xFF15803D), size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Affiliation Accepted by ${_activeRequest?.targetFacilityName}!',
                      style: AppTypography.cardTitle.copyWith(color: const Color(0xFF15803D)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Unique Doctor ID Issued: ${_activeRequest?.generatedDoctorId ?? 'DOC-MH-8421-104'}',
                      style: AppTypography.supporting.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text('Enter 6-Digit Authentication OTP', style: AppTypography.sectionTitle),
        const SizedBox(height: 6),
        Text(
          'A one-time activation PIN was sent to ${_activeRequest?.doctorMobile}.',
          style: AppTypography.supporting,
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _otpCtrl,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 8),
          decoration: InputDecoration(
            hintText: '849201',
            helperText: 'Demo Activation OTP: ${_activeRequest?.tempOtp ?? '849201'}',
          ),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(_errorMessage!, style: AppTypography.supporting.copyWith(color: RuralCareColors.critical)),
        ],
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _verifyOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A6B56),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Verify OTP & Set Password', style: AppTypography.button),
          ),
        ),
      ],
    );
  }

  // Step 4: Set Password & View Official Doctor ID Card
  Widget _step4PasswordAndIdCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Official Verified Doctor Card
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0A6B56), Color(0xFF00382E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0A6B56).withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.health_and_safety, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'RuralCare Medical Registry',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'VERIFIED / अधिकृत',
                      style: TextStyle(color: Color(0xFF15803D), fontWeight: FontWeight.bold, fontSize: 10),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                _activeRequest?.doctorName ?? 'Dr. Sunita Kulkarni',
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                '${_activeRequest?.specialty} • ${_activeRequest?.qualification}',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const Divider(color: Colors.white24, height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('DOCTOR ID', style: TextStyle(color: Colors.white60, fontSize: 10)),
                      Text(
                        _activeRequest?.generatedDoctorId ?? 'DOC-MH-8421-104',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('COUNCIL REG NO.', style: TextStyle(color: Colors.white60, fontSize: 10)),
                      Text(
                        _activeRequest?.registrationNumber ?? 'MMC/2019/06/6120',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Affiliated: ${_activeRequest?.targetFacilityName}',
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),
        const Text('Create Secure Access Password', style: AppTypography.sectionTitle),
        const SizedBox(height: 6),
        const Text(
          'Set a password to use with your new Doctor ID for future logins.',
          style: AppTypography.supporting,
        ),
        const SizedBox(height: 16),
        Container(
          decoration: AppDecorations.card(),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              TextField(
                controller: _passwordCtrl,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirmPasswordCtrl,
                obscureText: _obscurePassword,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                  prefixIcon: Icon(Icons.lock_reset_outlined),
                ),
              ),
            ],
          ),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(_errorMessage!, style: AppTypography.supporting.copyWith(color: RuralCareColors.critical)),
        ],
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _finalizeAndLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A6B56),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Complete Registration & Enter Doctor Dashboard', style: AppTypography.button),
          ),
        ),
      ],
    );
  }

  Widget _itemRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.supporting),
          Text(value, style: AppTypography.body.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
