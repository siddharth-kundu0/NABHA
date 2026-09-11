# RuralCare — Backend & Technical Specification
## Flutter + Firebase + Python Architecture

## 1. Technology Decision
make 
RuralCare will use:

| Layer | Technology |
|---|---|
| Mobile / Web App | Flutter |
| Authentication | Firebase Authentication |
| Primary App Data / Sync | Firebase Firestore |
| File Storage | Firebase Storage |
| Push Notifications | Firebase Cloud Messaging |
| Backend / Business Logic | Python |
| Recommended Python API Framework | FastAPI |
| Background Jobs | Python worker / scheduled jobs |
| Hosting | Cloud/server environment suitable for Python API |
| Device Communication | Flutter + device/BLE integration |
| Monitoring | Application logs + Firebase/system monitoring |

### Architecture principle

Flutter is the product interface.

Firebase provides identity, cloud data, storage and messaging infrastructure.

Python is the controlled business-logic/API layer for workflows that require validation, rules, orchestration, clinical coordination logic, alerts, smart referral matching and integrations.

---

# 2. High-Level Architecture

```text
                    ┌─────────────────────┐
                    │      Flutter        │
                    │ Patient / HW / Doc  │
                    │ Facility / Admin    │
                    └──────────┬──────────┘
                               │ HTTPS
                               ▼
                    ┌─────────────────────┐
                    │   Python Backend    │
                    │       FastAPI       │
                    ├─────────────────────┤
                    │ Auth verification   │
                    │ RBAC / permissions  │
                    │ Clinical workflows  │
                    │ Triage              │
                    │ Referrals            │
                    │ Monitoring           │
                    │ Alert engine         │
                    │ Notifications        │
                    │ Integrations         │
                    └───────┬─────┬────────┘
                            │     │
                ┌───────────┘     └─────────────┐
                ▼                               ▼
      ┌──────────────────┐             ┌──────────────────┐
      │ Firebase         │             │ External Services│
      │ Auth             │             │ Video            │
      │ Firestore        │             │ Maps             │
      │ Storage          │             │ SMS              │
      │ FCM              │             │ ABDM             │
      └──────────────────┘             │ Emergency/Device │
                                       └──────────────────┘
```

---

# 3. Responsibility Split

## Flutter

Flutter should handle:

- UI
- Navigation
- Form entry
- Local state
- Local/offline queue
- Device/BLE interaction where appropriate
- Basic client validation
- Camera/microphone/location permissions
- Push-notification presentation
- Charts and patient trends
- Role-specific dashboards

Flutter must not be trusted for security-sensitive business rules.

---

## Firebase

Firebase should handle:

### Authentication
- Phone authentication
- Session identity
- User identity tokens

### Firestore
- Core application records
- Real-time status where useful
- Offline-capable client data
- Structured collections

### Storage
- Diagnostic files
- Uploaded documents
- Clinician attachments
- Approved patient documents

### FCM
- Push notifications
- Alert delivery

Firebase should not be treated as the only place where complex clinical business logic lives.

---

## Python Backend

Python should handle:

- API endpoints
- Authorization checks
- Business rules
- Digital triage engine
- Referral workflows
- Smart facility matching
- Monitoring rules
- Alert escalation
- Notification orchestration
- Follow-up generation
- Audit events
- External API integrations
- Data validation
- Administrative workflows
- Background processing
- Report/analytics preparation

---

# 4. API Design

Recommended base:

```text
/api/v1/
```

## Identity

```text
POST   /auth/session
GET    /auth/me
GET    /users/{user_id}
PATCH  /users/{user_id}
```

## Patients

```text
POST   /patients
GET    /patients/{patient_id}
PATCH  /patients/{patient_id}
GET    /patients/{patient_id}/summary
GET    /patients/{patient_id}/records
```

## Appointments

```text
GET    /appointments
POST   /appointments
GET    /appointments/{id}
PATCH  /appointments/{id}
POST   /appointments/{id}/cancel
```

## Triage

```text
POST   /triage
GET    /triage/{id}
```

## Consultations

```text
POST   /consultations
GET    /consultations/{id}
POST   /consultations/{id}/complete
```

## Referrals

```text
POST   /referrals
GET    /referrals/{id}
PATCH  /referrals/{id}
POST   /referrals/{id}/accept
POST   /referrals/{id}/reject
POST   /referrals/{id}/status
```

## Medicines

```text
GET    /medicines/search
GET    /medicines/{id}
GET    /medicines/{id}/availability
```

## Diagnostics

