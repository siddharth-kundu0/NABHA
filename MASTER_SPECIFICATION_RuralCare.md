# RuralCare — MASTER SPECIFICATION
## Complete Product, UX, Workflow, Technical, Hardware & Implementation Specification

> This is the master source document for the RuralCare application. It consolidates the product direction, roles, navigation, modules, workflows, UI scope, architecture, hardware/remote monitoring requirements, alert escalation, maternal/high-risk features and implementation plan.

---

# 1. PRODUCT IDENTITY

**Product Name:** RuralCare

**Positioning:** Integrated rural healthcare access, continuity and coordination platform.

**Primary Goal:** Improve timely access, continuity, quality support and coordination for rural and underserved communities.

**Core principle:**

> Right patient + right information + right facility + right time + right follow-up.

RuralCare is not only a telemedicine application. Teleconsultation is one part of a larger patient-care journey.

---

# 2. PROBLEM

The target communities may experience:

- Long travel distances
- Specialist shortages
- Irregular diagnostics
- Fragmented health records
- Delayed referrals
- Limited awareness of available services
- Constrained healthcare staff
- Limited equipment
- Movement between facilities without continuity
- Poor connectivity
- Language barriers
- Low health literacy
- Affordability constraints
- Missed follow-ups

The product therefore focuses on coordination and continuity across the care journey.

---

# 3. PRODUCT VISION

RuralCare connects:

```text
Patient
   ↕
Health Worker
   ↕
Doctor / Specialist
   ↕
Facility
   ↕
Referral Network
   ↕
District / System Administration
```

Optional connected hardware adds:

```text
Patient
   ↓
Health Device
   ↓
RuralCare
   ↓
Doctor / Health Worker
   ↓
Alert / Escalation
```

---

# 4. USER ROLES

## 4.1 Patient

Needs:
- Healthcare access
- Appointments
- Records
- Teleconsultation
- Referrals
- Medicines
- Diagnostics
- Follow-up
- Emergency support
- Remote monitoring where enrolled

---

## 4.2 Health Worker

Examples:
- ASHA
- ANM
- CHO
- Other frontline workers

Needs:
- Patient registration
- Screening
- Vitals
- Triage
- Risk identification
- Follow-up
- Home visits
- Referrals
- Alerts
- Maternal care
- Chronic disease care

---

## 4.3 Doctor / Specialist

Needs:
- Patient queue
- Clinical summary
- Consultation
- Records
- Prescription
- Diagnostics
- Referrals
- Teleconsultation
- Remote monitoring
- High-risk review
- Follow-up

---

## 4.4 Facility Staff

Possible staff:
- Facility Admin/Manager
- Doctor
- Pharmacist
- Diagnostic staff
- Nurse
- Other authorised staff

Needs:
- Queue
- Intake
- Facility services
- Medicine availability
- Diagnostic availability
- Referral coordination
- Facility operational status

---

## 4.5 System Admin

Needs:
- User & role management
- Facility management
- Approval workflows
- Monitoring
- Audit
- Administrative controls

---

# 5. FACILITY MODEL

A facility is an organisational entity, not a user role.

Examples:
- Sub-centre
- PHC
- CHC
- Rural Hospital
- District Hospital

Future architecture may support private facilities.

Relationship:

```text
Doctor User
     ↓
Facility Membership
     ↓
Facility
```

A doctor may be associated with multiple facilities.

---

# 6. PATIENT NAVIGATION

Locked patient navigation:

```text
Home | Appointments | Records | Referrals | Profile
```

Feature modules such as Medicines, Diagnostics, Teleconsultation and Emergency should not become permanent bottom-nav tabs.

---

# 7. GLOBAL DESIGN SYSTEM

## Visual direction

RuralCare V2:
- Trustworthy
- Calm
- Human
- Modern
- Accessible
- Healthcare-oriented
- Blue-forward with supportive green/teal states
- Warm amber for warnings
- Red only for critical/emergency conditions
- Neutral backgrounds
- White surfaces

## Typography

Use a multilingual-friendly font family. Noto Sans was the approved design direction.

## Accessibility

- Large touch targets
- Icon + label where useful
- No color-only status meaning
- Text must not clip in Hindi/Marathi
- Progressive disclosure
- Scroll naturally on long clinical pages

