import 'package:ruralcare/app/routes.dart';

/// Centralized localization dictionary for Onboarding and Beneficiary Registration.
/// Supports English, Hindi (हिन्दी), and Marathi (मराठी).
class RegistrationStrings {
  final String langCode;

  RegistrationStrings(this.langCode);

  factory RegistrationStrings.of(SessionCoordinator session) {
    return RegistrationStrings(session.canonicalLanguageCode);
  }

  bool get isHi =>
      langCode == 'hi' ||
      langCode == 'Hindi' ||
      langCode == 'हिन्दी' ||
      langCode == 'हिंदी';
  bool get isMr => langCode == 'mr' || langCode == 'Marathi' || langCode == 'मराठी';
  bool get isEn => !isHi && !isMr;

  // --- Onboarding Navigation & Step Titles ---
  String stepOf(int current, int total) {
    if (isHi) return 'चरण $current / $total';
    if (isMr) return 'टप्पा $current / $total';
    return 'Step $current of $total';
  }

  String get btnContinue => isHi ? 'आगे बढ़ें' : (isMr ? 'पुढे जा' : 'Continue');
  String get btnContinueRole =>
      isHi ? 'चयनित भूमिका के साथ आगे बढ़ें' : (isMr ? 'निवडलेल्या भूमिकेसह पुढे जा' : 'Continue with Selected Role');
  String get alreadyRegisteredSignIn =>
      isHi
          ? 'पहले से पंजीकृत हैं? साइन इन करें'
          : (isMr ? 'आधीच नोंदणीकृत? लॉगिन करा' : 'Already registered? Sign In');

  // --- Onboarding Step 0: Welcome ---
  String get welcomeTitle =>
      isHi ? 'रूरलकेयर में आपका स्वागत है' : (isMr ? 'रूरलकेअर मध्ये आपले स्वागत आहे' : 'Welcome to RuralCare');
  String get welcomeSubtitle =>
      isHi ? 'ग्रामीण स्वास्थ्य निरंतरता एवं समन्वय मंच' : (isMr ? 'ग्रामीण आरोग्य निरंतरता व समन्वय मंच' : 'Rural Health Continuity & Coordination Platform');
  String get welcomeDesc =>
      isHi
          ? 'ग्रामीण परिवारों, फ्रंटलाइन आशा कार्यकर्ताओं और विशेषज्ञ अस्पतालों को एक समन्वित स्वास्थ्य प्रणाली में जोड़ना।'
          : (isMr
              ? 'ग्रामीण कुटुंबे, आशा सेविका आणि तज्ज्ञ रुग्णालयांना एकाच समन्वित आरोग्य साखळीत जोडणारा डिजिटल मंच.'
              : 'Connecting rural families, frontline ASHA health workers, and specialist hospitals into a single coordinated continuum of care.');

  String get pillar1Title => isHi ? 'स्वास्थ्य निरंतरता' : (isMr ? 'आरोग्य निरंतरता' : 'Continuum of Care');
  String get pillar1Desc =>
      isHi
          ? 'नागरिक से आशा और उप-जिला अस्पताल तक एकीकृत स्वास्थ्य रिकॉर्ड'
          : (isMr ? 'नागरिकांपासून आशा व उपजिल्हा रुग्णालयापर्यंत अखंड आरोग्य नोंदी' : 'Unified health records from citizen to ASHA and district hospitals');

  String get pillar2Title => isHi ? 'ऑफ़लाइन-रेडी सिंक' : (isMr ? 'ऑफलाइन-रेडी सिंक' : 'Offline-Ready Sync');
  String get pillar2Desc =>
      isHi
          ? 'इंटरनेट न होने पर भी सभी रिकॉर्ड सुरक्षित, नेटवर्क आने पर ऑटो-सिंक'
          : (isMr ? 'नेटवर्क नसतानाही नोंदी सुरक्षित, नेटवर्क येताच स्वयंचलित सिंक' : 'Secure offline records with zero data loss in low-connectivity areas');

