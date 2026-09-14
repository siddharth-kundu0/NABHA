import 'package:ruralcare/app/routes.dart';

/// Centralized localization dictionary for all Patient Portal screens.
/// Supports English, Hindi (हिन्दी), and Marathi (मराठी).
class PatientStrings {
  final String langCode;

  PatientStrings(this.langCode);

  factory PatientStrings.of(SessionCoordinator session) {
    return PatientStrings(session.canonicalLanguageCode);
  }

  bool get isHi =>
      langCode == 'hi' ||
      langCode == 'Hindi' ||
      langCode == 'हिन्दी' ||
      langCode == 'हिंदी';
  bool get isMr => langCode == 'mr' || langCode == 'Marathi' || langCode == 'मराठी';
  bool get isEn => !isHi && !isMr;

  // --- Common & Global ---
  String get appTitle => 'RuralCare';
  String get back => isHi ? 'वापस' : (isMr ? 'मागे' : 'Back');
  String get save => isHi ? 'सुरक्षित करें' : (isMr ? 'जतन करा' : 'Save');
  String get cancel => isHi ? 'रद्द करें' : (isMr ? 'रद्द करा' : 'Cancel');
  String get edit => isHi ? 'संपादित करें' : (isMr ? 'संपादित करा' : 'Edit');
  String get view => isHi ? 'देखें' : (isMr ? 'पहा' : 'View');
  String get update => isHi ? 'अपडेट करें' : (isMr ? 'अद्ययावत करा' : 'Update');
  String get emergencyHelp => isHi ? 'आपातकालीन सहायता (108)' : (isMr ? 'तातडीची मदत (108)' : 'Emergency Help (108)');
  String get emergencySub => isHi ? 'आपात स्थिति में एम्बुलेंस व अस्पताल सहायता' : (isMr ? 'रुग्णवाहिका व वैद्यकीय मदत' : 'Ambulance and facility emergency support');
  String get verified => isHi ? 'सत्यापित' : (isMr ? 'सत्यापित' : 'Verified');
  String get confirmed => isHi ? 'पुष्ट' : (isMr ? 'निश्चित' : 'Confirmed');
  String get pending => isHi ? 'लंबित' : (isMr ? 'प्रलंबित' : 'Pending');

  // --- Home Screen ---
  String greeting(String name) {
    if (isHi) return 'नमस्ते, $name';
    if (isMr) return 'नमस्कार, $name';
    return 'Good morning, $name';
  }

  String get nextCareHeading => isHi ? 'आपकी अगली अपॉइंटमेंट' : (isMr ? 'तुमची पुढची अपॉइंटमेंट' : 'Your next appointment');
  String get viewAppointment => isHi ? 'अपॉइंटमेंट विवरण देखें' : (isMr ? 'अपॉइंटमेंट तपशील पहा' : 'View appointment');
  String get howCanWeHelp => isHi ? 'हम आपकी कैसे मदद कर सकते हैं?' : (isMr ? 'आम्ही कशी मदत करू शकतो?' : 'How can we help?');
  String get bookAppointment => isHi ? 'अपॉइंटमेंट बुक करें' : (isMr ? 'भेट बुक करा' : 'Book appointment');
  String get teleconsultation => isHi ? 'टेलीकंसल्टेशन' : (isMr ? 'टेलीसल्ला' : 'Teleconsultation');
  String get findFacility => isHi ? 'अस्पताल खोजें' : (isMr ? 'रुग्णालय शोधा' : 'Find facility');
  String get medicines => isHi ? 'दवाइयां' : (isMr ? 'औषधे' : 'Medicines');
  String get diagnostics => isHi ? 'निदान जांच व लैब' : (isMr ? 'निदान चाचण्या व लॅब' : 'Diagnostics & lab tests');
  String get activeReferral => isHi ? 'सक्रिय रेफरल' : (isMr ? 'सक्रिय संदर्भ' : 'Active referral');
  String get viewReferral => isHi ? 'रेफरल देखें' : (isMr ? 'संदर्भ पहा' : 'View referral');
  String get yourHealthSnapshot => isHi ? 'आपकी स्वास्थ्य स्थिति' : (isMr ? 'तुमचे आरोग्य' : 'Your health');
  String get recentConsultation => isHi ? 'हालिया परामर्श' : (isMr ? 'नुकतीच झालेली सल्लामसलत' : 'Recent consultation');
  String get latestHealthReadings => isHi ? 'नवीनतम स्वास्थ्य रीडिंग' : (isMr ? 'नवीनतम आरोग्याच्या नोंदी' : 'Latest health readings');
  String get reviewNeeded => isHi ? 'जांच आवश्यक' : (isMr ? 'तपासणी आवश्यक' : 'Review needed');
  String get normal => isHi ? 'सामान्य' : (isMr ? 'सामान्य' : 'Normal');
  String get latestPrescription => isHi ? 'नवीनतम नुस्खा' : (isMr ? 'नवीनतम औषधोपचार' : 'Latest prescription');
  String get assignedAsha => isHi ? 'नियुक्त आशा कार्यकर्ता' : (isMr ? 'नियुक्त आशा सेविका' : 'Assigned health worker');
  String get callAsha => isHi ? 'संपर्क करें' : (isMr ? 'संपर्क करा' : 'Call');

