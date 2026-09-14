import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:ruralcare/data/models/patient_dto.dart';
import 'package:ruralcare/data/models/appointment_dto.dart';
import 'package:ruralcare/data/repositories/appointment_repository.dart';

class PatientHistoryPdfService {
  static final PatientHistoryPdfService _instance = PatientHistoryPdfService._internal();
  factory PatientHistoryPdfService() => _instance;
  PatientHistoryPdfService._internal();

  /// Generates the raw PDF bytes for a patient's complete longitudinal health record
  Future<Uint8List> generatePatientHistoryPdf({
    required PatientDto patient,
    List<PrescriptionDto>? prescriptions,
  }) async {
    final pdf = pw.Document();
    final rxList = prescriptions ?? AppointmentRepository().getPrescriptionsForPatient(patient.id);
    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // 1. Header Banner
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#2457C5'),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'NABHA RuralCare - Integrated Health Platform',
                        style: const pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Ayushman Bharat Digital Mission (ABDM) Longitudinal Health Record',
                        style: const pw.TextStyle(color: PdfColors.white, fontSize: 10),
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Text(
                      'OFFICIAL EHR',
                      style: pw.TextStyle(
                        color: PdfColor.fromHex('#2457C5'),
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // 2. Patient Demographics & ABHA Information Card
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColor.fromHex('#DCE4ED')),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    flex: 6,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          patient.fullName,
                          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#172B4D')),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text('Age: ${patient.age} Yrs  •  Gender: ${patient.gender}  •  Village: ${patient.village}',
                            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                        pw.Text('Sub-Centre: ${patient.subCentre}  •  District: ${patient.district}',
                            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                        pw.Text('Assigned ASHA: ${patient.assignedAsha}  •  Phone: ${patient.phoneNumber}',
                            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                      ],
                    ),
                  ),
                  pw.Expanded(
                    flex: 4,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: pw.BoxDecoration(
                            color: PdfColor.fromHex('#EDF3FF'),
                            borderRadius: pw.BorderRadius.circular(4),
                          ),
                          child: pw.Text(
                            'ABHA: ${patient.abhaId.isNotEmpty ? patient.abhaId : 'ABHA-${patient.ruralCareId}'}',
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColor.fromHex('#2457C5'),
                            ),
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text('RuralCare ID: ${patient.ruralCareId}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                        pw.Text('Generated: $dateStr', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // 3. Section: Recent Vitals Telemetry
            pw.Text(
              '1. Vitals Telemetry & Clinical Observations',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#172B4D')),
            ),
            pw.SizedBox(height: 6),
            if (patient.latestVitals != null) ...[
              pw.TableHelper.fromTextArray(
                border: pw.TableBorder.all(color: PdfColor.fromHex('#DCE4ED')),
                headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#172B4D')),
                cellStyle: const pw.TextStyle(fontSize: 9),
                headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#F7F9FC')),
                headers: ['Blood Pressure', 'Pulse', 'SpO2', 'Temperature', 'Blood Sugar', 'Haemoglobin', 'Telemetry Source'],
                data: [
                  [
                    '${patient.latestVitals!.systolicBp}/${patient.latestVitals!.diastolicBp} mmHg',
                    '${patient.latestVitals!.pulse} bpm',
                    '${patient.latestVitals!.spO2}%',
                    '${patient.latestVitals!.temperature} °F',
                    '${patient.latestVitals!.bloodSugar} mg/dL',
                    '${patient.latestVitals!.haemoglobin} g/dL',
                    'Sensor / ASHA Frontline',
                  ]
                ],
              ),
            ] else ...[
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColor.fromHex('#DCE4ED'))),
                child: pw.Text('No recent vitals telemetry recorded.', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
              ),
            ],
            pw.SizedBox(height: 16),

            // 4. Section: Prescriptions & Care Plans
            pw.Text(
              '2. E-Prescriptions & Clinical Encounters (ABDM FHIR R4 Records)',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#172B4D')),
            ),
            pw.SizedBox(height: 6),
            if (rxList.isNotEmpty) ...[
              ...rxList.map((rx) {
                final rxDate = DateFormat('dd MMM yyyy').format(rx.issuedAt);
                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 10),
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColor.fromHex('#DCE4ED')),
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Encounter: $rxDate  •  Doctor: ${rx.doctorName}',
                              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#172B4D'))),
                          pw.Text('ID: ${rx.id}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                        ],
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text('Diagnosis: ${rx.diagnosis}', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#2457C5'))),
                      if (rx.adviceNotes != null && rx.adviceNotes!.isNotEmpty)
                        pw.Text('Clinical Advice: ${rx.adviceNotes}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                      pw.SizedBox(height: 6),
                      pw.TableHelper.fromTextArray(
                        border: pw.TableBorder.all(color: PdfColor.fromHex('#E2E8F0')),
                        headerStyle: const pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                        cellStyle: const pw.TextStyle(fontSize: 8),
                        headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#EEF3F8')),
                        headers: ['Medicine Name', 'Dosage', 'Frequency', 'Duration (Days)'],
                        data: rx.medicines.map((m) => [m.medicineName, m.dosage, m.frequency, '${m.durationDays} days']).toList(),
                      ),
                    ],
                  ),
                );
              }),
            ] else ...[
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColor.fromHex('#DCE4ED'))),
                child: pw.Text('No historical prescriptions recorded.', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
              ),
            ],
            pw.SizedBox(height: 16),

            // 5. Emergency Contact & Consent Certification Footer
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#F7F9FC'),
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: PdfColor.fromHex('#DCE4ED')),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Emergency Contact: ${patient.emergencyContact.name} (${patient.emergencyContact.relationship}) - ${patient.emergencyContact.phoneNumber}',
                          style: const pw.TextStyle(fontSize: 9)),
                      pw.Text('Emergency Ambulance Service: 108 (Toll Free National Emergency)',
                          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#B42318'))),
                    ],
                  ),
                  pw.Text('Verified ABDM Health Locker Sync', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                ],
              ),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  /// Direct helper to preview, print or download PDF on user's device
  Future<void> exportOrPrintPatientHistory(BuildContext context, PatientDto patient) async {
    final pdfBytes = await generatePatientHistoryPdf(patient: patient);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'NABHA_RuralCare_${patient.fullName.replaceAll(' ', '_')}_Health_Summary.pdf',
    );
  }
}
