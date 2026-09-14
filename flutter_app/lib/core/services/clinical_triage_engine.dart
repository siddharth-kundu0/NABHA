import 'dart:math';
import 'package:ruralcare/data/models/triage_dto.dart';

class CategoryQuestion {
  final String id;
  final String textEn;
  final String textHi;
  final String textMr;
  final bool isRedFlag; // If true and answered YES, triggers P0 Red
  final String clinicalRationale;

  const CategoryQuestion({
    required this.id,
    required this.textEn,
    required this.textHi,
    required this.textMr,
    required this.isRedFlag,
    required this.clinicalRationale,
  });
}

class ClinicalTriageEngine {
  static final ClinicalTriageEngine _instance = ClinicalTriageEngine._internal();
  factory ClinicalTriageEngine() => _instance;
  ClinicalTriageEngine._internal();

  /// 31 Fine-Grained Anatomical Regions in Plain Everyday Language across Anterior and Posterior views
  final List<AnatomicalRegionDto> _anatomicalRegions = [
    // 1. HEAD & SENSES (Anterior)
    const AnatomicalRegionDto(
      id: 'forehead_right',
      nameEn: 'Right Forehead & Temple',
      nameHi: 'माथे का दायाँ हिस्सा और कनपटी',
      nameMr: 'कपाळाची उजवी बाजू व कानशीला',
      systemType: 'Head & Brain',
      systemTypeHi: 'सिर और दिमाग',
      systemTypeMr: 'डोके व मेंदू',
      view: AnatomicalView.anterior,
      normalizedX: 0.58,
      normalizedY: 0.08,
      commonSymptoms: [
        'Throbbing headache on right side',
        'Face feeling weak or droopy on right side',
        'Blurry vision or flashing lights in right eye',
        'Tender swelling on temple / side of forehead',
      ],
      commonSymptomsHi: [
        'दाहिनी तरफ तेज सिरदर्द या माइग्रेन',
        'चेहरे के दाएँ हिस्से में कमजोरी या सुन्नपन',
        'दाहिनी आँख के आगे चमक या धुंधलापन',
        'माथे की नस में छूने पर तेज दर्द',
      ],
      commonSymptomsMr: [
        'उजव्या बाजूला तीव्र डोकेदुखी',
        'चेहऱ्याच्या उजव्या बाजूला अशक्तपणा किंवा वाकडेपणा',
        'उजव्या डोळ्यासमोर चमक किंवा अंधुक दिसणे',
        'कपाळाच्या उजव्या बाजूला ठसठसणे व सूज',
      ],
      isHighRisk: true,
      emergencyProtocol: EmergencyProtocol(
        diagnosisName: 'Brain Stroke Danger (FAST Alert)',
        diagnosisNameHi: 'लकवा / ब्रेन स्ट्रोक का खतरा',
        diagnosisNameMr: 'अर्धांगवायू / पक्षाघाताचा तीव्र धोका',
        warningMessage: 'Sudden face droop, weak arm, or slurred speech can be a stroke. Reach a hospital immediately.',
        warningMessageHi: 'चेहरा टेढ़ा होना, हाथ में कमजोरी या बोलने में लड़खड़ाहट लकवा (स्ट्रोक) हो सकता है। तुरंत अस्पताल पहुँचें।',
        warningMessageMr: 'तोंड वाकडे होणे, हातात ताकद न राहणे किंवा बोलणे अडखळणे हा पक्षाघाताचा झटका असू शकतो. त्वरित रुग्णालयात जा.',
        hospitalAction: '108 Emergency Stroke Ambulance Dispatch',
        hospitalActionHi: '108 एम्बुलेंस और तुरंत अस्पताल',
        hospitalActionMr: '१०८ रुग्णवाहिका व तातडीची मदत',
        targetFacilityType: 'District Hospital Stroke Unit',
        targetFacilityTypeHi: 'जिला अस्पताल स्ट्रोक यूनिट',
        targetFacilityTypeMr: 'जिल्हा रुग्णालय स्ट्रोक विभाग',
      ),
    ),
    const AnatomicalRegionDto(
      id: 'forehead_left',
      nameEn: 'Left Forehead & Temple',
      nameHi: 'माथे का बायाँ हिस्सा और कनपटी',
      nameMr: 'कपाळाची डावी बाजू व कानशीला',
      systemType: 'Head & Brain',
      systemTypeHi: 'सिर और दिमाग',
      systemTypeMr: 'डोके व मेंदू',
      view: AnatomicalView.anterior,
      normalizedX: 0.42,
      normalizedY: 0.08,
      commonSymptoms: [
        'Severe throbbing headache on left side',
        'Face numbness or weakness on left side',
        'Eye pain with sensitivity to light',
        'Heavy head and nausea',
      ],
      commonSymptomsHi: [
        'बाएँ तरफ गंभीर सिरदर्द',
        'चेहरे के बाएँ हिस्से में सुन्नपन या कमजोरी',
        'रोशनी से परेशानी और आँख में दर्द',
        'सिर भारी होना और उल्टी जैसा लगना',
      ],
      commonSymptomsMr: [
        'डाव्या बाजूला तीव्र डोकेदुखी',
        'चेहऱ्याच्या डाव्या बाजूला बधीरपणा किंवा अशक्तपणा',
        'प्रकाशाचा त्रास आणि डोळ्यात वेदना',
        'डोके जड होणे व मळमळणे',
      ],
      isHighRisk: true,
      emergencyProtocol: EmergencyProtocol(
        diagnosisName: 'Brain Stroke Danger (FAST Alert)',
        diagnosisNameHi: 'लकवा / ब्रेन स्ट्रोक का खतरा',
        diagnosisNameMr: 'अर्धांगवायू / पक्षाघाताचा तीव्र धोका',
        warningMessage: 'Sudden severe left-sided headache with weakness or visual changes needs immediate emergency care.',
        warningMessageHi: 'बाएँ सिर में अचानक तेज दर्द के साथ कमजोरी या नजर में बदलाव होना आपातकाल है। तुरंत जांच कराएं।',
        warningMessageMr: 'डाव्या डोक्यात अचानक तीव्र वेदना आणि अशक्तपणा असल्यास त्वरित आपत्कालीन तपासणी आवश्यक आहे.',
        hospitalAction: '108 Emergency Stroke Ambulance Dispatch',
        hospitalActionHi: '108 एम्बुलेंस और तुरंत अस्पताल',
        hospitalActionMr: '१०८ रुग्णवाहिका व तातडीची मदत',
        targetFacilityType: 'District Hospital Stroke Unit',
        targetFacilityTypeHi: 'जिला अस्पताल स्ट्रोक यूनिट',
        targetFacilityTypeMr: 'जिल्हा रुग्णालय स्ट्रोक विभाग',
      ),
    ),
    const AnatomicalRegionDto(
      id: 'eyes_orbit',
      nameEn: 'Eyes & Sight',
      nameHi: 'आँखें और नज़र',
      nameMr: 'डोळे व दृष्टी',
      systemType: 'Eyes & Vision',
      systemTypeHi: 'आँखें और रोशनी',
      systemTypeMr: 'डोळे व दृष्टी',
      view: AnatomicalView.anterior,
      normalizedX: 0.50,
      normalizedY: 0.11,
      commonSymptoms: [
        'Sudden loss of vision in one eye',
        'Red, painful and watery eye',
        'Seeing colored circles around lights',
        'Double vision or dark spots',
      ],
      commonSymptomsHi: [
        'अचानक एक आँख से दिखाई देना बंद होना',
        'आँख लाल होना, तेज दर्द और पानी आना',
        'रोशनी के चारों ओर रंगीन घेरे दिखना',
        'एक की जगह दो चीजें दिखना (डबल विज़न)',
      ],
      commonSymptomsMr: [
        'एका डोळ्याने अचानक दिसणे बंद होणे',
        'डोळा लाल होणे, तीव्र वेदना व पाणी येणे',
        'दिव्याभोवती रंगीत कडे दिसणे',
        'एकाऐवजी दोन वस्तू दिसणे (दुहेरी दृष्टी)',
      ],
      isHighRisk: true,
      emergencyProtocol: EmergencyProtocol(
        diagnosisName: 'Sudden Eye Crisis / Vision Danger',
        diagnosisNameHi: 'आँख की रोशनी का आपातकाल (ग्लूकोमा/अंधापन खतरा)',
        diagnosisNameMr: 'दृष्टी गमावण्याचा धोका (काचबिंदू / नेत्र आणीबाणी)',
        warningMessage: 'Sudden loss of sight or severe eye pain with redness requires immediate eye doctor attention to save vision.',
        warningMessageHi: 'अचानक नजर जाना या तेज दर्द के साथ आँख लाल होना दृष्टि के लिए बड़ा खतरा है। तुरंत नेत्र विशेषज्ञ के पास जाएं।',
        warningMessageMr: 'अचानक दृष्टी जाणे किंवा लाल डोळ्यासह तीव्र वेदना झाल्यास दृष्टी वाचवण्यासाठी त्वरित नेत्रतज्ज्ञांकडे जा.',
        hospitalAction: 'Emergency Eye Clinic Transfer',
        hospitalActionHi: 'आपातकालीन नेत्र अस्पताल ले जाएं',
        hospitalActionMr: 'तातडीने नेत्र रुग्णालयात दाखल करा',
        targetFacilityType: 'Speciality Eye Centre / District Hospital',
      ),
    ),
    const AnatomicalRegionDto(
      id: 'nose_sinus',
      nameEn: 'Nose & Sinus',
      nameHi: 'नाक और सर्दी-जुकाम',
      nameMr: 'नाक व सायनस',
      systemType: 'Nose & Breathing',
      systemTypeHi: 'नाक और सांस',
      systemTypeMr: 'नाक व श्वसन',
      view: AnatomicalView.anterior,
      normalizedX: 0.50,
      normalizedY: 0.13,
      commonSymptoms: [
        'Heavy nose bleed that will not stop',
        'Heavy pressure and pain around cheeks and forehead',
        'Thick yellow-green mucus with fever',
        'Loss of smell and blocked nose',
      ],
      commonSymptomsHi: [
        'नाक से लगातार खून बहना (नकसीर)',
        'गाल और माथे पर भारी दबाव व दर्द',
        'बुखार के साथ गाढ़ा पीला-हरा कफ',
        'सूंघने की क्षमता जाना और बंद नाक',
      ],
      commonSymptomsMr: [
        'नाकातून सतत रक्त येणे (घोळणा फुटणे)',
        'गालावर व कपाळावर तीव्र दाब व वेदना',
        'तापासह घट्ट पिवळा-हिरवा शेंबूड',
        'वास न येणे व नाक बंद होणे',
      ],
      emergencyProtocol: EmergencyProtocol(
        diagnosisName: 'Heavy Nose Bleeding / Deep Sinus Infection',
        diagnosisNameHi: 'नाक से अत्यधिक रक्तस्राव (नकसीर खतरा)',
        diagnosisNameMr: 'नाकातून अति तीव्र रक्तस्त्राव',
        warningMessage: 'Continuous nose bleeding that does not stop after pressing for 10 minutes needs urgent hospital care.',
        warningMessageHi: '10 मिनट दबाने के बाद भी नाक से खून बंद न होना कमजोरी ला सकता है। तुरंत अस्पताल में पट्टी कराएं।',
        warningMessageMr: '१० मिनिटे नाक दाबून धरल्यानंतरही रक्त थांबत नसल्यास त्वरित रुग्णालयात जाऊन उपचार घ्या.',
        hospitalAction: 'Emergency Bleeding Stop Care',
        hospitalActionHi: 'आपातकालीन रक्तस्राव रोकथाम',
        hospitalActionMr: 'तातडीचे रक्तस्त्राव नियंत्रण',
        targetFacilityType: 'Sub-District Hospital / CHC',
      ),
    ),
    const AnatomicalRegionDto(
      id: 'mouth_jaw',
      nameEn: 'Jaw & Mouth',
      nameHi: 'जबड़ा और मुँह',
      nameMr: 'जबडा व तोंड',
      systemType: 'Teeth & Mouth',
      systemTypeHi: 'दाँत और मुँह',
      systemTypeMr: 'दात व तोंड',
      view: AnatomicalView.anterior,
      normalizedX: 0.50,
      normalizedY: 0.16,
      commonSymptoms: [
        'Severe pain in jaw spreading from chest',
        'Swelling under chin making it hard to swallow',
        'Severe toothache with pus swelling',
        'Unable to open mouth properly',
      ],
      commonSymptomsHi: [
        'सीने से जबड़े तक उठता तेज दर्द',
        'ठोड़ी के नीचे सूजन जिससे निगलना मुश्किल हो',
        'मसूड़े में तेज दर्द और मवाद',
        'मुँह खोलने में असमर्थता',
      ],
      commonSymptomsMr: [
        'छातीतून जबड्याकडे येणाऱ्या तीव्र वेदना',
        'हनुवटीखाली सूज ज्यामुळे गिळणे कठीण होते',
        'दातातील तीव्र ठसठस व पू होणे',
        'तोंड उघडता न येणे',
      ],
      isHighRisk: true,
      emergencyProtocol: EmergencyProtocol(
        diagnosisName: 'Throat Swelling Danger / Heart Attack Warning',
        diagnosisNameHi: 'गले की खतरनाक सूजन / दिल के दौरे का संकेत',
        diagnosisNameMr: 'घशातील गंभीर सूज / हृदयविकाराचा इशारा',
        warningMessage: 'Pain spreading to jaw or deep swelling under chin blocking breathing is an emergency.',
        warningMessageHi: 'जबड़े में उठता दर्द दिल के दौरे का लक्षण हो सकता है, और ठोड़ी के नीचे सूजन से सांस रुक सकती है।',
        warningMessageMr: 'जबड्यात पसरणाऱ्या वेदना हृदयविकाराचे लक्षण असू शकतात आणि गळ्याखालील सुजेने श्वास कोंडू शकतो.',
        hospitalAction: '108 Airway Protection & Cardiac ECG Screening',
        hospitalActionHi: 'आपातकालीन सांस व दिल की जांच',
        hospitalActionMr: 'तातडीची श्वसन व हृदय तपासणी',
        targetFacilityType: 'District Hospital Surgical / ICU Unit',
      ),
    ),

    // 2. NECK & AIRWAY
    const AnatomicalRegionDto(
      id: 'throat_airway',
      nameEn: 'Throat & Voice Pipe',
      nameHi: 'गला और सांस की नली',
      nameMr: 'घसा व श्वसन नलिका',
      systemType: 'Throat & Breathing',
      systemTypeHi: 'गला और सांस',
      systemTypeMr: 'घसा व श्वसन',
      view: AnatomicalView.anterior,
      normalizedX: 0.50,
      normalizedY: 0.20,
      commonSymptoms: [
        'Whistling sound while breathing in (Stridor)',
        'Unable to swallow even water or saliva',
        'Throat swelling after allergy or bee sting',
        'Choking sensation and barking cough',
      ],
      commonSymptomsHi: [
        'सांस अंदर लेते समय सीटी जैसी आवाज आना',
        'पानी या थूक भी न निगल पाना (लार टपकना)',
        'एलर्जी या कीड़े के काटने के बाद गला सूजना',
        'दम घुटना और भौंकने जैसी खांसी',
      ],
      commonSymptomsMr: [
        'श्वास घेताना शिट्टीसारखा किंवा घरघर आवाज येणे',
        'पाणी किंवा लाळही गिळता न येणे',
        'अ‍ॅलर्जी किंवा कीटक चावल्यामुळे घसा सुजणे',
        'श्वास गुदमरणे व कोरडा खोकला',
      ],
      isHighRisk: true,
      emergencyProtocol: EmergencyProtocol(
        diagnosisName: 'Severe Throat Blockage / Choking Danger',
        diagnosisNameHi: 'सांस की नली में रुकावट (दम घुटने का खतरा)',
        diagnosisNameMr: 'श्वसन नलिकेत अडथळा (श्वास गुदमरण्याचा धोका)',
        warningMessage: 'Breathing with a loud whistling noise or inability to swallow saliva means the windpipe is swelling shut. Call 108 immediately.',
        warningMessageHi: 'सांस लेते समय सीटी की आवाज आना या थूक न निगल पाना सांस की नली बंद होने का संकेत है। तुरंत 108 बुलाएं।',
        warningMessageMr: 'श्वास घेताना घरघर आवाज येणे किंवा लाळही न गिळता येणे म्हणजे श्वसन नलिका बंद होण्याचा धोका आहे. १०८ त्वरित बोलवा.',
        hospitalAction: '108 Emergency Oxygen & Airway Rescue',
        hospitalActionHi: '108 आपातकालीन ऑक्सीजन सहायता',
        hospitalActionMr: '१०८ आपत्कालीन ऑक्सिजन व श्वसन मदत',
        targetFacilityType: 'District Hospital Trauma & Emergency Department',
      ),
    ),
    const AnatomicalRegionDto(
      id: 'cervical_spine_back',
      nameEn: 'Back of Neck',
      nameHi: 'गर्दन का पिछला हिस्सा',
      nameMr: 'मानेची मागची बाजू',
      systemType: 'Neck & Spine',
      systemTypeHi: 'गर्दन और रीढ़',
      systemTypeMr: 'मान व मणका',
      view: AnatomicalView.posterior,
      normalizedX: 0.50,
      normalizedY: 0.18,
      commonSymptoms: [
        'Stiff neck with high fever (Cannot touch chin to chest)',
        'Sharp pain shooting down from neck into arms',
        'Neck pain after fall or accident with weakness',
        'Severe muscle spasm and unable to turn head',
      ],
      commonSymptomsHi: [
        'तेज बुखार के साथ गर्दन में अकड़न (ठोड़ी सीने से न लगना)',
        'गर्दन से दोनों हाथों तक बिजली जैसा तेज दर्द दौड़ना',
        'दुर्घटना या गिरने के बाद गर्दन में दर्द और कमजोरी',
        'गर्दन में तेज खिंचाव और सिर घुमाने में लाचारी',
      ],
      commonSymptomsMr: [
        'तीव्र तापासह मान ताठरणे (हनुवटी छातीला न टेकणे)',
        'मानेतून दोन्ही हातांकडे विजेसारख्या कळा येणे',
        'अपघातानंतर मानेत तीव्र वेदना व अशक्तपणा',
        'मानेचे स्नायू आखडणे व मान हलवता न येणे',
      ],
      isHighRisk: true,
      emergencyProtocol: EmergencyProtocol(
        diagnosisName: 'Neck Stiffness Danger (Meningitis / Spine Trauma)',
        diagnosisNameHi: 'गर्दन अकड़ना व दिमागी बुखार का खतरा (मेनिन्जाइटिस)',
        diagnosisNameMr: 'मान ताठरणे व मेंदूज्वराचा गंभीर धोका (मेनिंजायटिस)',
        warningMessage: 'Stiff neck with high fever can be brain fever (meningitis). After an accident, keep neck completely still.',
        warningMessageHi: 'तेज बुखार के साथ गर्दन अकड़ना दिमागी बुखार (मेनिन्जाइटिस) हो सकता है। चोट लगने पर गर्दन बिल्कुल न हिलाएं।',
        warningMessageMr: 'तीव्र तापासह मान ताठरणे हा मेंदूज्वर असू शकतो. अपघातानंतर मान अजिबात हलवू नका.',
        hospitalAction: 'Emergency Spinal Immobilization & Lumbar Puncture Intake',
        hospitalActionHi: 'आपातकालीन गर्दन सुरक्षा व भर्ती',
        hospitalActionMr: 'तातडीने मान स्थिर ठेवणे व दाखल करणे',
        targetFacilityType: 'District Hospital Trauma / Neuro Ward',
      ),
    ),

    // 3. CHEST & CARDIAC
    const AnatomicalRegionDto(
      id: 'chest_precordium',
      nameEn: 'Heart & Chest Area',
      nameHi: 'सीना और दिल का हिस्सा',
      nameMr: 'छाती व हृदयाचा भाग',
      systemType: 'Heart & Circulation',
      systemTypeHi: 'दिल और रक्तसंचार',
      systemTypeMr: 'हृदय व रक्तप्रवाह',
      view: AnatomicalView.anterior,
      normalizedX: 0.44,
      normalizedY: 0.28,
      commonSymptoms: [
        'Heavy crushing pain or tightness in center of chest',
        'Pain spreading to left arm, shoulder, or jaw',
        'Cold sweating with sudden dizziness',
        'Fast pounding heartbeat with weakness',
        'Extreme shortness of breath while resting',
      ],
      commonSymptomsHi: [
        'सीने में भारी पत्थर जैसा भारीपन या निचोड़ने वाला दर्द',
        'दर्द का बाएँ हाथ, कंधे या जबड़े में फैलना',
        'अचानक ठंडा पसीना और चक्कर आना',
        'दिल की धड़कन तेज होना और कमजोरी',
        'बैठे-बैठे भी सांस फूलना',
      ],
      commonSymptomsMr: [
        'छातीवर प्रचंड दगड ठेवल्यासारखा दाब किंवा आवळल्यासारखी वेदना',
        'वेदना डाव्या हाताकडे, खांद्याकडे किंवा जबड्याकडे पसरणे',
        'अचानक थंड घाम सुटणे व चक्कर येणे',
        'हृदयाचे ठोके खूप जलद पडणे व अशक्तपणा',
        'बसल्या जागीही तीव्र धाप लागणे',
      ],
      isHighRisk: true,
      emergencyProtocol: EmergencyProtocol(
        diagnosisName: 'Severe Heart Attack Risk (Cardiac STEMI)',
        diagnosisNameHi: 'गंभीर दिल का दौरा (हार्ट अटैक का खतरा)',
        diagnosisNameMr: 'तीव्र हृदयविकाराचा झटका (हार्ट अटॅकचा धोका)',
        warningMessage: 'Heavy chest tightness with cold sweating or pain spreading to the left arm is a Heart Attack sign. Call 108 immediately.',
        warningMessageHi: 'सीने में भारीपन के साथ ठंडा पसीना आना या बाएँ हाथ में दर्द फैलना दिल का दौरा (हार्ट अटैक) हो सकता है। तुरंत 108 एम्बुलेंस बुलाएं।',
        warningMessageMr: 'छातीवर दाब, थंड घाम सुटणे किंवा डाव्या हातात वेदना पसरणे हे हृदयविकाराच्या झटक्याचे लक्षण असू शकते. विलंब न करता १०८ रुग्णवाहिका बोलवा.',
        hospitalAction: '108 Cardiac ALS Ambulance Dispatch',
        hospitalActionHi: '108 कार्डियक एम्बुलेंस तत्काल बुलाएं',
        hospitalActionMr: '१०८ कार्डियाक रुग्णवाहिका त्वरित बोलवा',
        targetFacilityType: 'Baramati SDH / District Hospital Cardiac Care Unit',
        targetFacilityTypeHi: 'जिला अस्पताल हृदय रोग आईसीयू',
        targetFacilityTypeMr: 'जिल्हा रुग्णालय हृदयविकार विभाग',
      ),
    ),
    const AnatomicalRegionDto(
      id: 'chest_right_lung',
      nameEn: 'Right Chest & Breathing',
      nameHi: 'दायाँ सीना और फेफड़ा',
      nameMr: 'उजवी छाती व फुफ्फुस',
      systemType: 'Lungs & Breathing',
      systemTypeHi: 'फेफड़े और सांस',
      systemTypeMr: 'फुफ्फुस व श्वसन',
      view: AnatomicalView.anterior,
      normalizedX: 0.56,
      normalizedY: 0.28,
      commonSymptoms: [
        'Sharp chest pain when taking a deep breath',
        'Coughing up blood or rust-colored phlegm',
        'Severe fast breathing and oxygen drop',
        'High fever with chest congestion',
      ],
      commonSymptomsHi: [
        'गहरी सांस लेने पर सीने में कांटे जैसा चुभता दर्द',
        'खांसी में खून या भूरा कफ आना',
        'बहुत तेज सांस चलना और घबराहट',
        'तेज बुखार और सीने में जकड़न',
      ],
      commonSymptomsMr: [
        'दीर्घ श्वास घेताना छातीत तीक्ष्ण टोचल्यासारखी वेदना',
        'खोकल्यातून रक्त किंवा काळपट कफ पडणे',
        'खूप जलद श्वास चालणे व ऑक्सिजन कमी होणे',
        'तीव्र ताप आणि छातीत घरघर',
      ],
      isHighRisk: true,
      emergencyProtocol: EmergencyProtocol(
        diagnosisName: 'Lung Air Leak / Blood Clot in Lungs',
        diagnosisNameHi: 'फेफड़े में हवा का रिसाव या खून का थक्का',
        diagnosisNameMr: 'फुफ्फुसात हवा भरणे किंवा रक्ताची गुठळी',
        warningMessage: 'Sudden sharp chest pain with extreme breathlessness and blue lips needs emergency hospital oxygen care.',
        warningMessageHi: 'गहरी सांस पर तेज दर्द के साथ सांस फूलना और होंठ नीले पड़ना फेफड़े का आपातकाल है। तुरंत अस्पताल ले जाएं।',
        warningMessageMr: 'श्वास घेताना छातीत तीव्र वेदना, दम लागणे आणि ओठ निळे पडणे हे फुफ्फुसाचे गंभीर संकट आहे. तातडीने ऑक्सिजन उपचारांची गरज आहे.',
        hospitalAction: '108 Emergency Oxygen Therapy & Rapid Chest Drainage Protocol',
        hospitalActionHi: '108 आपातकालीन ऑक्सीजन सहायता',
        hospitalActionMr: '१०८ आपत्कालीन ऑक्सिजन व छाती उपचार',
        targetFacilityType: 'Community / District Hospital Respiratory ICU',
      ),
    ),
    const AnatomicalRegionDto(
      id: 'upper_back_thoracic',
      nameEn: 'Upper Back',
      nameHi: 'पीठ का ऊपरी हिस्सा',
      nameMr: 'पाठीचा वरचा भाग',
      systemType: 'Back & Spine',
      systemTypeHi: 'पीठ और रीढ़',
      systemTypeMr: 'पाठ व मणका',
      view: AnatomicalView.posterior,
      normalizedX: 0.50,
      normalizedY: 0.29,
      commonSymptoms: [
        'Sudden tearing pain between shoulder blades',
        'Backbone tender to touch after a fall',
        'Severe muscle catch between shoulders',
        'Pain worsens on taking deep breath',
      ],
      commonSymptomsHi: [
        'दोनों कंधों के बीच अचानक चीरने जैसा तेज दर्द',
        'गिरने के बाद रीढ़ की हड्डी पर छूने से दर्द',
        'कंधों के बीच तेज जकड़न व नस खिंचना',
        'गहरी सांस लेने पर पीठ में दर्द बढ़ना',
      ],
      commonSymptomsMr: [
        'दोन्ही खांद्यांच्या मध्ये अचानक फाडल्यासारखी तीव्र वेदना',
        'पडल्यानंतर पाठीच्या मणक्याला हात लावल्यास कळा',
        'खांद्यांमधील स्नायू आखडणे व कळा येणे',
        'दीर्घ श्वास घेतल्यावर पाठीत वेदना वाढणे',
      ],
      isHighRisk: true,
      emergencyProtocol: EmergencyProtocol(
        diagnosisName: 'Tearing Back Pain / Spine Damage',
        diagnosisNameHi: 'पीठ में चीरने जैसा दर्द / रीढ़ की चोट',
        diagnosisNameMr: 'पाठीत तीव्र फाडल्यासारखी वेदना / मणक्याची दुखापत',
        warningMessage: 'Sudden tearing pain between shoulder blades radiating to back requires immediate emergency vascular check.',
        warningMessageHi: 'कंधों के बीच चीरने जैसा दर्द रक्तनली फटने का बड़ा खतरा हो सकता है। तुरंत बड़े अस्पताल जाएं।',
        warningMessageMr: 'खांद्यांच्या मध्ये फाडल्यासारखी तीव्र वेदना मुख्य रक्तवाहिनीच्या धोक्याचे लक्षण असू शकते. त्वरित तज्ज्ञ डॉक्टरांकडे जा.',
        hospitalAction: '108 Emergency Vascular Surgery Alert',
        hospitalActionHi: '108 आपातकालीन संवहनी अलर्ट',
        hospitalActionMr: '१०८ आपत्कालीन रक्तवाहिनी अलर्ट',
        targetFacilityType: 'Tertiary Medical College / District Hospital',
      ),
    ),

    // 4. SHOULDERS & ARMS
    const AnatomicalRegionDto(
      id: 'shoulder_right',
      nameEn: 'Right Shoulder',
      nameHi: 'दायाँ कंधा',
      nameMr: 'उजवा खांदा',
      systemType: 'Shoulders & Bones',
      systemTypeHi: 'कंधा और जोड़',
      systemTypeMr: 'खांदा व सांधे',
      view: AnatomicalView.anterior,
      normalizedX: 0.68,
      normalizedY: 0.25,
      commonSymptoms: [
        'Unable to lift or move right arm',
        'Shoulder bone popped out / visible deformity',
        'Collarbone broken with clicking sound',
        'Aching shoulder pain spreading from liver area',
      ],
      commonSymptomsHi: [
        'दाहिना हाथ ऊपर उठाने में असमर्थता',
        'कंधे की हड्डी खिसकना या टेढ़ी दिखना',
        'हंसली (कॉलरबोन) में चटकने जैसी आवाज व दर्द',
        'लिवर/पेट के हिस्से से कंधे तक फैलता दर्द',
      ],
      commonSymptomsMr: [
        'उजवा हात वर उचलण्यास किंवा हलवण्यास असमर्थता',
        'खांद्याचे हाड निखळणे किंवा वाकडे दिसणे',
        'गळ्याच्या हाडात (कॉलरबोन) कडकड आवाज व वेदना',
        'पोटातील समस्येमुळे खांद्यात उठणाऱ्या कळा',
      ],
      emergencyProtocol: EmergencyProtocol(
        diagnosisName: 'Shoulder Dislocation / Liver Pain Spread',
        diagnosisNameHi: 'कंधा खिसकना / पित्त या लिवर का दर्द',
        diagnosisNameMr: 'खांदा निखळणे / यकृत वेदना प्रसार',
        warningMessage: 'Dislocated joint needs gentle medical reset; pain spreading to right shoulder can also indicate a liver problem.',
        warningMessageHi: 'खिसके हुए कंधे को डॉक्टर से बिठवाएं; कंधे का दर्द लिवर में गड़बड़ी का भी संकेत हो सकता है।',
        warningMessageMr: 'निखळलेला खांदा डॉक्टरांकडून बसवून घ्यावा; उजव्या खांद्यातील वेदना यकृताच्या विकाराशीही संबंधित असू शकते.',
        hospitalAction: 'Emergency X-ray & Orthopedic Reduction',
        hospitalActionHi: 'आपातकालीन एक्स-रे और हड्डी जांच',
        hospitalActionMr: 'तातडीचे एक्स-रे व सांधा तपासणी',
        targetFacilityType: 'Sub-District Hospital Orthopedic Wing',
      ),
    ),
    const AnatomicalRegionDto(
      id: 'shoulder_left',
      nameEn: 'Left Shoulder',
      nameHi: 'बायाँ कंधा',
      nameMr: 'डावा खांदा',
      systemType: 'Shoulders & Heart Spread',
      systemTypeHi: 'कंधा और दिल का फैलाव',
      systemTypeMr: 'खांदा व हृदय प्रसार',
      view: AnatomicalView.anterior,
      normalizedX: 0.32,
      normalizedY: 0.25,
      commonSymptoms: [
        'Aching in left shoulder spreading from chest',
        'Shoulder dislocated and cannot move',
        'Collarbone fracture post-fall',
        'Severe night pain in shoulder joint',
      ],
      commonSymptomsHi: [
        'सीने से बाएँ कंधे की तरफ फैलता दर्द',
        'कंधा खिसकना और बिल्कुल न हिल पाना',
        'गिरने के बाद हंसली की हड्डी टूटना',
        'रात को कंधे के जोड़ में असहनीय दर्द',
      ],
      commonSymptomsMr: [
        'छातीतून डाव्या खांद्याकडे पसरणाऱ्या वेदना',
        'खांदा निखळणे व अजिबात हालचाल न होणे',
        'पडल्यानंतर गळ्याचे हाड फ्रॅक्चर होणे',
        'रात्रीच्या वेळी खांद्याच्या सांध्यात तीव्र वेदना',
      ],
      isHighRisk: true,
      emergencyProtocol: EmergencyProtocol(
        diagnosisName: 'Left Shoulder Pain Spread (Heart Angina Alert)',
        diagnosisNameHi: 'बाएँ कंधे का दर्द (दिल के दौरे की चेतावनी)',
        diagnosisNameMr: 'डाव्या खांद्यातील वेदना (हार्ट अटॅकची पूर्वसूचना)',
        warningMessage: 'Unexplained left shoulder ache without injury must be checked for heart problems with an immediate ECG.',
        warningMessageHi: 'बिना किसी चोट के बाएँ कंधे में दर्द होना दिल की बीमारी का संकेत हो सकता है। तुरंत ईसीजी कराएं।',
        warningMessageMr: 'कोणतीही दुखापत नसताना डाव्या खांद्यात अचानक वेदना झाल्यास त्वरित ईसीजी (ECG) करून घेणे गरजेचे आहे.',
        hospitalAction: '108 Immediate ECG & Cardiac Triage Protocol',
        hospitalActionHi: '108 ईसीजी जांच और दिल की सुरक्षा',
        hospitalActionMr: '१०८ त्वरित ईसीजी व हृदय तपासणी',
        targetFacilityType: 'Primary / Sub-District Health Centre',
      ),
    ),
    const AnatomicalRegionDto(
      id: 'elbow_hand_right',
      nameEn: 'Right Arm & Hand',
      nameHi: 'दायाँ हाथ और पंजा',
      nameMr: 'उजवा हात व पाऊल',
      systemType: 'Arms & Hands',
      systemTypeHi: 'हाथ और बाजू',
      systemTypeMr: 'हात व पंजे',
      view: AnatomicalView.anterior,
      normalizedX: 0.76,
      normalizedY: 0.48,
      commonSymptoms: [
        'Arm or wrist bent out of shape (Bone fracture)',
        'Deep bleeding cut or machine crush injury',
        'Severe burns or chemical contact on hand',
        'Tingling and numbness in fingers',
      ],
      commonSymptomsHi: [
        'हाथ या कलाई की हड्डी टूटना या टेढ़ी होना',
        'गहरा घाव, कटने से भारी खून बहना या दबना',
        'हाथ पर तेज जलन या आग से झुलसना',
        'उंगलियों में झनझनाहट और सुन्नपन',
      ],
      commonSymptomsMr: [
        'हात किंवा मनगटाचे हाड मोडणे किंवा वाकडे होणे',
        'खोल जखम, रक्तस्त्राव किंवा हातावर वजन पडणे',
        'हात भाजणे किंवा रासायनिक पदार्थाने जळजळ',
        'बोटांमध्ये मुंग्या येणे व बधीरपणा',
      ],
      emergencyProtocol: EmergencyProtocol(
        diagnosisName: 'Arm Bone Fracture / Deep Bleeding Wound',
        diagnosisNameHi: 'हाथ की हड्डी टूटना / गहरा घाव और रक्तस्राव',
        diagnosisNameMr: 'हाताचे हाड फ्रॅक्चर / खोल जखम व रक्तस्त्राव',
        warningMessage: 'Swollen tight arm with excruciating pain when moving fingers needs urgent bone setting and splinting.',
        warningMessageHi: 'हाथ में तेज सूजन और उंगलियां हिलाने पर बहुत दर्द होना हड्डी टूटने का संकेत है। तुरंत प्लास्टर या पट्टी कराएं।',
        warningMessageMr: 'हाताला तीव्र सूज व बोटे हलवताना असह्य वेदना होत असल्यास हाड मोडले असू शकते. त्वरित मलमपट्टी व प्लास्टर आवश्यक आहे.',
        hospitalAction: 'Emergency Orthopedic Decompression & Splinting',
        hospitalActionHi: 'आपातकालीन हड्डी जोड़ व प्लास्टर',
        hospitalActionMr: 'तातडीचे हाड जोडणी व प्लास्टर',
        targetFacilityType: 'Sub-District Hospital Orthopedic Unit',
      ),
    ),
    const AnatomicalRegionDto(
      id: 'elbow_hand_left',
      nameEn: 'Left Arm & Hand',
      nameHi: 'बायाँ हाथ और पंजा',
      nameMr: 'डावा हात व पाऊल',
      systemType: 'Arms & Heart Spread',
      systemTypeHi: 'हाथ और दिल का फैलाव',
      systemTypeMr: 'हात व हृदय प्रसार',
      view: AnatomicalView.anterior,
      normalizedX: 0.24,
      normalizedY: 0.48,
      commonSymptoms: [
        'Left arm heavy, numb and aching from chest',
        'Left arm bone fracture or deformity',
        'Deep cut on wrist with heavy bleeding',
        'Cold, pale fingers with weak pulse',
      ],
      commonSymptomsHi: [
        'सीने से बाएँ हाथ में भारीपन, सुन्नपन और दर्द',
        'बाएँ हाथ की हड्डी टूटना या मुड़ना',
        'कलाई पर गहरा कट और खून बहना',
        'उंगलियां ठंडी, सफेद पड़ना और नाड़ी न मिलना',
      ],
      commonSymptomsMr: [
        'छातीतून डाव्या हातामध्ये जडपणा, बधीरता व कळा',
        'डाव्या हाताचे हाड मोडणे किंवा वाकडे होणे',
        'मनगटावर खोल जखम होऊन सतत रक्त वाहणे',
        'बोटे गार पडणे, पांढरी होणे व नाडी न लागणे',
      ],
      emergencyProtocol: EmergencyProtocol(
        diagnosisName: 'Heart Attack Arm Spread / Artery Injury',
        diagnosisNameHi: 'दिल के दौरे का बाएँ हाथ में फैलाव / नस कटना',
        diagnosisNameMr: 'हार्ट अटॅकचा डाव्या हातात प्रसार / रक्तवाहिनी दुखापत',
        warningMessage: 'Numbness or heaviness spreading down the left arm with chest discomfort is a cardiac sign.',
        warningMessageHi: 'सीने में परेशानी के साथ बाएँ हाथ में भारीपन और सुन्नपन दिल के दौरे का प्रमुख संकेत है।',
        warningMessageMr: 'छातीत अस्वस्थतेसह डाव्या हातात जडपणा व बधीरपणा येणे हे हृदयविकाराचे प्रमुख लक्षण असू शकते.',
        hospitalAction: 'Emergency Hemostatic Control & Vascular Intake',
        hospitalActionHi: 'आपातकालीन नस जांच व खून रोकना',
        hospitalActionMr: 'तातडीचे रक्तस्त्राव नियंत्रण व तपासणी',
        targetFacilityType: 'District Hospital Trauma & Surgical Wing',
      ),
    ),

    // 5. STOMACH & BELLY
    const AnatomicalRegionDto(
      id: 'abdomen_epigastrium',
      nameEn: 'Upper Stomach',
      nameHi: 'पेट का ऊपरी हिस्सा',
      nameMr: 'पोटाचा वरचा भाग',
      systemType: 'Stomach & Digestion',
      systemTypeHi: 'पेट और पाचन',
      systemTypeMr: 'पोट व पचन',
      view: AnatomicalView.anterior,
      normalizedX: 0.50,
      normalizedY: 0.37,
      commonSymptoms: [
        'Sudden unbearable pain in upper belly spreading to back',
        'Belly feels hard like a wooden board',
        'Vomiting blood or coffee-colored fluid',
        'Constant severe burning unaffected by antacids',
      ],
      commonSymptomsHi: [
        'पेट के ऊपरी हिस्से में अचानक असहनीय दर्द जो पीठ तक जाए',
        'पेट पत्थर की तरह सख्त (कड़ा) हो जाना',
        'उल्टी में खून या गहरे रंग का पदार्थ आना',
        'दवा लेने के बाद भी लगातार तेज जलन व दर्द',
      ],
      commonSymptomsMr: [
        'पोटाच्या वरच्या भागात अचानक असह्य वेदना ज्या पाठीत जातात',
        'पोट लाकडासारखे एकदम ताठर किंवा कडक होणे',
        'उलटीतून रक्त किंवा काळपट द्रव पडणे',
        'गोळी घेऊनही कमी न होणारी तीव्र जळजळ व आग',
      ],
      isHighRisk: true,
      emergencyProtocol: EmergencyProtocol(
        diagnosisName: 'Severe Stomach Perforation / Pancreas Emergency',
        diagnosisNameHi: 'पेट में छेद या गंभीर पैनक्रियाज दर्द',
        diagnosisNameMr: 'पोटात छिद्र किंवा स्वादुपिंडाचा तीव्र संसर्ग',
        warningMessage: 'A rock-hard belly with sudden severe pain can mean a perforated ulcer. Do not eat or drink anything; reach hospital immediately.',
        warningMessageHi: 'पेट पत्थर जैसा सख्त होना और तेज दर्द पेट में छाला फटने का संकेत है। मरीज को कुछ भी खिलाएं-पिलाएं नहीं, तुरंत सर्जरी अस्पताल ले जाएं।',
        warningMessageMr: 'पोट दगडासारखे ताठर होणे व असह्य वेदना हे पोटात अल्सर फुटल्याचे लक्षण असू शकते. काहीही खाऊ-पिऊ घालू नका, त्वरित शस्त्रक्रिया विभागात दाखल करा.',
        hospitalAction: '108 Surgical Acute Abdomen Transfer (IV Fluids & Surgical Consult)',
        hospitalActionHi: '108 सर्जिकल एम्बुलेंस और तुरंत अस्पताल',
        hospitalActionMr: '१०८ सर्जिकल रुग्णवाहिका व तातडीची शस्त्रक्रिया',
        targetFacilityType: 'Baramati SDH / District Hospital Surgical Ward',
      ),
    ),
    const AnatomicalRegionDto(
      id: 'abdomen_ruq',
      nameEn: 'Upper Right Belly / Liver',
      nameHi: 'पेट का दायाँ ऊपरी हिस्सा',
      nameMr: 'पोटाची उजवी वरची बाजू',
      systemType: 'Liver & Gallbladder',
      systemTypeHi: 'यकृत और पित्ताशय',
      systemTypeMr: 'यकृत व पित्ताशय',
      view: AnatomicalView.anterior,
      normalizedX: 0.58,
      normalizedY: 0.38,
      commonSymptoms: [
        'Severe pain under right ribs spreading to right shoulder',
        'Yellow eyes, yellow skin, and dark yellow urine (Jaundice)',
        'High fever with intense shivering / chills',
        'Nausea and pain after eating fatty oily food',
      ],
      commonSymptomsHi: [
        'दाहिनी पसलियों के नीचे तेज दर्द जो कंधे तक जाए',
        'आँखें व त्वचा पीली पड़ना और गहरा पीला पेशाब (पीलिया)',
        'कंपकंपी के साथ बहुत तेज बुखार आना',
        'तला-भुना खाने के बाद पेट में तेज मरोड़ व उल्टी',
      ],
      commonSymptomsMr: [
        'उजव्या बरगड्यांखाली असह्य वेदना ज्या खांद्याकडे जातात',
        'डोळे व त्वचा पिवळी होणे आणि गर्द पिवळी लघवी (कावीळ)',
        'थंडी वाजून खूप तीव्र ताप भरणे',
        'तळलेले/तेलकट खाल्ल्यानंतर पोटात तीव्र कळा व मळमळ',
      ],
      isHighRisk: true,
      emergencyProtocol: EmergencyProtocol(
        diagnosisName: 'Severe Gallbladder / Liver Infection (Jaundice Danger)',
        diagnosisNameHi: 'पित्ताशय की थैली या लिवर का गंभीर संक्रमण (पीलिया खतरा)',
        diagnosisNameMr: 'पित्ताशय किंवा यकृताचा तीव्र संसर्ग (कावीळ आणीबाणी)',
        warningMessage: 'Right-sided upper belly pain with high fever and yellow eyes indicates an infected bile duct or liver infection.',
        warningMessageHi: 'पेट के दाएँ हिस्से में दर्द के साथ पीलिया और तेज बुखार पित्त की नली में रुकावट का संकेत है। तुरंत अस्पताल दिखाएं।',
        warningMessageMr: 'उजव्या पोटात वेदनेसह कावीळ व तीव्र ताप असणे हे पित्तनलिकेत अडथळा किंवा जंतुसंसर्गाचे लक्षण आहे. त्वरित उपचार घ्या.',
        hospitalAction: 'Emergency Sepsis Protocol & Biliary Decompression Alert',
        hospitalActionHi: 'आपातकालीन लिवर व पित्त उपचार',
        hospitalActionMr: 'तातडीचे यकृत व पित्ताशय उपचार',
        targetFacilityType: 'District Hospital Surgical & GI Unit',
      ),
    ),
    const AnatomicalRegionDto(
      id: 'abdomen_rlq',
      nameEn: 'Lower Right Belly / Appendix',
      nameHi: 'पेट का निचला दायाँ हिस्सा (अपेंडिक्स)',
      nameMr: 'पोटाची उजवी खालची बाजू (अपेंडिक्स)',
      systemType: 'Lower Belly & Appendix',
      systemTypeHi: 'निचला पेट व अपेंडिक्स',
      systemTypeMr: 'खालचे पोट व अपेंडिक्स',
      view: AnatomicalView.anterior,
      normalizedX: 0.56,
      normalizedY: 0.48,
      commonSymptoms: [
        'Sharp pain starting near navel then moving to lower right belly',
        'Excruciating pain when pressing lower right side and letting go quickly',
        'Cannot walk straight or jump due to sharp belly pain',
        'Fever, loss of appetite, and vomiting',
      ],
      commonSymptomsHi: [
        'दर्द पहले नाभि के पास शुरू होकर नीचे दाएँ हिस्से में बैठना',
        'निचले दाएँ पेट को दबाकर अचानक छोड़ने पर तेज दर्द होना',
        'पेट दर्द की वजह से सीधा खड़ा न हो पाना या लंगड़ाना',
        'बुखार, भूख बिल्कुल न लगना और बार-बार उल्टी',
      ],
      commonSymptomsMr: [
        'वेदना आधी बेंबीजवळ सुरू होऊन नंतर उजव्या बाजूला खाली स्थिरावणे',
        'उजव्या खालच्या पोटावर दाब देऊन पटकन हात काढल्यास असह्य कळ',
        'पोटदुखीमुळे सरळ उभे न राहता येणे किंवा वाकून चालणे',
        'ताप, भूक अजिबात मंदावणे आणि उलट्या होणे',
      ],
      isHighRisk: true,
      emergencyProtocol: EmergencyProtocol(
        diagnosisName: 'Severe Appendicitis (Burst Risk)',
        diagnosisNameHi: 'अपेंडिक्स का गंभीर संक्रमण (फटने का जोखिम)',
        diagnosisNameMr: 'अपेंडिक्सचा तीव्र संसर्ग (फुटण्याचा धोका)',
        warningMessage: 'Severe lower right belly pain that hurts on touching or coughing is an Appendix infection. Delay can cause it to burst; see a surgeon immediately.',
        warningMessageHi: 'पेट के निचले दाएँ हिस्से में तेज दर्द अपेंडिक्स का संक्रमण है। देरी करने पर यह फट सकता है। तुरंत सर्जन के पास जाएं।',
        warningMessageMr: 'उजव्या खालच्या पोटात असह्य वेदना अपेंडिक्स सुजल्याचे लक्षण आहे. विलंब झाल्यास ते फुटू शकते. त्वरित सर्जनचा सल्ला घ्या.',
        hospitalAction: 'Immediate 108 Emergency Surgical Transfer for Appendectomy',
        hospitalActionHi: '108 आपातकालीन सर्जरी एम्बुलेंस',
        hospitalActionMr: '१०८ तातडीची शस्त्रक्रिया रुग्णवाहिका',
        targetFacilityType: 'Baramati Sub-District Hospital Surgical Theatre',
      ),
    ),
    const AnatomicalRegionDto(
      id: 'abdomen_umbilicus',
      nameEn: 'Navel & Mid-Belly',
      nameHi: 'नाभि और बीच का पेट',
      nameMr: 'बेंबी व मध्य पोट',
      systemType: 'Belly & Bowels',
      systemTypeHi: 'पेट और आंतें',
      systemTypeMr: 'पोट व आतडे',
      view: AnatomicalView.anterior,
      normalizedX: 0.50,
      normalizedY: 0.44,
      commonSymptoms: [
        'Severe cramping stomach pains with big bloated belly',
        'Unable to pass any gas or stool for over 2 days',
        'Vomiting green or foul-smelling dark liquid',
        'Painful bulge at navel that cannot be pushed in (Hernia)',
      ],
      commonSymptomsHi: [
        'पेट में तेज मरोड़ और पेट बहुत ज्यादा फूल जाना',
        '2 दिन से ज्यादा समय से गैस या शौच बिल्कुल न निकलना',
        'हरे या बदबूदार गहरे रंग की उल्टी होना',
        'नाभि पर दर्द भरी गांठ जो अंदर न दबे (फंसा हुआ हर्निया)',
      ],
      commonSymptomsMr: [
        'पोटात अति तीव्र पीळ पडणे आणि पोट ढोल्यासारखे फुगणे',
        '२ दिवसांपेक्षा जास्त काळ शौचास न होणे किंवा गॅस न सुटणे',
        'हिरवट किंवा दुर्गंधीयुक्त काळपट उलट्या होणे',
        'बेंबीजवळ दुखणारी गाठ जी आत जात नाही (हर्निया अडकणे)',
      ],
      isHighRisk: true,
      emergencyProtocol: EmergencyProtocol(
        diagnosisName: 'Blocked Bowel / Trapped Hernia',
        diagnosisNameHi: 'आंतों में रुकावट या फंसा हुआ हर्निया',
        diagnosisNameMr: 'आतड्यांमधील अडथळा किंवा हर्निया अडकणे',
        warningMessage: 'Complete inability to pass stool or gas with severe bloating and vomiting means the intestines are blocked. Emergency hospital care required.',
        warningMessageHi: 'पेट बहुत फूलना, गैस या शौच न उतरना और उल्टी होना आंतों में रुकावट का संकेत है। तुरंत अस्पताल ले जाएं।',
        warningMessageMr: 'पोट खूप फुगणे, शौच किंवा गॅस बंद होणे आणि उलट्या होणे हे आतडे अडकल्याचे लक्षण आहे. त्वरित रुग्णालयात दाखल करा.',
        hospitalAction: 'Emergency Nasogastric Tube Decompression & Surgical Intake',
        hospitalActionHi: 'आपातकालीन आंत सुरक्षा व सर्जरी जांच',
        hospitalActionMr: 'तातडीचे आतडे उपचार व शस्त्रक्रिया तपासणी',
        targetFacilityType: 'District Hospital General Surgery Department',
      ),
    ),
    const AnatomicalRegionDto(
      id: 'abdomen_llq',
      nameEn: 'Lower Left Belly',
      nameHi: 'पेट का निचला बायाँ हिस्सा',
      nameMr: 'पोटाची डावी खालची बाजू',
      systemType: 'Lower Belly & Bowels',
      systemTypeHi: 'निचला पेट और बड़ी आंत',
      systemTypeMr: 'खालचे पोट व मोठे आतडे',
      view: AnatomicalView.anterior,
      normalizedX: 0.44,
      normalizedY: 0.48,
      commonSymptoms: [
        'Pain in lower left belly worsening on movement',
        'Passing bright red blood in toilet / stool',
        'Severe constipation alternating with bloody loose motions',
        'Fever with sensitive lower stomach',
      ],
      commonSymptomsHi: [
        'पेट के निचले बाएँ हिस्से में तेज दर्द और ऐंठन',
        'शौच में लाल खून आना',
        'कब्ज के बाद अचानक खूनी दस्त होना',
        'बुखार के साथ निचले पेट में छूने पर तेज दर्द',
      ],
      commonSymptomsMr: [
        'पोटाच्या डाव्या खालच्या भागात तीव्र वेदना व कळ',
        'शौचावाटे लाल रक्त पडणे',
        'बद्धकोष्ठतेनंतर अचानक रक्ताची जुलाब होणे',
        'तापासह पोटाच्या डाव्या बाजूला हात लावल्यास कळ',
      ],
      emergencyProtocol: EmergencyProtocol(
        diagnosisName: 'Severe Lower Bowel Infection / Bleeding',
        diagnosisNameHi: 'बड़ी आंत का गंभीर दर्द व रक्तस्राव',
        diagnosisNameMr: 'मोठ्या आतड्याचा तीव्र संसर्ग व रक्तस्त्राव',
        warningMessage: 'Severe left belly pain with fresh blood in stool needs medical investigation to prevent perforation.',
        warningMessageHi: 'बाएँ पेट में तेज दर्द के साथ खून आना आंत में सूजन या छाला हो सकता है। डॉक्टर को दिखाएं।',
        warningMessageMr: 'डाव्या पोटात वेदनेसह शौचातून रक्त पडणे हे आतड्याला सूज किंवा जखम असण्याचे लक्षण आहे. त्वरित तपासणी करा.',
        hospitalAction: 'Emergency GI Triage & Fluid Resuscitation',
        hospitalActionHi: 'आपातकालीन पेट व रक्तस्राव जांच',
        hospitalActionMr: 'तातडीची पोटाची व रक्तस्त्राव तपासणी',
        targetFacilityType: 'Sub-District Hospital Inpatient Medical/Surgical Unit',
      ),
    ),

    // 6. PELVIS & SUPRAPUBIC
    const AnatomicalRegionDto(
      id: 'pelvis_suprapubic',
      nameEn: 'Lower Pelvis & Bladder',
      nameHi: 'पेड़ू और पेशाब का हिस्सा',
      nameMr: 'ओटीपोट व मूत्राशय',
      systemType: 'Pelvis & Urinary',
      systemTypeHi: 'पेड़ू और पेशाब',
      systemTypeMr: 'ओटीपोट व लघवी',
      view: AnatomicalView.anterior,
      normalizedX: 0.50,
      normalizedY: 0.54,
      commonSymptoms: [
        'Severe lower belly pain with vaginal bleeding (Pregnant female)',
        'Unable to pass urine despite severe painful urge (Blocked bladder)',
        'Severe sudden pain and swelling in private parts (Male)',
        'High fever with foul-smelling vaginal discharge',
      ],
      commonSymptomsHi: [
        'पेड़ू में तेज दर्द के साथ खून आना (गर्भवती महिला)',
        'पेशाब बिल्कुल न उतरना और मूत्राशय में तेज दबाव व दर्द',
        'निजी अंग (अंडकोष) में अचानक असहनीय दर्द और सूजन (पुरुष)',
        'तेज बुखार और बदबूदार पानी या मवाद आना',
      ],
      commonSymptomsMr: [
        'ओटीपोटात तीव्र वेदनेसह योनीतून रक्तस्त्राव (गर्भवती महिला)',
        'लघवी तुंबणे आणि प्रचंड वेदना होऊनही लघवी न होणे',
        'खाजगी भागात (अंडवृद्धी) अचानक असह्य वेदना व सूज (पुरुष)',
        'तीव्र ताप आणि दुर्गंधीयुक्त स्राव होणे',
      ],
      isHighRisk: true,
      emergencyProtocol: EmergencyProtocol(
        diagnosisName: 'Severe Pregnancy Emergency / Acute Male Pain',
        diagnosisNameHi: 'गर्भावस्था का आपातकाल / तीव्र अंडकोष दर्द',
        diagnosisNameMr: 'गर्भाशयाची आणीबाणी / अंडवृद्धी तीव्र वेदना',
        warningMessage: 'In pregnant women, sudden pelvic pain with bleeding can be an ectopic pregnancy. In men, sudden acute testicular pain needs hospital surgery within 6 hours.',
        warningMessageHi: 'गर्भवती महिलाओं में पेट दर्द व रक्तस्राव गंभीर खतरा है। पुरुषों में अचानक तेज अंडकोष दर्द 6 घंटे के भीतर सर्जरी मांगता है। तुरंत 108 बुलाएं।',
        warningMessageMr: 'गर्भवती महिलेमध्ये ओटीपोटात वेदना व रक्तस्त्राव अत्यंत धोक्याचा आहे. पुरुषांमध्ये अचानक अंडवृद्धी दुखल्यास ६ तासांत उपचार आवश्यक असतात.',
        hospitalAction: '108 Immediate Emergency Obstetric / Urologic Transfer',
        hospitalActionHi: '108 आपातकालीन प्रसूति / यूरोलॉजी एम्बुलेंस',
        hospitalActionMr: '१०८ तातडीची प्रसूती / मूत्ररोग रुग्णवाहिका',
        targetFacilityType: 'District Hospital Comprehensive Emergency Obstetric (CEmOC) / Urology',
      ),
    ),

    // 7. BACK, SPINE & FLANKS (Posterior)
    const AnatomicalRegionDto(
      id: 'flank_kidney_right',
      nameEn: 'Right Kidney & Waist',
      nameHi: 'कमर की दाहिनी करवट और गुर्दा',
      nameMr: 'उजवी कूस व मूत्रपिंड',
      systemType: 'Kidneys & Urine',
      systemTypeHi: 'गुर्दे और पेशाब',
      systemTypeMr: 'मूत्रपिंड व लघवी',
      view: AnatomicalView.posterior,
      normalizedX: 0.58,
      normalizedY: 0.42,
      commonSymptoms: [
        'Excruciating pain in side of back shooting down to groin (Stone pain)',
        'Red or cola-colored blood in urine',
        'Shaking chills and high fever with back pain',
        'Severe restlessness and vomiting from pain',
      ],
      commonSymptomsHi: [
        'कमर के दाएँ हिस्से से नीचे पेशाब के रास्ते तक बिजली जैसी तेज टीस (पथरी का दर्द)',
        'पेशाब में लाल या भूरे रंग का खून आना',
        'कंपकंपी वाली ठंड और तेज बुखार के साथ कमर दर्द',
        'दर्द के मारे तड़पना और उल्टी आना',
      ],
      commonSymptomsMr: [
        'उजव्या कुशीतून खाली लघवीच्या जागेकडे जाणाऱ्या असह्य कळा (मुतखडा)',
        'लघवीतून लाल किंवा काळपट रक्त पडणे',
        'थंडी वाजून तीव्र ताप आणि पाठदुखी',
        'वेदनांमुळे विव्हळणे व उलट्या होणे',
      ],
      isHighRisk: true,
      emergencyProtocol: EmergencyProtocol(
        diagnosisName: 'Kidney Stone Blockage with Infection',
        diagnosisNameHi: 'गुर्दे की पथरी व गंभीर संक्रमण (किडनी खतरा)',
        diagnosisNameMr: 'मुतखडा अडकणे व तीव्र संसर्ग (किडनी आणीबाणी)',
        warningMessage: 'Severe side pain with high fever and bloody urine means an infected blocked kidney. Immediate hospital treatment required.',
        warningMessageHi: 'कमर में तेज दर्द के साथ तेज बुखार और खून वाला पेशाब गुर्दे में मवाद/संक्रमण का संकेत है। तुरंत अस्पताल दिखाएं।',
        warningMessageMr: 'कुशीत असह्य कळा, तीव्र ताप आणि लघवीतून रक्त असणे हे मूत्रपिंडात संसर्ग अडकल्याचे लक्षण आहे. त्वरित उपचार घ्या.',
        hospitalAction: 'Emergency Urology / Nephrology Sepsis Intake',
        hospitalActionHi: 'आपातकालीन गुर्दा उपचार व जांच',
        hospitalActionMr: 'तातडीचे मूत्रपिंड उपचार व तपासणी',
        targetFacilityType: 'District Hospital Urology Ward',
      ),
    ),
    const AnatomicalRegionDto(
      id: 'flank_kidney_left',
      nameEn: 'Left Kidney & Waist',
      nameHi: 'कमर की बायीं करवट और गुर्दा',
      nameMr: 'डावी कूस व मूत्रपिंड',
      systemType: 'Kidneys & Urine',
      systemTypeHi: 'गुर्दे और पेशाब',
      systemTypeMr: 'मूत्रपिंड व लघवी',
      view: AnatomicalView.posterior,
      normalizedX: 0.42,
      normalizedY: 0.42,
      commonSymptoms: [
        'Severe stabbing pain in left waist spreading to front',
        'Severe burning sensation when passing urine',
        'High fever with cold shivering',
        'Barely passing any urine despite drinking water',
      ],
      commonSymptomsHi: [
        'बायीं कमर में चुभने वाला तेज दर्द जो आगे की तरफ आए',
        'पेशाब करते समय अत्यधिक तेज जलन व दर्द',
        'कड़ाके की ठंड और तेज बुखार',
        'पानी पीने के बाद भी बहुत कम पेशाब उतरना',
      ],
      commonSymptomsMr: [
        'डाव्या कुशीत टोचल्यासारख्या तीव्र कळा ज्या पुढे पसरतात',
        'लघवी करताना असह्य जळजळ व वेदना',
        'भरपूर थंडी वाजून तीव्र ताप येणे',
        'पाणी पिऊनही लघवीचे प्रमाण खूप कमी होणे',
      ],
      emergencyProtocol: EmergencyProtocol(
        diagnosisName: 'Kidney Infection Emergency',
        diagnosisNameHi: 'गुर्दे का गंभीर संक्रमण (पायलोनेफ्राइटिस)',
        diagnosisNameMr: 'मूत्रपिंडाचा तीव्र संसर्ग (किडनी इन्फेक्शन)',
        warningMessage: 'Left waist pain with shaking chills and low urine output needs urgent doctor antibiotics and drip.',
        warningMessageHi: 'कमर में दर्द, ठंड लगना और पेशाब कम आना गुर्दे के संक्रमण का संकेत है। तुरंत अस्पताल में स्लाइन और दवा लगवाएं।',
        warningMessageMr: 'कुशीत वेदना, थंडी वाजणे आणि लघवी कमी होणे हे मूत्रपिंडातील संसर्गाचे लक्षण आहे. त्वरित रुग्णालयात सलाइन व औषधे सुरू करा.',
        hospitalAction: 'Urgent Inpatient Admission & Renal Ultrasound',
        hospitalActionHi: 'आपातकालीन गुर्दा भर्ती व सोनोग्राफी',
        hospitalActionMr: 'तातडीने दाखल करणे व सोनोग्राफी',
        targetFacilityType: 'Sub-District Hospital Inpatient Unit',
      ),
    ),
    const AnatomicalRegionDto(
      id: 'lumbar_spine_lower_back',
      nameEn: 'Lower Back & Waist',
      nameHi: 'कमर का निचला हिस्सा एवं रीढ़',
      nameMr: 'पाठीचा खालचा भाग व कंबर',
      systemType: 'Backbone & Nerves',
      systemTypeHi: 'रीढ़ और नसें',
      systemTypeMr: 'मणका व मज्जातंतू',
      view: AnatomicalView.posterior,
      normalizedX: 0.50,
      normalizedY: 0.48,
      commonSymptoms: [
        'Loss of bladder or bowel control with back pain (Incontinence)',
        'Numbness between thighs, groin, or buttocks (Saddle numbness)',
        'Sudden weakness in both legs / feet dragging on floor',
        'Severe backbone pain after lifting weight or falling',
      ],
      commonSymptomsHi: [
        'कमर दर्द के साथ पेशाब या पाखाने पर नियंत्रण खत्म होना',
        'जांघों के बीच, कूल्हों या निजी अंगों में सुन्नपन (सुई चुभोने पर भी पता न चलना)',
        'दोनों पैरों में अचानक भारी कमजोरी / पैर घिसट कर चलना',
        'वजन उठाने या गिरने के बाद रीढ़ की हड्डी में असहनीय दर्द',
      ],
      commonSymptomsMr: [
        'कंबरदुखीसह लघवी किंवा शौचावर ताबा न राहणे (आपोआप गळणे)',
        'मांड्यांच्या मध्ये किंवा खाजगी भागात पूर्ण बधीरपणा',
        'दोन्ही पायांत अचानक तीव्र अशक्तपणा / पाय फरफटत चालणे',
        'वजन उचलल्यानंतर किंवा पडल्यानंतर मणक्यात असह्य वेदना',
      ],
      isHighRisk: true,
      emergencyProtocol: EmergencyProtocol(
        diagnosisName: 'Severe Nerve & Spine Compression (Cauda Equina)',
        diagnosisNameHi: 'कमर की नसों पर गंभीर दबाव (कॉडा इक्विना)',
        diagnosisNameMr: 'मणक्याच्या नसांवर तीव्र ताण (कॉडा इक्विना)',
        warningMessage: 'Back pain with loss of bladder control or numbness in groin is a spine nerve emergency. Surgery is needed within 24 hours to prevent permanent paralysis.',
        warningMessageHi: 'कमर दर्द के साथ पेशाब का छूटना या जांघों के बीच सुन्नपन नसों के दबने का गंभीर आपातकाल है। 24 घंटे में इलाज न मिलने पर स्थायी लकवा हो सकता है।',
        warningMessageMr: 'कंबरदुखीसह लघवीवर ताबा न राहणे किंवा खाजगी भागात बधीरपणा येणे हे मणक्याच्या नसा दबल्याचे गंभीर लक्षण आहे. २४ तासांत उपचार न झाल्यास कायमचे अपंगत्व येऊ शकते.',
        hospitalAction: '108 Emergency Neurosurgical Protocol Transfer',
        hospitalActionHi: '108 न्यूरोसर्जरी आपातकालीन एम्बुलेंस',
        hospitalActionMr: '१०८ मज्जातंतू शस्त्रक्रिया रुग्णवाहिका',
        targetFacilityType: 'District Hospital Spine & Neurosurgical Unit',
      ),
    ),

    // 8. HIPS & LEGS
    const AnatomicalRegionDto(
      id: 'hip_thigh_right',
      nameEn: 'Right Hip & Thigh',
      nameHi: 'दायाँ कूल्हा और जांघ',
      nameMr: 'उजवा खुबा व मांडी',
      systemType: 'Hips & Bones',
      systemTypeHi: 'कूल्हा और हड्डी',
      systemTypeMr: 'खुबा व हाडे',
      view: AnatomicalView.anterior,
      normalizedX: 0.57,
      normalizedY: 0.65,
      commonSymptoms: [
        'Unable to stand or bear weight on right leg after fall (Elderly)',
        'Right leg looks shorter and turned outwards',
        'Severe thigh deformity and swelling (Broken thigh bone)',
        'Warm, red, tender swelling in right thigh (Blood clot)',
      ],
      commonSymptomsHi: [
        'गिरने के बाद दाएँ पैर पर बिल्कुल वजन न दे पाना (बुजुर्गों में)',
        'दायाँ पैर छोटा और बाहर की तरफ मुड़ा हुआ दिखना',
        'जांघ की हड्डी में गंभीर टेढ़ापन और सूजन (फ्रैक्चर)',
        'जांघ में तेज दर्द, लाली और गरम सूजन (खून का थक्का)',
      ],
      commonSymptomsMr: [
        'पडल्यानंतर उजव्या पायावर अजिबात उभे न राहता येणे (ज्येष्ठांमध्ये)',
        'उजवा पाय लहान झालेला व बाहेरच्या बाजूला वळलेला दिसणे',
        'मांडीचे हाड मोडल्यामुळे आलेली मोठी सूज व वाकडेपणा',
        'मांडीमध्ये तीव्र वेदना, लाली व गरम सूज (रक्ताची गुठळी)',
      ],
      isHighRisk: true,
      emergencyProtocol: EmergencyProtocol(
        diagnosisName: 'Broken Hip / Thigh Bone Fracture',
        diagnosisNameHi: 'कूल्हे या जांघ की हड्डी का फ्रैक्चर',
        diagnosisNameMr: 'खुबा किंवा मांडीचे हाड फ्रॅक्चर',
        warningMessage: 'Inability to stand with an outward turned leg indicates a hip fracture. Keep leg still; do not force movement.',
        warningMessageHi: 'गिरने के बाद पैर बाहर मुड़ा होना कूल्हा टूटने का संकेत है। पैर को हिलाएं नहीं; तुरंत स्ट्रेचर पर अस्पताल ले जाएं।',
        warningMessageMr: 'पडल्यानंतर पाय बाहेर वळणे हा खुबा तुटल्याचा पुरावा आहे. पाय अजिबात न हलवता त्वरित स्ट्रेचरवरून रुग्णालयात न्या.',
        hospitalAction: 'Emergency Immobilization (Hare Traction) & Orthopedic Intake',
        hospitalActionHi: 'आपातकालीन पैर सुरक्षा व हड्डी अस्पताल',
        hospitalActionMr: 'तातडीने पाय स्थिर करणे व रुग्णालय दाखल',
        targetFacilityType: 'Sub-District Hospital Orthopedic Department',
      ),
    ),
    const AnatomicalRegionDto(
      id: 'hip_thigh_left',
      nameEn: 'Left Hip & Thigh',
      nameHi: 'बायाँ कूल्हा और जांघ',
      nameMr: 'डावा खुबा व मांडी',
      systemType: 'Hips & Bones',
      systemTypeHi: 'कूल्हा और हड्डी',
      systemTypeMr: 'खुबा व हाडे',
      view: AnatomicalView.anterior,
      normalizedX: 0.43,
      normalizedY: 0.65,
      commonSymptoms: [
        'Left hip pain when walking or standing',
        'Stiff groin making it difficult to sit on floor',
        'Thigh bone pain following vehicle accident',
        'Severe deep throbbing pain along front of thigh',
      ],
      commonSymptomsHi: [
        'चलने या खड़े होने पर बाएँ कूल्हे में तेज दर्द',
        'कूल्हा अकड़ना जिससे नीचे जमीन पर बैठना मुश्किल हो',
        'सड़क दुर्घटना के बाद जांघ में तेज दर्द',
        'जांघ के अगले हिस्से में गहरी कसक व दर्द',
      ],
      commonSymptomsMr: [
        'चालताना किंवा उभे राहताना डाव्या खुब्यात तीव्र वेदना',
        'खुबा आखडल्यामुळे खाली मांडी घालून बसता न येणे',
        'अपघातानंतर मांडीच्या हाडात असह्य वेदना',
        'मांडीच्या पुढील भागात खोलवर ठसठसणे',
      ],
      emergencyProtocol: EmergencyProtocol(
        diagnosisName: 'Left Hip Injury / Joint Dislocation',
        diagnosisNameHi: 'बायाँ कूल्हा चोट / जोड़ खिसकना',
        diagnosisNameMr: 'डावा खुबा दुखापत / सांधा निखळणे',
        warningMessage: 'Severe hip pain after accident needs an immediate X-ray to check for hip dislocation or bone damage.',
        warningMessageHi: 'चोट के बाद कूल्हे में तेज दर्द होने पर तुरंत एक्स-रे कराएं ताकि जोड़ खिसकने का पता चल सके।',
        warningMessageMr: 'अपघातानंतर खुब्यात तीव्र वेदना असल्यास त्वरित एक्स-रे करून सांध्याची तपासणी करा.',
        hospitalAction: 'Urgent Orthopedic Imaging & Splinting',
        hospitalActionHi: 'एक्स-रे और हड्डी सुरक्षा जांच',
        hospitalActionMr: 'तातडीचे एक्स-रे व तपासणी',
        targetFacilityType: 'Sub-District Hospital Trauma Unit',
      ),
    ),
    const AnatomicalRegionDto(
      id: 'knee_right',
      nameEn: 'Right Knee',
      nameHi: 'दायाँ घुटना',
      nameMr: 'उजवा गुडघा',
      systemType: 'Knees & Joints',
      systemTypeHi: 'घुटना और जोड़',
      systemTypeMr: 'गुडघा व सांधे',
      view: AnatomicalView.anterior,
      normalizedX: 0.57,
      normalizedY: 0.76,
      commonSymptoms: [
        'Hot, bright red, painfully swollen knee with fever',
        'Completely unable to put foot down or bend knee',
        'Knee locked in place with popping sound',
        'Heavy fluid swelling after twist or fall',
      ],
      commonSymptomsHi: [
        'घुटना बहुत गरम, लाल, सूजा हुआ और तेज बुखार (संक्रमण)',
        'पैर जमीन पर बिल्कुल न रख पाना और घुटना न मुड़ना',
        'घुटने में कड़कड़ आवाज के साथ जोड़ का अटक जाना',
        'गिरने या मुड़ने के बाद घुटने में पानी/खून भर जाना',
      ],
      commonSymptomsMr: [
        'गुडघा अत्यंत गरम, लालबुंद, सुजलेला आणि तीव्र ताप (संसर्ग)',
        'पाय जमिनीवर टेकवता न येणे किंवा गुडघा न वाकणे',
        'गुडघ्यात आवाज येऊन सांधा लॉक होणे / अडकणे',
        'पडल्यानंतर गुडघ्यात भरपूर पाणी किंवा रक्त जमा होणे',
      ],
      isHighRisk: true,
      emergencyProtocol: EmergencyProtocol(
        diagnosisName: 'Septic Joint Infection / Knee Hemorrhage',
        diagnosisNameHi: 'घुटने में गंभीर मवाद/संक्रमण (सेप्टिक आर्थराइटिस)',
        diagnosisNameMr: 'गुडघ्यात पू भरणे / गंभीर संसर्ग (सेप्टिक आर्थ्रायटिस)',
        warningMessage: 'A hot, red, swollen joint with fever is a bacterial joint infection. Delay can permanently destroy the knee within 24-48 hours.',
        warningMessageHi: 'तेज बुखार के साथ लाल गरम सूजा हुआ घुटना गंभीर संक्रमण है। 24-48 घंटे में जोड़ खराब हो सकता है; तुरंत डॉक्टर से मवाद निकलवाएं।',
        warningMessageMr: 'तापासह गुडघा लाल, गरम व सुजलेला असल्यास तो गंभीर जिवाणू संसर्ग असू शकतो. २४-४८ तासांत सांधा कायमचा निकामी होण्याचा धोका असतो.',
        hospitalAction: 'Emergency Joint Aspiration & Inpatient Admission',
        hospitalActionHi: 'आपातकालीन सुई से जांच व भर्ती',
        hospitalActionMr: 'तातडीने सुईने तपासणी व रुग्णालय दाखल',
        targetFacilityType: 'District Hospital Orthopedic & Rheumatology Wing',
      ),
    ),
    const AnatomicalRegionDto(
      id: 'knee_left',
      nameEn: 'Left Knee',
      nameHi: 'बायाँ घुटना',
      nameMr: 'डावा गुडघा',
      systemType: 'Knees & Joints',
      systemTypeHi: 'घुटना और जोड़',
      systemTypeMr: 'गुडघा व सांधे',
      view: AnatomicalView.anterior,
      normalizedX: 0.43,
      normalizedY: 0.76,
      commonSymptoms: [
        'Left knee swelling and pain when climbing stairs',
        'Kneecap slipped out of place (Visible deformity)',
        'Chronic arthritis flare-up with grinding sensation',
        'Pain on inner or outer side of knee joint',
      ],
      commonSymptomsHi: [
        'सीढ़ियां चढ़ने या बैठने पर बाएँ घुटने में तेज दर्द',
        'घुटने की कटोरी (जानुफलक) अपनी जगह से खिसक जाना',
        'घुटने के पुराने गठिया का तेज दर्द व रगड़ महसूस होना',
        'घुटने के किनारे की नस में दर्द',
      ],
      commonSymptomsMr: [
        'पायऱ्या चढताना किंवा बसताना डाव्या गुडघ्यात तीव्र वेदना',
        'गुडघ्याची वाटी जागेवरून घसरणे किंवा वाकडी दिसणे',
        'गुडघ्याच्या जुनाट सांधेदुखीचा भडका व करकर आवाज',
        'गुडघ्याच्या कडेच्या नसांमध्ये तीव्र कळ',
      ],
      emergencyProtocol: EmergencyProtocol(
        diagnosisName: 'Kneecap Dislocation / Knee Ligament Tear',
        diagnosisNameHi: 'घुटने की कटोरी खिसकना / लिगामेंट टूटना',
        diagnosisNameMr: 'गुडघ्याची वाटी निखळणे / लिगामेंट इजा',
        warningMessage: 'Visible joint deformity with inability to walk requires urgent orthopedic alignment.',
        warningMessageHi: 'घुटने की कटोरी खिसकने पर पैर न हिलाएं; अस्पताल में विशेषज्ञ से इसे सीधा करवाएं।',
        warningMessageMr: 'गुडघ्याची वाटी निखळल्यास स्वतःहून ओढू नका; रुग्णालयात तज्ज्ञांकडून सरळ करून घ्या.',
        hospitalAction: 'Urgent Orthopedic Consultation & Splint',
        hospitalActionHi: 'हड्डी विशेषज्ञ परामर्श व पट्टा',
        hospitalActionMr: 'अस्थिरोगतज्ज्ञ सल्ला व पट्टा',
        targetFacilityType: 'Sub-District Hospital Orthopedic Clinic',
      ),
    ),
    const AnatomicalRegionDto(
      id: 'lower_leg_calf_right',
      nameEn: 'Right Calf & Lower Leg',
      nameHi: 'दाहिनी पिण्डली और पैर',
      nameMr: 'उजवी पोटरी व पाय',
      systemType: 'Calf & Blood Veins',
      systemTypeHi: 'पिण्डली और नसें',
      systemTypeMr: 'पोटरी व रक्तवाहिन्या',
      view: AnatomicalView.anterior,
      normalizedX: 0.57,
      normalizedY: 0.86,
      commonSymptoms: [
        'One-sided painful, swollen, tender calf (Blood clot danger / DVT)',
        'Shiny, tight, hard calf with extreme pain when pulling toes up',
        'Broken shin bone with open bleeding wound',
        'Severe muscle tear or sudden snap in calf',
      ],
      commonSymptomsHi: [
        'एक तरफ की पिण्डली में तेज सूजन, दर्द और गर्माहट (खून का थक्का / DVT)',
        'पिण्डली की त्वचा तनी हुई, चमकीली और पंजा ऊपर खींचने पर तेज दर्द',
        'पैर की नली वाली हड्डी टूटना और खून बहना',
        'पिण्डली की नस खिंचना या तेज अकड़न',
      ],
      commonSymptomsMr: [
        'एकाच बाजूच्या पोटरीला सूज, तीव्र वेदना व उष्णता (रक्ताची गुठळी / DVT)',
        'पोटरी कडक ताठरणे आणि चवडा वर खेचल्यास असह्य कळ',
        'नळीचे हाड मोडणे आणि जखमेतून रक्त येणे',
        'पोटरीचा स्नायू फाटणे किंवा अचानक लचकणे',
      ],
      isHighRisk: true,
      emergencyProtocol: EmergencyProtocol(
        diagnosisName: 'Deep Vein Blood Clot (DVT) / Compartment Syndrome',
        diagnosisNameHi: 'पैर की नस में खून का थक्का (DVT खतरा)',
        diagnosisNameMr: 'पायाच्या नसांमध्ये रक्ताची गुठळी (DVT धोका)',
        warningMessage: 'A swollen, hot, tender calf can mean a deep vein blood clot (DVT). If it travels to the lungs, it can be fatal. Go to hospital right away.',
        warningMessageHi: 'एक पैर की पिण्डली में अचानक सूजन और दर्द नस में खून का थक्का (DVT) हो सकता है। यह फेफड़ों में पहुँचकर जानलेवा हो सकता है। तुरंत अस्पताल जाएं।',
        warningMessageMr: 'एकाच पोटरीला सूज, उष्णता व वेदना असणे हे नसेत रक्ताची गुठळी (DVT) झाल्याचे लक्षण असू शकते. ही गुठळी फुफ्फुसात गेल्यास जीवघेणी ठरू शकते. त्वरित जा.',
        hospitalAction: '108 Vascular Emergency Transfer (Venous Doppler & Anticoagulation)',
        hospitalActionHi: '108 नस सुरक्षा एम्बुलेंस (डॉपलर जांच)',
        hospitalActionMr: '१०८ रक्तवाहिनी तपासणी रुग्णवाहिका',
        targetFacilityType: 'District Hospital Vascular & Medical ICU',
      ),
    ),
    const AnatomicalRegionDto(
      id: 'lower_leg_calf_left',
      nameEn: 'Left Calf & Lower Leg',
      nameHi: 'बायीं पिण्डली और पैर',
      nameMr: 'डावी पोटरी व पाय',
      systemType: 'Calf & Blood Veins',
      systemTypeHi: 'पिण्डली और नसें',
      systemTypeMr: 'पोटरी व रक्तवाहिन्या',
      view: AnatomicalView.anterior,
      normalizedX: 0.43,
      normalizedY: 0.86,
      commonSymptoms: [
        'Painful cramps and tightness in left calf at night',
        'Dark skin discoloration and non-healing leg ulcer',
        'Swollen blue veins bursting and bleeding (Varicose veins)',
        'Shin splint pain along front bone after walking',
      ],
      commonSymptomsHi: [
        'रात में बायीं पिण्डली में तेज ऐंठन और नस चढ़ना',
        'पैर की त्वचा काली पड़ना और घाव न भरना',
        'उभरी हुई नीली नसों से खून बहना (वेरिकोज वेन्स)',
        'पैदल चलने के बाद नली की हड्डी में तेज दर्द',
      ],
      commonSymptomsMr: [
        'रात्री डाव्या पोटरीत तीव्र गोळा येणे व चमक भरणे',
        'पायाची त्वचा काळी पडणे आणि जुनी जखम न भरणे',
        'फुगलेल्या निळ्या नसा फुटून रक्त येणे (व्हेरिकोज व्हेन्स)',
        'चालल्यानंतर नळीच्या हाडात ठसठसणे',
      ],
      emergencyProtocol: EmergencyProtocol(
        diagnosisName: 'Bleeding Varicose Vein / Severe Leg Cellulitis',
        diagnosisNameHi: 'पैर की नस से भारी रक्तस्राव / गंभीर त्वचा संक्रमण',
        diagnosisNameMr: 'नसेतून रक्तस्त्राव / पायाचा गंभीर संसर्ग',
        warningMessage: 'Spreading redness and heat in calf with high fever needs prompt antibiotics to prevent deep tissue destruction.',
        warningMessageHi: 'पैर में फैलती लाली, तेज जलन और बुखार गंभीर संक्रमण (सेल्युलाइटिस) है। तुरंत एंटीबायोटिक इलाज कराएं।',
        warningMessageMr: 'पायावर पसरणारी लाली, तीव्र उष्णता आणि ताप हा गंभीर संसर्ग असू शकतो. त्वरित अँटीबायोटिक उपचार घ्या.',
        hospitalAction: 'Urgent Wound Care & Inpatient Antimicrobial Protocol',
        hospitalActionHi: 'घाव उपचार व एंटीबायोटिक भर्ती',
        hospitalActionMr: 'जखम उपचार व औषधोपचार',
        targetFacilityType: 'Community Health Centre Inpatient Ward',
      ),
    ),
    const AnatomicalRegionDto(
      id: 'ankle_foot_right',
      nameEn: 'Right Ankle & Foot',
      nameHi: 'दायाँ टखना और पैर का पंजा',
      nameMr: 'उजवा घोटा व पाऊल',
      systemType: 'Ankles & Feet',
      systemTypeHi: 'टखना और पैर',
      systemTypeMr: 'घोटा व पाऊल',
      view: AnatomicalView.anterior,
      normalizedX: 0.58,
      normalizedY: 0.95,
      commonSymptoms: [
        'Severe ankle twist with dark purple bruising and swelling',
        'Blackened, foul-smelling diabetic foot wound (Gangrene danger)',
        'Excruciating burning pain in big toe joint (Gout attack)',
        'Cannot take even 4 steps on foot after injury',
      ],
      commonSymptomsHi: [
        'टखना मुड़ना, नीला पड़ना और पैर पर खड़े न हो पाना',
        'शुगर (डायबिटीज) का बदबूदार काला पड़ता घाव (गैंग्रीन का खतरा)',
        'पैर के अँगूठे में अचानक तेज लाल जलन और दर्द (गठिया/यूरिक एसिड)',
        'चोट के बाद 4 कदम भी न चल पाना (हड्डी टूटना)',
      ],
      commonSymptomsMr: [
        'घोटा मुरगळणे, काळा-निळा पडणे व उभे न राहता येणे',
        'मधुमेहाची दुर्गंधीयुक्त काळी पडणारी जखम (गँगरीनचा धोका)',
        'पायाच्या अंगठ्याच्या सांध्यात तीव्र लाल जळजळ व आग (गाउट)',
        'दुखापतीनंतर ४ पावलेही टाकता न येणे (हाड मोडणे)',
      ],
      isHighRisk: true,
      emergencyProtocol: EmergencyProtocol(
        diagnosisName: 'Diabetic Foot Gangrene / Ankle Bone Fracture',
        diagnosisNameHi: 'डायबिटीज पैर का सड़ना (गैंग्रीन) / टखना फ्रैक्चर',
        diagnosisNameMr: 'मधुमेहाची सडणारी जखम (गँगरीन) / घोटा फ्रॅक्चर',
        warningMessage: 'A black or foul-smelling diabetic wound threatens leg amputation. Emergency hospital wound cleaning needed immediately.',
        warningMessageHi: 'डायबिटीज मरीज के पैर में काला घाव या बदबू आना पैर कटने (अंग-विच्छेदन) का बड़ा खतरा है। तुरंत अस्पताल में सफाई कराएं।',
        warningMessageMr: 'मधुमेहाच्या रुग्णाच्या पायाला काळी पडणारी किंवा दुर्गंधी येणारी जखम पाय कापण्याचा धोका निर्माण करते. त्वरित शस्त्रक्रिया विभागात जा.',
        hospitalAction: 'Emergency Surgical Debridement & Diabetic Limb Rescue',
        hospitalActionHi: 'आपातकालीन घाव सर्जरी व पैर सुरक्षा',
        hospitalActionMr: 'तातडीची जखमेची शस्त्रक्रिया व पाय बचाव',
        targetFacilityType: 'District Hospital Surgical & Diabetic Foot Unit',
      ),
    ),
    const AnatomicalRegionDto(
      id: 'ankle_foot_left',
      nameEn: 'Left Ankle & Foot',
      nameHi: 'बायाँ टखना और पैर का पंजा',
      nameMr: 'डावा घोटा व पाऊल',
      systemType: 'Ankles & Feet',
      systemTypeHi: 'टखना और पैर',
      systemTypeMr: 'घोटा व पाऊल',
      view: AnatomicalView.anterior,
      normalizedX: 0.42,
      normalizedY: 0.95,
      commonSymptoms: [
        'Left ankle swelling and unable to bear weight',
        'Sharp heel pain when stepping down first thing in morning',
        'Burning tingling sensation in soles of feet (Nerve weakness)',
        'Broken or dislocated toe after hitting an object',
      ],
      commonSymptomsHi: [
        'बायाँ टखना सूजना और उस पर बिल्कुल खड़ा न हो पाना',
        'सुबह बिस्तर से उठकर पहला कदम रखते ही एड़ी में कांटे जैसी चुभन',
        'तलवों में तेज जलन, सुई चुभना और सुन्नपन (नसों की कमजोरी)',
        'ठोकर लगने से अँगूठे या उंगली की हड्डी मुड़ना',
      ],
      commonSymptomsMr: [
        'डावा घोटा सुजणे आणि अजिबात वजन न टाकता येणे',
        'सकाळी उठून पहिले पाऊल टाकताना टाचेत तीव्र टोचल्यासारखी कळ',
        'पायाच्या तळव्यांची जळजळ, मुंग्या व बधीरपणा (नसांची कमजोरी)',
        'ठेच लागल्यामुळे बोट वाकडे होणे किंवा हाड मोडणे',
      ],
      emergencyProtocol: EmergencyProtocol(
        diagnosisName: 'Severe Ankle Fracture / Cold Ischemic Foot',
        diagnosisNameHi: 'टखने की हड्डी टूटना / पैर ठंडा व बेजान पड़ना',
        diagnosisNameMr: 'घोटा फ्रॅक्चर / पाय गार व रक्तपुरवठा बंद होणे',
        warningMessage: 'A pale, ice-cold, pulseless foot after an ankle injury requires immediate bone straightening and blood flow restoration.',
        warningMessageHi: 'चोट के बाद पैर ठंडा और सफेद पड़ना नस में खून रुकने का संकेत है। तुरंत हड्डी विशेषज्ञ को दिखाएं।',
        warningMessageMr: 'दुखापतीनंतर पाय पांढरा, बर्फासारखा गार पडणे म्हणजे रक्तपुरवठा थांबल्याचे लक्षण आहे. त्वरित हाड जोडणी व तपासणी करा.',
        hospitalAction: 'Urgent Orthopedic X-Ray & Stabilization',
        hospitalActionHi: 'एक्स-रे और पैर सुरक्षा जांच',
        hospitalActionMr: 'तातडीचे एक्स-रे व तपासणी',
        targetFacilityType: 'Sub-District Hospital Emergency Wing',
      ),
    ),
  ];