  // --- Navigation Tabs ---
  String get navHome => isHi ? 'मुख्य पृष्ठ' : (isMr ? 'मुख्य पृष्ठ' : 'Home');
  String get navSymptomChecker => isHi ? 'लक्षण जाँच' : (isMr ? 'लक्षण तपासणी' : 'Symptom Checker');
  String get symptomChecker => isHi ? 'लक्षण जाँच' : (isMr ? 'लक्षण तपासणी' : 'Symptom Checker');
  String get symptomCheckerSub => isHi ? 'शरीर के अंग पर टैप करें और लक्षण बताएं' : (isMr ? 'शरीराच्या भागावर टॅप करा व लक्षणे सांगा' : 'Interactive body map and health assessment');
  String get navAppointments => isHi ? 'अपॉइंटमेंट' : (isMr ? 'अपॉइंटमेंट' : 'Appointments');
  String get navRecords => isHi ? 'रिकॉर्ड' : (isMr ? 'नोंदी' : 'Records');
  String get navReferrals => isHi ? 'रेफरल' : (isMr ? 'संदर्भ' : 'Referrals');
  String get navProfile => isHi ? 'प्रोफ़ाइल' : (isMr ? 'प्रोफाइल' : 'Profile');

  // --- Appointment Booking Screen ---
  String get appointmentsTitle => isHi ? 'अपॉइंटमेंट्स' : (isMr ? 'भेटी' : 'Appointments');
  String get tabUpcoming => isHi ? 'आगामी' : (isMr ? 'आगामी' : 'Upcoming');
  String get tabPast => isHi ? 'विगत' : (isMr ? 'मागील' : 'Past');
  String get noUpcomingApts => isHi ? 'कोई आगामी अपॉइंटमेंट नहीं' : (isMr ? 'कोणतीही आगामी भेट नाही' : 'No upcoming appointments');
  String get noUpcomingAptsSub => isHi ? 'आपके निर्धारित टेली-परामर्श और ओपीडी दौरे यहां दिखाई देंगे।' : (isMr ? 'तुमचे नियोजित टेलिकन्सल्टेशन आणि ओपीडी भेटी येथे दिसतील.' : 'Your scheduled teleconsultations and facility OPD visits will appear here.');
  String get noPastApts => isHi ? 'कोई विगत अपॉइंटमेंट नहीं' : (isMr ? 'कोणतीही मागील भेट नाही' : 'No past appointments');
  String get noPastAptsSub => isHi ? 'आपके पूर्ण परामर्श और रिकॉर्ड यहां संग्रहीत किए जाएंगे।' : (isMr ? 'तुमचे पूर्ण झालेले सल्लामसलत आणि नोंदी येथे संग्रहित केल्या जातील.' : 'Your completed consultations and records will be archived here.');
  String get scheduleAppointment => isHi ? 'अपॉइंटमेंट निर्धारित करें' : (isMr ? 'भेट निश्चित करा' : 'Schedule an appointment');
  String get teleconsultationMode => isHi ? 'टेलीपरामर्श' : (isMr ? 'टेलिकन्सल्टेशन' : 'Teleconsultation');
  String get inPersonMode => isHi ? 'प्रत्यक्ष ओपीडी' : (isMr ? 'प्रत्यक्ष ओपीडी' : 'In-Person OPD');
  String get specialtyLabel => isHi ? 'विशेषज्ञता' : (isMr ? 'विशेषज्ञता' : 'Specialty');
  String get timeSlotLabel => isHi ? 'समय स्लॉट' : (isMr ? 'वेळ स्लॉट' : 'Time slot');
  String get reasonLabel => isHi ? 'भेंट का कारण' : (isMr ? 'भेटीचे कारण' : 'Reason for visit');
  String get reasonHint => isHi ? 'उदा. तीसरी तिमाही एएनसी नियमित जांच' : (isMr ? 'उदा. तिसरी तिमाही एएनसी नियमित तपासणी' : 'e.g. 3rd Trimester ANC routine follow-up');
  String get confirmAppointmentBtn => isHi ? 'अपॉइंटमेंट की पुष्टि करें' : (isMr ? 'भेटीची पुष्टी करा' : 'Confirm appointment');
  String get joinTeleconsult => isHi ? 'परामर्श में शामिल हों' : (isMr ? 'सल्ल्यामध्ये सामील व्हा' : 'Join consultation');
  String get viewArrivalPass => isHi ? 'आगमन पास देखें' : (isMr ? 'प्रवेश पास पहा' : 'View arrival pass');
  String get aptConfirmedToast => isHi ? 'अपॉइंटमेंट सफलतापूर्वक पुष्ट हुई!' : (isMr ? 'भेट यशस्वीरित्या निश्चित झाली!' : 'Appointment confirmed successfully!');

