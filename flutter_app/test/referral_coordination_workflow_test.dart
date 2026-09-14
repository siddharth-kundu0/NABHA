import 'package:flutter_test/flutter_test.dart';
import 'package:ruralcare/app/routes.dart';
import 'package:ruralcare/data/models/referral_dto.dart';
import 'package:ruralcare/data/repositories/referral_repository.dart';
import 'package:ruralcare/data/repositories/facility_repository.dart';
import 'package:ruralcare/data/repositories/notification_repository.dart';

import 'package:ruralcare/data/models/vitals_dto.dart';

void main() {
  group('End-to-End Rural Referral Coordination Workflow Tests', () {
    late ReferralRepository refRepo;
    late FacilityRepository facRepo;
    late NotificationRepository notifRepo;

    setUp(() {
      refRepo = ReferralRepository();
      facRepo = FacilityRepository();
      notifRepo = NotificationRepository();

      refRepo.resetToDefaults();
      refRepo.addReferral(
        ReferralDto(
          id: 'REF-11021',
          patientId: 'pat-002',
          patientName: 'Kavita Rajesh Devi',
          patientAge: 26,
          patientGender: 'Female',
          patientPhone: '+91 98234 11204',
          referringFacility: 'Kashti Sub-Centre',
          referringProviderName: 'Sunita Bai',
          referringProviderRole: 'ASHA Worker',
          targetFacilityId: 'FAC-SDH-301',
          targetFacilityName: 'Shirur Sub-District Hospital (उप-जिल्हा रुग्णालय)',
          requiredSpecialty: 'Obstetrician & Gynecologist',
          reason: 'High-risk Pregnancy (34 wks) with Severe Pre-eclampsia (BP 160/105 mmHg) and Pedal Edema',
          urgency: 'EMERGENCY',
          status: 'HOSPITAL_NOTIFIED',
          recommendationRationale: 'High-risk pre-eclampsia with emergency obstetric specialist care required',
          createdAt: DateTime.now().subtract(const Duration(minutes: 42)),
          updatedAt: DateTime.now().subtract(const Duration(minutes: 10)),
          vitals: VitalsDto(
            id: 'vit-101',
            patientId: 'pat-002',
            recordedById: 'hw-001',
            recordedByRole: 'ASHA',
            recordedAt: DateTime.now(),
            systolicBp: 148,
            diastolicBp: 98,
            pulse: 92,
            spO2: 97,
            temperature: 98.6,
            bloodSugar: 104,
            haemoglobin: 9.4,
          ),
          bloodUnitsRequired: const {'O+': 2},
          chronicConditions: const ['Gestational Hypertension', 'Mild Anemia'],
          diagnosticsPerformed: const ['Urine Albumin (3+)', 'Hemoglobin (9.4 g/dL)', 'Capillary Blood Glucose (104 mg/dL)'],
          checklistDone: const [true, true, true, false, false],
          coordinationNotes: [
            'Referral initiated by ASHA Sunita Bai after emergency detection at Kashti Sub-Centre at 10:15 AM.',
          ],
        ),
      );
      refRepo.addReferral(
        ReferralDto(
          id: 'REF-9842-104',
          patientId: 'pat-004',
          patientName: 'Ramesh Sharma',
          patientAge: 8,
          patientGender: 'Male',
          patientPhone: '+91 98221 55431',
          referringFacility: 'Kashti Sub-Centre',
          referringProviderName: 'Sunita Bai',
          referringProviderRole: 'ASHA Worker',
          targetFacilityId: 'FAC-SDH-301',
          targetFacilityName: 'Shirur Sub-District Hospital',
          requiredSpecialty: 'Pediatrics',
          reason: 'Severe acute asthma exacerbation',
          urgency: 'EMERGENCY',
          status: 'PENDING_TRIAGE',
          recommendationRationale: 'Pediatric specialist care required',
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        ),
      );
    });

    test('1. Initial referrals contain complete clinical and patient information', () {
      final kavita = refRepo.getReferralById('REF-11021');
      expect(kavita, isNotNull);
      expect(kavita!.patientName, equals('Kavita Rajesh Devi'));
      expect(kavita.patientAge, equals(26));
      expect(kavita.referringFacility, equals('Kashti Sub-Centre'));
      expect(kavita.referringProviderRole, equals('ASHA Worker'));
      expect(kavita.requiredSpecialty, equals('Obstetrician & Gynecologist'));
      expect(kavita.vitals, isNotNull);
      expect(kavita.vitals!.systolicBp, equals(148));
      expect(kavita.bloodUnitsRequired['O+'], equals(2));
      expect(kavita.chronicConditions, contains('Gestational Hypertension'));
      expect(kavita.diagnosticsPerformed, isNotEmpty);
    });

    test('2. Facility capability checking verifies specialist, diagnostics, and blood bank', () {
      final cap = refRepo.checkFacilityCapability(
        facilityId: 'FAC-SDH-301',
        requiredSpecialty: 'OB/GYN Specialist',
        requiredResources: ['MCH Ward Bed', 'Ultrasound (USG)', 'Emergency Bay'],
        bloodRequirements: {'O+': 2},
      );

      expect(cap.specialistAvailable, isTrue);
      expect(cap.diagnosticsAvailable, isTrue);
      expect(cap.bloodAvailable, isTrue);
      expect(cap.isFullyCapable, isTrue);
    });

    test('3. Clinical triage allows updating priority and required resources', () {
      refRepo.triageReferral(
        'REF-11021',
        priority: 'EMERGENCY',
        notes: 'BP persistently high (152/98) with proteinuria 2+. Escalated to emergency fast-track.',
      );

      final updated = refRepo.getReferralById('REF-11021');
      expect(updated!.urgency, equals('EMERGENCY'));
      expect(updated.isEmergency, isTrue);
      expect(updated.coordinationNotes.any((n) => n.contains('Escalated to emergency')), isTrue);
    });

    test('4. Accept referral reserves bed, blood units, and notifies referring ASHA', () {
      final initialOPlusStock = facRepo.currentFacility.bloodBankStock['O+'] ?? 0;

      refRepo.acceptReferral(
        'REF-11021',
        reservation: const BedReservationDto(
          bedNumber: 'MCH-04',
          bedType: 'MCH High-Dependency Bed',
          wardUnit: 'Maternal & Child Health Ward',
          assignedSpecialist: 'Dr. Rahul Shinde, MD (OB/GYN)',
        ),
        bloodUnitsToReserve: {'O+': 2},
      );

      final accepted = refRepo.getReferralById('REF-11021');
      expect(accepted!.status, equals('ACCEPTED'));
      expect(accepted.bedReservation, isNotNull);
      expect(accepted.bedReservation!.bedNumber, equals('MCH-04'));
      expect(accepted.bloodUnitsReserved['O+'], equals(2));

      // Facility repository updated
      final updatedOPlusStock = facRepo.currentFacility.bloodBankStock['O+'] ?? 0;
      expect(updatedOPlusStock, equals(initialOPlusStock - 2));

      // Notification dispatched
      final hwNotifs = notifRepo.getNotificationsForRole(AppRole.healthWorker);
      expect(hwNotifs.any((n) => n.title.contains('Referral Accepted') && n.title.contains('Kavita')), isTrue);
    });

    test('5. Rejection and Re-routing workflows correctly record rationale and notify', () {
      final ramesh = refRepo.getReferralById('REF-9842-104');
      expect(ramesh, isNotNull);

      // Re-route test
      refRepo.rerouteReferral(
        'REF-9842-104',
        targetFacilityId: 'FAC-DH-401',
        targetFacilityName: 'Aundh District Hospital',
        reason: 'Patient requires tertiary pediatric pulmonology intensive care.',
      );

      final rerouted = refRepo.getReferralById('REF-9842-104');
      expect(rerouted!.status, equals('RE_ROUTED'));
      expect(rerouted.reroutedFacilityId, equals('FAC-DH-401'));

      final hwNotifs = notifRepo.getNotificationsForRole(AppRole.healthWorker);
      expect(hwNotifs.any((n) => n.title.contains('Referral Re-routed') && n.message.contains('Aundh District Hospital')), isTrue);
    });

    test('6. Transport status tracking and delay escalation', () {
      refRepo.updateTransportStatus(
        'REF-11021',
        transport: const TransportDetailsDto(
          requirement: 'AMBULANCE_108',
          transportStatus: 'IN_TRANSIT',
          vehicleId: 'MH-12-AMB-108',
          driverName: 'Deepak Shinde',
          driverPhone: '+919811200108',
          estimatedTransitMinutes: 35,
        ),
      );

      var kavita = refRepo.getReferralById('REF-11021');
      expect(kavita!.transportDetails!.transportStatus, equals('IN_TRANSIT'));
      expect(kavita.status, equals('IN_TRANSIT'));

      // Simulate overdue transit delay
      refRepo.flagOverdueTransit('REF-11021', delayMinutes: 25);
      kavita = refRepo.getReferralById('REF-11021');
      expect(kavita!.isOverdue, isTrue);
      expect(kavita.coordinationNotes.any((n) => n.contains('DELAY ALERT')), isTrue);
    });

    test('7. Fast-track check-in by token or ID marks patient arrived and linked', () {
      final checkedIn = refRepo.checkInReferralByToken('REF-11021');
      expect(checkedIn, isNotNull);
      expect(checkedIn!.status, equals('CHECKED_IN'));
      expect(checkedIn.checkedInAt, isNotNull);
      expect(checkedIn.checkInToken, isNotNull);
    });

    test('8. Clinical handoff records structured vitals and handover note', () {
      refRepo.completeClinicalHandoff(
        'REF-11021',
        receivingDoctor: 'Dr. Rahul Shinde, MD (OB/GYN)',
        handoffNotes: 'Received in OB Emergency Bay 2. Triage Red. Administered IV Labetalol 20mg bolus, initiated CTG, infusing O+ RBC.',
      );

      final handedOff = refRepo.getReferralById('REF-11021');
      expect(handedOff!.clinicalHandoff, isNotNull);
      expect(handedOff.clinicalHandoff!.handoffCompleted, isTrue);
      expect(handedOff.clinicalHandoff!.receivingDoctor, equals('Dr. Rahul Shinde, MD (OB/GYN)'));
      expect(handedOff.status, equals('UNDER_EVALUATION'));
    });

    test('9. Post-arrival disposition updates status to ADMITTED', () {
      refRepo.recordDisposition(
        'REF-11021',
        disposition: 'ADMITTED',
        notes: 'Admitted to MCH High-Dependency Ward Bed 04. BP stabilized to 138/86 on Labetalol infusion.',
      );

      final admitted = refRepo.getReferralById('REF-11021');
      expect(admitted!.disposition, equals('ADMITTED'));
      expect(admitted.status, equals('ADMITTED'));
    });

    test('10. Counter-referral dispatches discharge plan, releases blood units, and notifies ASHA', () {
      // First accept referral to reserve blood units
      refRepo.acceptReferral(
        'REF-11021',
        reservation: const BedReservationDto(
          bedNumber: 'MCH-04',
          bedType: 'MCH High-Dependency Bed',
          wardUnit: 'Maternal & Child Health Ward',
          assignedSpecialist: 'Dr. Rahul Shinde, MD (OB/GYN)',
        ),
        bloodUnitsToReserve: {'O+': 2},
      );

      final stockAfterReserve = facRepo.currentFacility.bloodBankStock['O+'] ?? 0;

      refRepo.dispatchCounterReferral(
        referralId: 'REF-11021',
        counterReferral: CounterReferralDto(
          diagnosis: 'Severe Gestational Hypertension & Nutritional Anaemia (Stabilized)',
          treatmentProvided: 'IV Labetalol stabilized BP to 128/82. 2 units O+ packed cells infused. USG verified good fetal viability.',
          prescribedMedicines: const [
            'Tab Labetalol 100mg BD x 14 days',
            'Tab Calcium Carbonate 500mg OD',
            'Oral Iron Syrup (Syrup Autrin) 10ml OD',
          ],
          followUpInstructions: 'Weekly BP check at Kashti Sub-Centre. Restrict excess salt. Report immediately if severe headache occurs.',
          warningSigns: const [
            'Severe persistent headache',
            'Epigastric / right upper quadrant abdominal pain',
            'Visual blurring or flashing spots',
            'Decreased fetal kicks (<10 in 12 hours)',
          ],
          followUpDate: DateTime.now().add(const Duration(days: 7)),
          reasonForReturn: 'Acute hypertension controlled; patient fit for continuing rural antenatal monitoring.',
          receivingFacility: 'Kashti Sub-Centre',
          dispatchedAt: DateTime.now(),
          dispatchedBy: 'Dr. Rahul Shinde, MD (OB/GYN)',
        ),
      );

      final counterReferred = refRepo.getReferralById('REF-11021');
      expect(counterReferred!.status, equals('COUNTER_REFERRED'));
      expect(counterReferred.counterReferral, isNotNull);
      expect(counterReferred.counterReferral!.warningSigns.length, equals(4));

      // Reserved blood units released
      final releasedStock = facRepo.currentFacility.bloodBankStock['O+'] ?? 0;
      expect(releasedStock, equals(stockAfterReserve + 2));

      // Notification sent to ASHA
      final hwNotifs = notifRepo.getNotificationsForRole(AppRole.healthWorker);
      expect(hwNotifs.any((n) => n.title.contains('Counter-Referral Care Plan') && n.title.contains('Kavita')), isTrue);
    });

    test('11. Referral closure seals case and updates audit log', () {
      refRepo.closeReferral('REF-11021');

      final closed = refRepo.getReferralById('REF-11021');
      expect(closed!.status, equals('CLOSED'));
      expect(closed.coordinationNotes.any((n) => n.contains('closed')), isTrue);
    });
  });
}