  String get pillar3Title => isHi ? 'स्मार्ट रेफरल व 108' : (isMr ? 'स्मार्ट संदर्भ व १०८' : 'Smart Referral & 108');
  String get pillar3Desc =>
      isHi
          ? 'अस्पताल बेड की त्वरित तैयारी और 108 एम्बुलेंस प्री-अलर्ट'
          : (isMr ? 'रुग्णालय खाटांची पूर्व-तयारी आणि १०८ रुग्णवाहिका अलर्ट' : 'Instant hospital bed readiness and 108 ambulance triage alert');

  // --- Onboarding Step 1: Language ---
  String get chooseLanguageTitle =>
      isHi ? 'अपनी भाषा चुनें' : (isMr ? 'आपली भाषा निवडा' : 'Choose your language');
  String get chooseLanguageSubtitle =>
      isHi ? 'भाषा निवडा / Choose Language' : (isMr ? 'भाषा चुनें / Choose Language' : 'भाषा चुनें / भाषा निवडा');
  String get chooseLanguageDesc =>
      isHi
          ? 'परामर्श, जांच रिपोर्ट और अलर्ट के लिए अपनी पसंदीदा भाषा का चयन करें।'
          : (isMr
              ? 'सल्लामसलत, तपासणी अहवाल आणि सूचनांसाठी आपली प्राधान्य भाषा निवडा.'
              : 'Select your preferred interface language for consultations, reports, and alerts.');

  // --- Onboarding Step 2: Role Selection ---
  String get selectRoleTitle =>
      isHi ? 'अपनी भूमिका चुनें' : (isMr ? 'आपली भूमिका निवडा' : 'Select your profile role');
  String get selectRoleSubtitle =>
      isHi ? 'अपनी कार्यप्रणाली चुनें' : (isMr ? 'आपली कार्यप्रणाली निवडा' : 'Role-based healthcare workspace');
  String get selectRoleDesc =>
      isHi
          ? 'प्रत्येक उपयोगकर्ता भूमिका आपकी आवश्यकताओं के अनुसार विशेष कार्यक्षेत्र प्रदान करती है।'
          : (isMr
              ? 'प्रत्येक भूमिका आपल्या गरजेनुसार सानुकूल वैद्यकीय कार्यक्षेत्र प्रदान करते.'
              : 'Each user role provides custom clinical workspaces tailored to your needs.');

  String get rolePatientTitle => isHi ? 'मरीज़ / परिवार (नागरिक)' : (isMr ? 'रुग्ण / कुटुंब (नागरिक)' : 'Patient / Family (Citizen)');
  String get rolePatientDesc =>
      isHi
          ? 'अपॉइंटमेंट बुक करें, जांच रिपोर्ट देखें, दवा उपलब्धता और टेलीकंसल्टेशन।'
          : (isMr
              ? 'अपॉइंटमेंट बुक करा, तपासणी अहवाल, औषध उपलब्धता आणि टेलीसल्ला.'
              : 'Book appointments, view test reports, medicine availability, and teleconsult.');

  String get roleDoctorTitle => isHi ? 'चिकित्सा अधिकारी / डॉक्टर' : (isMr ? 'वैद्यकीय अधिकारी / डॉक्टर' : 'Medical Officer / Doctor');
  String get roleDoctorDesc =>
      isHi
          ? 'ओपीडी कतार, ई-नुस्खे, रेफरल प्रबंधन और टेलीकंसल्टेशन समीक्षा।'
          : (isMr
              ? 'ओपीडी रांग, ई-औषधोपचार, संदर्भ व्यवस्थापन आणि टेलीसल्ला.'
              : 'Review clinical queue, issue prescriptions, manage referrals & teleconsult.');

  String get roleHwTitle => isHi ? 'आशा / स्वास्थ्य कार्यकर्ता' : (isMr ? 'आशा / आरोग्य सेविका' : 'ASHA / Health Worker');
  String get roleHwDesc =>
      isHi
          ? 'लाभार्थी पंजीकरण, वाइटल्स संग्रह, डिजिटल ट्राइएज और एएनसी फॉलो-अप।'
          : (isMr
              ? 'लाभार्थी नोंदणी, मापदंड नोंद, डिजिटल ट्रायज आणि एएनसी पाठपुरावा.'
              : 'Register beneficiaries, record vitals, digital triage, and follow up ANC.');