  // --- Longitudinal Records Screen ---
  String get healthRecordsTitle => isHi ? 'स्वास्थ्य रिकॉर्ड' : (isMr ? 'आरोग्य नोंदी' : 'Health records');
  String get filterAll => isHi ? 'सभी' : (isMr ? 'सर्व' : 'All');
  String get filterPrescriptions => isHi ? 'दवाएं' : (isMr ? 'औषधे' : 'Prescriptions');
  String get filterDiagnostics => isHi ? 'जांच रिपोर्ट' : (isMr ? 'तपासणी अहवाल' : 'Diagnostics');
  String get filterVitals => isHi ? 'महत्वपूर्ण संकेत' : (isMr ? 'महत्त्वाचे मापदंड' : 'Vitals');
  String get filterConsultations => isHi ? 'परामर्श' : (isMr ? 'सल्लामसलत' : 'Consultations');

  // --- Referral Tracker Screen ---
  String get referralDetailsTitle => isHi ? 'रेफरल विवरण' : (isMr ? 'संदर्भ तपशील' : 'Referral details');
  String get referralProgressTitle => isHi ? 'रेफरल प्रगति' : (isMr ? 'संदर्भ प्रगती' : 'Referral progress');
  String get referredFrom => isHi ? 'रेफरल स्रोत: ' : (isMr ? 'संदर्भ स्रोत: ' : 'Referred from: ');
  String get referredTo => isHi ? 'रेफरल गंतव्य: ' : (isMr ? 'संदर्भ गंतव्य: ' : 'Referred to: ');
  String get referralReason => isHi ? 'कारण: ' : (isMr ? 'कारण: ' : 'Reason: ');
  String get digitalArrivalPass => isHi ? 'डिजिटल आगमन पास' : (isMr ? 'डिजिटल प्रवेश पास' : 'Digital Arrival Pass');
  String get arrivalPassInstruction => isHi ? 'अस्पताल रिसेप्शन पर त्वरित प्रवेश हेतु यह कोड दिखाएं' : (isMr ? 'रुग्णालय स्वागत कक्षात जलद प्रवेशासाठी हा कोड दाखवा' : 'Show this pass at facility intake for priority queueing');
  String get downloadArrivalPass => isHi ? 'पास डाउनलोड करें' : (isMr ? 'पास डाउनलोड करा' : 'Download pass');

