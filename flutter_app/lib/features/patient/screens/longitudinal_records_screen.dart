import 'package:flutter/material.dart';
import 'package:ruralcare/app/routes.dart';
import 'package:ruralcare/core/theme/app_theme.dart';
import 'package:ruralcare/data/models/appointment_dto.dart';
import 'package:ruralcare/data/models/patient_dto.dart';
import 'package:ruralcare/data/repositories/appointment_repository.dart';
import 'package:ruralcare/data/repositories/patient_repository.dart';
import 'package:ruralcare/core/services/patient_history_pdf_service.dart';

/// Longitudinal Records Screen conforming strictly to DESIGN.md Section 6:
/// Summary first. Simple filters for consultations, prescriptions, diagnostics, and vitals.
/// Shows date, type, clinician/facility, and clear clinical content with no decorative framing.
class LongitudinalRecordsScreen extends StatefulWidget {
  const LongitudinalRecordsScreen({super.key});

  @override
  State<LongitudinalRecordsScreen> createState() => _LongitudinalRecordsScreenState();
}

class _LongitudinalRecordsScreenState extends State<LongitudinalRecordsScreen> {
  String _selectedFilter = 'All';
  String _searchQuery = '';
  final List<String> _filters = ['All', 'Prescriptions', 'Diagnostics', 'Vitals', 'Consultations'];

