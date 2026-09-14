import 'package:ruralcare/app/routes.dart';

/// Multilingual localization engine for the Facility Staff workspace.
/// Supports English, Hindi (हिन्दी), and Marathi (मराठी).
class FacilityStrings {
  final String lang;

  FacilityStrings(this.lang);

  factory FacilityStrings.of(SessionCoordinator session) {
    return FacilityStrings(session.activeLanguage);
  }

  bool get isHi => lang == 'Hindi' || lang == 'हिन्दी' || lang == 'hi';
  bool get isMr => lang == 'Marathi' || lang == 'मराठी' || lang == 'mr';

  // Navigation Tabs
  String get tabDashboard => isHi ? 'डैशबोर्ड' : (isMr ? 'डॅशबोर्ड' : 'Dashboard');
  String get tabQueue => isHi ? 'कतार' : (isMr ? 'प्रतीक्षा यादी' : 'Queue');
  String get tabServices => isHi ? 'सेवाएं' : (isMr ? 'सेवा' : 'Services');
  String get tabReferrals => isHi ? 'रेफरल' : (isMr ? 'संदर्भ' : 'Referrals');
  String get tabProfile => isHi ? 'प्रोफ़ाइल' : (isMr ? 'प्रोफाइल' : 'Profile');

  // App Bar & Connectivity
  String get facilityDesk => isHi
      ? 'सुविधा संचालन एवं प्रवेश डेस्क'
      : (isMr ? 'सुविधा कार्य आणि प्रवेश कक्ष' : 'Facility Operations & Intake Desk');
  String get online => isHi ? 'ऑनलाइन' : (isMr ? 'ऑनलाइन' : 'Online');
  String get offline => isHi ? 'ऑफलाइन' : (isMr ? 'ऑफलाइन' : 'Offline');
  String get onlineSynced => isHi
      ? 'ऑनलाइन • सिंक 10:42 AM'
      : (isMr ? 'ऑनलाइन • सिंक 10:42 AM' : 'Online • Synced 10:42 AM');
  String get offlineBanner => isHi
      ? 'स्थानीय रूप से सहेजा गया • ऑफ़लाइन मोड'
      : (isMr ? 'स्थानिकरीत्या सेव्ह केले • ऑफलाइन मोड' : 'Saved locally • Offline Mode');

  // Staff Roles
  String get roleAdmin => isHi ? 'सुविधा प्रशासक' : (isMr ? 'सुविधा व्यवस्थापक' : 'Facility Admin');
  String get roleDoctor => isHi ? 'चिकित्सा अधिकारी' : (isMr ? 'वैद्यकीय अधिकारी' : 'Medical Officer');
  String get rolePharmacist => isHi ? 'मुख्य फार्मासिस्ट' : (isMr ? 'मुख्य औषधनिर्माता' : 'Pharmacist');
  String get roleLab => isHi ? 'लैब डायग्नोस्टिक स्टाफ' : (isMr ? 'प्रयोगशाळा कर्मचारी' : 'Diagnostic Staff');
  String get roleNurse => isHi ? 'स्टाफ नर्स / वार्ड सिस्टर' : (isMr ? 'स्टाफ परिचारिका / वॉर्ड सिस्टर' : 'Staff Nurse');
  String get roleReception => isHi ? 'प्रवेश एवं रेफरल डेस्क' : (isMr ? 'नोंदणी व संदर्भ कक्ष' : 'Reception & Intake');