  List<AnatomicalRegionDto> get anatomicalRegions => List.unmodifiable(_anatomicalRegions);
  List<AnatomicalRegionDto> get allRegions => anatomicalRegions;
  List<AnatomicalRegionDto> getRegionsForView(AnatomicalView view) => _anatomicalRegions.where((r) => r.view == view).toList();

  /// Resolves the nearest fine-grained anatomical region for given normalized coordinates on the canvas
  AnatomicalRegionDto findRegionByCoordinate(double normX, double normY, AnatomicalView view) {
    final candidateRegions = _anatomicalRegions.where((r) => r.view == view).toList();
    if (candidateRegions.isEmpty) return _anatomicalRegions.first;

    AnatomicalRegionDto closest = candidateRegions.first;
    double minDistance = double.infinity;

    for (final reg in candidateRegions) {
      final dx = reg.normalizedX - normX;
      final dy = reg.normalizedY - normY;
      // We weight Y slightly more because human height has more vertical anatomical differentiation
      final dist = sqrt(dx * dx + (dy * 1.2) * (dy * 1.2));
      if (dist < minDistance) {
        minDistance = dist;
        closest = reg;
      }
    }

    return closest;
  }

  AnatomicalRegionDto getRegionById(String id) {
    return _anatomicalRegions.firstWhere(
      (r) => r.id == id,
      orElse: () => _anatomicalRegions.first,
    );
  }

