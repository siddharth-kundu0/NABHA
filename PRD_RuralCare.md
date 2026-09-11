# RuralCare — Product Requirements Document (PRD)

## 1. Product Overview

**Product:** RuralCare  
**Positioning:** Integrated rural healthcare access, continuity and coordination platform.

RuralCare is designed for rural and underserved communities where patients may face long travel distances, specialist shortages, fragmented records, delayed referrals, irregular diagnostics, medicine availability uncertainty, connectivity limitations, language barriers and gaps in follow-up.

RuralCare connects:
- Patients
- Frontline health workers
- Doctors and specialists
- Facility staff
- System administrators
- Healthcare facilities
- Optional connected health hardware for high-risk patients and pregnant women

The product is intended to strengthen coordination around the public-health journey rather than replace doctors, facilities or emergency services.

---

## 2. Problem Statement

The existing healthcare journey can break across multiple points:

1. Patient is screened locally.
2. Information may not follow the patient between facilities.
3. A specialist may not be available locally.
4. Diagnostics or medicines may not be immediately available.
5. Referral decisions may be made without a complete view of facility capability.
6. Patients may not know referral status or whether they reached the receiving facility.
7. High-risk patients may not be monitored continuously.
8. Follow-up can be delayed or missed.
9. Low-connectivity environments can interrupt digital workflows.

RuralCare addresses these gaps through coordinated digital workflows, longitudinal records, assisted teleconsultation, digital triage, referral tracking, facility/service visibility, follow-up management, emergency escalation and optional remote patient monitoring.

---

## 3. Product Goals

### Primary goals

- Improve timely access to appropriate healthcare.
- Maintain continuity of patient information across facilities.
- Support frontline workers and doctors with structured patient information.
- Reduce avoidable referral delays.
- Improve referral completion and follow-up.
- Improve visibility of medicine and diagnostic availability.
- Provide assisted teleconsultation.
- Support high-risk and maternal-health monitoring.
- Provide offline/low-connectivity workflows.
- Create clear escalation pathways for abnormal remote-monitoring events.

### Secondary goals

- Support multilingual interfaces.
- Support voice/local-language interaction where feasible.
- Make facility capacity and service information easier to coordinate.
- Provide operational dashboards for facilities and administrators.
- Keep data structures compatible with future interoperability work.

---

## 4. Non-Goals / Guardrails

RuralCare must not:

- Replace clinical judgement with autonomous AI.
- Claim a diagnosis solely from an algorithm.
- Promise ambulance dispatch without a real integration.
- Promise emergency-service availability.
- Invent government integrations, certifications or official claims.
- Automatically share a patient's complete medical record during emergencies.
- Recommend alternative medicines/substitutions without appropriate clinical workflow.
- Use hard-coded emergency numbers unless an actual approved integration/process is implemented.
- Present sample/demo data as real government or patient data.

AI, where used, is decision support only.

---

## 5. Target Users

### Patient
Needs appointments, records, teleconsultation, referrals, medicine and diagnostic visibility, follow-up reminders, emergency access and optional connected-device monitoring.

### Health Worker
Examples: ASHA, ANM, CHO and other frontline workers.

Needs patient registration, screening, vitals capture, triage support, high-risk prioritisation, follow-up, home-visit tasks, referrals and alerts.

### Doctor / Specialist
Needs patient clinical history, vitals, records, teleconsultation, prescriptions, diagnostics, referrals, follow-up and remote-monitoring trends.

### Facility Staff
Includes:
- Facility Admin/Manager
- Doctor/Specialist
- Pharmacist
- Diagnostic staff
- Other authorised staff

Needs queues, patient intake, facility services, medicine/diagnostic status, referrals, facility operations and coordination.

### System Administrator
Needs:
- User and role management
- Facility management
- Approval workflows
- System monitoring
- Audit logs
- Administrative/security controls

---

## 6. Facility Model

A healthcare facility is an organisational entity, not a public user role.

Possible facility types:
- Sub-centre
- PHC
- CHC
- Rural Hospital
- District Hospital
- Other supported facilities

The data model should support government/public facilities first and leave room for future private facilities without redesigning the core model.

Example relationship:

`Doctor User → Facility ID → Facility`

A doctor may be associated with one or multiple facilities.

---

## 7. Core Product Modules

### Patient
- Onboarding
- Dashboard
- Appointments
- Medical Records
- Teleconsultation
- Referrals
- Medicines
- Diagnostics
- Follow-up
- Notifications
- Emergency Response
- Remote Patient Monitoring
- Profile / Settings

### Health Worker
- Dashboard
- Patient Registration
- Patient Queue
- Screening & Vitals
- Digital Triage
- High-Risk Patient List
- Follow-ups
- Home Visits
- Referral Management
- Alerts
- Maternal Health
- Chronic Disease Monitoring

### Doctor / Specialist
- Dashboard
- Patient Queue
- Clinical Summary
- Consultation & Care Plan
- Records
- Prescription
- Diagnostics
- Referrals
- Teleconsultation
- Remote Patient Monitoring
- High-Risk Monitoring
- Follow-up