```text
GET    /diagnostics/tests
GET    /diagnostics/tests/{id}
GET    /diagnostics/facilities
GET    /diagnostics/reports/{id}
```

## Follow-up

```text
POST   /followups
GET    /followups
PATCH  /followups/{id}
POST   /followups/{id}/complete
```

## Monitoring

```text
POST   /monitoring/devices
POST   /monitoring/devices/{id}/assign
POST   /monitoring/measurements
GET    /monitoring/patients/{patient_id}/current
GET    /monitoring/patients/{patient_id}/trends
GET    /monitoring/patients/{patient_id}/alerts
```

## Alerts

```text
GET    /alerts
POST   /alerts/{id}/acknowledge
POST   /alerts/{id}/escalate
POST   /alerts/{id}/resolve
```

## Facilities

```text
GET    /facilities
GET    /facilities/{id}
GET    /facilities/{id}/services
GET    /facilities/{id}/availability
GET    /facilities/{id}/capabilities
```

## Administration

```text
GET    /admin/users
PATCH  /admin/users/{id}
GET    /admin/facilities
POST   /admin/facilities
GET    /admin/audit
GET    /admin/system-health
```

---

# 5. Authentication & Authorization

Firebase Authentication is the identity provider.

Python backend should verify the Firebase-issued identity token before processing protected requests.

Authorization should then evaluate:

```text
User
  ↓
Role
  ↓
Facility membership
  ↓
Permission
  ↓
Requested resource
```

Examples:

- Patient can read their own clinical information.
- Doctor can access patients assigned to their permitted clinical context.
- Facility staff can access facility-scoped operational information.
- System Admin has administrative permissions.
- A doctor associated with Facility A must not automatically gain unrestricted access to Facility B.

---

# 6. Recommended RBAC

## Patient

```text
patient.read_self
patient.update_self
appointment.manage_self
record.read_self
referral.read_self
monitoring.read_self
emergency.create
```

## Health Worker

```text
patient.create
patient.read_assigned
vitals.write
triage.create
followup.manage
referral.create
monitoring.read_assigned
```

## Doctor / Specialist

```text
patient.read_clinical
consultation.manage
prescription.create
diagnostic.order
referral.manage
monitoring.review
followup.manage
```

## Facility Staff

```text
queue.manage
patient.intake
service.status.update
medicine.status.update
diagnostic.status.update
referral.inbound.manage
referral.outbound.manage
```

## System Admin

```text
user.manage
role.manage
facility.manage
approval.manage
audit.read
system.monitor
```

---

# 7. Firestore Collection Model

Suggested top-level collections:

```text
users
patients
facilities
facility_memberships
appointments
encounters
prescriptions
diagnostic_orders
diagnostic_reports
referrals
followups
notifications
devices
device_assignments
measurements
monitoring_rules
alerts
audit_events
facility_services
medicine_availability
diagnostic_availability
```

Use subcollections where data is naturally scoped to a parent entity.

---

# 8. Patient Data Model

Conceptual patient record:

```text
patientId
ruralCareId
profile
contact
language
location
riskProfile
nextOfKin
assignedFacility
assignedCareTeam
consents
createdAt
updatedAt
```

Do not use a random frontend-generated identifier as the sole identity mechanism.

---

# 9. Connected Hardware Architecture

## Device pathway

```text
Hardware Sensor
      ↓
Flutter Device Layer
      ↓
Local Measurement Buffer
      ↓
Measurement API
      ↓
Python Validation
      ↓
Firestore
      ↓
Monitoring Rule Engine
      ↓
Alert Engine
```

Initial measurements:

- Heart rate
- SpO₂
- Body temperature

---

# 10. Measurement Validation

Python should validate:

- Patient association
- Device association
- Metric type
- Unit
- Timestamp
- Numeric range sanity
- Duplicate events
- Data quality flags
- Device status

A technically valid measurement is not automatically a clinically abnormal event.

---

# 11. Monitoring Rule Engine

A rule should contain conceptually:

```text
ruleId
metric
patientGroup
condition
threshold/reference
requiredDuration
requiredReadings
severity
notificationPolicy
active
version
```

Clinical thresholds must be configurable and validated by the clinical team.

Do not hard-code unapproved medical thresholds into Flutter.

---

# 12. Alert Escalation Engine

```text
Measurement
     ↓
Quality Check
     ↓
Clinical Rule
     ↓
Alert Event
     ↓
Severity
     ├── Informational
     ├── Abnormal
     ├── High Risk
     └── Critical
```

Then:

```text
Abnormal
  ↓
Next-of-Kin Notification
  ↓
Continue Monitoring
  ↓
Persistence Condition
  ↓
Facility Notification
  ↓
Clinical Acknowledgement
  ↓
Resolution
```

Critical events may use immediate escalation.

---

# 13. Notification Service

Create a Python notification abstraction:

```text
NotificationService
 ├─ PushChannel
 ├─ SMSChannel
 └─ FutureChannel
```

Each event receives:

```text
notificationId
recipient
channel
createdAt
sentAt
deliveredAt
status
failureReason
```

Possible statuses:

- queued
- sent
- delivered
- failed
- unavailable
- acknowledged

---

# 14. Smart Referral Engine

Input:

```text
Patient condition
Current location
Required specialty
Required diagnostic
Required medicine
Emergency status
Transport requirement
```

Facility capability:

```text
Facility
 ├─ distance
 ├─ specialists
 ├─ beds
 ├─ blood
 ├─ diagnostics
 ├─ medicines
 ├─ emergency capability
 └─ transport
```

Output:

```text
ranked facilities
+
reason for ranking
+
availability freshness
```

The recommendation must remain explainable to the clinician.

---

# 15. Digital Triage Engine

Digital triage is decision support.

Input:
- symptoms
- vitals
- history
- risk factors
- maternal context
- monitoring data

Output:
- routine
- high-risk
- emergency

The backend should return:
- classification
- reasons
- flags
- recommended next workflow

It should not claim an autonomous diagnosis.

---

# 16. Offline Architecture

Flutter:

```text
User action
   ↓
Local storage / queue
   ↓
Pending Sync
   ↓
Connection restored
   ↓
Sync
   ↓
Backend acknowledgement
   ↓
Synced
```

Every critical record should expose:

```text
syncState
lastSyncedAt
```

Possible states:

- local
- pending
- syncing
- synced
- failed

---

# 17. Audit Logging

Python should create audit events for important actions.

Examples:

- Role change
- Facility affiliation
- Approval
- Referral creation
- Referral acceptance
- Alert generation
- Notification
- Alert acknowledgement
- Device assignment
- Facility status change
- Clinical coordination action

Recommended:

```text
auditId
actorId
actorRole
action
targetType
targetId
timestamp
result
metadata
```

---

# 18. Background Processing

Use background Python jobs for:

- Escalation timers
- Delayed facility notifications
- Follow-up reminder generation
- Notification retry
- Sync reconciliation
- Periodic facility-status processing
- Analytics aggregation

Do not depend on a Flutter screen remaining open for critical backend tasks.

---

# 19. Error Handling

Every API should return structured errors.

Example:

```json
{
  "code": "FACILITY_UNAVAILABLE",
  "message": "The selected facility is currently unavailable.",
  "request_id": "..."
}
```

Errors must be user-safe and developer-debuggable.

Do not expose secrets or internal stack traces.

---

# 20. Security

Required:

- Firebase identity verification
- Backend authorization
- HTTPS
- Secret management
- Least privilege
- Audit logs
- Storage access controls
- Firestore security rules
- Role/facility scoping
- Consent-aware data sharing

Do not place backend credentials inside the Flutter app.

---

# 21. Testing Strategy

## Unit
- Triage rules
- Referral ranking
- Alert rules
- Notification routing

## Integration
- Flutter → Python
- Python → Firestore
- Python → FCM
- Device → Flutter → backend

## Offline
- Offline capture
- Sync retry
- Duplicate events
- Conflict handling

## Safety
- False alert
- Missing alert
- Notification failure
- Device disconnect
- Facility unavailable

## Security
- Role bypass
- Facility boundary bypass
- Unauthorized patient access
- Invalid token

---

# 22. Recommended Project Structure

```text
ruralcare/
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

# 23. Development Order

1. Firebase project setup
2. Flutter shell/navigation
3. Firebase Authentication
4. Python FastAPI backend
5. User/facility/RBAC
6. Patient + records
7. Appointments
8. Doctor workflow
9. Referrals
10. Facility operations
11. Admin
12. Offline sync
13. Notifications
14. Emergency
15. Hardware integration
16. Remote monitoring
17. Alert escalation
18. Smart referral
19. Maternal/high-risk workflows
20. External integrations

---

# 24. Golden Rule

Flutter should never be the source of truth for clinical authorization, escalation timers, alert decisions or sensitive permissions.

Python should own business rules.

Firebase should provide trusted infrastructure services.

The final system should remain usable when connectivity is weak.