  /// Universal General Danger Signs (MoHFW National Triage Protocol) in Plain Everyday Language
  List<CategoryQuestion> getUniversalDangerQuestions() {
    return const [
      CategoryQuestion(
        id: 'danger_avpu',
        textEn: 'Is the person unconscious, fainting, or unable to recognize family?',
        textHi: 'क्या मरीज बेहोश है, तेज चक्कर खाकर गिर रहा है, या पहचान नहीं पा रहा?',
        textMr: 'व्यक्ती बेशुद्ध आहे, चक्कर येऊन पडली आहे किंवा कोणाला ओळखू शकत नाही का?',
        isRedFlag: true,
        clinicalRationale: 'Loss of consciousness / altered mental status (MoHFW Red Emergency)',
      ),
      CategoryQuestion(
        id: 'danger_resp',
        textEn: 'Is there extreme struggle to breathe, whistling sound, or blue lips?',
        textHi: 'क्या सांस लेने में बहुत जोर लग रहा है, सीटी की आवाज आ रही है या होंठ नीले पड़ रहे हैं?',
        textMr: 'श्वास घेण्यास खूप त्रास होत आहे, घरघर आवाज येतोय किंवा ओठ निळे पडले आहेत का?',
        isRedFlag: true,
        clinicalRationale: 'Severe respiratory distress or airway blockage (MoHFW Red Emergency)',
      ),
      CategoryQuestion(
        id: 'danger_shock',
        textEn: 'Are hands and feet ice cold, clammy, with extreme dizziness upon sitting?',
        textHi: 'क्या हाथ-पैर बर्फ जैसे ठंडे पड़ गए हैं और उठने पर बहुत तेज चक्कर आ रहे हैं?',
        textMr: 'हात-पाय बर्फासारखे गार पडले आहेत आणि उठून बसल्यावर तीव्र चक्कर येत आहे का?',
        isRedFlag: true,
        clinicalRationale: 'Circulatory shock signs / dangerous blood pressure drop (MoHFW Red Emergency)',
      ),
      CategoryQuestion(
        id: 'danger_bleed',
        textEn: 'Is there continuous heavy bleeding, vomiting blood, or bloody stool?',
        textHi: 'क्या लगातार अत्यधिक खून बह रहा है, खून की उल्टी हो रही है या मल में खून आ रहा है?',
        textMr: 'सतत जास्त रक्तस्त्राव होत आहे, रक्ताची उलटी झाली आहे किंवा शौचातून रक्त जात आहे का?',
        isRedFlag: true,
        clinicalRationale: 'Heavy uncontrolled bleeding (MoHFW Red Emergency)',
      ),
    ];
  }