  // --- Patient Profile Screen ---
  String get profileTitle => isHi ? 'मरीज़ प्रोफ़ाइल' : (isMr ? 'रुग्ण प्रोफाइल' : 'Patient Profile');
  String get profileSubtitle => isHi ? 'व्यक्तिगत विवरण, पहुंच और प्राथमिकताएं प्रबंधित करें' : (isMr ? 'वैयक्तिक तपशील, प्रवेश आणि प्राधान्ये व्यवस्थापित करा' : 'Manage personal details, access & preferences');
  String get patientViewBadge => isHi ? 'मरीज़ दृश्य' : (isMr ? 'रुग्ण दृश्य' : 'Patient View');
  String get settingsPreferences => isHi ? 'सेटिंग्स और प्राथमिकताएं' : (isMr ? 'सेटिंग्ज आणि प्राधान्ये' : 'SETTINGS & PREFERENCES');
  String get personalDetailsItem => isHi ? 'व्यक्तिगत विवरण' : (isMr ? 'वैयक्तिक तपशील' : 'Personal Details');
  String get personalDetailsItemSub => isHi ? 'नाम, फोन, आयु, लिंग एवं गांव' : (isMr ? 'नाव, फोन, वय, लिंग आणि गाव' : 'Name, phone, age, gender & village');
  String get langAccessibilityItem => isHi ? 'भाषा और पहुंच' : (isMr ? 'भाषा आणि सुलभता' : 'Language & Accessibility');
  String get langAccessibilityItemSub => isHi ? 'English, हिन्दी, मराठी • टेक्स्ट आकार' : (isMr ? 'English, हिन्दी, मराठी • मजकूर आकार' : 'English, हिन्दी, मराठी • Text size & contrast');
  String get emergencyContactsItem => isHi ? 'आपातकालीन संपर्क' : (isMr ? 'तातडीचे संपर्क' : 'Emergency Contacts');
  String get emergencyContactsItemSub => isHi ? '1 संपर्क कॉन्फ़िगर किया गया' : (isMr ? '१ संपर्क कॉन्फिगर केला' : '1 contact configured');
  String get privacySecurityItem => isHi ? 'गोपनीयता और डेटा पहुंच' : (isMr ? 'गोपनीयता आणि डेटा प्रवेश' : 'Privacy & Data Access');
  String get privacySecurityItemSub => isHi ? 'एबीडीएम सहमति, डॉक्टर पहुंच एवं सुरक्षा' : (isMr ? 'एबीडीएम संमती, डॉक्टर प्रवेश व सुरक्षा' : 'ABDM consent, doctor access & security');
  String get offlineStorageItem => isHi ? 'ऑफलाइन डेटा और सिंक' : (isMr ? 'ऑफलाइन डेटा आणि सिंक' : 'Offline Data & Sync');
  String get offlineStorageItemSub => isHi ? 'स्थानीय एन्क्रिप्टेड स्टोरेज • 14 रिकॉर्ड' : (isMr ? 'स्थानिक एन्क्रिप्टेड स्टोरेज • १४ नोंदी' : 'Local encrypted storage • 14 records');
  String get switchAccountRole => isHi ? 'भूमिका बदलें' : (isMr ? 'भूमिका बदला' : 'Switch Role');
  String get logOut => isHi ? 'लॉग आउट करें' : (isMr ? 'लॉग आउट करा' : 'Log Out');

  // --- Personal Details Screen ---
  String get basicInfoTitle => isHi ? 'मूलभूत जानकारी' : (isMr ? 'मूलभूत माहिती' : 'Basic Information');
  String get fullNameLabel => isHi ? 'पूरा नाम' : (isMr ? 'पूर्ण नाव' : 'Full Name');
  String get registeredMobileLabel => isHi ? 'पंजीकृत मोबाइल' : (isMr ? 'नोंदणीकृत मोबाइल' : 'Registered Mobile');
  String get ageDobLabel => isHi ? 'आयु / जन्म तिथि' : (isMr ? 'वय / जन्मतारीख' : 'Age / DOB');
  String get genderLabel => isHi ? 'लिंग' : (isMr ? 'लिंग' : 'Gender');
  String get female => isHi ? 'महिला' : (isMr ? 'महिला' : 'Female');
  String get male => isHi ? 'पुरुष' : (isMr ? 'पुरुष' : 'Male');
  String get otherGender => isHi ? 'अन्य' : (isMr ? 'इतर' : 'Other');
  String get healthIdTitle => isHi ? 'रूरलकेयर स्वास्थ्य पहचान' : (isMr ? 'रूरलकेअर आरोग्य ओळख' : 'RuralCare Health Identifier');
  String get abdmAbhaId => isHi ? 'एबीडीएम आभा पता' : (isMr ? 'एबीडीएम आभा पत्ता' : 'ABDM ABHA Address');
  String get addressLocationTitle => isHi ? 'पता एवं स्वास्थ्य क्षेत्र' : (isMr ? 'पत्ता आणि आरोग्य क्षेत्र' : 'Address & Healthcare Area');
  String get villageLabel => isHi ? 'गांव' : (isMr ? 'गाव' : 'Village');
  String get subCentreLabel => isHi ? 'उप-केंद्र (आरोग्य मंदिर)' : (isMr ? 'उप-केंद्र (आरोग्य मंदिर)' : 'Sub-Centre');
  String get talukaLabel => isHi ? 'तालुका' : (isMr ? 'तालुका' : 'Taluka');
  String get districtLabel => isHi ? 'जिला' : (isMr ? 'जिल्हा' : 'District');
  String get pincodeLabel => isHi ? 'पिन कोड' : (isMr ? 'पिन कोड' : 'Pincode');
  String get editBasicInfoTitle => isHi ? 'मूल जानकारी संपादित करें' : (isMr ? 'मूलभूत माहिती संपादित करा' : 'Edit Basic Information');
  String get updateDetailsBtn => isHi ? 'विवरण अपडेट करें' : (isMr ? 'तपशील अद्ययावत करा' : 'Update Details');
  String get detailsUpdatedToast => isHi ? 'व्यक्तिगत विवरण सफलतापूर्वक अपडेट किए गए' : (isMr ? 'वैयक्तिक तपशील यशस्वीरित्या अद्ययावत झाले' : 'Personal details updated successfully');

