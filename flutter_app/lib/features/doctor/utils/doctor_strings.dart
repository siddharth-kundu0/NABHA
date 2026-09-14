import 'package:ruralcare/app/routes.dart';

/// Multilingual localization engine for the Doctor / Specialist workspace.
/// Supports English, Hindi (हिन्दी), and Marathi (मराठी).
class DoctorStrings {
  final String lang;

  DoctorStrings(this.lang);

  factory DoctorStrings.of(SessionCoordinator session) {
    return DoctorStrings(session.activeLanguage);
  }

  bool get isHi => lang == 'Hindi' || lang == 'हिन्दी' || lang == 'hi';
  bool get isMr => lang == 'Marathi' || lang == 'मराठी' || lang == 'mr';

  // Navigation Tabs
  String get tabDashboard => isHi ? 'डैशबोर्ड' : (isMr ? 'डॅशबोर्ड' : 'Dashboard');
  String get tabPatients => isHi ? 'मरीज़' : (isMr ? 'रुग्ण' : 'Patients');
  String get tabQueue => isHi ? 'कतार' : (isMr ? 'प्रतीक्षा यादी' : 'Queue');
  String get tabReferrals => isHi ? 'रेफरल' : (isMr ? 'संदर्भ' : 'Referrals');
  String get tabProfile => isHi ? 'प्रोफ़ाइल' : (isMr ? 'प्रोफाइल' : 'Profile');

  // Status & App Bar
  String get online => isHi ? 'ऑनलाइन' : (isMr ? 'ऑनलाइन' : 'Online');
  String get offline => isHi ? 'ऑफलाइन' : (isMr ? 'ऑफलाइन' : 'Offline');
  String get statusOnlineSync => isHi
      ? 'ऑनलाइन • अंतिम सिंक: 10:42 AM'
      : (isMr ? 'ऑनलाइन • शेवटचे समक्रमण: 10:42 AM' : 'Online • Last sync: 10:42 AM');
  String get statusOffline => isHi
      ? 'ऑफलाइन मोड • स्थानीय कैशिंग सक्रिय'
      : (isMr ? 'ऑफलाइन मोड • स्थानिक कॅशिंग सक्रिय' : 'Offline Mode • Local Caching Active');

  // Clinician Persona Card
  String get clinicianRole => isHi
      ? 'चिकित्सा अधिकारी • प्राथमिक स्वास्थ्य केंद्र रामपुर'
      : (isMr ? 'वैद्यकीय अधिकारी • प्राथमिक आरोग्य केंद्र रामपूर' : 'Medical Officer • PHC Rampur Clinical Catchment');
  String get clinicianFacility => isHi
      ? 'प्राथमिक स्वास्थ्य केंद्र रामपुर • कक्ष संख्या 1 (OPD)'
      : (isMr ? 'प्राथमिक आरोग्य केंद्र रामपूर • कक्ष १ (OPD)' : 'Primary Health Centre Rampur • Room 1 (OPD)');

  // Bento Workload Cards
  String get todaysAppointments => isHi ? 'आज के अपॉइंटमेंट' : (isMr ? 'आजच्या भेटी' : "Today's Appointments");
  String get done => isHi ? 'पूर्ण' : (isMr ? 'पूर्ण' : 'Done');
  String get inQueue => isHi ? 'कतार में' : (isMr ? 'प्रतीक्षेत' : 'In Queue');
  String get waiting => isHi ? 'प्रतीक्षारत' : (isMr ? 'प्रतीक्षेत' : 'Waiting');
  String get followups => isHi ? 'फॉलो-अप' : (isMr ? 'फॉलो-अप' : 'Follow-ups');
  String get ancNcd => isHi ? 'मातृत्व / गैर-संचारी' : (isMr ? 'मातृत्व / एनसीडी' : 'ANC / NCD');
  String get pendingReferrals => isHi ? 'लंबित रेफरल' : (isMr ? 'प्रलंबित संदर्भ' : 'Pending Referrals');
  String get pending => isHi ? 'लंबित' : (isMr ? 'प्रलंबित' : 'Pending');

  // Quick Clinical Actions
  String get quickActions => isHi ? 'त्वरित नैदानिक कार्य' : (isMr ? 'त्वरित वैद्यकीय कृती' : 'Quick Clinical Actions');
  String get quickActionsSub => isHi ? 'त्वरित कार्य' : (isMr ? 'त्वरित कृती' : 'Quick Tasks');
  String get actionQueue => isHi ? 'कतार' : (isMr ? 'प्रतीक्षा यादी' : 'Queue');
  String get actionSearch => isHi ? 'मरीज़ खोजें' : (isMr ? 'रुग्ण शोधा' : 'Search');
  String get actionFollowups => isHi ? 'फॉलो-अप' : (isMr ? 'फॉलो-अप' : 'Follow-ups');
  String get actionReferrals => isHi ? 'रेफरल' : (isMr ? 'संदर्भ' : 'Referrals');