  String get roleFacilityTitle => isHi ? 'अस्पताल कर्मचारी' : (isMr ? 'रुग्णालय कर्मचारी' : 'Facility Staff / Hospital');
  String get roleFacilityDesc =>
      isHi
          ? 'बेड उपलब्धता, क्यूआर रेफरल डेस्क और डॉक्टर सत्यापन।'
          : (isMr ? 'खाटा उपलब्धता, क्यूआर संदर्भ कक्ष आणि डॉक्टर पडताळणी.' : 'Bed capacity, QR referral intake desk, live stock & approvals.');

  String get roleAdminTitle => isHi ? 'जिला स्वास्थ्य प्रशासन' : (isMr ? 'जिल्हा आरोग्य प्रशासन' : 'District Health Admin');
  String get roleAdminDesc =>
      isHi
          ? 'जिला स्वास्थ्य विश्लेषण, सुविधा रजिस्ट्री और अनुपालन ऑडिट।'
          : (isMr ? 'जिल्हा आरोग्य विश्लेषण, सुविधा नोंदणी आणि ऑडिट.' : 'District health analytics, facility registry, and compliance audit.');

  // --- Patient Registration Step Titles (1 to 5) ---
  String regStepTitle(int step) {
    switch (step) {
      case 0:
        return isHi ? 'मोबाइल सत्यापन (चरण 1/5)' : (isMr ? 'मोबाइल पडताळणी (टप्पा 1/5)' : 'Mobile Verification (Step 1/5)');
      case 1:
        return isHi ? 'ओटीपी प्रमाणीकरण (चरण 2/5)' : (isMr ? 'ओटीपी प्रमाणीकरण (टप्पा 2/5)' : 'OTP Authentication (Step 2/5)');
      case 2:
        return isHi ? 'लाभार्थी प्रोफ़ाइल (चरण 3/5)' : (isMr ? 'लाभार्थी प्रोफाइल (टप्पा 3/5)' : 'Beneficiary Profile (Step 3/5)');
      case 3:
        return isHi ? 'स्वास्थ्य क्षेत्र व उप-केंद्र (चरण 4/5)' : (isMr ? 'आरोग्य क्षेत्र व उप-केंद्र (टप्पा 4/5)' : 'Healthcare Area (Step 4/5)');
      case 4:
        return isHi ? 'रूरलकेयर स्वास्थ्य आईडी (चरण 5/5)' : (isMr ? 'रूरलकेअर आरोग्य आयडी (टप्पा 5/5)' : 'RuralCare Health ID (Step 5/5)');
      default:
        return isHi ? 'मरीज़ पंजीकरण' : (isMr ? 'रुग्ण नोंदणी' : 'Patient Registration');
    }
  }

  // --- Registration Step 0: Mobile ---
  String get mobileHeader => isHi ? 'मोबाइल नंबर दर्ज करें' : (isMr ? 'मोबाइल नंबर प्रविष्ट करा' : 'Enter Mobile Number');
  String get mobileSubheader =>
      isHi ? 'स्वास्थ्य रिकॉर्ड एक्सेस के लिए अपना 10-अंकीय नंबर दर्ज करें' : (isMr ? 'आरोग्य नोंदींसाठी आपला १०-अंकी नंबर प्रविष्ट करा' : 'Enter your 10-digit number for health record access');
  String get mobileExplanation =>
      isHi
          ? 'हम आपके स्वास्थ्य रिकॉर्ड तक सुरक्षित पहुंच सत्यापित करने के लिए एसएमएस के माध्यम से 6-अंकीय कोड भेजेंगे।'
          : (isMr
              ? 'आम्ही आपल्या आरोग्य नोंदींच्या सुरक्षिततेसाठी एसएमएसद्वारे ६-अंकी कोड पाठवू.'
              : 'We will send a 6-digit authentication code via SMS to verify your healthcare record access.');
  String get mobileFieldLabel => isHi ? 'फ़ोन नंबर' : (isMr ? 'फोन नंबर' : 'Phone Number');
  String get mobileFieldHint => isHi ? '10-अंकीय मोबाइल नंबर' : (isMr ? '१०-अंकी मोबाइल नंबर' : 'Enter 10-digit mobile number');
  String get btnSendOtp => isHi ? 'सत्यापन कोड (ओटीपी) भेजें' : (isMr ? 'पडताळणी कोड (ओटीपी) पाठवा' : 'Send Verification Code (OTP)');
  String get errInvalidMobile =>
      isHi ? 'अमान्य प्रविष्टि: मोबाइल नंबर ठीक 10 अंकों का होना चाहिए।' : (isMr ? 'अवैध नोंद: मोबाइल क्रमांक नेमका १० अंकांचा असणे आवश्यक आहे.' : 'Invalid entry: Mobile number must be exactly 10 digits.');
  String get errInvalidMobileExact10 => errInvalidMobile;