  // --- Privacy & Security Screen ---
  String get privacySecurityTitle => isHi ? 'गोपनीयता और डेटा पहुंच' : (isMr ? 'गोपनीयता आणि डेटा प्रवेश' : 'Privacy & Data Access');
  String get abdmConsentFramework => isHi ? 'एबीडीएम सहमति ढांचा' : (isMr ? 'एबीडीएम संमती चौकट' : 'ABDM Consent Framework');
  String get consentActiveNotice => isHi ? 'आपकी स्वास्थ्य जानकारी पूरी तरह सुरक्षित और एन्क्रिप्टेड है।' : (isMr ? 'तुमची आरोग्य माहिती पूर्णपणे सुरक्षित व एन्क्रिप्टेड आहे.' : 'Your health data is securely encrypted under ABDM standards.');
  String get activeDoctorAccess => isHi ? 'सक्रिय डॉक्टर पहुंच' : (isMr ? 'सक्रिय डॉक्टर प्रवेश' : 'Active Doctor Access');
  String get revokeAccess => isHi ? 'पहुंच हटाएं' : (isMr ? 'प्रवेश रद्द करा' : 'Revoke Access');
  String get emergencyContactDetails => isHi ? 'आपातकालीन संपर्क विवरण' : (isMr ? 'तातडीचे संपर्क तपशील' : 'Emergency Contact Details');
  String get contactFullName => isHi ? 'संपर्क व्यक्ति का नाम' : (isMr ? 'संपर्क व्यक्तीचे नाव' : 'Contact Full Name');
  String get relationshipLabel => isHi ? 'संबंध' : (isMr ? 'नाते' : 'Relationship');
  String get phoneNumberLabel => isHi ? 'फ़ोन नंबर' : (isMr ? 'फोन नंबर' : 'Phone Number');
  String get saveContactBtn => isHi ? 'संपर्क सहेजें' : (isMr ? 'संपर्क जतन करा' : 'Save Contact');
  String get contactSavedToast => isHi ? 'आपातकालीन संपर्क सहेजा गया' : (isMr ? 'तातडीचा संपर्क जतन झाला' : 'Emergency contact saved successfully');

  // --- Teleconsultation Landing Screen ---
  String get teleconsultTitle => isHi ? 'टेलीकंसल्टेशन' : (isMr ? 'टेलिकन्सल्टेशन' : 'Teleconsultation');
  String get chooseSpecialistStep => isHi ? 'विशेषज्ञ डॉक्टर चुनें' : (isMr ? 'तज्ज्ञ डॉक्टर निवडा' : 'Choose Specialist');
  String get consultDetailsStep => isHi ? 'परामर्श विवरण' : (isMr ? 'सल्लामसलत तपशील' : 'Consultation Details');
  String get waitingRoomStep => isHi ? 'प्रतीक्षालय' : (isMr ? 'प्रतीक्षालय' : 'Virtual Waiting Room');
  String get enterLiveCallBtn => isHi ? 'कॉल में प्रवेश करें' : (isMr ? 'कॉलमध्ये प्रवेश करा' : 'Enter Consultation');
  String get enterSymptomsHint => isHi ? 'अपने लक्षण या समस्या यहां लिखें...' : (isMr ? 'तुमची लक्षणे किंवा समस्या येथे लिहा...' : 'Describe your symptoms or health issue...');
  String get doctorAvailable => isHi ? 'उपलब्ध' : (isMr ? 'उपलब्ध' : 'Available');