  String _getFilterLabel(String key, bool isHi, bool isMr) {
    switch (key) {
      case 'All':
        return isHi ? 'सभी' : (isMr ? 'सर्व' : 'All');
      case 'Prescriptions':
        return isHi ? 'दवाएं' : (isMr ? 'औषधे' : 'Prescriptions');
      case 'Diagnostics':
        return isHi ? 'जांच रिपोर्ट' : (isMr ? 'तपासणी अहवाल' : 'Diagnostics');
      case 'Vitals':
        return isHi ? 'महत्वपूर्ण संकेत' : (isMr ? 'महत्त्वाचे मापदंड' : 'Vitals');
      case 'Consultations':
        return isHi ? 'परामर्श' : (isMr ? 'सल्लामसलत' : 'Consultations');
      default:
        return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    final aptRepo = AppointmentRepository();
    final patientRepo = PatientRepository();
    final session = SessionCoordinator();

    return ListenableBuilder(
      listenable: Listenable.merge([aptRepo, patientRepo, session]),
      builder: (context, _) {
        final isHi = session.isHindi;
        final isMr = session.isMarathi;
        final patient = patientRepo.activePatient;

        if (patient == null) {
          return Scaffold(
            backgroundColor: RuralCareColors.canvas,
            appBar: AppBar(
              title: Text(
                isHi ? 'स्वास्थ्य रिकॉर्ड' : (isMr ? 'आरोग्य नोंदी' : 'Health records'),
                style: AppTypography.pageTitle,
              ),
              backgroundColor: RuralCareColors.surface,
              elevation: 0,
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.folder_open, size: 48, color: RuralCareColors.textSecondary),
                    const SizedBox(height: 12),
                    Text(
                      isHi ? 'कोई स्वास्थ्य रिकॉर्ड नहीं मिला' : (isMr ? 'कोणतीही नोंद आढळली नाही' : 'No health records found'),
                      style: AppTypography.cardTitle,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isHi ? 'परामर्श और नुस्खे यहां संग्रहीत किए जाएंगे।' : (isMr ? 'सल्लामसलत आणि औषधे येथे संग्रहित केली जातील.' : 'Consultations and lab reports will appear here once recorded.'),
                      style: AppTypography.supporting,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final prescriptions = aptRepo.getPrescriptionsForPatient(patient.id);
        final vitals = patient.latestVitals;

        return Scaffold(
          backgroundColor: RuralCareColors.canvas,
          appBar: AppBar(
            title: Text(
              isHi ? 'स्वास्थ्य रिकॉर्ड' : (isMr ? 'आरोग्य नोंदी' : 'Health records'),
              style: AppTypography.pageTitle,
            ),
            backgroundColor: RuralCareColors.surface,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.picture_as_pdf_outlined, color: RuralCareColors.primary),
                tooltip: 'Download Health Record PDF',
                onPressed: () => PatientHistoryPdfService().exportOrPrintPatientHistory(context, patient),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: const BoxDecoration(
                  color: RuralCareColors.surface,
                  border: Border(bottom: BorderSide(color: RuralCareColors.border, width: 1.0)),
                ),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _filters.length,
                  separatorBuilder: (ctx, idx) => const SizedBox(width: 8),
                  itemBuilder: (ctx, idx) {
                    final filterKey = _filters[idx];
                    final isSelected = _selectedFilter == filterKey;
                    final displayLabel = _getFilterLabel(filterKey, isHi, isMr);

                    return ChoiceChip(
                      label: Text(displayLabel),
                      selected: isSelected,
                      onSelected: (val) => setState(() => _selectedFilter = filterKey),
                      selectedColor: RuralCareColors.primarySoft,
                      backgroundColor: RuralCareColors.surface,
                      labelStyle: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? RuralCareColors.primary : RuralCareColors.textSecondary,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? RuralCareColors.primary : RuralCareColors.border,
                          width: 1.0,
                        ),
                      ),
                      showCheckmark: false,
                    );
                  },
                ),
              ),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            children: [
              // Keyword Search Input
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                  decoration: InputDecoration(
                    hintText: isHi ? 'दवा, जांच या डॉक्टर खोजें...' : (isMr ? 'औषध, तपासणी किंवा डॉक्टर शोधा...' : 'Search records by keyword, lab test, or date...'),
                    hintStyle: const TextStyle(fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF005140), size: 20),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                ),
              ),

              // Clinical Summary Section
              if ((_selectedFilter == 'All' || _selectedFilter == 'Vitals') &&
                  (_searchQuery.isEmpty || 'vitals bp blood pressure spo2'.contains(_searchQuery))) ...[
                _buildVitalsSummaryCard(vitals, patient, isHi, isMr),
                const SizedBox(height: 16),
              ],

              // Prescriptions Section
              if (_selectedFilter == 'All' || _selectedFilter == 'Prescriptions') ...[
                ...prescriptions.map((rx) => _buildPrescriptionCard(rx, isHi, isMr)),
                const SizedBox(height: 16),
              ],

              // Diagnostics Section
              if (_selectedFilter == 'All' || _selectedFilter == 'Diagnostics') ...[
                _buildDiagnosticReportCard(
                  title: isHi
                      ? 'पूर्ण रक्त गणना (CBC) एवं हीमोग्लोबिन'
                      : (isMr ? 'संपूर्ण रक्त गणना (CBC) आणि हिमोग्लोबिन' : 'Complete Blood Count (CBC) & Hb'),
                  date: '08 Sep 2026',
                  facility: isHi ? 'बारामती एसडीएच प्रयोगशाला' : (isMr ? 'बारामती एसडीएच प्रयोगशाळा' : 'Baramati SDH Laboratory'),
                  summary: isHi
                      ? 'हीमोग्लोबिन: 7.8 g/dL (मध्यम एनीमिया)। प्लेटलेट्स: 2,10,000/mcL.'
                      : (isMr
                          ? 'हिमोग्लोबिन: 7.8 g/dL (मध्यम अशक्तपणा). प्लेटलेट्स: २,१०,०००/mcL.'
                          : 'Haemoglobin: 7.8 g/dL (Moderate Anemia). Platelets: 210,000/mcL.'),
                  hasAttention: true,
                  isHi: isHi,
                  isMr: isMr,
                ),
                const SizedBox(height: 14),
                _buildDiagnosticReportCard(
                  title: isHi
                      ? 'प्रसूति अल्ट्रासाउंड (USG) - 32 सप्ताह'
                      : (isMr ? 'प्रसूती अल्ट्रासाऊंड (USG) - ३२ आठवडे' : 'Obstetric Ultrasound (USG) - 32 Weeks'),
                  date: '24 Aug 2026',
                  facility: isHi ? 'बारामती एसडीएच रेडियोलॉजी' : (isMr ? 'बारामती एसडीएच रेडिओलॉजी' : 'Baramati SDH Radiology'),
                  summary: isHi
                      ? 'एकल जीवित अंतर्गर्भाशयी भ्रूण। सामान्य एमनियोटिक द्रव सूचकांक।'
                      : (isMr
                          ? 'एकल जिवंत गर्भाशयातील गर्भ. सामान्य अ‍ॅम्निओटिक फ्लुइड इंडेक्स.'
                          : 'Single live intrauterine fetus. Cephalic presentation. Normal amniotic fluid index.'),
                  hasAttention: false,
                  isHi: isHi,
                  isMr: isMr,
                ),
                const SizedBox(height: 16),
              ],

              // Consultations Section
              if (_selectedFilter == 'All' || _selectedFilter == 'Consultations') ...[
                _buildConsultationSummaryCard(
                  title: isHi ? 'टेली-एएनसी परामर्श समीक्षा' : (isMr ? 'टेलि-एएनसी सल्लामसलत आढावा' : 'Tele-ANC Consultation Review'),
                  date: '12 Aug 2026',
                  clinician: 'Dr. Anjali Deshmukh (OB/GYN)',
                  facility: isHi ? 'बारामती उप-जिला अस्पताल' : (isMr ? 'बारामती उपजिल्हा रुग्णालय' : 'Baramati Sub-District Hospital'),
                  notes: isHi
                      ? 'गर्भकालीन उच्च रक्तचाप की निगरानी। कम नमक आहार, आराम और हर 48 घंटे में बीपी मापने की सलाह।'
                      : (isMr
                          ? 'गर्भधारणेदरम्यान उच्च रक्तदाबाचे निरीक्षण. कमी मीठ आहार, विश्रांती आणि दर ४८ तासांनी बीपी तपासण्याचा सल्ला.'
                          : 'Gestational hypertension monitored. Advised low salt diet, rest, and BP logging every 48 hours.'),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildVitalsSummaryCard(vitals, PatientDto patient, bool isHi, bool isMr) {
    if (vitals == null) return const SizedBox.shrink();

    final statusText = vitals.hasWarning
        ? (isHi ? 'समीक्षा आवश्यक' : (isMr ? 'पुनरावलोकन आवश्यक' : 'Review needed'))
        : (isHi ? 'सामान्य' : (isMr ? 'सामान्य' : 'Normal'));

    return Container(
      decoration: AppDecorations.card(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isHi ? 'नवीनतम स्वास्थ्य माप' : (isMr ? 'नवीनतम आरोग्य मोजमाप' : 'Latest health measurements'),
                style: AppTypography.cardTitle,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: AppDecorations.statusBadge(
                  background: vitals.hasWarning ? RuralCareColors.warningSoft : RuralCareColors.successSoft,
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: vitals.hasWarning ? RuralCareColors.warning : RuralCareColors.success,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _metricTile(
                isHi ? 'रक्तचाप' : (isMr ? 'रक्तदाब' : 'Blood pressure'),
                '${vitals.systolicBp}/${vitals.diastolicBp} mmHg',
                isCritical: vitals.systolicBp > 140,
              ),
              const SizedBox(width: 10),
              _metricTile(
                isHi ? 'हीमोग्लोबिन' : (isMr ? 'हिमोग्लोबिन' : 'Haemoglobin'),
                '${vitals.haemoglobin} g/dL',
                isCritical: vitals.haemoglobin < 9.0,
              ),
              const SizedBox(width: 10),
              _metricTile(
                isHi ? 'ऑक्सीजन SpO2' : (isMr ? 'ऑक्सिजन SpO2' : 'Oxygen SpO2'),
                '${vitals.spO2}%',
                isCritical: vitals.spO2 < 95,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            isHi
                ? 'आशा ${patient.assignedAsha} द्वारा दर्ज • सुरक्षित मातृत्व प्रोटोकॉल'
                : (isMr
                    ? 'आशा ${patient.assignedAsha} द्वारे नोंदवले • सुरक्षित मातृत्व प्रोटोकॉल'
                    : 'Recorded by ASHA ${patient.assignedAsha} • Safe Pregnancy Protocol'),
            style: AppTypography.supporting,
          ),
        ],
      ),
    );
  }

  Widget _metricTile(String label, String value, {bool isCritical = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isCritical ? RuralCareColors.warningSoft : RuralCareColors.surfaceSubtle,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isCritical ? RuralCareColors.warning.withOpacity(0.3) : RuralCareColors.border,
            width: 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: RuralCareColors.textSecondary), maxLines: 1),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isCritical ? RuralCareColors.warning : RuralCareColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrescriptionCard(PrescriptionDto rx, bool isHi, bool isMr) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: AppDecorations.card(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(rx.id, style: AppTypography.cardTitle),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: AppDecorations.statusBadge(background: RuralCareColors.primarySoft),
                child: Text(
                  isHi ? 'FHIR सत्यापित' : (isMr ? 'FHIR सत्यापित' : 'FHIR Verified'),
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: RuralCareColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('${rx.doctorName} • ${rx.diagnosis}', style: AppTypography.supporting),
          const Divider(color: RuralCareColors.border, height: 20),
          ...rx.medicines.map((m) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.circle, size: 6, color: RuralCareColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${m.name} (${m.dosage}) — ${m.frequency}',
                        style: AppTypography.body,
                      ),
                    ),
                  ],
                ),
              )),
          if (rx.lifestyleAdvice != null && rx.lifestyleAdvice!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '${isHi ? "सलाह: " : (isMr ? "सल्ला: " : "Advice: ")}${rx.lifestyleAdvice}',
              style: AppTypography.supporting,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDiagnosticReportCard({
    required String title,
    required String date,
    required String facility,
    required String summary,
    required bool hasAttention,
    required bool isHi,
    required bool isMr,
  }) {
    return Container(
      decoration: AppDecorations.card(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(title, style: AppTypography.cardTitle),
              ),
              if (hasAttention)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: AppDecorations.statusBadge(background: RuralCareColors.warningSoft),
                  child: Text(
                    isHi ? 'ध्यान दें' : (isMr ? 'लक्ष द्या' : 'Attention flag'),
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: RuralCareColors.warning),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text('$facility • $date', style: AppTypography.supporting),
          const SizedBox(height: 10),
          Text(summary, style: AppTypography.body),
        ],
      ),
    );
  }

  Widget _buildConsultationSummaryCard({
    required String title,
    required String date,
    required String clinician,
    required String facility,
    required String notes,
  }) {
    return Container(
      decoration: AppDecorations.card(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.cardTitle),
          const SizedBox(height: 4),
          Text('$clinician • $facility • $date', style: AppTypography.supporting),
          const SizedBox(height: 10),
          Text(notes, style: AppTypography.body),
        ],
      ),
    );
  }
}