  // Multi-Tier Approval Chain Strings
  String get staffApprovals => isHi ? 'स्टाफ अनुमोदन डेस्क' : (isMr ? 'कर्मचारी मंजुरी कक्ष' : 'Staff Approvals Desk');
  String get pendingApprovals => isHi ? 'लंबित अनुमोदन' : (isMr ? 'प्रलंबित मंजुऱ्या' : 'Pending Approvals');
  String get approveStaff => isHi ? 'स्वीकृत करें' : (isMr ? 'मंजूर करा' : 'Approve Access');
  String get rejectStaff => isHi ? 'अस्वीकृत करें' : (isMr ? 'नाकारा' : 'Reject');
  String get waitingApprovalTitle => isHi ? 'सत्यापन एवं अनुमोदन लंबित' : (isMr ? 'पडताळणी व मंजुरी प्रलंबित' : 'Verification & Approval Pending');
  String get waitingStaffDesc => isHi
      ? 'आपके क्रेडेंशियल अस्पताल प्रशासन (सुविधा व्यवस्थापक) को अनुमोदन हेतु भेजे गए हैं।'
      : (isMr ? 'आपली माहिती रुग्णालय प्रशासनाकडे (सुविधा व्यवस्थापक) मंजुरीसाठी पाठवली आहे.' : 'Your credentials have been submitted to the Facility Administrator / Medical Superintendent for verification and workspace access.');
  String get waitingAdminDesc => isHi
      ? 'सुविधा व्यवस्थापक क्रेडेंशियल जिला स्वास्थ्य प्रशासन (CMHO) को सत्यापन हेतु भेजे गए हैं।'
      : (isMr ? 'सुविधा व्यवस्थापक माहिती जिल्हा आरोग्य प्रशासनाकडे (CMHO) पडताळणीसाठी पाठवली आहे.' : 'Your Facility Administrator credentials have been submitted to the District Health Office (CMHO) for official verification.');
  String get checkStatus => isHi ? 'अनुमोदन स्थिति जांचें' : (isMr ? 'मंजुरी स्थिती तपासा' : 'Check Approval Status');
  String get fastTrackDemo => isHi ? 'डेमो अनुमोदन (फास्ट-ट्रैक)' : (isMr ? 'डेमो मंजुरी (फास्ट-ट्रॅक)' : 'Authorize Access (Demo / Dev)');

  // Specialized Workstations
  String get pharmacyWorkstation => isHi ? 'फार्मेसी एवं दवा वितरण' : (isMr ? 'औषधनिर्माण व वितरण' : 'Pharmacy Dispensary & Stores');
  String get labWorkstation => isHi ? 'केंद्रीय पैथोलॉजी एवं लैब' : (isMr ? 'मध्यवर्ती पॅथॉलॉजी व लॅब' : 'Central Diagnostic & Pathology Lab');
  String get nurseWorkstation => isHi ? 'इनपेशेंट वार्ड एवं ट्रायज' : (isMr ? 'आंतररुग्ण वॉर्ड व ट्रायज' : 'Inpatient Care & Triage');
  String get intakeWorkstation => isHi ? 'मरीज पंजीकरण एवं 108 डेस्क' : (isMr ? 'रुग्ण नोंदणी व १०८ कक्ष' : 'Patient Registration & 108 Desk');
  String get dispenseAction => isHi ? 'दवा वितरित करें' : (isMr ? 'औषधे वितरित करा' : 'Dispense & Mark Filled');
  String get testWorklist => isHi ? 'जांच कार्यसूची' : (isMr ? 'तपासणी कार्यसूची' : 'Diagnostic Worklist');
  String get enterResult => isHi ? 'परिणाम दर्ज करें' : (isMr ? 'निष्कर्ष नोंदवा' : 'Enter Test Results');

  // Overview Tab
  String get shiftActive => isHi ? 'शिफ्ट सक्रिय' : (isMr ? 'शिफ्ट सक्रिय' : 'Shift Active');
  String get bedCapacity => isHi ? 'बिस्तर क्षमता एवं उपयोग' : (isMr ? 'बेड क्षमता आणि वापर' : 'Bed Capacity & Occupancy');
  String get liveTelemetry => isHi ? 'लाइव टेलीमेट्री' : (isMr ? 'थेट टेलीमेट्री' : 'Live Telemetry');
  String get vacantBeds => isHi ? 'उपलब्ध बिस्तर' : (isMr ? 'उपलब्ध बेड्स' : 'Vacant beds available');
  String get admitPatient => isHi ? 'रोगी भर्ती (-1)' : (isMr ? 'रुग्ण भरती (-1)' : 'Admit Patient (-1 bed)');
  String get dischargePatient => isHi ? 'रोगी छुट्टी (+1)' : (isMr ? 'रुग्ण सोडले (+1)' : 'Discharge Patient (+1 bed)');