  // --- Direct Login Screen ---
  String get directSignInTitle => isHi ? 'सीधा प्रवेश / लॉगिन' : (isMr ? 'थेट लॉगिन' : 'Direct Sign In');
  String get accountSignInTitle => isHi ? 'खाता लॉगिन' : (isMr ? 'खाते लॉगिन' : 'Account Sign In');
  String get selectRolePrompt => isHi ? 'अपनी भूमिका चुनें' : (isMr ? 'आपली भूमिका निवडा' : 'Select your profile role');
  String get signInBtn => isHi ? 'लॉगिन करें' : (isMr ? 'लॉगिन करा' : 'Sign In');
  String get mobileOrIdLabel => isHi ? 'मोबाइल नंबर या आईडी' : (isMr ? 'मोबाइल क्रमांक किंवा आयडी' : 'Mobile Number or ID');
  String get passwordOrOtpLabel => isHi ? 'पासवर्ड या ओटीपी' : (isMr ? 'पासवर्ड किंवा ओटीपी' : 'Password or OTP');
  String get enterPasswordHint => isHi ? 'पासवर्ड या 6-अंकीय कोड दर्ज करें' : (isMr ? 'पासवर्ड किंवा ६-अंकी कोड प्रविष्ट करा' : 'Enter password or 6-digit code');
  String get pleaseEnterIdentifier => isHi ? 'कृपया अपनी आईडी या मोबाइल नंबर दर्ज करें।' : (isMr ? 'कृपया आपला आयडी किंवा मोबाइल क्रमांक प्रविष्ट करा.' : 'Please enter your ID or mobile number.');
  String get pleaseEnterPassword => isHi ? 'कृपया अपना पासवर्ड या ओटीपी दर्ज करें।' : (isMr ? 'कृपया आपला पासवर्ड किंवा ओटीपी प्रविष्ट करा.' : 'Please enter your password or OTP.');

  // --- Facility / Referral Status Localizer ---
  String localizeReferralStatus(String status) {
    switch (status.toUpperCase()) {
      case 'CREATED':
        return isHi ? 'रेफरल बनाया गया' : (isMr ? 'संदर्भ नोंदणी झाली' : 'Referral Created');
      case 'SENT':
      case 'DISPATCHED':
        return isHi ? 'प्रेषित' : (isMr ? 'पाठवला' : 'Dispatched');
      case 'ACCEPTED':
        return isHi ? 'स्वीकृत' : (isMr ? 'स्वीकारले' : 'Accepted');
      case 'ADMITTED':
        return isHi ? 'भर्ती' : (isMr ? 'दाखल' : 'Admitted');
      case 'COMPLETED':
      case 'CLOSED':
        return isHi ? 'पूर्ण' : (isMr ? 'पूर्ण' : 'Completed');
      default:
        return status;
    }
  }

  // --- My Medications ---
  String get myMedications => isHi ? 'मेरी दवाइयां' : (isMr ? 'माझी औषधे' : 'My Medications');
  String get activePrescriptions => isHi ? 'सक्रिय नुस्खे' : (isMr ? 'सक्रिय औषधे' : 'Active Prescriptions');
  String get pastMedications => isHi ? 'पिछली दवाएं' : (isMr ? 'मागील औषधे' : 'Past Medications');
  String get noActiveMedications => isHi ? 'कोई सक्रिय दवा निर्धारित नहीं' : (isMr ? 'कोणतीही सक्रिय औषधे नाहीत' : 'No active prescriptions');
  String get noActiveMedicationsSub => isHi ? 'डॉक्टर द्वारा निर्धारित दवाएं यहां स्वचालित रूप से दिखाई देंगी।' : (isMr ? 'डॉक्टरांनी दिलेली औषधे येथे आपोआप दिसतील.' : 'Medications prescribed by doctors will automatically appear here.');
  String get noPastMedications => isHi ? 'कोई पिछला दवा इतिहास नहीं' : (isMr ? 'कोणताही मागील औषध इतिहास नाही' : 'No past medication history');
  String get dosageSchedule => isHi ? 'खुराक कार्यक्रम' : (isMr ? 'डोस वेळापत्रक' : 'Dosage Schedule');
  String get takeAfterFood => isHi ? 'भोजन के बाद पानी के साथ लें' : (isMr ? 'जेवणानंतर पाण्यासोबत घ्या' : 'Take after food with water');
  String get takeBeforeFood => isHi ? 'भोजन से पहले लें' : (isMr ? 'जेवणापूर्वी घ्या' : 'Take before food');
  String get morning => isHi ? 'सुबह' : (isMr ? 'सकाळी' : 'Morning');
  String get afternoon => isHi ? 'दोपहर' : (isMr ? 'दुपारी' : 'Afternoon');
  String get night => isHi ? 'रात' : (isMr ? 'रात्री' : 'Night');
  String get refillReminder => isHi ? 'रीफिल रिमाइंडर' : (isMr ? 'रिफिल स्मरणपत्र' : 'Refill Reminder');
  String get prescribedBy => isHi ? 'निर्धारितकर्ता: ' : (isMr ? 'औषध देणारे: ' : 'Prescribed by: ');
  String get daysRemaining => isHi ? 'दिन शेष' : (isMr ? 'दिवस शिल्लक' : 'days left');

