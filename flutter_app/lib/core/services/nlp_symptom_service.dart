import 'package:ruralcare/data/models/triage_dto.dart';

class NlpExtractionResult {
  final String rawQuery;
  final List<String> extractedSymptoms;
  final String primaryOrganZone;
  final List<String> redFlagAlerts;
  final TriagePriority suggestedPriority;
  final String summaryEn;
  final String summaryHi;
  final String summaryMr;

  const NlpExtractionResult({
    required this.rawQuery,
    required this.extractedSymptoms,
    required this.primaryOrganZone,
    required this.redFlagAlerts,
    required this.suggestedPriority,
    required this.summaryEn,
    required this.summaryHi,
    required this.summaryMr,
  });

  List<String> get dangerFlags => redFlagAlerts;
}

class NlpSymptomService {
  static final NlpSymptomService _instance = NlpSymptomService._internal();
  factory NlpSymptomService() => _instance;
  NlpSymptomService._internal();

  NlpExtractionResult parseMessage(String input) {
    final lower = input.toLowerCase().trim();
    final List<String> symptoms = [];
    final List<String> redFlags = [];
    String organ = 'General';
    TriagePriority priority = TriagePriority.p2Green;

    if (lower.isEmpty) {
      return const NlpExtractionResult(
        rawQuery: '',
        extractedSymptoms: [],
        primaryOrganZone: 'General',
        redFlagAlerts: [],
        suggestedPriority: TriagePriority.p2Green,
        summaryEn: 'No symptoms entered.',
        summaryHi: 'कोई लक्षण दर्ज नहीं किया गया।',
        summaryMr: 'कोणतीही लक्षणे नोंदवली नाहीत.',
      );
    }

    // 1. CHEST / CARDIAC & SEVERE RESPIRATORY (High Danger / P0 Red)
    if (_matchesAny(lower, [
      'chhati', 'chest', 'chaati', 'seene', 'seena', 'hriday',
      'breath', 'saans', 'swas', 'shwas', 'dum', 'suffocation',
      'heart attack', 'cardiac', 'palpitation'
    ])) {
      organ = 'Chest';
      if (_matchesAny(lower, ['dard', 'pain', 'dukhi', 'dukhat', 'tight', 'pressure', 'jalan', 'heaviness'])) {
        symptoms.add('Acute Chest Pain');
        redFlags.add('Potential acute coronary syndrome / cardiac emergency');
        priority = TriagePriority.p0Red;
      }
      if (_matchesAny(lower, ['saans', 'shwas', 'breath', 'swas', 'takleef', 'tras', 'shortness', 'gasping'])) {
        symptoms.add('Shortness of Breath (Dyspnea)');
        redFlags.add('Respiratory distress requiring immediate oxygenation');
        priority = TriagePriority.p0Red;
      }
    }

    // 2. ABDOMEN / GASTROINTESTINAL (e.g. "mera pet dukhra hai", "potat dukhatahe")
    if (_matchesAny(lower, [
      'pet', 'petat', 'stomach', 'abdomen', 'belly', 'tummy', 'pot', 'jathar'
    ])) {
      if (organ == 'General') organ = 'Abdomen';
      if (_matchesAny(lower, ['dukh', 'dard', 'pain', 'cramp', 'marod', 'dukhat', 'kharab'])) {
        final isSevereAbdomen = _matchesAny(lower, ['tez', 'bahut', 'severe', 'khup', 'marod', 'asahan', 'cramp']);
        if (isSevereAbdomen) {
          symptoms.add('Abdominal Pain & Cramping');
          if (priority != TriagePriority.p0Red) priority = TriagePriority.p1Yellow;
        } else {
          symptoms.add('Mild Abdominal Discomfort');
        }
      }
      if (_matchesAny(lower, ['ulti', 'vomit', 'matli', 'nausea', 'vomiting'])) {
        symptoms.add('Vomiting / Nausea');
      }
      if (_matchesAny(lower, ['dast', 'loose motion', 'diarrhoea', 'diarrhea', 'patla dast'])) {
        symptoms.add('Acute Diarrhoea');
      }
      if (_matchesAny(lower, ['jalan', 'acid', 'acidity', 'burning'])) {
        symptoms.add('Epigastric Burning / Gastric Distress');
      }
    }

    // 3. HEAD & NEUROLOGICAL (Headache, Dizziness, Vision)
    if (_matchesAny(lower, [
      'sar', 'sir', 'head', 'doke', 'matha', 'chakkar', 'dizziness', 'giddiness', 'behosh', 'faint'
    ])) {
      if (organ == 'General') organ = 'Head';
      final hasPain = _matchesAny(lower, ['dard', 'pain', 'dukh', 'dukhi', 'dukhat', 'heavy', 'bhari', 'vedna']);
      if (hasPain) {
        final isSevere = _matchesAny(lower, [
          'tez', 'bahut', 'severe', 'khup', 'asaadhya', 'migraine', 'unbearable', 'phat', 'extreme', 'worst', 'asahan'
        ]);
        if (isSevere) {
          symptoms.add('Severe Headache / Migraine');
          if (priority != TriagePriority.p0Red) priority = TriagePriority.p1Yellow;
        } else {
          // Normal, mild, or routine headache without severe descriptors
          symptoms.add('Mild / Normal Headache');
          // Keeps priority as p2Green unless elevated by other conditions
        }
      }
      if (_matchesAny(lower, ['chakkar', 'dizzy', 'giddy', 'spin', 'bhavre', 'chakar'])) {
        symptoms.add('Vertigo & Dizziness');
      }
      if (_matchesAny(lower, ['behosh', 'unconscious', 'faint', 'murccha', 'chhoti behoshi'])) {
        symptoms.add('Loss of Consciousness / Syncope');
        redFlags.add('Acute altered sensorium / syncopal episode');
        priority = TriagePriority.p0Red;
      }
    }

    // 4. MATERNAL & OBSTETRIC RED FLAGS
    if (_matchesAny(lower, ['garbh', 'pregnant', 'potat baal', 'garbhvati', 'bleeding', 'delivery', 'pani padla'])) {
      if (organ == 'General') organ = 'Pelvis';
      if (_matchesAny(lower, ['khoon', 'blood', 'bleeding', 'lal pani'])) {
        symptoms.add('Antepartum Hemorrhage / Vaginal Bleeding');
        redFlags.add('Severe obstetric hemorrhage risk');
        priority = TriagePriority.p0Red;
      }
      if (_matchesAny(lower, ['dard', 'pain', 'contraction', 'prasav'])) {
        symptoms.add('Obstetric Labour Pain');
        if (priority != TriagePriority.p0Red) priority = TriagePriority.p1Yellow;
      }
    }

    // 5. PEDIATRIC GENERAL DANGER SIGNS (Child < 5)
    if (_matchesAny(lower, ['baccha', 'baby', 'balak', 'chhota', 'doodh', 'dudh', 'pi nahi'])) {
      if (_matchesAny(lower, ['doodh nahi', 'dudh nahi', 'not feeding', 'unable to drink', 'ulti'])) {
        symptoms.add('Inability to Feed / Persistent Vomiting');
        redFlags.add('Pediatric general danger sign (IMNCI)');
        priority = TriagePriority.p0Red;
      }
    }

    // 6. FEVER & INFECTIONS
    if (_matchesAny(lower, ['bukhar', 'fever', 'taap', 'tap', 'garam'])) {
      final isSevereFever = _matchesAny(lower, ['tez', 'bahut', 'high', 'severe', 'khup']);
      if (isSevereFever) {
        if (!symptoms.contains('High Fever')) symptoms.add('High Fever');
        if (priority != TriagePriority.p0Red) priority = TriagePriority.p1Yellow;
      } else {
        if (!symptoms.contains('Mild / Moderate Fever')) symptoms.add('Mild / Moderate Fever');
      }
    }

    // 7. LIMBS & JOINTS
    if (_matchesAny(lower, ['haath', 'paon', 'pair', 'godi', 'leg', 'arm', 'joint', 'sandhi', 'sujan', 'swelling'])) {
      if (organ == 'General') organ = 'Limbs';
      if (_matchesAny(lower, ['sujan', 'swelling', 'edema'])) {
        symptoms.add('Limb Swelling / Pedal Edema');
      }
      if (_matchesAny(lower, ['dard', 'pain', 'fracture', 'mar lagla'])) {
        symptoms.add('Joint / Musculoskeletal Pain');
      }
    }

    // Fallback if no specific keyword triggered
    if (symptoms.isEmpty) {
      symptoms.add('General Discomfort / Health Concern');
    }

    final summaryEn = 'Identified symptoms: ${symptoms.join(', ')} (${priority.code} Priority)';
    final summaryHi = 'पहचाने गए लक्षण: ${symptoms.join(', ')} (${priority.code} प्राथमिकता)';
    final summaryMr = 'ओळखलेली लक्षणे: ${symptoms.join(', ')} (${priority.code} प्राधान्य)';

    return NlpExtractionResult(
      rawQuery: input,
      extractedSymptoms: symptoms,
      primaryOrganZone: organ,
      redFlagAlerts: redFlags,
      suggestedPriority: priority,
      summaryEn: summaryEn,
      summaryHi: summaryHi,
      summaryMr: summaryMr,
    );
  }

  bool _matchesAny(String text, List<String> keywords) {
    for (final k in keywords) {
      if (text.contains(k)) return true;
    }
    return false;
  }
}