  // Alerts
  String get alertColdChain => isHi
      ? 'वैक्सीन कोल्ड-चेन 4.2°C (सुरक्षित) • ILR 1 सत्यापित'
      : (isMr ? 'लस शीत-साखळी 4.2°C (सुरक्षित) • ILR 1 पडताळणी पूर्ण' : 'Vaccine Storage 4.2°C (Secure) • ILR 1 Verified');
  String get alertLowStock => isHi
      ? 'एमोक्सिसिलिन एवं ओआरएस (कम स्टॉक) • 3 दिन शेष'
      : (isMr ? 'एमॉक्सिसिलिन आणि ओआरएस (कमी साठा) • ३ दिवस शिल्लक' : 'Amoxicillin & ORS (Low Stock) • 3d left');

  // Bento Metrics
  String get appointments => isHi ? 'अपॉइंटमेंट्स' : (isMr ? 'भेटी' : 'Appointments');
  String get total => isHi ? 'कुल' : (isMr ? 'एकूण' : 'Total');
  String get queueWaiting => isHi ? 'कतार में प्रतीक्षारत' : (isMr ? 'प्रतीक्षेत' : 'Queue Waiting');
  String get inConsultation => isHi ? 'परामर्श में' : (isMr ? 'सल्लामसलतीत' : 'In Consultation');
  String get activeReferrals => isHi ? 'सक्रिय रेफरल' : (isMr ? 'सक्रिय संदर्भ' : 'Active Referrals');
  String get labDiagnostics => isHi ? 'लैब जांच' : (isMr ? 'लॅब चाचण्या' : 'Lab Diagnostics');
  String get pending => isHi ? 'लंबित' : (isMr ? 'प्रलंबित' : 'Pending');

  // Quick Operations
  String get quickOperations => isHi ? 'त्वरित संचालन' : (isMr ? 'त्वरित कार्य' : 'Quick Operations');
  String get queueDesk => isHi ? 'कतार डेस्क' : (isMr ? 'प्रतीक्षा कक्ष' : 'Queue Desk');
  String get queueDeskSub => isHi ? 'कतार प्रबंधन' : (isMr ? 'रांग व्यवस्थापन' : 'Queue Management');
  String get patientIntake => isHi ? 'मरीज पंजीकरण' : (isMr ? 'रुग्ण नोंदणी' : 'Patient Intake');
  String get patientIntakeSub => isHi ? 'प्रवेश डेस्क' : (isMr ? 'प्रवेश कक्ष' : 'Intake Desk');
  String get referralNetwork => isHi ? 'रेफरल नेटवर्क' : (isMr ? 'संदर्भ नेटवर्क' : 'Referrals Desk');
  String get referralNetworkSub => isHi ? 'मरीज स्थानांतरण' : (isMr ? 'रुग्ण हस्तांतरण' : 'Care Transfers');
  String get serviceStatus => isHi ? 'सेवा स्थिति' : (isMr ? 'सेवा स्थिती' : 'Service Status');
  String get serviceStatusSub => isHi ? 'दवा व जांच स्थिति' : (isMr ? 'औषध व चाचणी स्थिती' : 'Availability Ledger');

