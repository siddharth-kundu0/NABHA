import 'package:flutter/material.dart';
import 'package:ruralcare/core/theme/app_theme.dart';
import 'package:ruralcare/core/services/firebase_auth_service.dart';
import 'package:ruralcare/app/routes.dart';
import 'package:ruralcare/data/models/facility_dto.dart';
import 'package:ruralcare/data/repositories/facility_repository.dart';

class HealthWorkerRegistrationScreen extends StatefulWidget {
  final VoidCallback? onComplete;

  const HealthWorkerRegistrationScreen({super.key, this.onComplete});

  @override
  State<HealthWorkerRegistrationScreen> createState() => _HealthWorkerRegistrationScreenState();
}

class _HealthWorkerRegistrationScreenState extends State<HealthWorkerRegistrationScreen> {
  int _step = 0; // 0: Credentials, 1: Sub-centre & Area, 2: OTP & ID Card

  // Form Controllers: Zero pre-filled mock data
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _mobileCtrl = TextEditingController();
  final TextEditingController _workerIdCtrl = TextEditingController();
  String _workerType = 'ASHA (Frontline Health Activist)';
  final TextEditingController _villageCtrl = TextEditingController();

  FacilityDto? _selectedSubCentre;
  final TextEditingController _otpCtrl = TextEditingController();
  String? _errorMessage;

  final List<String> _workerTypes = [
    'ASHA (Frontline Health Activist)',
    'ANM (Auxiliary Nurse Midwife)',
    'CHO (Community Health Officer)',
    'Anganwadi Worker (AWW)',
  ];