  // --- Arrival Pass ---
  String get fastTrackArrivalPass => isHi ? 'ABDM फास्ट-ट्रैक आगमन पास' : (isMr ? 'ABDM जलद प्रवेश पास' : 'ABDM Fast-Track Arrival Pass');
  String get arrivalPassSub => isHi ? 'तुरंत फास्ट-ट्रैक चेक-इन के लिए अस्पताल रिसेप्शन पर यह डिजिटल टोकन दिखाएं।' : (isMr ? 'त्वरित तपासणीसाठी रुग्णालय स्वागत कक्षात हे डिजिटल टोकन दाखवा.' : 'Present this digital token at the facility reception for immediate fast-track check-in.');
  String get tokenNumber => isHi ? 'कतार टोकन' : (isMr ? 'रांग टोकन' : 'Queue Token');
  String get roomNumber => isHi ? 'परामर्श कक्ष' : (isMr ? 'सल्ला कक्ष' : 'Consultation Room');
  String get scanAtReception => isHi ? 'रिसेप्शन पर स्कैन करें' : (isMr ? 'रिसेप्शनवर स्कॅन करा' : 'Scan at Reception');

  // --- Digital Triage & Appointment Booking ---
  String get symptomsCheck => isHi ? 'प्राथमिक लक्षण (डिजिटल ट्राइएज)' : (isMr ? 'प्राथमिक लक्षणे (डिजिटल ट्रायज)' : 'Primary Symptoms (Digital Triage)');
  String get selectSymptomsHint => isHi ? 'तत्काल चिकित्सकीय प्राथमिकता के लिए अपने लक्षण चुनें' : (isMr ? 'त्वरित वैद्यकीय प्राधान्यासाठी तुमची लक्षणे निवडा' : 'Select your symptoms for clinical prioritization');
  String get fever => isHi ? 'बुखार' : (isMr ? 'ताप' : 'Fever');
  String get cough => isHi ? 'खांसी व जुकाम' : (isMr ? 'खोकला व सर्दी' : 'Cough & Cold');
  String get headacheBp => isHi ? 'सिरदर्द / बीपी' : (isMr ? 'डोकेदुखी / बीपी' : 'Headache / BP');
  String get pregnancy => isHi ? 'गर्भावस्था जांच' : (isMr ? 'गरोदरपण तपासणी' : 'Pregnancy Checkup');
  String get chestPain => isHi ? 'सीने में दर्द' : (isMr ? 'छातीत दुखणे' : 'Chest Pain');
  String get abdominalPain => isHi ? 'पेट दर्द' : (isMr ? 'पोटदुखी' : 'Abdominal Pain');
  String get jointPain => isHi ? 'जोड़ों का दर्द' : (isMr ? 'सांधेदुखी' : 'Joint Pain');
  String get skinRash => isHi ? 'त्वचा पर चकत्ते' : (isMr ? 'त्वचेवर पुरळ' : 'Skin Rash');
  String get triageSeverity => isHi ? 'ट्राइएज प्राथमिकता स्तर' : (isMr ? 'ट्रायज प्राधान्य स्तर' : 'Triage Priority Level');
  String get routineSeverity => isHi ? 'सामान्य ओपीडी देखभाल' : (isMr ? 'नियमित ओपीडी काळजी' : 'Routine OPD Care');
  String get prioritySeverity => isHi ? 'प्राथमिकता चिकित्सकीय समीक्षा' : (isMr ? 'प्राधान्य वैद्यकीय पुनरावलोकन' : 'Priority Clinical Review');
  String get urgentSeverity => isHi ? 'अति-आवश्यक देखभाल प्रोटोकॉल' : (isMr ? 'तातडीची काळजी प्रोटोकॉल' : 'Urgent Care Protocol');
  String get selectFacility => isHi ? 'अस्पताल / स्वास्थ्य केंद्र चुनें' : (isMr ? 'रुग्णालय / आरोग्य केंद्र निवडा' : 'Select Hospital / Facility');
  String get searchDoctorFacility => isHi ? 'डॉक्टर या अस्पताल खोजें...' : (isMr ? 'डॉक्टर किंवा रुग्णालय शोधा...' : 'Search doctors or facilities...');
  String get singleAppointmentError => isHi ? 'इस समय स्लॉट के लिए इस डॉक्टर के साथ आपकी अपॉइंटमेंट पहले से बुक है।' : (isMr ? 'या वेळ स्लॉटसाठी या डॉक्टरांकडे तुमची भेट आधीच बुक केली आहे.' : 'You already have a consultation booked with this doctor for this time slot.');