  // OPD & Urgent Inbound
  String get opdSchedule => isHi ? 'ओपीडी अनुसूची एवं इनबाउंड केस' : (isMr ? 'ओपीडी वेळापत्रक आणि इनबाउंड केसेस' : 'OPD Schedule & Inbound Cases');
  String get prepareIntake => isHi ? 'प्रवेश तैयार करें' : (isMr ? 'प्रवेश तयार करा' : 'Prepare Intake');
  String get inboundUrgent => isHi ? 'आपातकालीन इनबाउंड' : (isMr ? 'तातडीचे इनबाउंड' : 'INBOUND URGENT');

  // Queue Tab
  String get todaysQueue => isHi ? 'आज की मरीज कतार' : (isMr ? 'आजची रुग्ण प्रतीक्षा यादी' : "Today's Patient Queue");
  String get avgWait => isHi ? 'औसत प्रतीक्षा: 12 मिनट' : (isMr ? 'सरासरी प्रतीक्षा: १२ मिनिटे' : 'Avg. 12m wait');
  String get registered => isHi ? 'पंजीकृत' : (isMr ? 'नोंदणीकृत' : 'Registered');
  String get waitingCount => isHi ? 'प्रतीक्षारत' : (isMr ? 'प्रतीक्षेत' : 'Waiting');
  String get inCabin => isHi ? 'डॉक्टर केबिन में' : (isMr ? 'डॉक्टर दालनात' : 'In Doctor Cabin');
  String get searchPatient => isHi ? 'मरीज़ का नाम या आईडी खोजें...' : (isMr ? 'रुग्णाचे नाव किंवा आयडी शोधा...' : 'Search Patient Name or RuralCare ID...');
  String get allPatients => isHi ? 'सभी मरीज' : (isMr ? 'सर्व रुग्ण' : 'All Patients');
  String get openPatient => isHi ? 'मरीज विवरण' : (isMr ? 'रुग्ण तपशील' : 'Open Patient');
  String get updateStatus => isHi ? 'स्थिति अपडेट' : (isMr ? 'स्थिती अपडेट' : 'Update Status');
  String get fastTrackCheckin => isHi ? 'फास्ट-ट्रैक टोकन चेक-इन' : (isMr ? 'फास्ट-ट्रॅक टोकन चेक-इन' : 'Fast-track arrival token check-in');
  String get checkIn => isHi ? 'चेक-इन' : (isMr ? 'चेक-इन' : 'Check-in');

  // Services Tab
  String get facilityServices => isHi ? 'सुविधा सेवाएं एवं उपलब्धता' : (isMr ? 'सुविधा सेवा आणि उपलब्धता' : 'Facility Services & Availability');
  String get subEssentialMeds => isHi ? 'दवाइयां' : (isMr ? 'औषधे' : 'Medicines');
  String get subDiagnostics => isHi ? 'जांच सेवाएं' : (isMr ? 'चाचणी सेवा' : 'Diagnostics');
  String get subClinical => isHi ? 'स्वास्थ्य सेवाएं' : (isMr ? 'आरोग्य सेवा' : 'Clinical Services');
  String get available => isHi ? 'उपलब्ध' : (isMr ? 'उपलब्ध' : 'Available');
  String get lowStock => isHi ? 'कम स्टॉक' : (isMr ? 'कमी साठा' : 'Low Stock');
  String get unavailable => isHi ? 'अनुपलब्ध' : (isMr ? 'अनुपलब्ध' : 'Unavailable');
  String get updateRequired => isHi ? 'अपडेट आवश्यक' : (isMr ? 'अपडेट आवश्यक' : 'Update Required');
  String get reportDiscrepancy => isHi ? 'विसंगति रिपोर्ट करें' : (isMr ? 'तफावत नोंदवा' : 'Report Discrepancy');
  String get bloodBank => isHi ? 'ब्लड बैंक इन्वेंटरी' : (isMr ? 'रक्तपेढी साठा' : 'Blood Bank Inventory');

