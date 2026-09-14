import 'package:flutter/material.dart';
import 'package:ruralcare/app/routes.dart';
import 'package:ruralcare/core/theme/app_theme.dart';
import 'package:ruralcare/features/auth/screens/direct_login_screen.dart';
import 'package:ruralcare/features/auth/screens/doctor_registration_flow_screen.dart';
import 'package:ruralcare/features/auth/screens/facility_registration_screen.dart';
import 'package:ruralcare/features/auth/screens/health_worker_registration_screen.dart';
import 'package:ruralcare/features/auth/screens/patient_registration_screen.dart';
import 'package:ruralcare/features/auth/utils/registration_strings.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback? onComplete;

  const OnboardingScreen({super.key, this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 0; // 0: Welcome, 1: Language, 2: Role Selection
  String _selectedLang = 'Hindi';
  AppRole _selectedRole = AppRole.patient;

  @override
  void initState() {
    super.initState();
    final session = SessionCoordinator();
    _selectedLang = session.isMarathi ? 'Marathi' : (session.isHindi ? 'Hindi' : 'English');
  }

  void _next() {
    final session = SessionCoordinator();
    if (_step == 0) {
      setState(() => _step = 1);
    } else if (_step == 1) {
      session.switchLanguage(_selectedLang);
      setState(() => _step = 2);
    } else if (_step == 2) {
      session.switchRole(_selectedRole);

      // Route to role-specific onboarding
      Widget targetScreen;
      switch (_selectedRole) {
        case AppRole.patient:
          targetScreen = PatientRegistrationScreen(onComplete: widget.onComplete);
          break;
        case AppRole.doctor:
          targetScreen = DoctorRegistrationFlowScreen(onComplete: widget.onComplete);
          break;
        case AppRole.healthWorker:
          targetScreen = HealthWorkerRegistrationScreen(onComplete: widget.onComplete);
          break;
        case AppRole.facilityStaff:
          targetScreen = FacilityRegistrationScreen(onComplete: widget.onComplete);
          break;
        case AppRole.admin:
          session.completeOnboarding();
          widget.onComplete?.call();
          return;
      }

      Navigator.of(context).push(MaterialPageRoute(builder: (_) => targetScreen));
    }
  }

  void _openDirectLogin() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DirectLoginScreen(onLoginSuccess: widget.onComplete),
      ),
    );
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
            leading: _step > 0
                ? IconButton(
                    icon: const Icon(Icons.arrow_back, color: RuralCareColors.textPrimary),
                    onPressed: () => setState(() => _step--),
                  )
                : null,
            title: Text(strings.stepOf(_step + 1, 3), style: AppTypography.supporting),
            // User Feedback #2: Removed duplicate "Sign In" button from AppBar actions
            actions: const [],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(3),
              child: LinearProgressIndicator(
                value: (_step + 1) / 3,
                minHeight: 3,
                backgroundColor: RuralCareColors.border,
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0A6B56)),
              ),
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: _buildCurrentStep(strings, session),
                  ),
                ),
                // Bottom Action Area
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: const BoxDecoration(
                    color: RuralCareColors.surface,
                    border: Border(top: BorderSide(color: RuralCareColors.border, width: 1.0)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _next,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0A6B56),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: Text(
                            _step == 2 ? strings.btnContinueRole : strings.btnContinue,
                            style: AppTypography.button,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Single, clean Sign In link at bottom
                      TextButton(
                        onPressed: _openDirectLogin,
                        child: Text(
                          strings.alreadyRegisteredSignIn,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF0A6B56),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCurrentStep(RegistrationStrings strings, SessionCoordinator session) {
    switch (_step) {
      case 0:
        return _stepWelcome(strings);
      case 1:
        return _stepLanguage(strings, session);
      case 2:
        return _stepRole(strings);
      default:
        return const SizedBox.shrink();
    }
  }

  // Step 0: Welcome (Aesthetic Modern Redesign)
  Widget _stepWelcome(RegistrationStrings strings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hero Visual Banner
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0A6B56), Color(0xFF043E32)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0A6B56).withOpacity(0.25),
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
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white30, width: 1),
                    ),
                    child: const Icon(Icons.health_and_safety_rounded, color: Colors.white, size: 28),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_rounded, size: 14, color: Color(0xFF15803D)),
                        SizedBox(width: 4),
                        Text(
                          'ABDM ALIGNED',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF15803D),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                strings.welcomeTitle,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                strings.welcomeSubtitle,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                strings.welcomeDesc,
                style: TextStyle(
                  fontSize: 12.5,
                  color: Colors.white.withOpacity(0.85),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // Quick Capabilities Chips
        Row(
          children: [
            _buildCapabilityChip(Icons.cloud_sync_outlined, strings.isHi ? 'ऑफ़लाइन सिंक' : (strings.isMr ? 'ऑफलाइन सिंक' : 'Offline Sync')),
            const SizedBox(width: 8),
            _buildCapabilityChip(Icons.emergency_outlined, strings.isHi ? '108 आपातकालीन' : (strings.isMr ? '१०८ तातडीची मदत' : '108 Fast-Track')),
            const SizedBox(width: 8),
            _buildCapabilityChip(Icons.lock_outline_rounded, strings.isHi ? 'डेटा सुरक्षा' : (strings.isMr ? 'डेटा सुरक्षा' : 'Secure Care')),
          ],
        ),

        const SizedBox(height: 18),

        // Core Care Continuity Pillars
        Text(
          strings.isHi ? 'रूरलकेयर की प्रमुख विशेषताएं' : (strings.isMr ? 'रूरलकेअर ची प्रमुख वैशिष्ट्ये' : 'Core Care Continuity Pillars'),
          style: AppTypography.cardTitle,
        ),
        const SizedBox(height: 10),

        _buildPillarCard(
          icon: Icons.alt_route_rounded,
          iconColor: const Color(0xFF0A6B56),
          title: strings.pillar1Title,
          desc: strings.pillar1Desc,
        ),
        const SizedBox(height: 10),
        _buildPillarCard(
          icon: Icons.cloud_done_rounded,
          iconColor: const Color(0xFF2563EB),
          title: strings.pillar2Title,
          desc: strings.pillar2Desc,
        ),
        const SizedBox(height: 10),
        _buildPillarCard(
          icon: Icons.local_hospital_rounded,
          iconColor: const Color(0xFFDC2626),
          title: strings.pillar3Title,
          desc: strings.pillar3Desc,
        ),
      ],
    );
  }

  Widget _buildCapabilityChip(IconData icon, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: RuralCareColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: const Color(0xFF0A6B56)),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: RuralCareColors.textPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPillarCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String desc,
  }) {
    return Container(
      decoration: AppDecorations.card(),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: RuralCareColors.textPrimary)),
                const SizedBox(height: 2),
                Text(desc, style: const TextStyle(fontSize: 11.5, color: RuralCareColors.textSecondary, height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Step 1: Language Selection (Aesthetic Modern Redesign)
  Widget _stepLanguage(RegistrationStrings strings, SessionCoordinator session) {
    final languages = [
      {
        'id': 'Hindi',
        'code': 'hi',
        'native': 'हिन्दी',
        'english': 'Hindi',
        'desc': 'देवनागरी लिपि में संपूर्ण इंटरफ़ेस, रिपोर्ट एवं मार्गदर्शन',
        'badge': 'लोकप्रिय / Popular',
      },
      {
        'id': 'Marathi',
        'code': 'mr',
        'native': 'मराठी',
        'english': 'Marathi',
        'desc': 'स्थानिक आरोग्य संदर्भ, मराठी इंटरफेस व सहाय्य',
        'badge': 'स्थानिक / Regional',
      },
      {
        'id': 'English',
        'code': 'en',
        'native': 'English',
        'english': 'English',
        'desc': 'Standard clinical interface & medical terminology',
        'badge': 'Clinical Standard',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(strings.chooseLanguageTitle, style: AppTypography.pageTitle),
        const SizedBox(height: 4),
        Text(strings.chooseLanguageSubtitle, style: const TextStyle(color: Color(0xFF0A6B56), fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Text(strings.chooseLanguageDesc, style: AppTypography.body),
        const SizedBox(height: 20),
        ...languages.map((l) {
          final isSelected = _selectedLang == l['id'];
          return InkWell(
            onTap: () {
              setState(() => _selectedLang = l['id']!);
              session.switchLanguage(l['code']!);
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFF0FDF4) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? const Color(0xFF0A6B56) : RuralCareColors.border,
                  width: isSelected ? 2.0 : 1.0,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF0A6B56).withOpacity(0.12),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF0A6B56) : const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      l['native']!.substring(0, 1),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : const Color(0xFF475569),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              l['native']!,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? const Color(0xFF0A6B56) : RuralCareColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '(${l['english']})',
                              style: const TextStyle(fontSize: 12, color: RuralCareColors.textSecondary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          l['desc']!,
                          style: const TextStyle(fontSize: 11.5, color: RuralCareColors.textSecondary, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                  Radio<String>(
                    value: l['id']!,
                    groupValue: _selectedLang,
                    activeColor: const Color(0xFF0A6B56),
                    onChanged: (val) {
                      setState(() => _selectedLang = val!);
                      session.switchLanguage(l['code']!);
                    },
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // Step 2: Role Selection (Aesthetic Modern Redesign)
  Widget _stepRole(RegistrationStrings strings) {
    final roles = [
      {
        'role': AppRole.patient,
        'title': strings.rolePatientTitle,
        'desc': strings.rolePatientDesc,
        'icon': Icons.person_outline_rounded,
        'accent': const Color(0xFF0A6B56),
      },
      {
        'role': AppRole.healthWorker,
        'title': strings.roleHwTitle,
        'desc': strings.roleHwDesc,
        'icon': Icons.volunteer_activism_outlined,
        'accent': const Color(0xFF166534),
      },
      {
        'role': AppRole.doctor,
        'title': strings.roleDoctorTitle,
        'desc': strings.roleDoctorDesc,
        'icon': Icons.medical_services_outlined,
        'accent': const Color(0xFF2563EB),
      },
      {
        'role': AppRole.facilityStaff,
        'title': strings.roleFacilityTitle,
        'desc': strings.roleFacilityDesc,
        'icon': Icons.local_hospital_outlined,
        'accent': const Color(0xFFD97706),
      },
      {
        'role': AppRole.admin,
        'title': strings.roleAdminTitle,
        'desc': strings.roleAdminDesc,
        'icon': Icons.admin_panel_settings_outlined,
        'accent': const Color(0xFF475569),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(strings.selectRoleTitle, style: AppTypography.pageTitle),
        const SizedBox(height: 4),
        Text(strings.selectRoleSubtitle, style: const TextStyle(color: Color(0xFF0A6B56), fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(strings.selectRoleDesc, style: AppTypography.body),
        const SizedBox(height: 18),
        ...roles.map((r) {
          final role = r['role'] as AppRole;
          final isSelected = _selectedRole == role;
          final accent = r['accent'] as Color;

          return InkWell(
            onTap: () => setState(() => _selectedRole = role),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFF0FDF4) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? const Color(0xFF0A6B56) : RuralCareColors.border,
                  width: isSelected ? 2.0 : 1.0,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: isSelected ? accent.withOpacity(0.15) : RuralCareColors.surfaceSubtle,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      r['icon'] as IconData,
                      color: isSelected ? accent : RuralCareColors.textSecondary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r['title'] as String,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? const Color(0xFF0A6B56) : RuralCareColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          r['desc'] as String,
                          style: const TextStyle(fontSize: 11.5, color: RuralCareColors.textSecondary, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                  Radio<AppRole>(
                    value: role,
                    groupValue: _selectedRole,
                    activeColor: const Color(0xFF0A6B56),
                    onChanged: (val) => setState(() => _selectedRole = val!),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
