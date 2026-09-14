import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ruralcare/app/routes.dart';
import 'package:ruralcare/core/theme/app_theme.dart';
import 'package:ruralcare/data/models/patient_dto.dart';
import 'package:ruralcare/data/repositories/patient_repository.dart';
import 'package:ruralcare/features/auth/utils/registration_strings.dart';
import 'package:ruralcare/core/services/firebase_auth_service.dart';

class PatientRegistrationScreen extends StatefulWidget {
  final VoidCallback? onComplete;

  const PatientRegistrationScreen({super.key, this.onComplete});

  @override
  State<PatientRegistrationScreen> createState() => _PatientRegistrationScreenState();
}

class _PatientRegistrationScreenState extends State<PatientRegistrationScreen> {
  int _step = 0; // 0: Mobile, 1: OTP, 2: Demographics, 3: Location, 4: RuralCare ID Card

  // Form Controllers: User Feedback #4, #5, #6 - Zero pre-filled values
  final TextEditingController _mobileCtrl = TextEditingController();
  final TextEditingController _otpCtrl = TextEditingController();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _districtCtrl = TextEditingController();
  final TextEditingController _talukaCtrl = TextEditingController();
  final TextEditingController _villageCtrl = TextEditingController();
  final TextEditingController _pincodeCtrl = TextEditingController();

  DateTime? _dateOfBirth;
  String? _selectedGender;
  String? _selectedSubCentre;

  String? _errorMessage;
  final String _generatedOtp = '482910';
  String _generatedRuralCareId = 'RC-MH-8421-104';
  PatientDto? _registeredPatient;

  static const List<Map<String, String>> _subCentres = [
    {
      'id': 'Kashti Sub-Centre',
      'facilityId': 'FAC-SC-102',
      'en': 'Kashti Sub-Centre (Shirur)',
      'hi': 'काष्टी उप-केंद्र (शिरूर)',
      'mr': 'काष्टी उप-केंद्र (शिरूर)',
      'district': 'Pune Rural',
      'taluka': 'Shirur',
      'asha': 'Sunita Tai Gaikwad (ASHA-MH-401)',
    },
    {
      'id': 'Rampur Sub-Centre',
      'facilityId': 'FAC-SC-103',
      'en': 'Rampur Sub-Centre (Shirur)',
      'hi': 'रामपूर उप-केंद्र (शिरूर)',
      'mr': 'रामपूर उप-केंद्र (शिरूर)',
      'district': 'Pune Rural',
      'taluka': 'Shirur',
      'asha': 'Kavita Verma (ASHA-MH-402)',
    },
    {
      'id': 'Kalyanpur Sub-Centre',
      'facilityId': 'FAC-SC-104',
      'en': 'Kalyanpur Sub-Centre (Haveli)',
      'hi': 'कल्याणपूर उप-केंद्र (हवेली)',
      'mr': 'कल्याणपूर उप-केंद्र (हवेली)',
      'district': 'Pune Rural',
      'taluka': 'Haveli',
      'asha': 'Sunita Devi (ASHA-MH-403)',
    },
    {
      'id': 'Shirur Rural Sub-Centre',
      'facilityId': 'FAC-SC-105',
      'en': 'Shirur Rural Sub-Centre (Shirur)',
      'hi': 'शिरूर ग्रामीण उप-केंद्र (शिरूर)',
      'mr': 'शिरूर ग्रामीण उप-केंद्र (शिरूर)',
      'district': 'Pune Rural',
      'taluka': 'Shirur',
      'asha': 'Mangal Suresh Patil (ASHA-MH-404)',
    },
    {
      'id': 'Daund Sub-Centre',
      'facilityId': 'FAC-SC-106',
      'en': 'Daund Sub-Centre (Daund)',
      'hi': 'दौंड उप-केंद्र (दौंड)',
      'mr': 'दौंड उप-केंद्र (दौंड)',
      'district': 'Pune Rural',
      'taluka': 'Daund',
      'asha': 'Ranjana Shinde (ASHA-MH-405)',
    },
  ];