  // Referrals Tab
  String get referralCoordination => isHi ? 'रेफरल समन्वय' : (isMr ? 'संदर्भ समन्वय' : 'Referral Coordination');
  String get inbound => isHi ? 'इनबाउंड (आवक)' : (isMr ? 'इनबाउंड (आवक)' : 'Inbound');
  String get outbound => isHi ? 'आउटबाउंड (जावक)' : (isMr ? 'आउटबाउंड (जावक)' : 'Outbound');
  String get acceptReferral => isHi ? 'रेफरल स्वीकारें' : (isMr ? 'संदर्भ स्वीकारा' : 'Accept & Reserve Bed');
  String get acknowledgeArrival => isHi ? 'आगमन दर्ज करें' : (isMr ? 'आगमन नोंदवा' : 'Acknowledge Arrival');
  String get createOutbound => isHi ? '+ नया रेफरल भेजें' : (isMr ? '+ नवीन संदर्भ पाठवा' : '+ Create Outbound Referral');

  // Additional Clinical & Operational Actions
  String get callPatient => isHi ? 'मरीज को बुलाएं' : (isMr ? 'रुग्णाला बोलवा' : 'Call Patient');
  String get assignRoom => isHi ? 'कमरा आवंटित करें' : (isMr ? 'दालन नियुक्त करा' : 'Assign Room');
  String get viewSummary => isHi ? 'सारांश देखें' : (isMr ? 'तपशील पहा' : 'View Summary');
  String get emergencyCapacity => isHi ? 'आपातकालीन बिस्तर क्षमता' : (isMr ? 'तातडीची बेड क्षमता' : 'Emergency Capacity');
  String get reassignStaff => isHi ? 'स्टाफ पुनर्नियुक्त करें' : (isMr ? 'कर्मचारी पुनर्नियुक्त करा' : 'Reassign Staff');
  String get forceSync => isHi ? 'क्लस्टर सिंक करें' : (isMr ? 'क्लस्टर सिंक करा' : 'Force Cluster Sync');
  String get toastUpdated => isHi ? 'स्थिति अपडेट हो गई' : (isMr ? 'स्थिती अपडेट झाली' : 'Status Updated');
  String get toastLedgerRefreshed => isHi
      ? 'सुविधा खाता रीफ्रेश हो गया'
      : (isMr ? 'सुविधा खाते रीफ्रेश झाले' : 'Local facility ledger refreshed.');
  String get toastCallingPatient => isHi
      ? 'मरीज़ को केबिन में बुलाया जा रहा है...'
      : (isMr ? 'रुग्णाला दालनात बोलावले जात आहे...' : 'Calling patient to OPD cabin...');
  String get weeklyEncounters => isHi ? 'साप्ताहिक रोगी विज़िट' : (isMr ? 'साप्ताहिक रुग्ण भेटी' : 'Weekly Patient Encounters');
  String get viewReferralDetails => isHi ? 'रेफरल विवरण देखें' : (isMr ? 'संदर्भ तपशील पहा' : 'View Referral Details');

  // Profile Tab
  String get facilityDetails => isHi ? 'अस्पताल विवरण' : (isMr ? 'रुग्णालय तपशील' : 'Facility Details');
  String get dutyShift => isHi ? 'ड्यूटी शिफ्ट प्रबंधन' : (isMr ? 'ड्युटी शिफ्ट व्यवस्थापन' : 'Duty Shift Management');
  String get staffRoster => isHi ? 'ऑन-ड्यूटी स्टाफ रोस्टर' : (isMr ? 'ऑन-ड्युटी कर्मचारी यादी' : 'On-Duty Staff Roster');
  String get languageSettings => isHi ? 'भाषा चयन' : (isMr ? 'भाषा निवडा' : 'Language Preferences');
  String get offlineSimulation => isHi ? 'ऑफ़लाइन मोड सिमुलेशन' : (isMr ? 'ऑफलाइन मोड सिम्युलेशन' : 'Offline Simulation Mode');
  String get cancel => isHi ? 'रद्द करें' : (isMr ? 'रद्द करा' : 'Cancel');
}