---

# 8. LANGUAGE RULE

Initial supported languages:

- English
- Hindi
- Marathi

Normal screen behaviour:

```text
User selects language
        ↓
Normal interface uses that language
```

Do not intentionally show English + Hindi + Marathi simultaneously throughout the UI.

Bilingual text should be used only where it has a clear accessibility or domain purpose.

---

# 9. PATIENT ONBOARDING

```text
Welcome
→ Language
→ Role
→ Mobile
→ OTP
→ Basic Profile
→ Healthcare Area
→ Account Created
→ RuralCare ID
→ Dashboard
```

Avoid unsupported government claims, hard-coded official IDs or invented helplines.

---

# 10. PATIENT MODULES

## Dashboard

Includes:
- Greeting
- Area/facility
- Notification access
- Language access
- One next-care item
- Quick actions
- Health snapshot
- Follow-up when relevant
- Active referral when relevant
- Emergency access

Quick actions:
- Book Appointment
- Teleconsultation
- Find Facility
- Medicines
- Diagnostics

---

## Appointments

```text
List
→ Facility
→ Doctor
→ Date
→ Time
→ Review
→ Confirm
→ Details
```

---

## Medical Records

```text
Records Overview
→ Consultation History
→ Consultation Details
→ Prescription
→ Diagnostic Report
```

Summary first; details one tap away.

---

## Teleconsultation

```text
Landing
→ Doctor
→ Consultation Details
→ Waiting Room
→ Live Call
→ Completed
```

Live call:
- Video
- Audio
- Controls
- Transcript
- Help/Emergency

Transcript is a communication aid, not automatically the official medical record.

---

## Referrals

```text
Overview
→ Details
→ Timeline
→ Receiving Facility
→ Outcome
```

Core lifecycle:

```text
Created
→ Sent
→ Accepted
→ Appointment/Visit
→ Completed
→ Follow-up
```

---

## Medicines

```text
Overview
→ Search
→ Details
→ Facility Availability
→ Result
```

States:
- Available
- Low Stock
- Out of Stock
- Information Unavailable

---

## Diagnostics

```text
Overview
→ Test
→ Details
→ Facility
→ Report
```

---

## Emergency

```text
Emergency Help
→ Confirm
→ Alert Active
→ Notifications / Escalation
→ Resolved / Cancelled
```

Never claim emergency dispatch unless an actual integration exists.

---

# 11. HEALTH WORKER MODULES

## Dashboard

Priority:
1. Emergency
2. High risk
3. Follow-up overdue
4. Follow-up due
5. Routine

---

## Patient workflow

```text
Patient
→ Registration
→ Screening
→ Vitals
→ History
→ Digital Triage
→ Action
```

Actions:
- Local care
- Doctor review
- Teleconsultation
- Referral
- Emergency

---

## Follow-up

```text
Follow-up Queue
→ Patient
→ Visit
→ Update Record
→ Schedule Next
```

---

# 12. DOCTOR MODULES

Doctor workflow:

```text
Dashboard
→ Queue
→ Patient
→ Clinical Summary
→ Current Visit
→ Assessment
→ Care Plan
→ Complete
```

Care-plan outputs:
- Prescription
- Diagnostics
- Referral
- Teleconsultation
- Follow-up

---

# 13. FACILITY MODULES

## Dashboard

Shows:
- Facility status
- Appointments
- Queue
- Referrals
- Diagnostics
- Services
- Operational alerts

## Queue

```text
Today's Queue
→ Search
→ Open Patient
→ Update Status
→ Complete
```

## Services

- Medicines
- Diagnostics
- Clinical services
- Availability
- Status updates

## Referral Coordination

```text
Inbound
→ Review
→ Accept
→ Prepare Intake

Outbound
→ Create
→ Select Facility
→ Track
```

---

# 14. SYSTEM ADMIN MODULES

## Dashboard
- Registered users
- Active facilities
- Pending approvals
- System/telemetry health
- Pending credential/facility approvals
- Audit trail

## Users & Roles
- Search/filter
- Approve association
- Edit role
- Manage access
- Reactivate
- View records where permitted

## Facilities
- Registry
- Facility type
- Ownership
- Jurisdiction
- Services
- Workforce
- Readiness
- Monitoring