  // --- Care Plan & Post-Call Refinements ---
  String get saveReport => isHi ? 'रिपोर्ट सहेजें' : (isMr ? 'अहवाल जतन करा' : 'Save Report');
  String get reportSavedSuccess => isHi ? 'चिकित्सकीय परामर्श रिपोर्ट मरीज के रिकॉर्ड में सफलतापूर्वक सहेजी गई।' : (isMr ? 'वैद्यकीय सल्लामसलत अहवाल रुग्णाच्या नोंदीमध्ये यशस्वीरित्या जतन केला गेला.' : 'Clinical consultation report saved successfully to patient record.');
  String get doctorVerified => isHi ? 'डॉक्टर द्वारा सत्यापित' : (isMr ? 'डॉक्टरांद्वारे सत्यापित' : 'Doctor Verified');
  String get prescribedMedsReadOnly => isHi ? 'डॉक्टर द्वारा निर्धारित दवाएं' : (isMr ? 'डॉक्टरांनी दिलेली औषधे' : 'Doctor Prescribed Medications');
  String get orderedLabTests => isHi ? 'डॉक्टर द्वारा अनुशंसित जांच' : (isMr ? 'डॉक्टरांनी शिफारस केलेल्या चाचण्या' : 'Doctor Ordered Diagnostic Tests');
  String get referredFacility => isHi ? 'संदर्भित अस्पताल' : (isMr ? 'संदर्भित रुग्णालय' : 'Referred Facility');
  String get requestFacilityChange => isHi ? 'अस्पताल बदलने का अनुरोध करें' : (isMr ? 'रुग्णालय बदलण्याची विनंती करा' : 'Request Facility Change');
  String get reasonForFacilityChange => isHi ? 'अस्पताल बदलने का कारण' : (isMr ? 'रुग्णालय बदलण्याचे कारण' : 'Reason for Facility Change');
  String get facilityChangeRequested => isHi ? 'अस्पताल बदलाव का अनुरोध डॉक्टर की समीक्षा के लिए भेजा गया।' : (isMr ? 'रुग्णालय बदलण्याची विनंती डॉक्टरांच्या पुनरावलोकनासाठी पाठवली आहे.' : 'Facility change request submitted for doctor review.');
  String get ashaInstructions => isHi ? 'आशा कार्यकर्ता निर्देश' : (isMr ? 'आशा सेविका सूचना' : 'Frontline ASHA Instructions');
  String get addReminderSuccess => isHi ? 'फॉलो-अप निर्धारित हुआ! एसएमएस और व्हाट्सएप अलर्ट भेजा गया।' : (isMr ? 'फॉलो-अप निश्चित झाले! एसएमएस आणि व्हॉट्सअ‍ॅप अलर्ट पाठवला गेला.' : 'Follow-up scheduled! SMS and WhatsApp alerts dispatched.');
  String get downloadSummaryPdf => isHi ? 'सारांश पीडीएफ डाउनलोड करें' : (isMr ? 'सारांश पीडीएफ डाउनलोड करा' : 'Download Summary PDF');
  String get clinicalSummaryTitle => isHi ? 'चिकित्सकीय परामर्श सारांश' : (isMr ? 'वैद्यकीय सल्लामसलत सारांश' : 'Clinical Encounter Summary');
}