  /// Plain Everyday Language questions specific to the selected anatomical region
  List<CategoryQuestion> getQuestionsForRegion(AnatomicalRegionDto region) {
    final List<CategoryQuestion> list = [];
    // Red-flag question for this region
    list.add(CategoryQuestion(
      id: 'reg_danger_${region.id}',
      textEn: 'Experiencing urgent warning sign: ${region.emergencyProtocol.diagnosisName}?',
      textHi: 'क्या यह गंभीर चेतावनी लक्षण दिख रहा है: ${region.emergencyProtocol.localizedDiagnosis(true, false)}?',
      textMr: 'हे गंभीर धोक्याचे लक्षण दिसत आहे का: ${region.emergencyProtocol.localizedDiagnosis(false, true)}?',
      isRedFlag: true,
      clinicalRationale: region.emergencyProtocol.warningMessage,
    ));

    // Secondary clinical evaluation questions for this organ
    list.add(CategoryQuestion(
      id: 'reg_severity_${region.id}',
      textEn: 'Is the pain so intense that you cannot sleep or move normally?',
      textHi: 'क्या दर्द इतना तेज है कि नींद नहीं आ रही या चलना-फिरना मुश्किल है?',
      textMr: 'वेदना इतकी तीव्र आहे का की झोप येत नाही किंवा सामान्य हालचाल करणे कठीण झाले आहे?',
      isRedFlag: false,
      clinicalRationale: 'Severe functional impairment (P1 Urgent)',
    ));

    list.add(CategoryQuestion(
      id: 'reg_fever_${region.id}',
      textEn: 'Accompanied by shivering, high fever, or constant vomiting?',
      textHi: 'क्या इसके साथ तेज बुखार, कंपकंपी या लगातार उल्टी हो रही है?',
      textMr: 'यासोबत तीव्र ताप, थंडी वाजणे किंवा सतत उलट्या होत आहेत का?',
      isRedFlag: false,
      clinicalRationale: 'Systemic inflammatory response (P1 Urgent)',
    ));

    return list;
  }