  // --- Registration Step 1: OTP ---
  String get otpHeader => isHi ? '6-अंकीय ओटीपी दर्ज करें' : (isMr ? '६-अंकी ओटीपी प्रविष्ट करा' : 'Enter 6-Digit OTP');
  String otpSentTo(String phone) => isHi ? '+91 $phone पर भेजा गया' : (isMr ? '+91 $phone वर पाठवला' : 'Sent to +91 $phone');
  String get otpFieldHint => '------';
  String get otpHelperText =>
      isHi ? 'आपके फोन पर प्राप्त 6 अंक दर्ज करें' : (isMr ? 'आपल्या फोनवर आलेले ६ अंक प्रविष्ट करा' : 'Enter 6 digits sent to your phone');
  String get btnVerifyOtp => isHi ? 'सत्यापित करें और आगे बढ़ें' : (isMr ? 'पडताळणी करा आणि पुढे जा' : 'Verify & Continue');
  String get errInvalidOtp =>
      isHi ? 'अमान्य प्रविष्टि: ओटीपी ठीक 6 अंकों का होना चाहिए।' : (isMr ? 'अवैध नोंद: ओटीपी नेमका ६ अंकांचा असणे आवश्यक आहे.' : 'Invalid entry: OTP must be exactly 6 digits.');
  String get errInvalidOtpExact6 => errInvalidOtp;
  String get errOtpMismatch =>
      isHi ? 'अमान्य ओटीपी: दर्ज किया गया ओटीपी प्राप्त कोड से मेल नहीं खाता।' : (isMr ? 'अवैध ओटीपी: प्रविष्ट केलेला ओटीपी प्राप्त कोडशी जुळत नाही.' : 'Invalid OTP: The entered OTP does not match the received verification code.');
  String simulatedSmsPill(String otp) =>
      isHi ? 'एसएमएस प्राप्त: आपका सत्यापन कोड $otp है' : (isMr ? 'एसएमएस प्राप्त: आपला पडताळणी कोड $otp आहे' : 'SMS received: Your verification code is $otp');