## System Monitoring
- Identity/access
- Clinical record sync
- Offline sync
- Teleconsultation infrastructure
- Edge node health
- Administrative activity log
- Audit export

---

# 15. DIGITAL TRIAGE

Triage is decision support.

Inputs:
- Symptoms
- Vitals
- History
- Risk factors
- Maternal context
- Remote-monitoring information

Outputs:
- Routine
- High risk
- Emergency

No autonomous diagnosis.

---

# 16. SMART FACILITY SELECTION

Do not choose a facility only because it is nearest.

Consider:
- Distance
- Specialist availability
- Bed availability
- Blood
- Diagnostics
- Medicine
- Emergency capability
- Transport

Example:

```text
Hospital A = nearest but no specialist
Hospital B = farther but specialist + bed
Hospital C = no required diagnostic

Recommended = Hospital B
```

Recommendation must be explainable.

---

# 17. REFERRAL COORDINATION

Full journey:

```text
Referral Required
→ Facility Matching
→ Referral Created
→ Facility Notified
→ Accepted
→ Appointment / Visit
→ Transport if available
→ Patient Arrived
→ Treatment
→ Completed
→ Follow-up
```

The key product principle is:

> Do not simply refer the patient. Track the patient until referral completion and follow-up.

---

# 18. REMOTE PATIENT MONITORING

## Target population

Initial:
- High-risk patients
- Pregnant women

## Hardware measurements

Initial:
- Heart rate
- SpO₂
- Body temperature

Future sensors can be added after validation.

---

# 19. HARDWARE DATA FLOW

```text
Sensor
→ Flutter Device Layer
→ Local Buffer
→ Backend API
→ Validation
→ Firestore
→ Monitoring Rules
→ Alerts
→ Clinician Dashboard
```

---

# 20. HARDWARE DATA MODEL

Each reading should include:

```text
measurementId
patientId
deviceId
metric
value
unit
measuredAt
receivedAt
syncState
quality
```

Potential device fields:

```text
deviceId
deviceType
serialNumber
status
firmwareVersion
battery
```

---

# 21. REMOTE MONITORING STATES

```text
Normal
Abnormal
High Risk
Critical
Disconnected
Pending Sync
Offline
Unavailable
```

A stale or poor-quality reading must not be treated as a current valid measurement.

---

# 22. ALERT ENGINE

```text
Measurement
→ Quality Check
→ Clinical Rule
→ Alert
→ Recipient
→ Delivery
→ Escalation
→ Acknowledgement
→ Resolution
```

Severity:
- Informational
- Abnormal
- High Risk
- Critical

Clinical thresholds must be approved before production.

---

# 23. ESCALATION LOGIC

Desired concept:

```text
Abnormal Reading
      ↓
Store Reading
      ↓
Next-of-Kin Notification
      ↓
Continue Monitoring
      ↓
Does abnormal condition persist?
      ↓
YES
      ↓
Appropriate Healthcare Facility Notification
      ↓
Facility Acknowledgement
      ↓
Clinical Action
      ↓
Resolved
```

Critical events may bypass persistence and escalate immediately.

---

# 24. NEXT-OF-KIN

Patient stores:

- Name
- Relationship
- Contact
- Preferred channel
- Priority
- Consent/eligibility state

Notification should contain minimum necessary information.

---

# 25. FACILITY ESCALATION

Appropriate facility selection may use:

- Patient location
- Assigned facility
- Facility capability
- Specialist
- Emergency capability
- Bed availability
- Diagnostics
- Transport

Notification statuses:

```text
Queued
Sent
Delivered
Failed
Unavailable
Acknowledged
```

---

# 26. MATERNAL HEALTH

Track:

- Pregnancy registration
- ANC
- Expected delivery date
- Risk profile
- Vitals
- Relevant lab values
- Previous complications
- Delivery
- PNC
- Follow-up

Connect maternal care to:
- monitoring
- alerts
- referrals
- teleconsultation
- emergency

---

# 27. CHRONIC DISEASE

Initial:
- Hypertension
- Diabetes

Track:
- Readings
- Treatment
- Follow-up
- Trends
- Alerts
- Referral

---

# 28. NOTIFICATIONS

Notification classes:

- Appointment
- Follow-up
- Referral
- Medicine
- Diagnostics
- Remote monitoring
- Next of kin
- Facility escalation
- Administrative

Delivery must be auditable.

---

# 29. OFFLINE-FIRST

```text
User action
→ Local save
→ Pending Sync
→ Sync
→ Server acknowledgement
→ Synced
```

Never claim server synchronization before confirmation.

---

# 30. CONNECTIVITY

Every relevant workflow should expose:
- Online
- Offline
- Pending Sync
- Last Sync
- Sync Failed

Connectivity state is part of the product experience.

---

# 31. MULTILINGUAL + VOICE

Languages:
- English
- Hindi
- Marathi

Potential later feature:
- Voice/local-language interaction

Do not hard-code mixed-language UI.

---

# 32. SECURITY

Core:
- Firebase Authentication
- Role-based access
- Facility-based access
- Least privilege
- Audit logging
- Consent
- Secure storage
- Controlled file access

---

# 33. TECH STACK

## Frontend

**Flutter**

Responsibilities:
- UI
- Navigation
- Local state
- Device interaction
- Offline queue
- Charts
- Notifications
- Permission handling

---

## Firebase

**Firebase Authentication**
- Identity

**Firestore**
- Application data
- Real-time data
- Offline support

**Firebase Storage**
- Documents/files

**Firebase Cloud Messaging**
- Push notifications

---

## Python Backend

**Recommended:** FastAPI

Responsibilities:
- Business logic
- Authorization
- Triage
- Referral engine
- Monitoring
- Alerts
- Notification orchestration
- Background jobs
- Integrations
- Audit
- Administrative logic

---

# 34. BACKEND API AREAS

```text
/auth
/patients
/appointments
/triage
/consultations
/referrals
/medicines
/diagnostics
/followups
/monitoring
/alerts
/facilities
/notifications
/admin
/audit
```

Version:

```text
/api/v1/
```

---

# 35. DATA DOMAINS

```text
Identity
Patient
Clinical
Care Coordination
Monitoring
Facility Operations
Notifications
Administration
Audit
```

---

# 36. DATABASE ENTITIES

Core:

```text
User
Role
Facility
FacilityMembership
Patient
NextOfKin
Appointment
Encounter
Vital
Prescription
DiagnosticOrder
DiagnosticReport
Referral
FollowUp
Device
DeviceAssignment
Measurement
MonitoringRule
AlertEvent
NotificationEvent
FacilityService
MedicineAvailability
DiagnosticAvailability
ApprovalRequest
AuditEvent
```

---

# 37. SCREEN INVENTORY

## Patient
- Onboarding screens
- Dashboard
- Appointments
- Records
- Teleconsultation
- Referrals
- Medicines
- Diagnostics
- Emergency
- Follow-up
- Notifications
- Profile
- Remote Monitoring
- Maternal Health

## Health Worker
- Dashboard
- Patient registration
- Queue
- Screening/vitals
- Triage
- High-risk
- Follow-up
- Home visit
- Referral
- Alerts
- Maternal
- Chronic
- Monitoring

## Doctor
- Dashboard
- Queue
- Clinical summary
- Consultation
- Prescription
- Diagnostics
- Referrals
- Teleconsult
- Monitoring
- Alerts
- Follow-up

## Facility
- Dashboard
- Queue
- Services
- Medicines
- Diagnostics
- Referral coordination
- Intake

## Admin
- Dashboard
- User & role management
- Facility management
- Monitoring & audit

---

# 38. UI SOURCE OF TRUTH

**Stitch:** approved visual design source of truth.

**Flutter:** final implemented interface.

**Python/Firebase:** application/backend source of truth for live data and behaviour.

Do not redesign approved screens unless:
- a workflow is incomplete,
- the screen contradicts the master specification,
- accessibility fails,
- or a genuine usability issue is discovered.

---

# 39. MOCK DATA RULE

Demo data is allowed for demonstrating the UI.

Do not invent:
- government certifications
- official integrations
- government helplines
- official IDs
- guaranteed emergency services
- unsupported subsidies
- unsupported free-care promises
- clinical claims

When development begins, static demo values should gradually become dynamic.

---

# 40. IMPLEMENTATION ORDER

## Phase 1
Flutter project + navigation

