import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ruralcare/app/routes.dart';
import 'package:ruralcare/core/theme/app_theme.dart';
import 'package:ruralcare/data/models/facility_dto.dart';
import 'package:ruralcare/data/repositories/facility_repository.dart';
import 'package:ruralcare/features/auth/screens/facility_approval_waiting_screen.dart';

class FacilityRegistrationScreen extends StatefulWidget {
  final VoidCallback? onComplete;

  const FacilityRegistrationScreen({super.key, this.onComplete});

  @override
  State<FacilityRegistrationScreen> createState() => _FacilityRegistrationScreenState();
}

class _FacilityRegistrationScreenState extends State<FacilityRegistrationScreen> {
  int _step = 0; // 0: Facility Selection & Role, 1: Professional Credentials

  String? _selectedFacilityId;
  FacilityStaffRole _selectedRole = FacilityStaffRole.pharmacist;

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _idCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();

  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final facilities = FacilityRepository().facilities;
    if (facilities.isNotEmpty) {
      _selectedFacilityId = facilities.first.id;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _idCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _next() {
    final session = SessionCoordinator();
    final isHi = session.isHindi;
    final isMr = session.isMarathi;

    if (_step == 0) {
      if (_selectedFacilityId == null) {
        setState(() {
          _errorMessage = isHi
              ? 'कृपया एक स्वास्थ्य सुविधा का चयन करें।'
              : (isMr ? 'कृपया एक आरोग्य सुविधा निवडा.' : 'Please select a healthcare facility.');
        });
        return;
      }
      setState(() {
        _errorMessage = null;
        _step = 1;
      });
    } else {
      final name = _nameCtrl.text.trim();
      final phone = _phoneCtrl.text.trim();
      final empId = _idCtrl.text.trim();
      final password = _passwordCtrl.text.trim();

      if (name.isEmpty) {
        setState(() => _errorMessage = isHi
            ? 'कृपया अपना पूरा नाम दर्ज करें।'
            : (isMr ? 'कृपया आपले पूर्ण नाव प्रविष्ट करा.' : 'Please enter your full name.'));
        return;
      }

      if (phone.length != 10 || !RegExp(r'^[0-9]{10}$').hasMatch(phone)) {
        setState(() => _errorMessage = isHi
            ? 'अमान्य प्रविष्टि: मोबाइल नंबर ठीक 10 अंकों का होना चाहिए।'
            : (isMr ? 'अवैध नोंद: मोबाइल क्रमांक नेमका १० अंकांचा असणे आवश्यक आहे.' : 'Invalid entry: Mobile number must be exactly 10 digits.'));
        return;
      }

      if (empId.isEmpty) {
        setState(() => _errorMessage = isHi
            ? 'कृपया पंजीकरण या कर्मचारी आईडी दर्ज करें।'
            : (isMr ? 'कृपया नोंदणी किंवा कर्मचारी आयडी प्रविष्ट करा.' : 'Please enter employee or council registration ID.'));
        return;
      }

      if (password.isEmpty) {
        setState(() => _errorMessage = isHi
            ? 'कृपया एक सुरक्षित पासवर्ड या पिन दर्ज करें।'
            : (isMr ? 'कृपया एक सुरक्षित पासवर्ड किंवा पिन प्रविष्ट करा.' : 'Please enter a secure password or PIN.'));
        return;
      }

      final facRepo = FacilityRepository();
      final facility = facRepo.getFacilityById(_selectedFacilityId!) ?? facRepo.currentFacility;
      final reqId = 'REQ-FAC-${DateTime.now().millisecondsSinceEpoch % 90000 + 10000}';

      final isFacilityAdmin = _selectedRole == FacilityStaffRole.facilityAdmin;

      final request = FacilityStaffRequestDto(
        id: reqId,
        facilityId: facility.id,
        facilityName: facility.name,
        staffName: name,
        mobile: phone,
        role: _selectedRole,
        licenseOrEmployeeId: empId,
        department: _selectedRole.defaultDepartment,
        status: isFacilityAdmin
            ? FacilityApprovalStatus.pendingDistrictAdmin
            : FacilityApprovalStatus.pendingFacilityAdmin,
        submittedAt: DateTime.now(),
      );

      if (isFacilityAdmin) {
        facRepo.submitFacilityAdminRequest(request);
      } else {
        facRepo.submitStaffRequest(request);
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => FacilityApprovalWaitingScreen(request: request),
        ),
      );
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
        leading: _step > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: RuralCareColors.textPrimary),
                onPressed: () => setState(() => _step--),
              )
            : IconButton(
                icon: const Icon(Icons.close, color: RuralCareColors.textPrimary),
                onPressed: () => Navigator.of(context).pop(),
              ),
        title: Text(
          _step == 0
              ? (session.isHindi ? 'सुविधा एवं भूमिका चयन (1/2)' : 'Facility & Role Selection (1/2)')
              : (session.isHindi ? 'व्यावसायिक क्रेडेंशियल (2/2)' : 'Staff Credentials Setup (2/2)'),
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: _step == 0 ? _step0FacilityAndRole(session) : _step1Credentials(session),
        ),
      ),
    );
  }

  Widget _langBtn(String code, String label, bool isSelected, SessionCoordinator session) {
    return InkWell(
      onTap: () => session.switchLanguage(code),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0A6B56) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF0A6B56),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _step0FacilityAndRole(SessionCoordinator session) {
    final facilities = FacilityRepository().facilities;

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
              child: const Icon(Icons.apartment_outlined, color: Color(0xFF0A6B56), size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.isHindi ? 'अस्पताल स्टाफ एवं भूमिका' : 'Hospital Staff & Operational Role',
                    style: AppTypography.sectionTitle,
                  ),
                  Text(
                    session.isHindi
                        ? 'अपनी सुविधा और अधिकृत कार्यक्षेत्र का चयन करें'
                        : 'Select healthcare facility and requested role workspace',
                    style: AppTypography.supporting,
                  ),
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
              Text(
                session.isHindi ? 'संबद्ध स्वास्थ्य केंद्र / अस्पताल' : 'Affiliated Healthcare Facility',
                style: AppTypography.supporting,
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _selectedFacilityId,
                isExpanded: true,
                items: facilities.map((fac) {
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
                  prefixIcon: Icon(Icons.local_hospital_outlined),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                session.isHindi ? 'अस्पताल में आपकी भूमिका / पदनाम' : 'Your Operational Role / Designation',
                style: AppTypography.supporting,
              ),
              const SizedBox(height: 8),
              ...FacilityStaffRole.values.map((role) {
                final isSelected = _selectedRole == role;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFE8F5F2) : RuralCareColors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF0A6B56) : RuralCareColors.border,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: RadioListTile<FacilityStaffRole>(
                    value: role,
                    groupValue: _selectedRole,
                    activeColor: const Color(0xFF0A6B56),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedRole = val);
                    },
                    title: Text(
                      role.displayName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? const Color(0xFF0A6B56) : RuralCareColors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      role.defaultDepartment,
                      style: const TextStyle(fontSize: 11, color: RuralCareColors.textSecondary),
                    ),
                  ),
                );
              }),
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
            onPressed: _next,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A6B56),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              session.isHindi ? 'क्रेडेंशियल विवरण के लिए आगे बढ़ें' : 'Proceed to Enter Credentials',
              style: AppTypography.button,
            ),
          ),
        ),
      ],
    );
  }

  Widget _step1Credentials(SessionCoordinator session) {
    final isFacilityAdmin = _selectedRole == FacilityStaffRole.facilityAdmin;

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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.isHindi ? 'पेशेवर क्रेडेंशियल' : 'Professional Staff Credentials',
                    style: AppTypography.sectionTitle,
                  ),
                  Text(
                    isFacilityAdmin
                        ? (session.isHindi
                            ? 'सत्यापन अनुरोध जिला प्रशासन (CMHO) को भेजा जाएगा'
                            : 'Request will be sent to District Admin (CMHO) for approval')
                        : (session.isHindi
                            ? 'सत्यापन अनुरोध अस्पताल प्रशासन (सुविधा व्यवस्थापक) को भेजा जाएगा'
                            : 'Request will be sent to Facility Admin for approval'),
                    style: AppTypography.supporting,
                  ),
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
              Text(
                session.isHindi ? 'पूरा नाम' : 'Staff Full Name',
                style: AppTypography.supporting,
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  hintText: session.isHindi ? 'पूरा नाम दर्ज करें' : 'Enter full name',
                  prefixIcon: const Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                session.isHindi ? 'मोबाइल नंबर (10 अंक)' : 'Mobile Phone Number (10 Digits)',
                style: AppTypography.supporting,
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                decoration: InputDecoration(
                  hintText: session.isHindi ? '10-अंकीय मोबाइल नंबर' : 'Enter 10-digit mobile number',
                  prefixIcon: const Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                session.isHindi ? 'पंजीकरण / कर्मचारी आईडी' : 'Registration / Council / Employee ID',
                style: AppTypography.supporting,
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _idCtrl,
                decoration: InputDecoration(
                  hintText: session.isHindi ? 'आईडी दर्ज करें (उदा. PHARM-MH-842)' : 'Enter Registration or Employee ID',
                  prefixIcon: const Icon(Icons.numbers_outlined),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                session.isHindi ? 'सुरक्षित पासवर्ड / पिन' : 'Account Security PIN / Password',
                style: AppTypography.supporting,
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _passwordCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: session.isHindi ? 'पासवर्ड दर्ज करें' : 'Enter secure password',
                  prefixIcon: const Icon(Icons.lock_outline),
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
            onPressed: _next,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A6B56),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              isFacilityAdmin
                  ? (session.isHindi ? 'जिला प्रशासन को अनुमोदन अनुरोध भेजें' : 'Send Request to District Admin')
                  : (session.isHindi ? 'सुविधा व्यवस्थापक को अनुमोदन अनुरोध भेजें' : 'Send Request to Facility Admin'),
              style: AppTypography.button,
            ),
          ),
        ),
      ],
    );
  }
}