  // Schedule Section
  String get todaysSchedule => isHi ? 'आज का रोस्टर' : (isMr ? 'आजचे वेळापत्रक' : "Today's Schedule");
  String get todaysScheduleSub => isHi ? 'कार्य विवरण' : (isMr ? 'तपशील' : 'Daily Roster');
  String get viewQueue => isHi ? 'कतार देखें' : (isMr ? 'यादी पहा' : 'View Queue');
  String get filterAll => isHi ? 'सभी' : (isMr ? 'सर्व' : 'All');
  String get filterWaiting => isHi ? 'प्रतीक्षारत' : (isMr ? 'प्रतीक्षेत' : 'Waiting');
  String get filterTeleconsult => isHi ? 'टेलीकंसल्ट' : (isMr ? 'टेलिकन्सल्ट' : 'Teleconsult');
  String get filterFollowupDue => isHi ? 'फॉलो-अप देय' : (isMr ? 'फॉलो-अप बाकी' : 'Follow-up Due');
  String get filterInPerson => isHi ? 'प्रत्यक्ष उपस्थित' : (isMr ? 'प्रत्यक्ष' : 'In-Person');
  String get filterCompleted => isHi ? 'पूर्ण' : (isMr ? 'पूर्ण' : 'Completed');
  String get noAppointmentsScheduled => isHi
      ? 'कोई निर्धारित अपॉइंटमेंट नहीं'
      : (isMr ? 'कोणत्याही नियोजित अपॉइंटमेंट्स नाहीत' : 'No Scheduled Appointments');
  String get noAppointmentsScheduledSub => isHi
      ? 'जब मरीज़ कतार में जुड़ेंगे, वे यहाँ तुरंत दिखाई देंगे।'
      : (isMr ? 'रुग्ण रांगेत सामील झाल्यावर ते येथे लगेच दिसतील.' : 'Appointments booked by patients will appear here in real-time.');

  // Appointment Cards & Actions
  String get inConsultation => isHi ? 'परामर्श जारी' : (isMr ? 'सल्लामसलत सुरू' : 'In Consultation');
  String get completedStatus => isHi ? 'पूर्ण' : (isMr ? 'पूर्ण' : 'Completed');
  String get videoReady => isHi ? 'वीडियो व ऑडियो तैयार' : (isMr ? 'व्हिडिओ आणि ऑडिओ सज्ज' : 'Video & Audio Ready');
  String get facilityRoom => isHi ? 'प्रा. स्वा. केंद्र रामपुर • कक्ष 1' : (isMr ? 'प्रा. आ. केंद्र रामपूर • कक्ष १' : 'PHC Rampur • Room 1');
  String get resume => isHi ? 'जारी रखें' : (isMr ? 'सुरू ठेवा' : 'Resume');
  String get callPatient => isHi ? 'मरीज़ को कॉल करें →' : (isMr ? 'रुग्णाला कॉल करा →' : 'Call Patient →');
  String get reviewAndStart => isHi ? 'समीक्षा और आरंभ' : (isMr ? 'तपासा आणि सुरू करा' : 'Review & Start');
  String get reopenNote => isHi ? 'नोट फिर से खोलें' : (isMr ? 'नोंद पुन्हा उघडा' : 'Re-open Note');
  String get openRecord => isHi ? 'रिकॉर्ड खोलें' : (isMr ? 'नोंद पहा' : 'Open Record');
  String get openClinicalChartConsent => isHi
      ? 'क्लिनिकल चार्ट खोलें → (सहमति सत्यापित)'
      : (isMr ? 'क्लिनिकल चार्ट उघडा → (संमती सत्यापित)' : 'Open Clinical Chart → (Consent Verified)');
  String get requestForClinicalChart => isHi
      ? 'क्लिनिकल चार्ट के लिए अनुरोध भेजें'
      : (isMr ? 'क्लिनिकल चार्टसाठी विनंती पाठवा' : 'Request for Clinical Chart');
  String get abdmConsentActive => isHi
      ? 'सहमति सक्रिय'
      : (isMr ? 'संमती सक्रिय' : 'Consent Active');