  /// Prescribed clinical screening questions conforming to MoHFW / NHM / RBSK / RCH protocols
  List<CategoryQuestion> getQuestionsForCategory(PatientCategory category) {
    switch (category) {
      case PatientCategory.pregnantMaternal:
        return const [
          CategoryQuestion(
            id: 'mat_bleeding',
            textEn: 'Any vaginal bleeding, spotting, or leaking watery fluid?',
            textHi: 'क्या कोई योनि रक्तस्राव, दाग या पानी का स्राव हो रहा है?',
            textMr: 'काही योनीतून रक्तस्त्राव, डाग किंवा पाण्याचा स्राव होत आहे का?',
            isRedFlag: true,
            clinicalRationale: 'Antepartum hemorrhage or premature rupture of membranes (MoHFW RCH)',
          ),
          CategoryQuestion(
            id: 'mat_headache_vision',
            textEn: 'Severe persistent headache, blurred vision, or epigastric pain?',
            textHi: 'क्या तेज सिरदर्द, धुंधला दिखाई देना, या पेट के ऊपरी हिस्से में दर्द है?',
            textMr: 'तीव्र डोकेदुखी, अंधुक दृष्टी किंवा पोटाच्या वरच्या भागात वेदना आहेत का?',
            isRedFlag: true,
            clinicalRationale: 'Imminent eclampsia / preeclampsia danger sign (NHM)',
          ),
          CategoryQuestion(
            id: 'mat_fetal_movement',
            textEn: 'Noticeable decrease or absence of fetal kicks/movements in last 12 hours?',
            textHi: 'क्या पिछले 12 घंटों में शिशु की हलचल में उल्लेखनीय कमी या ठहराव है?',
            textMr: 'गेल्या १२ तासांत बाळाच्या हालचालींमध्ये लक्षणीय घट किंवा हालचाल थांबली आहे का?',
            isRedFlag: true,
            clinicalRationale: 'Fetal distress indicator',
          ),
          CategoryQuestion(
            id: 'mat_swelling',
            textEn: 'Sudden severe swelling of face, hands, or feet?',
            textHi: 'क्या चेहरे, हाथों या पैरों में अचानक तेज सूजन आई है?',
            textMr: 'चेहरा, हात किंवा पायांवर अचानक तीव्र सूज आली आहे का?',
            isRedFlag: false,
            clinicalRationale: 'Pre-eclampsia screening',
          ),
        ];
      case PatientCategory.childUnder5:
        return const [
          CategoryQuestion(
            id: 'child_lethargy',
            textEn: 'Child is abnormally sleepy, unconscious, or unable to be awakened?',
            textHi: 'क्या बच्चा अत्यधिक सुस्त, बेहोश या जगाने में असमर्थ है?',
            textMr: 'मूल असामान्यपणे झोपलेले, बेशुद्ध किंवा जागे होण्यास असमर्थ आहे का?',
            isRedFlag: true,
            clinicalRationale: 'IMNCI General Danger Sign (MoHFW)',
          ),
          CategoryQuestion(
            id: 'child_breathing',
            textEn: 'Chest indrawing, grunting, or severe fast breathing?',
            textHi: 'क्या सीने में गड्ढे पड़ रहे हैं (पसलियां धंसना) या सांस तेज चल रही है?',
            textMr: 'छाती खोलवर ओढली जात आहे का किंवा श्वास खूप जलद चालत आहे का?',
            isRedFlag: true,
            clinicalRationale: 'Severe pneumonia / respiratory distress (RBSK Protocol)',
          ),
          CategoryQuestion(
            id: 'child_vomiting',
            textEn: 'Unable to drink/breastfeed or vomiting everything consumed?',
            textHi: 'क्या बच्चा दूध पीने में असमर्थ है या जो कुछ खाता-पीता है सब उल्टी कर देता है?',
            textMr: 'मूल दूध पिण्यास असमर्थ आहे किंवा खाल्लेले सर्व उलटून काढत आहे का?',
            isRedFlag: true,
            clinicalRationale: 'Severe dehydration & systemic sepsis (IMNCI)',
          ),
          CategoryQuestion(
            id: 'child_convulsions',
            textEn: 'Any history of seizures, fits, or abnormal shaking episodes during this illness?',
            textHi: 'क्या इस बीमारी के दौरान दौरे, झटके या असामान्य कंपकंपी हुई है?',
            textMr: 'या आजारपणात झटके किंवा आकडी आली होती का?',
            isRedFlag: true,
            clinicalRationale: 'Febrile seizure / CNS infection danger sign',
          ),
        ];
      case PatientCategory.adultMale:
        return const [
          CategoryQuestion(
            id: 'male_chest_pressure',
            textEn: 'Severe crushing chest pain, pressure, or tightness radiating to left arm/jaw?',
            textHi: 'क्या सीने में भारी दबाव, जकड़न या बाएँ हाथ/जबड़े में दर्द हो रहा है?',
            textMr: 'छातीत प्रचंड दाब, आवळल्यासारखे वाटणे किंवा डाव्या हाताकडे/जबड्याकडे वेदना होत आहेत का?',
            isRedFlag: true,
            clinicalRationale: 'Acute coronary syndrome / Myocardial infarction (MoHFW STEMI Protocol)',
          ),
          CategoryQuestion(
            id: 'male_breathlessness',
            textEn: 'Sudden severe breathlessness or suffocating feeling while resting?',
            textHi: 'क्या आराम करते समय भी अचानक सांस फूल रही है या दम घुट रहा है?',
            textMr: 'विश्रांती घेत असतानाही अचानक धाप लागणे किंवा गुदमरल्यासारखे होत आहे का?',
            isRedFlag: true,
            clinicalRationale: 'Acute pulmonary edema / severe bronchospasm',
          ),
          CategoryQuestion(
            id: 'male_stroke_symptoms',
            textEn: 'Sudden weakness on one side of face/body, slurred speech, or loss of balance?',
            textHi: 'क्या चेहरे/शरीर के एक तरफ कमजोरी, बोलने में लड़खड़ाहट या संतुलन बिगड़ा है?',
            textMr: 'चेहऱ्याची किंवा शरीराची एक बाजू कमकुवत होणे, बोलताना अडखळणे किंवा तोल जाणे आहे का?',
            isRedFlag: true,
            clinicalRationale: 'FAST Stroke protocol alert',
          ),
          CategoryQuestion(
            id: 'male_high_fever',
            textEn: 'Persistent high fever (>102°F) for more than 3 days with intense headache?',
            textHi: 'क्या 3 दिन से अधिक समय से तेज बुखार (102°F से अधिक) और सिरदर्द है?',
            textMr: '३ दिवसांपेक्षा जास्त काळ तीव्र ताप (१०२°F पेक्षा जास्त) व डोकेदुखी आहे का?',
            isRedFlag: false,
            clinicalRationale: 'Severe infectious etiology / vector borne infection',
          ),
        ];
      case PatientCategory.adultFemaleElderly:
        return const [
          CategoryQuestion(
            id: 'female_chest_shortness',
            textEn: 'Sudden severe shortness of breath, unexplained cold sweating, or chest tightness?',
            textHi: 'क्या अचानक सांस लेने में भारी कठिनाई, अकारण ठंडा पसीना या सीने में जकड़न है?',
            textMr: 'अचानक तीव्र श्वास लागणे, अकारण थंड घाम किंवा छातीत आवळल्यासारखे वाटणे आहे का?',
            isRedFlag: true,
            clinicalRationale: 'Atypical presentation of acute coronary syndrome in women/elderly',
          ),
          CategoryQuestion(
            id: 'female_severe_abdominal_pain',
            textEn: 'Severe acute lower abdominal or pelvic pain with guarding/rigidity?',
            textHi: 'क्या पेट के निचले हिस्से में असहनीय दर्द या पेट में कड़ापन है?',
            textMr: 'पोटाच्या खालच्या भागात असह्य वेदना किंवा पोट ताठरले आहे का?',
            isRedFlag: true,
            clinicalRationale: 'Acute surgical abdomen / pelvic emergency',
          ),
          CategoryQuestion(
            id: 'female_fall_mobility',
            textEn: 'Recent fall with severe hip/joint pain and complete inability to bear weight?',
            textHi: 'क्या हाल ही में गिरने के बाद कूल्हे/जोड़ में तेज दर्द और वजन उठाने में असमर्थता है?',
            textMr: 'नुकत्याच पडल्यानंतर खुबा/सांध्यात तीव्र वेदना आणि उभे राहण्यास पूर्णपणे असमर्थ आहात का?',
            isRedFlag: false,
            clinicalRationale: 'Fragility fracture / orthopedic trauma in elderly',
          ),
          CategoryQuestion(
            id: 'female_confusion_fever',
            textEn: 'Sudden confusion, disorientation, or high fever with shivering?',
            textHi: 'क्या अचानक भ्रम/भूलने की स्थिति या कंपकंपी के साथ तेज बुखार है?',
            textMr: 'अचानक गोंधळलेली अवस्था/स्मृतीभ्रंश किंवा थंडी वाजून तीव्र ताप आहे का?',
            isRedFlag: false,
            clinicalRationale: 'Geriatric sepsis / acute delirium screening',
          ),
        ];
    }
  }