  @override
  void dispose() {
    _mobileCtrl.dispose();
    _otpCtrl.dispose();
    _nameCtrl.dispose();
    _districtCtrl.dispose();
    _talukaCtrl.dispose();
    _villageCtrl.dispose();
    _pincodeCtrl.dispose();
    super.dispose();
  }

  int _calculateAge(DateTime dob) {
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age < 0 ? 0 : age;
  }

  Future<void> _pickDateOfBirth(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(1996, 1, 1),
      firstDate: DateTime(1910),
      lastDate: now,
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0A6B56),
              onPrimary: Colors.white,
              onSurface: RuralCareColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dateOfBirth = picked;
        _errorMessage = null;
      });
    }
  }

  void _sendOtp(RegistrationStrings strings) {
    final mobile = _mobileCtrl.text.trim();
    if (mobile.length != 10 || !RegExp(r'^[0-9]{10}$').hasMatch(mobile)) {
      setState(() => _errorMessage = strings.errInvalidMobileExact10);
      return;
    }
    setState(() {
      _errorMessage = null;
      _step = 1;
    });
  }

  void _verifyOtp(RegistrationStrings strings) {
    final otp = _otpCtrl.text.trim();
    if (otp.length != 6 || !RegExp(r'^[0-9]{6}$').hasMatch(otp)) {
      setState(() => _errorMessage = strings.errInvalidOtpExact6);
      return;
    }
    if (otp != _generatedOtp) {
      setState(() => _errorMessage = strings.errOtpMismatch);
      return;
    }
    setState(() {
      _errorMessage = null;
      _step = 2;
    });
  }

  void _saveDemographics(RegistrationStrings strings) {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _errorMessage = strings.errMissingDemographics);
      return;
    }
    // Name must only contain letters and spaces
    if (!RegExp(r"^[a-zA-Z\u0900-\u097F\s.']+$").hasMatch(name)) {
      setState(() => _errorMessage = strings.errInvalidName);
      return;
    }
    if (_dateOfBirth == null) {
      setState(() => _errorMessage = strings.dobHint);
      return;
    }
    if (_selectedGender == null) {
      setState(() => _errorMessage = strings.genderSelectHint);
      return;
    }
    setState(() {
      _errorMessage = null;
      _step = 3;
    });
  }

  void _saveLocationAndGenerateId(RegistrationStrings strings) {
    if (_selectedSubCentre == null) {
      setState(() => _errorMessage = strings.subCentreSelectHint);
      return;
    }
    final village = _villageCtrl.text.trim();
    if (village.isEmpty) {
      setState(() => _errorMessage = strings.errMissingLocation);
      return;
    }
    if (!RegExp(r"^[a-zA-Z0-9\u0900-\u097F\s.,'-]+$").hasMatch(village)) {
      setState(() => _errorMessage = strings.errInvalidVillage);
      return;
    }
    final taluka = _talukaCtrl.text.trim();
    if (taluka.isNotEmpty && !RegExp(r"^[a-zA-Z0-9\u0900-\u097F\s.,'-]+$").hasMatch(taluka)) {
      setState(() => _errorMessage = strings.errInvalidTaluka);
      return;
    }
    final district = _districtCtrl.text.trim();
    if (district.isNotEmpty && !RegExp(r"^[a-zA-Z0-9\u0900-\u097F\s.,'-]+$").hasMatch(district)) {
      setState(() => _errorMessage = strings.errInvalidDistrict);
      return;
    }
    final pincode = _pincodeCtrl.text.trim();
    if (pincode.length != 6 || !RegExp(r'^[0-9]{6}$').hasMatch(pincode)) {
      setState(() => _errorMessage = strings.errInvalidPincode);
      return;
    }

    final idSuffix = DateTime.now().millisecondsSinceEpoch % 900 + 100;
    _generatedRuralCareId = 'RC-MH-8421-$idSuffix';

    final matched = _subCentres.firstWhere(
      (s) => s['id'] == _selectedSubCentre,
      orElse: () => _subCentres.first,
    );

    final calculatedAge = _calculateAge(_dateOfBirth!);

    // Register into PatientRepository
    final newPatient = PatientDto(
      id: _generatedRuralCareId,
      ruralCareId: _generatedRuralCareId,
      abhaId: '91-8821-${DateTime.now().millisecondsSinceEpoch % 9000 + 1000}',
      fullName: _nameCtrl.text.trim(),
      age: calculatedAge,
      gender: _selectedGender?.toUpperCase() ?? 'OTHER',
      phoneNumber: '+91${_mobileCtrl.text.trim()}',
      village: _villageCtrl.text.trim(),
      subCentre: _selectedSubCentre ?? 'Kashti Sub-Centre',
      district: _districtCtrl.text.trim().isEmpty ? (matched['district'] ?? 'Pune Rural') : _districtCtrl.text.trim(),
      assignedAsha: matched['asha'] ?? 'Sunita Tai Gaikwad (ASHA-MH-401)',
      emergencyContact: EmergencyContactDto(
        name: 'Family Contact',
        relationship: 'Guardian',
        phoneNumber: '+91${_mobileCtrl.text.trim()}',
      ),
    );
    _registeredPatient = newPatient;
    PatientRepository().addPatient(newPatient);
    PatientRepository().setActivePatient(newPatient);

    // Register user in Firebase Authentication and Firestore
    final mobileNum = _mobileCtrl.text.trim();
    final pwd = mobileNum.length >= 6 ? 'RC-$mobileNum' : 'RuralCare@123';
    FirebaseAuthService().registerUser(
      identifier: mobileNum,
      password: pwd,
      role: AppRole.patient,
      profileData: {
        ...newPatient.toJson(),
        'patientId': newPatient.id,
      },
    );

    setState(() {
      _errorMessage = null;
      _step = 4;
    });
  }

  void _finalizeAndEnterDashboard() {
    final session = SessionCoordinator();
    if (_registeredPatient != null) {
      final matched = _subCentres.firstWhere(
        (s) => s['id'] == _registeredPatient!.subCentre,
        orElse: () => _subCentres.first,
      );
      session.setAuthenticatedUser(
        uid: _registeredPatient!.id,
        email: '${_mobileCtrl.text.trim()}@ruralcare.nabha.gov.in',
        role: AppRole.patient,
        displayName: _registeredPatient!.fullName,
        catchment: _registeredPatient!.subCentre,
        facilityId: matched['facilityId'],
      );
      PatientRepository().setActivePatient(_registeredPatient!);
    }
    session.switchRole(AppRole.patient);
    session.completeOnboarding();

    if (widget.onComplete != null) {
      widget.onComplete!();
    } else {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionCoordinator();

    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        final strings = RegistrationStrings.of(session);

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
            title: Text(strings.regStepTitle(_step), style: AppTypography.cardTitle),
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: _buildCurrentStep(strings),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCurrentStep(RegistrationStrings strings) {
    switch (_step) {
      case 0:
        return _step0Mobile(strings);
      case 1:
        return _step1Otp(strings);
      case 2:
        return _step2Demographics(strings);
      case 3:
        return _step3Location(strings);
      case 4:
        return _step4HealthIdCard(strings);
      default:
        return const SizedBox.shrink();
    }
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

  // Step 0: Mobile Number (User enters phone, field starts empty)
  Widget _step0Mobile(RegistrationStrings strings) {
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
              child: const Icon(Icons.phone_android_outlined, color: Color(0xFF0A6B56), size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(strings.mobileHeader, style: AppTypography.sectionTitle),
                  Text(strings.mobileSubheader, style: AppTypography.supporting),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(strings.mobileExplanation, style: AppTypography.body),
        const SizedBox(height: 20),
        Container(
          decoration: AppDecorations.card(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(strings.mobileFieldLabel, style: AppTypography.supporting),
              const SizedBox(height: 6),
              TextField(
                controller: _mobileCtrl,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1),
                decoration: InputDecoration(
                  counterText: '',
                  prefixIcon: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    alignment: Alignment.centerLeft,
                    width: 65,
                    child: const Text(
                      '+91',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: RuralCareColors.textPrimary),
                    ),
                  ),
                  hintText: strings.mobileFieldHint,
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
            onPressed: () => _sendOtp(strings),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A6B56),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(strings.btnSendOtp, style: AppTypography.button),
          ),
        ),
      ],
    );
  }

  // Step 1: OTP Authentication (Field starts empty, helper banner provides code)
  Widget _step1Otp(RegistrationStrings strings) {
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
              child: const Icon(Icons.sms_outlined, color: Color(0xFF0A6B56), size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(strings.otpHeader, style: AppTypography.sectionTitle),
                  Text(strings.otpSentTo(_mobileCtrl.text), style: AppTypography.supporting),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Interactive simulated SMS banner so tester can see and enter the OTP
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFECFDF5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFA7F3D0)),
          ),
          child: Row(
            children: [
              const Icon(Icons.mark_email_read_outlined, color: Color(0xFF059669), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  strings.simulatedSmsPill(_generatedOtp),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF065F46)),
                ),
              ),
              InkWell(
                onTap: () {
                  setState(() => _otpCtrl.text = _generatedOtp);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    strings.isHi ? 'स्वतः भरें' : (strings.isMr ? 'स्वयं भरा' : 'Auto-fill'),
                    style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),
        Container(
          decoration: AppDecorations.card(),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              TextField(
                controller: _otpCtrl,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 6,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: 8),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: strings.otpFieldHint,
                  helperText: strings.otpHelperText,
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
            onPressed: () => _verifyOtp(strings),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A6B56),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(strings.btnVerifyOtp, style: AppTypography.button),
          ),
        ),
      ],
    );
  }

  // Step 2: Demographics & Exact Date of Birth (User Feedback #5)
  Widget _step2Demographics(RegistrationStrings strings) {
    final hasDob = _dateOfBirth != null;
    final dobFormatted = hasDob
        ? '${_dateOfBirth!.day.toString().padLeft(2, '0')} / ${_dateOfBirth!.month.toString().padLeft(2, '0')} / ${_dateOfBirth!.year}'
        : strings.dobHint;
    final calculatedAge = hasDob ? _calculateAge(_dateOfBirth!) : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(strings.profileHeader, style: AppTypography.sectionTitle),
        const SizedBox(height: 6),
        Text(strings.profileSubheader, style: AppTypography.supporting),
        const SizedBox(height: 20),
        Container(
          decoration: AppDecorations.card(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(strings.fullNameLabel, style: AppTypography.supporting),
              const SizedBox(height: 6),
              TextField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.person_outline),
                  hintText: strings.fullNameHint,
                ),
              ),
              const SizedBox(height: 16),

              // Date of Birth Selector replacing raw age field
              Text(strings.dobLabel, style: AppTypography.supporting),
              const SizedBox(height: 6),
              InkWell(
                onTap: () => _pickDateOfBirth(context),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: RuralCareColors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: RuralCareColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month_outlined, color: Color(0xFF0A6B56), size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          dobFormatted,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: hasDob ? FontWeight.bold : FontWeight.w500,
                            color: hasDob ? RuralCareColors.textPrimary : RuralCareColors.textSecondary,
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down, color: RuralCareColors.textSecondary),
                    ],
                  ),
                ),
              ),
              if (calculatedAge != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.cake_outlined, size: 14, color: Color(0xFF0A6B56)),
                    const SizedBox(width: 6),
                    Text(
                      strings.ageDisplay(calculatedAge),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0A6B56)),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),

              // Gender Selector
              Text(strings.genderLabel, style: AppTypography.supporting),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _selectedGender,
                hint: Text(strings.genderSelectHint, style: const TextStyle(color: RuralCareColors.textSecondary)),
                items: [
                  DropdownMenuItem(value: 'Female', child: Text(strings.genderFemale)),
                  DropdownMenuItem(value: 'Male', child: Text(strings.genderMale)),
                  DropdownMenuItem(value: 'Other', child: Text(strings.genderOther)),
                ],
                onChanged: (v) => setState(() => _selectedGender = v),
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
            onPressed: () => _saveDemographics(strings),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A6B56),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(strings.btnProceedLocation, style: AppTypography.button),
          ),
        ),
      ],
    );
  }

  // Step 3: Location / Healthcare Area with Sub-Centre Dropdown (User Feedback #6)
  Widget _step3Location(RegistrationStrings strings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(strings.locationHeader, style: AppTypography.sectionTitle),
        const SizedBox(height: 6),
        Text(strings.locationSubheader, style: AppTypography.supporting),
        const SizedBox(height: 20),
        Container(
          decoration: AppDecorations.card(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Feedback #6: Sub-Centre Dropdown
              Text(strings.subCentreLabel, style: AppTypography.supporting),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _selectedSubCentre,
                isExpanded: true,
                hint: Text(strings.subCentreSelectHint, style: const TextStyle(color: RuralCareColors.textSecondary)),
                items: _subCentres.map((sc) {
                  String label = sc['en']!;
                  if (strings.isHi && sc['hi'] != null) label = sc['hi']!;
                  if (strings.isMr && sc['mr'] != null) label = sc['mr']!;

                  return DropdownMenuItem<String>(
                    value: sc['id'],
                    child: Text(
                      label,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedSubCentre = val;
                    // Neutral: Do not auto-fill district and taluka so user enters clean input
                  });
                },
              ),
              const SizedBox(height: 16),

              Text(strings.villageLabel, style: AppTypography.supporting),
              const SizedBox(height: 6),
              TextField(
                controller: _villageCtrl,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.home_outlined),
                  hintText: strings.villageHint,
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(strings.talukaLabel, style: AppTypography.supporting),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _talukaCtrl,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.map_outlined),
                            hintText: strings.talukaHint,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(strings.districtLabel, style: AppTypography.supporting),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _districtCtrl,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.location_city_outlined),
                            hintText: strings.districtHint,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Text(strings.pincodeLabel, style: AppTypography.supporting),
              const SizedBox(height: 6),
              TextField(
                controller: _pincodeCtrl,
                keyboardType: TextInputType.number,
                maxLength: 6,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                decoration: InputDecoration(
                  counterText: '',
                  prefixIcon: const Icon(Icons.pin_drop_outlined),
                  hintText: strings.pincodeHint,
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
            onPressed: () => _saveLocationAndGenerateId(strings),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A6B56),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(strings.btnGenerateHealthId, style: AppTypography.button),
          ),
        ),
      ],
    );
  }

  // Step 4: RuralCare ID Card
  Widget _step4HealthIdCard(RegistrationStrings strings) {
    final ageText = _dateOfBirth != null ? '${_calculateAge(_dateOfBirth!)} Years' : '';
    final subCentreName = _selectedSubCentre ?? 'Kashti Sub-Centre';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Health ID Badge Card
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0A6B56), Color(0xFF02382D)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0A6B56).withOpacity(0.35),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(22),
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
                        child: const Icon(Icons.health_and_safety, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        strings.idCardTitle,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      strings.statusActive,
                      style: const TextStyle(color: Color(0xFF15803D), fontWeight: FontWeight.bold, fontSize: 10),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                _nameCtrl.text.isNotEmpty ? _nameCtrl.text : 'Citizen Beneficiary',
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                '${_selectedGender ?? ""} • $ageText • +91 ${_mobileCtrl.text}',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const Divider(color: Colors.white24, height: 26),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('RURALCARE UNIQUE ID', style: TextStyle(color: Colors.white60, fontSize: 10)),
                      Text(
                        _generatedRuralCareId,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(strings.linkedSubCentreLabel.toUpperCase(), style: const TextStyle(color: Colors.white60, fontSize: 10)),
                      Text(
                        subCentreName,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),
        Container(
          decoration: AppDecorations.card(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.verified_user_outlined, color: Color(0xFF0A6B56), size: 20),
                  const SizedBox(width: 8),
                  Text(strings.linkedSubCentreLabel, style: AppTypography.cardTitle),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                strings.abdmNotice,
                style: AppTypography.supporting,
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _finalizeAndEnterDashboard,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A6B56),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(strings.btnEnterDashboard, style: AppTypography.button),
          ),
        ),
      ],
    );
  }
}
