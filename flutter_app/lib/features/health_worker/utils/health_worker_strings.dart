import 'package:ruralcare/app/routes.dart';

/// Multilingual localization dictionary for the Health Worker / ASHA workspace.
/// Strictly supports English, Hindi (हिन्दी), and Marathi (मराठी).
class HealthWorkerStrings {
  final String lang;

  HealthWorkerStrings(this.lang);

  factory HealthWorkerStrings.of(SessionCoordinator session) {
    return HealthWorkerStrings(session.activeLanguage);
  }

  bool get isHi => lang == 'Hindi' || lang == 'हिन्दी' || lang == 'हिंदी' || lang == 'hi';
  bool get isMr => lang == 'Marathi' || lang == 'मराठी' || lang == 'mr';

  // Navigation Tabs
  String get tabDashboard => isHi ? 'डैशबोर्ड' : (isMr ? 'डॅशबोर्ड' : 'Dashboard');
  String get tabPatients => isHi ? 'मरीज़' : (isMr ? 'रुग्ण' : 'Patients');
  String get tabTasks => isHi ? 'कार्य' : (isMr ? 'कार्ये' : 'Tasks');
  String get tabReferrals => isHi ? 'रेफरल' : (isMr ? 'संदर्भ' : 'Referrals');
  String get tabProfile => isHi ? 'प्रोफ़ाइल' : (isMr ? 'प्रोफाइल' : 'Profile');

  // Header & Connectivity
  String get online => isHi ? 'ऑनलाइन' : (isMr ? 'ऑनलाइन' : 'Online');
  String get offline => isHi ? 'ऑफलाइन' : (isMr ? 'ऑफलाइन' : 'Offline');
  String get roleSubtitle => isHi
      ? 'आशा सेक्टर 3 कार्यक्षेत्र'
      : (isMr ? 'आशा सेक्टर ३ कार्यक्षेत्र' : 'ASHA Sector 3 Catchment');
  String get recordsSaved => isHi ? 'रिकॉर्ड सुरक्षित' : (isMr ? 'नोंदी सुरक्षित' : 'Records Saved');
  String get syncSuccess => isHi
      ? 'ऑफ़लाइन रिकॉर्ड पीएचसी रजिस्ट्री के साथ समन्वयित'
      : (isMr ? 'ऑफलाइन नोंदी पीएचसी नोंदणीसह समक्रमित केल्या' : 'Offline records synchronized with PHC registry');

  // 2x2 Performance Metrics Grid
  String get dueToday => isHi ? 'आज देय' : (isMr ? 'आज देय' : 'DUE TODAY');
  String get priorityCases => isHi ? 'प्राथमिकता मामले' : (isMr ? 'प्राधान्य प्रकरणे' : 'PRIORITY CASES');
  String get activeReferrals => isHi ? 'सक्रिय रेफरल' : (isMr ? 'सक्रिय संदर्भ' : 'ACTIVE REFERRALS');
  String get completedThisWeek => isHi ? 'इस सप्ताह पूर्ण' : (isMr ? 'या आठवड्यात पूर्ण' : 'COMPLETED THIS WEEK');

  // Quick Action Buttons
  String get findPatient => isHi ? 'मरीज़ खोजें' : (isMr ? 'रुग्ण शोधा' : 'Find Patient');
  String get recordFollowUp => isHi ? 'फॉलो-अप\nदर्ज करें' : (isMr ? 'फॉलो-अप\nनोंदवा' : 'Record\nFollow-up');
  String get referralSupport => isHi ? 'रेफरल\nसहायता' : (isMr ? 'संदर्भ\nमदत' : 'Referral\nSupport');
  String get todaysTasksAction => isHi ? 'आज के\nकार्य' : (isMr ? 'आजची\nकार्ये' : "Today's\nTasks");

  // Today's Tasks Section
  String get todaysTasks => isHi ? 'आज के कार्य' : (isMr ? 'आजची कार्ये' : "Today's Tasks");
  String get viewAll => isHi ? 'सभी देखें' : (isMr ? 'सर्व पहा' : 'View All');

  // Priority Badges
  String get priorityNormal => isHi ? '● सामान्य' : (isMr ? '● सामान्य' : '● Normal');
  String get priorityAnc => isHi ? '● एएनसी प्राथमिकता' : (isMr ? '● एएनसी प्राधान्य' : '● ANC Priority');
  String get priorityHigh => isHi ? '● उच्च प्राथमिकता' : (isMr ? '● उच्च प्राधान्य' : '● High Priority');
  String get priorityOverdue => isHi ? '● अतिदेय' : (isMr ? '● थकीत' : '● Overdue');