## Phase 2
Firebase Authentication + user roles

## Phase 3
Python backend + APIs

## Phase 4
Patient records + appointments

## Phase 5
Doctor + Health Worker workflows

## Phase 6
Referrals + Facility operations

## Phase 7
System Admin

## Phase 8
Offline synchronization

## Phase 9
Notifications + Emergency

## Phase 10
Hardware connection

## Phase 11
Remote monitoring

## Phase 12
Alert escalation

## Phase 13
Maternal/high-risk monitoring

## Phase 14
Smart referral

## Phase 15
External integrations

---

# 41. SIH DEMO STORY

Recommended end-to-end demonstration:

```text
High-risk patient
        ↓
Health Worker captures vitals
        ↓
Connected device adds HR / SpO₂ / Temperature
        ↓
Data syncs to RuralCare
        ↓
Digital triage identifies concern
        ↓
Doctor reviews patient
        ↓
Teleconsultation
        ↓
Patient remains under remote monitoring
        ↓
Abnormal reading
        ↓
Next-of-kin notified
        ↓
Abnormality persists
        ↓
Appropriate facility selected
        ↓
Facility notified
        ↓
Referral created / tracked
        ↓
Transport when available
        ↓
Patient arrives
        ↓
Treatment
        ↓
Follow-up
```

This demonstrates the complete value proposition.

---

# 42. SAFETY PRINCIPLES

1. No autonomous diagnosis.
2. No unsupported clinical thresholds.
3. No false delivery claims.
4. No emergency dispatch claims without real integration.
5. No unnecessary medical-record sharing.
6. Offline state must be visible.
7. Stale sensor readings must be visible.
8. Alert rules must be auditable.
9. Clinical rules need validation.
10. Critical failures should fail safely.

---

# 43. PROJECT STRUCTURE

```text
ruralcare/
│
├── flutter_app/
│   ├── lib/
│   │   ├── core/
│   │   ├── auth/
│   │   ├── patient/
│   │   ├── health_worker/
│   │   ├── doctor/
│   │   ├── facility/
│   │   ├── admin/
│   │   ├── appointments/
│   │   ├── records/
│   │   ├── teleconsult/
│   │   ├── referrals/
│   │   ├── medicines/
│   │   ├── diagnostics/
│   │   ├── monitoring/
│   │   ├── maternal/
│   │   ├── emergency/
│   │   └── shared/
│   └── test/
│
├── backend/
│   ├── app/
│   │   ├── api/
│   │   ├── auth/
│   │   ├── patients/
│   │   ├── appointments/
│   │   ├── triage/
│   │   ├── consultations/
│   │   ├── referrals/
│   │   ├── medicines/
│   │   ├── diagnostics/
│   │   ├── followups/
│   │   ├── monitoring/
│   │   ├── alerts/
│   │   ├── facilities/
│   │   ├── notifications/
│   │   ├── admin/
│   │   └── audit/
│   └── tests/
│
└── docs/
```

---

# 44. PRODUCT PRIORITY

## Must Have
- Patient journey
- Health worker workflow
- Doctor workflow
- Facility workflow
- Admin
- Records
- Teleconsultation
- Referral
- Follow-up
- Offline basics
- Emergency flow

## High Priority Next
- Hardware
- Remote monitoring
- Next-of-kin escalation
- Facility escalation
- Maternal/high-risk monitoring
- Smart facility selection

## Later
- Broader integrations
- Advanced analytics
- Voice
- Expanded hardware
- Additional disease modules

---

# 45. DEFINITION OF DONE

A workflow is not considered complete when only the Stitch screen exists.

A workflow is complete when:

```text
UI
+
Navigation
+
Validation
+
Backend
+
Data Model
+
Permissions
+
Offline handling
+
Error handling
+
Notifications where required
+
Audit where required
+
Testing
```

are all connected.

---

# 46. FINAL PRODUCT PRINCIPLE

RuralCare should not simply tell the patient:

> “Go to another hospital.”

RuralCare should help coordinate:

```text
Why referral?
→ Which facility?
→ Does it have the required capability?
→ Has the facility accepted?
→ Is the patient on the way?
→ Has the patient arrived?
→ What happened?
→ What follow-up is needed?
```

That continuity is the core differentiator of the platform.