  // --- Registration Step 2: Demographics & DOB ---
  String get profileHeader => isHi ? 'लाभार्थी प्रोफ़ाइल' : (isMr ? 'लाभार्थी प्रोफाइल' : 'Beneficiary Profile');
  String get profileSubheader =>
      isHi
          ? 'अपने आधार या आधिकारिक राशन कार्ड के अनुसार विवरण दर्ज करें।'
          : (isMr ? 'आपल्या आधार किंवा अधिकृत रेशन कार्डनुसार तपशील भरा.' : 'Enter your details as per your Aadhaar or official ration card.');
  String get fullNameLabel => isHi ? 'पूरा कानूनी नाम' : (isMr ? 'पूर्ण कायदेशीर नाव' : 'Full Legal Name');
  String get fullNameHint => isHi ? 'पूरा नाम दर्ज करें (जैसे: रमेश कुमार)' : (isMr ? 'पूर्ण नाव प्रविष्ट करा (उदा: रमेश कुमार)' : 'Enter full name (e.g. Ramesh Kumar)');
  String get dobLabel => isHi ? 'जन्म तिथि (DOB)' : (isMr ? 'जन्मतारीख (DOB)' : 'Date of Birth (DOB)');
  String get dobHint => isHi ? 'दिन / माह / वर्ष चुनें' : (isMr ? 'दिवस / महिना / वर्ष निवडा' : 'Select DD / MM / YYYY');
  String ageDisplay(int years) => isHi ? 'आयु: $years वर्ष' : (isMr ? 'वय: $years वर्षे' : 'Calculated Age: $years years');
  String get genderLabel => isHi ? 'लिंग' : (isMr ? 'लिंग' : 'Gender');
  String get genderSelectHint => isHi ? 'लिंग चुनें' : (isMr ? 'लिंग निवडा' : 'Select Gender');
  String get genderFemale => isHi ? 'महिला' : (isMr ? 'महिला' : 'Female');
  String get genderMale => isHi ? 'पुरुष' : (isMr ? 'पुरुष' : 'Male');
  String get genderOther => isHi ? 'अन्य' : (isMr ? 'इतर' : 'Other');
  String get btnProceedLocation => isHi ? 'स्थान और क्षेत्र पर आगे बढ़ें' : (isMr ? 'स्थान व क्षेत्रावर पुढे जा' : 'Proceed to Location & Area');
  String get errMissingDemographics =>
      isHi ? 'कृपया पूरा नाम, जन्म तिथि और लिंग चुनें।' : (isMr ? 'कृपया पूर्ण नाव, जन्मतारीख आणि लिंग निवडा.' : 'Please enter beneficiary full name, select Date of Birth, and gender.');
  String get errInvalidName =>
      isHi ? 'अमान्य प्रविष्टि: नाम में केवल अक्षर और रिक्त स्थान होने चाहिए।' : (isMr ? 'अवैध नोंद: नावामध्ये फक्त अक्षरे असावीत.' : 'Invalid entry: Name must contain only letters and spaces.');

  // --- Registration Step 3: Location & Sub-Centre Dropdown ---
  String get locationHeader => isHi ? 'स्वास्थ्य क्षेत्र और निवास' : (isMr ? 'आरोग्य क्षेत्र व निवास' : 'Healthcare Area & Residence');
  String get locationSubheader =>
      isHi
          ? 'यह आपके रिकॉर्ड को आपके स्थानीय उप-केंद्र और आशा कार्यकर्ता से जोड़ता है।'
          : (isMr ? 'हे आपल्या नोंदींना स्थानिक उप-केंद्र आणि आशा सेविकेशी जोडते.' : 'This links your record to your local Sub-Centre and designated ASHA worker.');
  String get subCentreLabel => isHi ? 'निकटतम उप-केंद्र (हेल्थ सेंटर)' : (isMr ? 'जवळचे उप-केंद्र (आरोग्य केंद्र)' : 'Nearest Sub-Centre (Health Centre)');
  String get subCentreSelectHint => isHi ? 'अपना उप-केंद्र चुनें' : (isMr ? 'आपले उप-केंद्र निवडा' : 'Select your Sub-Centre');
  String get districtLabel => isHi ? 'जिला' : (isMr ? 'जिल्हा' : 'District');
  String get districtHint => isHi ? 'जिले का नाम दर्ज करें' : (isMr ? 'जिल्ह्याचे नाव प्रविष्ट करा' : 'Enter district name');
  String get talukaLabel => isHi ? 'तालुका / ब्लॉक' : (isMr ? 'तालुका / ब्लॉक' : 'Taluka / Block');
  String get talukaHint => isHi ? 'तालुका या ब्लॉक दर्ज करें' : (isMr ? 'तालुका किंवा ब्लॉक प्रविष्ट करा' : 'Enter block / taluka');
  String get villageLabel => isHi ? 'गाँव / क्षेत्र' : (isMr ? 'गाव / क्षेत्र' : 'Village / Area');
  String get villageHint => isHi ? 'गाँव का नाम दर्ज करें' : (isMr ? 'गावाचे नाव प्रविष्ट करा' : 'Enter village name');
  String get pincodeLabel => isHi ? 'पिनकोड' : (isMr ? 'पिनकोड' : 'Pincode');
  String get pincodeHint => isHi ? '6-अंकीय पिनकोड दर्ज करें' : (isMr ? '६-अंकी पिनकोड प्रविष्ट करा' : 'Enter 6-digit pincode');
  String get btnGenerateHealthId => isHi ? 'रूरलकेयर स्वास्थ्य आईडी बनाएं' : (isMr ? 'रूरलकेअर आरोग्य आयडी तयार करा' : 'Generate RuralCare Health ID');
  String get errMissingLocation =>
      isHi
          ? 'कृपया उप-केंद्र, गाँव और 6-अंकीय पिनकोड दर्ज करें।'
          : (isMr ? 'कृपया उप-केंद्र, गाव आणि ६-अंकी पिनकोड प्रविष्ट करा.' : 'Please select your Sub-Centre and enter village and 6-digit pincode.');
  String get errInvalidPincode =>
      isHi ? 'अमान्य प्रविष्टि: पिनकोड ठीक 6 अंकों का होना चाहिए।' : (isMr ? 'अवैध नोंद: पिनकोड नेमका ६ अंकांचा असणे आवश्यक आहे.' : 'Invalid entry: Pincode must be exactly 6 digits.');
  String get errInvalidVillage =>
      isHi ? 'अमान्य प्रविष्टि: कृपया मान्य गाँव का नाम दर्ज करें।' : (isMr ? 'अवैध नोंद: कृपया वैध गावाचे नाव प्रविष्ट करा.' : 'Invalid entry: Please enter a valid village name.');
  String get errInvalidTaluka =>
      isHi ? 'अमान्य प्रविष्टि: कृपया मान्य तालुका दर्ज करें।' : (isMr ? 'अवैध नोंद: कृपया वैध तालुका प्रविष्ट करा.' : 'Invalid entry: Please enter a valid taluka.');
  String get errInvalidDistrict =>
      isHi ? 'अमान्य प्रविष्टि: कृपया मान्य जिला दर्ज करें।' : (isMr ? 'अवैध नोंद: कृपया वैध जिल्हा प्रविष्ट करा.' : 'Invalid entry: Please enter a valid district.');