### Facility
- Facility Dashboard
- Patient Queue
- Facility Services & Availability
- Medicines
- Diagnostics
- Referral Coordination
- Facility operations

### System Admin
- System Admin Dashboard
- User & Role Management
- Healthcare Facility Management
- System Monitoring & Audit

---

## 8. Patient Experience

### Patient navigation

`Home | Appointments | Records | Referrals | Profile`

Feature modules such as medicines, diagnostics, teleconsultation and emergency are reached from the dashboard and relevant workflows rather than becoming permanent navigation tabs.

### Patient onboarding

1. Welcome
2. Language Selection
3. Role Selection
4. Mobile Number
5. OTP
6. Basic Profile
7. Location / Healthcare Area
8. Account Created
9. Patient Dashboard

Interface language is selected by the user. The normal UI should not intentionally display English + Hindi + Marathi together unless a specific bilingual accessibility component is needed.

---

## 9. Digital Triage

Digital triage is decision support.

Potential inputs:
- Symptoms
- Vitals
- Medical history
- Risk flags
- Maternal/ANC information
- Existing conditions
- Recent clinical data

Possible outputs:
- Routine / lower-risk pathway
- High-risk pathway
- Emergency pathway

High-risk cases may lead to:
`Doctor Review → Teleconsultation → Referral Decision → Smart Facility Selection`

Emergency cases should use the dedicated emergency pathway.

Clinical thresholds and rules require clinical validation before implementation.

---

## 10. Connected Hardware / Remote Patient Monitoring

### Hardware scope

Initial planned measurements:
- Heart rate
- SpO₂
- Body temperature

Target population:
- High-risk patients
- Pregnant women

Future hardware integrations may expand only after validation.

### Data flow

`Hardware → Patient/Worker Device → RuralCare App → Backend → Patient Record / Monitoring → Clinician Dashboard`

Each measurement should record:
- patient
- device
- metric
- value
- unit
- timestamp
- sync state
- source
- optional quality/error metadata

### Monitoring states

- Normal
- Abnormal
- Critical
- Device disconnected
- Pending sync
- Offline
- Data unavailable

Do not hard-code clinical thresholds until approved by the clinical team.

---

## 11. Alert & Escalation

### Proposed escalation concept

1. Abnormal reading detected.
2. Reading/event is stored.
3. Patient receives appropriate warning when applicable.
4. Registered next of kin is notified according to the configured rule.
5. System continues monitoring.
6. If the validated persistence/escalation condition is met, the appropriate healthcare facility/clinical team is notified.
7. Facility acknowledges or manages the alert.
8. Emergency conditions may bypass the persistence step and use immediate escalation.

### Required statuses

- Detected
- Monitoring
- Notification queued
- Next of kin notified
- Facility notified
- Acknowledged
- Escalated
- Resolved
- Failed / unavailable

The system must not claim that a notification was delivered unless delivery is actually confirmed by the notification provider.

---

## 12. Emergency Response

Emergency flow:

`Emergency Help → Confirm Emergency → Alert Sent → Contacts/Facility Notified → Services/Integration Status → Resolved/Cancelled`

The system must distinguish:
- Sent
- Notified
- Connecting
- Unavailable
- Failed

Only the minimum necessary patient information should be shared.

Location sharing should be explicit and should not imply continuous tracking.

---

## 13. Smart Referral

RuralCare should select an appropriate receiving facility based on relevant capability, not only distance.

Potential facility-selection factors:
- Distance
- Specialist availability
- Bed availability
- Blood availability
- Diagnostic capability
- Medicine availability
- Emergency capability
- Transport availability
- Facility readiness

Example concept:

Hospital A is closer but lacks the required specialist.  
Hospital B is farther but has specialist + bed.  
Hospital C lacks the required diagnostic facility.

The system can recommend Hospital B when the validated rules indicate it is the most suitable option.

---

## 14. Referral Lifecycle

Proposed lifecycle:

`Created → Facility Selected → Referral Sent → Facility Accepted → Appointment/Visit → Transport (when available) → Patient Arrived → Treatment → Completed → Follow-up`

Not all states must be mandatory for every referral.

Every referral should have a unique reference identifier.

---

## 15. Teleconsultation

Assisted teleconsultation workflow:

1. Teleconsultation Landing
2. Choose Doctor/Specialist
3. Consultation Details
4. Waiting Room
5. Live Consultation
6. Consultation Completed

Live consultation:
- Video is primary.
- Transcript is secondary/collapsible.
- Transcript is a communication aid and must not automatically become the official medical record.
- Consent is explicit for optional record sharing.

---

## 16. Longitudinal Records

Records should support:
- Consultations
- Prescriptions
- Diagnostics
- Vitals
- Referrals
- Follow-ups
- Maternal/ANC information
- Remote-monitoring events

Record summaries should be shown first, with details one tap away.

The data model should be interoperability-friendly and designed so future standards/integrations can be added without restructuring the product.

---