  // Queue Tab
  String get doctorWorkspace => isHi ? 'डॉक्टर कार्यक्षेत्र' : (isMr ? 'डॉक्टर कार्यक्षेत्र' : 'Doctor Workspace');
  String get opdQueue => isHi ? 'ओपीडी कतार' : (isMr ? 'ओपीडी यादी' : 'OPD Queue');
  String get clinicalQueue => isHi ? 'क्लिनिकल कतार' : (isMr ? 'क्लिनिकल यादी' : 'Patient Queue');
  String get roomActive => isHi ? 'OPD कक्ष 1 सक्रिय' : (isMr ? 'OPD कक्ष १ सक्रिय' : 'OPD Room 1 Active');
  String get todaysQueue => isHi ? 'आज की कतार' : (isMr ? 'आजची यादी' : "Today's Queue");
  String get tomorrow => isHi ? 'कल' : (isMr ? 'उद्या' : 'Tomorrow');
  String get patientsWaiting => isHi ? 'मरीज़ प्रतीक्षारत' : (isMr ? 'रुग्ण प्रतीक्षेत' : 'Patients Waiting');
  String get completedToday => isHi ? 'आज पूर्ण' : (isMr ? 'आज पूर्ण' : 'Completed Today');
  String get searchQueueHint => isHi
      ? 'मरीज़, लक्षण या केंद्र द्वारा खोजें...'
      : (isMr ? 'रुग्ण, तक्रार किंवा केंद्राद्वारे शोधा...' : 'Search queue by patient, complaint or facility...');

  // Patients Tab
  String get patientCharts => isHi ? 'मरीज़ क्लिनिकल चार्ट' : (isMr ? 'रुग्ण क्लिनिकल चार्ट' : 'Patient Clinical Charts');
  String get patientChartsSub => isHi
      ? 'दीर्घकालिक चिकित्सा रिकॉर्ड, वाइटल टेलीमेट्री और लैब जांच'
      : (isMr ? 'वैद्यकीय नोंदी, वाइटल टेलिमेट्री आणि प्रयोगशाळा अहवाल' : 'Longitudinal medical records, vitals telemetry & lab investigations');
  String get searchPatientsHint => isHi
      ? 'नाम, रूरलकेयर आईडी या गांव द्वारा खोजें...'
      : (isMr ? 'नाव, रूरलकेअर आयडी किंवा गावावरून शोधा...' : 'Search by name, RuralCare ID or village...');
  String get tagAll => isHi ? 'सभी' : (isMr ? 'सर्व' : 'All');
  String get tagHighRisk => isHi ? 'उच्च जोखिम' : (isMr ? 'धोकादायक' : 'High Risk');
  String get tagAnc => isHi ? 'मातृत्व / ANC' : (isMr ? 'मातृत्व / ANC' : 'ANC / Maternity');
  String get tagNcd => isHi ? 'दीर्घकालिक रोग' : (isMr ? 'दीर्घकालीन आजार' : 'NCD / Chronic');

  // Consent Modal
  String get consentTitle => isHi
      ? 'ABDM क्लिनिकल रिकॉर्ड सहमति अनुरोध'
      : (isMr ? 'ABDM क्लिनिकल रेकॉर्ड संमती विनंती' : 'ABDM Consent Gateway');
  String get consentPurpose => isHi
      ? 'मरीज़ से पिछले स्वास्थ्य रिकॉर्ड, वाइटल टेलीमेट्री और लैब रिपोर्ट देखने की अनुमति मांगें।'
      : (isMr ? 'रुग्णाकडून पूर्वीच्या आरोग्य नोंदी, टेलिमेट्रिक व्हायटल्स आणि प्रयोगशाळा अहवाल पाहण्याची परवानगी मागा.' : 'Request access to view past health records, telemetric vitals, and lab reports from the patient.');
  String get consentScope => isHi
      ? 'दायरा: वाइटल टेलीमेट्री, निदान, पिछले प्रिस्क्रिप्शन, लैब रिपोर्ट'
      : (isMr ? 'व्याप्ती: व्हायटल्स टेलिमेट्री, निदान, मागील प्रिस्क्रिप्शन, लॅब अहवाल' : 'Scope: Vitals Telemetry, Diagnoses, Past Rx, Lab Reports');
  String get consentValidity => isHi
      ? 'मान्यता: राष्ट्रीय स्वास्थ्य एक्सचेंज (ABDM) द्वारा 24 घंटे'
      : (isMr ? 'वैधता: राष्ट्रीय आरोग्य एक्सचेंज (ABDM) द्वारे २४ तास' : 'Validity: 24 Hours via National Health Exchange (ABDM)');
  String get consentPatientIdentity => isHi
      ? 'मरीज़ पहचान और सूचना गंतव्य'
      : (isMr ? 'रुग्ण ओळख आणि सूचना गंतव्य' : 'Patient Identity & Notification Destination');
  String get consentSendButton => isHi
      ? 'एसएमएस द्वारा सहमति अनुरोध भेजें →'
      : (isMr ? 'एसएमएस द्वारे संमती विनंती पाठवा →' : 'Send Consent Request via SMS');
  String get consentOtpInstruction => isHi
      ? 'सत्यापन ओटीपी मरीज़ के मोबाइल पर भेजा गया। अधिकृत करने के लिए नीचे दर्ज करें:'
      : (isMr ? 'सत्यापन ओटीपी रुग्णाच्या मोबाइलवर पाठवला. अधिकृत करण्यासाठी खाली प्रविष्ट करा:' : 'Verification OTP sent to patient mobile. Enter below to authorize access:');
  String get consentEnterOtp => isHi ? '6 अंकों का मरीज़ ओटीपी दर्ज करें' : (isMr ? '६ अंकी रुग्ण ओटीपी प्रविष्ट करा' : 'Enter 6-digit Patient OTP');
  String get consentVerifyButton => isHi
      ? 'ओटीपी सत्यापित करें और डिक्रिप्ट करें →'
      : (isMr ? 'ओटीपी पडताळणी करा आणि डिक्रिप्ट करा →' : 'Verify OTP & Decrypt →');
  String get consentQuickFill => isHi ? 'त्वरित भरें' : (isMr ? 'त्वरित भरा' : 'Auto-Fill');
  String get consentOtpMismatch => isHi
      ? 'गलत ओटीपी। कृपया मरीज़ से पुनः जांच करें।'
      : (isMr ? 'चुकीचा ओटीपी. कृपया रुग्णाशी पुन्हा तपासा.' : 'Invalid OTP. Please check the code provided by the patient.');