  // --- Registration Step 4: Health ID Card ---
  String get idCardTitle => isHi ? 'रूरलकेयर नागरिक स्वास्थ्य आईडी' : (isMr ? 'रूरलकेअर नागरिक आरोग्य आयडी' : 'RuralCare Citizen Health ID');
  String get statusActive => isHi ? 'सक्रिय' : (isMr ? 'सक्रिय' : 'ACTIVE');
  String get abhaNumberLabel => isHi ? 'आभा नंबर' : (isMr ? 'आभा नंबर' : 'ABHA Number');
  String get linkedSubCentreLabel => isHi ? 'संबद्ध उप-केंद्र' : (isMr ? 'जोडलेले उप-केंद्र' : 'Linked Sub-Centre');
  String get assignedAshaLabel => isHi ? 'नियुक्त आशा कार्यकर्ता' : (isMr ? 'नियुक्त आशा सेविका' : 'Assigned ASHA Worker');
  String get abdmNotice =>
      isHi
          ? 'यह डिजिटल स्वास्थ्य आईडी आयुष्मान भारत डिजिटल मिशन (ABDM) मानकों के अनुरूप है। आपका रिकॉर्ड सुरक्षित एवं ऑफ़लाइन उपलब्ध है।'
          : (isMr
              ? 'हे डिजिटल आरोग्य आयडी आयुष्यमान भारत डिजिटल मिशन (ABDM) मानकांशी सुसंगत आहे. आपल्या नोंदी सुरक्षित आणि ऑफलाइन उपलब्ध आहेत.'
              : 'This digital health ID complies with Ayushman Bharat Digital Mission (ABDM) standards. Your records are securely cached offline.');
  String get btnEnterDashboard => isHi ? 'मरीज़ डैशबोर्ड में प्रवेश करें' : (isMr ? 'रुग्ण डॅशबोर्डवर जा' : 'Enter Patient Dashboard');
}