  // Task Cards Labels & Actions
  String get whoLabel => isHi ? 'मरीज़' : (isMr ? 'रुग्ण' : 'WHO');
  String get whenLabel => isHi ? 'समय' : (isMr ? 'वेळ' : 'WHEN');
  String get actionLabel => isHi ? 'कार्य' : (isMr ? 'कृती' : 'ACTION');
  String get viewDetails => isHi ? 'विवरण देखें' : (isMr ? 'तपशील पहा' : 'View Details');
  String get recordVitals => isHi ? 'वाइटल्स दर्ज करें' : (isMr ? 'मापदंड नोंदवा' : 'Record Vitals');

  // Field Screening Tools
  String get fieldScreeningTools => isHi ? 'फ़ील्ड स्क्रीनिंग टूल्स' : (isMr ? 'क्षेत्र तपासणी साधने' : 'Field Screening Tools');
  String get vitalsCheck => isHi ? 'वाइटल्स जांच' : (isMr ? 'मापदंड तपासणी' : 'Vitals Check');
  String get vitalsCheckSub => isHi ? 'बीपी, शुगर, SpO2' : (isMr ? 'बीपी, साखर, SpO2' : 'BP, Sugar, SpO2');
  String get digitalTriage => isHi ? 'डिजिटल ट्राइएज' : (isMr ? 'डिजिटल ट्रायज' : 'Digital Triage');
  String get digitalTriageSub => isHi ? 'लक्षण स्कोरिंग' : (isMr ? 'लक्षण गुणांकन' : 'Symptom scoring');
  String get ancTracker => isHi ? 'एएनसी ट्रैकर' : (isMr ? 'एएनसी ट्रॅकर' : 'ANC Tracker');
  String get ancTrackerSub => isHi ? 'उच्च-जोखिम मातृत्व' : (isMr ? 'उच्च-जोखीम मातृत्व' : 'High-risk maternity');
  String get emergencySos => isHi ? 'आपातकालीन SOS' : (isMr ? 'तातडीची मदत SOS' : 'Emergency SOS');
  String get emergencySosSub => isHi ? 'एम्बुलेंस और 108' : (isMr ? 'रुग्णवाहिका आणि १०८' : 'Ambulance & 108');

  // Weekly Activity Summary Modal
  String get weeklyLogTitle => isHi ? 'साप्ताहिक कार्य लॉग (18 पूर्ण)' : (isMr ? 'साप्ताहिक कार्य नोंदी (१८ पूर्ण)' : 'Weekly Activity Log (18 Completed)');
  String get hypertensionFollowups => isHi ? 'उच्च रक्तचाप फॉलो-अप' : (isMr ? 'उच्च रक्तदाब फॉलो-अप' : 'Hypertension Follow-ups');
  String get maternalAncChecks => isHi ? 'मातृ एएनसी जांच' : (isMr ? 'मातृ एएनसी तपासण्या' : 'Maternal ANC Checks');
  String get childImmunization => isHi ? 'बाल टीकाकरण समीक्षा' : (isMr ? 'बाल लसीकरण आढावा' : 'Child Immunization Reviews');
  String get closeSummary => isHi ? 'सारांश बंद करें' : (isMr ? 'सारांश बंद करा' : 'Close Summary');

  // Patient Directory
  String get patientDirectoryTitle => isHi ? 'मरीज़ निर्देशिका' : (isMr ? 'रुग्ण निर्देशिका' : 'Patient Directory');
  String get searchPatientHeaderTag => isHi ? 'मरीज़ खोजें' : (isMr ? 'रुग्ण शोधा' : 'Patient Search');
  String get patientDirectorySubtitle => isHi
      ? 'पीएचसी रामपुर कार्यक्षेत्र में सौंपे गए मरीज़ों को खोजें'
      : (isMr ? 'पीएचसी रामपूर कार्यक्षेत्रातील नेमून दिलेले रुग्ण शोधा' : 'Search assigned patients in PHC Rampur catchment');
  String get searchPlaceholder => isHi
      ? 'नाम, रूरलकेयर आईडी या मोबाइल द्वारा खोजें...'
      : (isMr ? 'नाव, रूरलकेअर आयडी किंवा मोबाईलद्वारे शोधा...' : 'Search by Name, RuralCare ID, or Mobile...');
  String get filterAll => isHi ? 'सभी' : (isMr ? 'सर्व' : 'All');
  String get filterHighRisk => isHi ? 'उच्च जोखिम' : (isMr ? 'उच्च जोखीम' : 'High Risk');
  String get filterAnc => isHi ? 'एएनसी' : (isMr ? 'एएनसी' : 'ANC');
  String get filterDueToday => isHi ? 'आज देय' : (isMr ? 'आज देय' : 'Due Today');
}