  // Referrals Tab
  String get referralsTitle => isHi ? 'रेफरल समन्वय डेस्क' : (isMr ? 'संदर्भ समन्वय डेस्क' : 'Referral Coordination Desk');
  String get referralsSub => isHi
      ? 'आशा कार्यकर्ता प्रेषण, तृतीयक रेफरल और जवाबी मार्गदर्शन'
      : (isMr ? 'आशा कार्यकर्त्यांचे संदर्भ, तृतीयक संदर्भ आणि मार्गदर्शन' : 'Frontline ASHA escalations, tertiary referrals & counter-referrals');
  String get tabInbound => isHi ? 'आवक रेफरल' : (isMr ? 'आवक संदर्भ' : 'Inbound Referrals');
  String get tabOutbound => isHi ? 'जावक ट्रैकिंग' : (isMr ? 'जावक ट्रॅकिंग' : 'Outbound Tracking');
  String get provideCounterGuidance => isHi
      ? 'जवाबी मार्गदर्शन प्रदान करें'
      : (isMr ? 'मार्गदर्शन सूचना पाठवा' : 'Provide Counter-Referral Guidance');
  String get counterGuidanceTitle => isHi
      ? 'जवाबी मार्गदर्शन निर्देश'
      : (isMr ? 'जवाबी मार्गदर्शन सूचना' : 'Counter-Referral Instructions');
  String get frontlineGuidance => isHi
      ? 'आशा कार्यकर्ता मार्गदर्शन निर्देश:'
      : (isMr ? 'आशा कार्यकर्त्यासाठी मार्गदर्शन सूचना:' : 'Frontline ASHA Guidance (निर्देश):');
  String get dispatchGuidance => isHi ? 'मार्गदर्शन भेजें' : (isMr ? 'मार्गदर्शन पाठवा' : 'Dispatch Guidance');
  String get cancel => isHi ? 'रद्द करें' : (isMr ? 'रद्द करा' : 'Cancel');

  // Profile Tab
  String get practiceFacilityTimings => isHi ? 'कार्य स्थल और समय' : (isMr ? 'कार्य स्थळ आणि वेळ' : 'Practice Facility & Timings');
  String get primaryFacility => isHi ? 'मुख्य केंद्र:' : (isMr ? 'मुख्य केंद्र:' : 'Primary Facility:');
  String get generalOpd => isHi ? 'सामान्य ओपीडी:' : (isMr ? 'सामान्य ओपीडी:' : 'General OPD:');
  String get teleconsultRoster => isHi ? 'टेलीकंसल्ट रोस्टर:' : (isMr ? 'टेलिकन्सल्ट वेळापत्रक:' : 'Teleconsult Roster:');
  String get langAndAccessibility => isHi ? 'भाषा और सुगमता' : (isMr ? 'भाषा आणि सुलभता' : 'Language & Accessibility');
  String get simulateOffline => isHi ? 'ऑफलाइन मोड का अनुकरण करें' : (isMr ? 'ऑफलाइन मोडचे अनुकरण करा' : 'Simulate Offline Mode');
  String get queueOfflineSub => isHi
      ? 'प्रिस्क्रिप्शन और अपडेट स्थानीय रूप से कतारबद्ध करें'
      : (isMr ? 'औषधपत्रे आणि अपडेट स्थानिक पातळीवर जतन करा' : 'Queue prescriptions and updates locally');
  String get switchDemoProfile => isHi ? 'डेमो प्रोफ़ाइल बदलें' : (isMr ? 'डेमो प्रोफाइल बदला' : 'Switch Demo Profile');
}