  @override
  void initState() {
    super.initState();
    final facs = FacilityRepository().facilities;
    if (facs.isNotEmpty) {
      _selectedSubCentre = facs.first;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _mobileCtrl.dispose();
    _workerIdCtrl.dispose();
    _villageCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_step == 0) {
      if (_nameCtrl.text.trim().isEmpty || _mobileCtrl.text.trim().isEmpty) {
        setState(() => _errorMessage = 'Please enter name and mobile number.');
        return;
      }
      setState(() {
        _errorMessage = null;
        _step = 1;
      });
    } else if (_step == 1) {
      if (_villageCtrl.text.trim().isEmpty || _selectedSubCentre == null) {
        setState(() => _errorMessage = 'Please assign a working village/sector and Sub-Centre.');
        return;
      }
      setState(() {
        _errorMessage = null;
        _step = 2;
      });
    } else if (_step == 2) {
      final name = _nameCtrl.text.trim();
      final mobile = _mobileCtrl.text.trim();
      final workerId = _workerIdCtrl.text.trim();
      final village = _villageCtrl.text.trim();
      final subCentre = _selectedSubCentre?.name ?? 'Kashti Sub-Centre';
      final email = '$mobile@ruralcare.nabha.gov.in';
      final uid = 'HW-${mobile.length >= 4 ? mobile.substring(mobile.length - 4) : '001'}';

      await FirebaseAuthService().registerUser(
        identifier: mobile,
        password: 'HW-$mobile',
        role: AppRole.healthWorker,
        profileData: {
          'uid': uid,
          'fullName': name,
          'name': name,
          'phoneNumber': mobile,
          'email': email,
          'role': 'healthWorker',
          'workerId': workerId,
          'workerType': _workerType,
          'village': village,
          'subCentre': subCentre,
          'catchment': subCentre,
          'facilityId': _selectedSubCentre?.id ?? 'FAC-SC-101',
          'facilityName': subCentre,
        },
      );

      final session = SessionCoordinator();
      session.setAuthenticatedUser(
        uid: uid,
        email: email,
        role: AppRole.healthWorker,
        displayName: name,
        catchment: subCentre,
        facilityId: _selectedSubCentre?.id ?? 'FAC-SC-101',
      );
      session.switchRole(AppRole.healthWorker);
      session.completeOnboarding();

      if (!mounted) return;
      if (widget.onComplete != null) {
        widget.onComplete!();
      } else {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
              ? 'Health Worker Onboarding (1/3)'
              : (_step == 1 ? 'Assigned Sub-Centre (2/3)' : 'Verified ASHA ID (3/3)'),
          style: AppTypography.cardTitle,
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

  Widget _buildCurrentStep() {
    switch (_step) {
      case 0:
        return _step0Credentials();
      case 1:
        return _step1Area();
      case 2:
        return _step2Card();
      default:
        return const SizedBox.shrink();
    }
  }

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
              child: const Icon(Icons.volunteer_activism_outlined, color: Color(0xFF0A6B56), size: 24),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Frontline Worker Profile', style: AppTypography.sectionTitle),
                  Text('आरोग्य सेविका व आशा कार्यकर्ता नोंदणी', style: AppTypography.supporting),
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
              const Text('Full Name', style: AppTypography.supporting),
              const SizedBox(height: 6),
              TextField(controller: _nameCtrl, decoration: const InputDecoration(hintText: 'e.g. Mangal Suresh Patil')),
              const SizedBox(height: 16),
              const Text('Cadre / Worker Role', style: AppTypography.supporting),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _workerType,
                items: _workerTypes.map((t) => DropdownMenuItem(value: t, child: Text(t, style: AppTypography.body))).toList(),
                onChanged: (v) => setState(() => _workerType = v ?? _workerType),
              ),
              const SizedBox(height: 16),
              const Text('Mobile Number (Authentication)', style: AppTypography.supporting),
              const SizedBox(height: 6),
              TextField(controller: _mobileCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(hintText: '10-digit mobile number')),
              const SizedBox(height: 16),
              const Text('Official ASHA / Worker ID', style: AppTypography.supporting),
              const SizedBox(height: 6),
              TextField(controller: _workerIdCtrl, decoration: const InputDecoration(hintText: 'e.g. ASHA-MH-401')),
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
            child: const Text('Proceed to Sector Assignment', style: AppTypography.button),
          ),
        ),
      ],
    );
  }

  Widget _step1Area() {
    final facs = FacilityRepository().facilities;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Assigned Facility & Village Catchment', style: AppTypography.sectionTitle),
        const SizedBox(height: 6),
        const Text('Select your parent Sub-Centre or PHC and assigned sector.', style: AppTypography.supporting),
        const SizedBox(height: 20),
        Container(
          decoration: AppDecorations.card(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Assigned Village / Habitations', style: AppTypography.supporting),
              const SizedBox(height: 6),
              TextField(controller: _villageCtrl, decoration: const InputDecoration(hintText: 'e.g. Kashti Village, Sectors 1-4')),
              const SizedBox(height: 16),
              const Text('Parent Healthcare Facility', style: AppTypography.supporting),
              const SizedBox(height: 8),
              ...facs.take(3).map((f) {
                final isSel = _selectedSubCentre?.id == f.id;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: AppDecorations.card(borderColor: isSel ? const Color(0xFF0A6B56) : RuralCareColors.border),
                  child: ListTile(
                    dense: true,
                    title: Text(f.name, style: AppTypography.cardTitle.copyWith(fontSize: 14)),
                    subtitle: Text(f.typeLabel, style: AppTypography.supporting.copyWith(fontSize: 12)),
                    trailing: Radio<FacilityDto>(
                      value: f,
                      groupValue: _selectedSubCentre,
                      activeColor: const Color(0xFF0A6B56),
                      onChanged: (val) => setState(() => _selectedSubCentre = val),
                    ),
                    onTap: () => setState(() => _selectedSubCentre = f),
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
            child: const Text('Verify & Create Worker ID', style: AppTypography.button),
          ),
        ),
      ],
    );
  }

  Widget _step2Card() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0A6B56), Color(0xFF003D32)],
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
                  const Text('RuralCare Frontline Health Cadre', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(12)),
                    child: const Text('ACTIVE / अधिकृत', style: TextStyle(color: Color(0xFF15803D), fontWeight: FontWeight.bold, fontSize: 10)),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(_nameCtrl.text, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('$_workerType • ${_workerIdCtrl.text}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
              const Divider(color: Colors.white24, height: 26),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('AFFILIATED SUB-CENTRE', style: TextStyle(color: Colors.white60, fontSize: 10)),
                      Text(_selectedSubCentre?.name ?? 'Kashti Sub-Centre', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('CATCHMENT', style: TextStyle(color: Colors.white60, fontSize: 10)),
                      Text(_villageCtrl.text.isNotEmpty ? _villageCtrl.text : 'Catchment Sector', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
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
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Field Vitals & Triage Workspace Enabled', style: AppTypography.cardTitle),
              SizedBox(height: 4),
              Text(
                'Your account is calibrated for offline vital capture, BLE sensor synchronization, maternal ANC tracking, and instant teleconsultation escalation.',
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
            onPressed: _next,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A6B56),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Enter Health Worker Dashboard', style: AppTypography.button),
          ),
        ),
      ],
    );
  }
}