## 17. Medicine Module

Flow:

`Medicines Overview → Search Medicine → Medicine Details → Availability by Facility → Availability Result`

Availability states:
- Available
- Low Stock
- Out of Stock
- Stock Information Unavailable

Avoid presenting exact inventory quantities unless the underlying system actually provides them.

---

## 18. Diagnostics Module

Flow:

`Diagnostics Overview → Select Test → Test Details → Find Facility → Diagnostic Report`

Separate:
- Test information
- Facility availability
- Result/report

Do not invent test preparation requirements.

---

## 19. Maternal Health

Target workflow:
- Pregnancy registration
- ANC visits
- Expected delivery date
- High-risk pregnancy identification
- Vitals
- Relevant clinical measurements
- Previous complications
- Delivery
- PNC
- Follow-up
- Alerts/referrals

High-risk maternal care should connect to remote monitoring, doctor review, referral and emergency coordination.

---

## 20. Chronic Disease Follow-up

Initial focus:
- Hypertension
- Diabetes
- Other clinically validated NCD workflows

Track:
- Measurements
- Treatment
- Follow-up date
- Adherence/follow-up state
- Abnormal trends
- Missed follow-up
- Referral status

---

## 21. Offline / Low-Connectivity Requirements

The product must support:

- Local capture where required
- Pending-sync state
- Last synchronized timestamp
- Retry
- Conflict handling
- Clear offline/online state
- Safe queueing of events
- No false claim that data has reached the server

Critical safety workflows require explicit failure handling.

---

## 22. Notifications

Possible notification classes:
- Appointment reminder
- Follow-up reminder
- Referral status
- Medicine/diagnostic availability update
- Remote-monitoring alert
- Next-of-kin notification
- Facility escalation
- System/admin event

Notification delivery status must be auditable.

---

## 23. Multilingual Accessibility

Initial languages:
- English
- Hindi
- Marathi

Rules:
- User selects interface language.
- Normal screen content should use the selected language.
- Avoid unnecessary simultaneous bilingual text.
- Where bilingual clinical or accessibility wording is necessary, it should be intentional rather than accidental.
- Voice/local-language interaction may be added later.

---

## 24. Security & Access

Foundation:
- Authentication
- Role-based access control
- Organization/facility-based access control
- Least-privilege access
- Audit logging
- Explicit consent for data sharing
- Secure storage
- Notification auditing

A system administrator is not equivalent to a doctor or facility user.

---

## 25. Technical Direction

Current agreed direction:

### Frontend
- Next.js
- TypeScript
- Responsive/PWA approach

### Backend
- Firebase initially:
  - Authentication
  - Firestore
  - Storage
  - Cloud Functions
  - Notifications

### Application APIs
Own `/api/...` interfaces for:
- Patients
- Appointments
- Triage
- Teleconsultation
- Referrals
- Medicines
- Diagnostics
- Follow-ups
- Monitoring
- Alerts
- Dashboards

### External integrations
Use mocks first; integrate real services only when available and validated.

Potential future integrations:
- ABDM/interoperability services
- Language/translation service
- Push notifications
- Maps
- Video
- Emergency/transport services
- Hardware/device SDKs

Do not claim an integration until it is implemented and tested.

---

## 26. Success Metrics

Suggested product metrics:

### Access
- Appointment completion rate
- Teleconsultation completion rate
- Average referral creation-to-acceptance time

### Continuity
- Referral completion rate
- Follow-up completion rate
- Record availability across facilities

### Operational
- Queue waiting time
- Facility information freshness
- Medicine/diagnostic availability update freshness

### Monitoring
- Remote-monitoring data sync success
- Alert acknowledgement time
- Escalation completion rate

### Maternal/high-risk
- High-risk case review rate
- Follow-up completion
- Alert response time

These metrics require validated definitions before production measurement.

---

## 27. MVP vs Later

### MVP
- Patient onboarding/dashboard
- Appointments
- Records
- Teleconsultation
- Referrals
- Medicines
- Diagnostics
- Emergency workflow
- Health worker workflow
- Doctor/facility workflow
- System admin
- Offline basics
- Mock notification flows

### Next stage
- Connected hardware
- Remote patient monitoring
- Alert escalation
- Maternal/high-risk monitoring
- Smart facility selection
- Transport/ambulance integrations
- Interoperability integrations
- Voice/local-language support

---

## 28. Design Source of Truth

- Stitch = visual design source of truth.
- Antigravity = working application/code source of truth.

Do not redesign existing approved screens unless a genuine functional or consistency issue is found.

The current approved visual direction is the RuralCare V2 design system.

---

## 29. Key Risks

- Clinical threshold validation
- Sensor/device reliability
- False alerts
- Missed alerts
- Offline synchronization conflicts
- Facility data freshness
- Notification delivery failures
- Privacy/consent issues
- Integration availability
- Overly complex workflows for frontline staff

Safety-sensitive rules must be validated before real-world deployment.

---

## 30. Product Principle

**Right patient + right information + right facility + right time + right follow-up.**