  /// Calculates Triage Priority (P0, P1, P2) based on multi-modal parameters
  TriageAssessmentDto evaluate({
    required String patientId,
    required String patientName,
    required PatientCategory category,
    required int heartRate,
    required int spO2,
    required double bodyTemp,
    required int systolicBp,
    required int diastolicBp,
    required Map<String, bool> questionAnswers,
    String rawMessage = '',
    List<String> nlpSymptoms = const [],
    String organZone = 'General',
    int existingQueueCount = 4,
    PainAssessmentDto? painAssessment,
    AnatomicalRegionDto? selectedRegion,
  }) {
    final List<String> redFlags = [];
    TriagePriority priority = TriagePriority.p2Green;

    // 1. Evaluate Hardware Vitals
    if (spO2 > 0 && spO2 < 90) {
      priority = TriagePriority.p0Red;
      redFlags.add('Hypoxemia: SpO2 critical at $spO2% (< 90%)');
    } else if (spO2 >= 90 && spO2 <= 94) {
      if (priority != TriagePriority.p0Red) priority = TriagePriority.p1Yellow;
    }

    if (heartRate > 130) {
      priority = TriagePriority.p0Red;
      redFlags.add('Extreme Tachycardia: Heart rate $heartRate bpm (> 130)');
    } else if (heartRate > 0 && heartRate < 45) {
      priority = TriagePriority.p0Red;
      redFlags.add('Severe Bradycardia: Heart rate $heartRate bpm (< 45)');
    } else if (heartRate > 105 || (heartRate > 0 && heartRate < 55)) {
      if (priority != TriagePriority.p0Red) priority = TriagePriority.p1Yellow;
    }

    if (bodyTemp >= 103.0) {
      if (priority != TriagePriority.p0Red) priority = TriagePriority.p1Yellow;
    }

    // 2. Evaluate Manual Blood Pressure
    if (systolicBp >= 160 || diastolicBp >= 110) {
      priority = TriagePriority.p0Red;
      redFlags.add('Hypertensive Crisis: BP $systolicBp/$diastolicBp mmHg (≥ 160/110)');
    } else if (systolicBp > 0 && systolicBp < 85) {
      priority = TriagePriority.p0Red;
      redFlags.add('Hypotensive Shock: Systolic BP $systolicBp mmHg (< 85)');
    } else if (systolicBp >= 140 || diastolicBp >= 90) {
      if (priority != TriagePriority.p0Red) priority = TriagePriority.p1Yellow;
    }

    // 3. Evaluate Universal Danger Questions & Category Questions
    final allQuestions = [
      ...getUniversalDangerQuestions(),
      ...getQuestionsForCategory(category),
      if (selectedRegion != null) ...getQuestionsForRegion(selectedRegion),
    ];

    for (final q in allQuestions) {
      if (questionAnswers[q.id] == true) {
        if (q.isRedFlag) {
          priority = TriagePriority.p0Red;
          redFlags.add('${q.textEn} (${q.clinicalRationale})');
        } else {
          if (priority != TriagePriority.p0Red) priority = TriagePriority.p1Yellow;
        }
      }
    }

    // 4. Evaluate Pain Matrix
    if (painAssessment != null) {
      if (painAssessment.severityScore >= 8) {
        if (priority != TriagePriority.p0Red) priority = TriagePriority.p1Yellow;
      }
      if (painAssessment.character.contains('Crushing') && painAssessment.radiation.contains('Arm')) {
        priority = TriagePriority.p0Red;
        redFlags.add('Crushing chest pain radiating to arm (Severe STEMI / Heart attack risk)');
      }
    }

    // 5. Generate Priority Queue Number
    final tokenSuffix = (existingQueueCount + 1).toString().padLeft(2, '0');
    final queueNumber = '${priority.code}-$tokenSuffix';

    return TriageAssessmentDto(
      id: 'TRG-${DateTime.now().millisecondsSinceEpoch % 100000}',
      patientId: patientId,
      patientName: patientName,
      category: category,
      heartRate: heartRate,
      spO2: spO2,
      bodyTemp: bodyTemp,
      systolicBp: systolicBp,
      diastolicBp: diastolicBp,
      questionAnswers: questionAnswers,
      rawPatientMessage: rawMessage,
      extractedSymptoms: nlpSymptoms,
      affectedBodyZone: selectedRegion?.nameEn ?? organZone,
      calculatedPriority: priority,
      queueNumber: queueNumber,
      redFlagAlerts: redFlags,
      assessedAt: DateTime.now(),
    );
  }
}
