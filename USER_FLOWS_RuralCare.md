# RuralCare — User Flows

## 1. Master Journey

```text
Patient / Community
        ↓
Registration / Identification
        ↓
Screening + Vitals + History
        ↓
Digital Triage
        ↓
┌──────────────┬──────────────────┬─────────────────┐
│ Routine      │ High Risk        │ Emergency       │
│              │                  │                 │
│ Local Care   │ Doctor Review    │ Emergency Flow  │
│              │ ↓                │                 │
│ Follow-up    │ Teleconsult      │ Escalation      │
│              │ ↓                │                 │
│              │ Referral?        │                 │
└──────────────┴───────┬──────────┴─────────────────┘
                        ↓
              Smart Facility Selection
                        ↓
                 Referral Created
                        ↓
             Facility Notification
                        ↓
              Transport (when available)
                        ↓
                   Patient Arrives
                        ↓
                     Treatment
                        ↓
                  Follow-up / Monitoring
```

---

# 2. Patient Onboarding

```text
Welcome
  ↓
Language Selection
  ↓
Role Selection = Patient
  ↓
Mobile Number
  ↓
OTP
  ↓
Basic Profile
  ↓
State / District / Local Area
  ↓
Account Created
  ↓
RuralCare ID
  ↓
Patient Dashboard
```

---

# 3. Patient Dashboard

```text
Patient Dashboard
  ↓
Next Care Item
  ├─ Appointment
  ├─ Follow-up
  └─ Referral
  ↓
Quick Actions
  ├─ Book Appointment
  ├─ Teleconsultation
  ├─ Find Facility
  ├─ Medicines
  └─ Diagnostics
  ↓
Health Snapshot
  ├─ Recent Consultation
  └─ Latest Prescription / Report
  ↓
Emergency Access
```

---

# 4. Appointment Flow

```text
Appointments
  ↓
Choose Healthcare Facility
  ↓
Choose Doctor / Specialist
  ↓
Select Date
  ↓
Select Time
  ↓
Review
  ↓
Confirm Appointment
  ↓
Appointment Details
```

---

# 5. Medical Records Flow

```text
Records
  ↓
Records Overview
  ├─ Consultations
  ├─ Prescriptions
  ├─ Diagnostics
  ├─ Referrals
  └─ Vitals
  ↓
Consultation History
  ↓
Consultation Details
  ↓
Prescription / Diagnostic Detail
```

---

# 6. Teleconsultation Flow

```text
Teleconsultation
  ↓
Choose Doctor / Specialist
  ↓
Consultation Details
  ↓
Consent / Record Sharing
  ↓
Waiting Room
  ↓
Live Consultation
  ├─ Video
  ├─ Audio
  ├─ Transcript
  ├─ Speaker controls
  └─ Help / Emergency
  ↓
Consultation Completed
  ↓
Conditional Outcomes
  ├─ Prescription
  ├─ Follow-up
  ├─ Referral
  └─ Diagnostic Recommendation
```

---

# 7. Referral Flow

```text
Doctor / Health Worker
  ↓
Referral Required
  ↓
Smart Facility Selection
  ├─ Distance
  ├─ Specialist
  ├─ Bed
  ├─ Blood
  ├─ Diagnostics
  ├─ Medicines
  ├─ Emergency capability
  └─ Transport availability
  ↓
Select Receiving Facility
  ↓
Referral Created
  ↓
Facility Notified
  ↓
Facility Accepts / Rejects
  ↓
Appointment / Visit
  ↓
Transport (if available)
  ↓
Patient Arrives
  ↓
Treatment
  ↓
Referral Completed
  ↓
Follow-up
```

---

# 8. Referral Tracking

```text
Created
  ↓
Sent
  ↓
Accepted
  ↓
Appointment / Visit
  ↓
Completed
  ↓
Follow-up
```

Optional operational stages:
```text
Transport Requested
  ↓
Transport Assigned
  ↓
Patient Picked Up
  ↓
Patient Arrived
```

---

# 9. Medicine Flow

```text
Medicines
  ↓
Search Medicine
  ↓
Medicine Details
  ↓
Check Availability
  ↓
Facilities
  ├─ Available
  ├─ Low Stock
  ├─ Out of Stock
  └─ Information Unavailable
  ↓
View Facility / Directions
```

---

# 10. Diagnostics Flow

```text
Diagnostics
  ↓
Search / Select Test
  ↓
Test Details
  ↓
Find Testing Facility
  ↓
Availability
  ↓
Diagnostic Report
  ↓
Result Details
```

---

# 11. Emergency Flow

```text
Emergency Help
  ↓
Confirm Emergency
  ↓
Emergency Event Created
  ↓
Emergency Contact / Next of Kin
  ↓
Assigned / Appropriate Facility
  ↓
Emergency Services Integration (if available)
  ↓
Status Tracking
  ├─ Sent
  ├─ Notified
  ├─ Connecting
  ├─ Unavailable
  └─ Failed
  ↓
Resolved / Cancelled
```

Critical events may bypass waiting/persistence rules.

---

# 12. Remote Patient Monitoring

## Patient / Hardware

```text
Hardware
  ↓
Measurement
  ├─ Heart Rate
  ├─ SpO₂
  └─ Body Temperature
  ↓
Patient Device / App
  ↓
Sync
  ├─ Online
  ├─ Pending Sync
  └─ Offline
  ↓
Backend
  ↓
Remote Monitoring Record
```

---

# 13. Remote Monitoring Alert Flow

```text
Reading Received
  ↓
Quality / Validity Check
  ↓
Clinical Rule Evaluation
  ↓
Normal?
 ├─ Yes → Store + Trend
 └─ No
      ↓
 Abnormal Event
      ↓
 Patient Warning (when appropriate)
      ↓
 Next of Kin Notification
      ↓
 Continue Monitoring
      ↓
 Persistence / Escalation Rule Met?
      ├─ No → Continue Monitoring
      └─ Yes
            ↓
      Healthcare Facility Notification
            ↓
      Clinical Acknowledgement
            ↓
      Assessment / Action
            ↓
      Resolved
```

For emergency-critical events:

```text
Critical Event
  ↓
Immediate Escalation
```

---

# 14. Hardware Device Lifecycle

```text
Register Device
  ↓
Pair / Associate With Patient
  ↓
Verify Device
  ↓
Capture Reading
  ↓
Sync
  ↓
Monitor Connectivity
  ↓
Battery / Device Status
  ↓
Replace / Unpair Device
```

---

# 15. Health Worker Flow

```text
Health Worker Dashboard
  ↓
Today's Patients
  ↓
Priority
  ├─ Emergency
  ├─ High Risk
  ├─ Follow-up Due
  └─ Routine
  ↓
Open Patient
  ↓
Capture / Review Vitals
  ↓
Symptoms + History
  ↓
Digital Triage
  ↓
Action
  ├─ Local Care
  ├─ Doctor Review
  ├─ Teleconsultation
  ├─ Referral
  └─ Emergency
```

---

# 16. Health Worker Follow-up

```text
Follow-up Queue
  ↓
Patient
  ↓
Reason
  ├─ ANC
  ├─ Chronic Disease
  ├─ Referral
  ├─ Medication
  └─ General Follow-up
  ↓
Complete Visit
  ↓
Update Record
  ↓
Schedule Next Follow-up
```

---

# 17. Doctor Flow

```text
Doctor Dashboard
  ↓
Patient Queue
  ↓
Open Patient
  ↓
Clinical Summary
  ↓
Current Visit
  ↓
Review
  ├─ Chief Concern
  ├─ Vitals
  ├─ History
  ├─ Medications
  ├─ Diagnostics
  └─ Referrals
  ↓
Clinical Assessment
  ↓
Care Plan
  ├─ Prescription
  ├─ Diagnostics
  ├─ Teleconsultation
  ├─ Referral
  └─ Follow-up
  ↓
Complete Consultation
```

---

# 18. Doctor Remote Monitoring

```text
Patient
  ↓
Remote Monitoring
  ↓
Current Reading
  ↓
Trend
  ↓
Alert History
  ↓
Device / Sync Status
  ↓
Clinical Review
  ↓
Action
  ├─ Continue Monitoring
  ├─ Contact Patient
  ├─ Schedule Review
  ├─ Teleconsult
  └─ Referral / Escalation
```

---

# 19. Maternal Health Flow

```text
Pregnancy Registration
  ↓
ANC Assessment
  ↓
Vitals + Relevant Measurements
  ↓
Risk Assessment
  ↓
Normal?
 ├─ Yes → Routine ANC + Follow-up
 └─ No → High-Risk Monitoring
              ↓
          Doctor Review
              ↓
          Teleconsult
              ↓
          Referral if needed
              ↓
          Follow-up
              ↓
          Delivery / PNC
```

---

# 20. Chronic Disease Flow

```text
Patient
  ↓
Condition Registered
  ↓
Periodic Measurements
  ↓
Treatment
  ↓
Follow-up
  ↓
Trend
  ↓
Abnormal / Missed Follow-up?
 ├─ No → Continue
 └─ Yes → Alert / Review
               ↓
           Doctor Review
               ↓
       Treatment / Referral / Follow-up
```

---

# 21. Facility Staff Flow

```text
Facility Dashboard
  ↓
Queue / Patient Intake
  ↓
Open Patient
  ↓
Current Encounter
  ↓
Update Status
  ↓
Assign Room / Service
  ↓
Consultation / Diagnostic / Pharmacy workflow
  ↓
Complete / Refer
```

---

# 22. Facility Referral Desk

```text
Referral Coordination
  ↓
Inbound
  ├─ Review
  ├─ Accept
  └─ Prepare Intake
  ↓
Outbound
  ├─ Create Referral
  ├─ Select Facility
  └─ Track Status
```

---

# 23. Facility Availability

```text
Facility Services & Availability
  ↓
Medicine
  ├─ Available
  ├─ Low Stock
  └─ Unavailable
  ↓
Diagnostics
  ↓
Clinical Services
  ↓
Update Status
```

---

# 24. System Admin Flow

## Dashboard

```text
System Admin Dashboard
  ↓
Overview
  ├─ Users
  ├─ Facilities
  ├─ Pending Approvals
  └─ System Health
```

## User & Role Management

```text
Users & Roles
  ↓
Search / Filter
  ↓
Open User
  ↓
Review Role / Facility
  ↓
Approve / Edit / Manage Access / Reactivate
  ↓
Audit
```

## Facility Management

```text
Facilities
  ↓
Search / Filter
  ↓
Select Facility
  ↓
Facility Overview
  ↓
Capacity / Services / Workforce / Status
  ↓
Update / Reassign / Register
```

## Monitoring & Audit

```text
System Monitoring & Audit
  ↓
Infrastructure Status
  ↓
Offline Sync
  ↓
Node Status
  ↓
Administrative Activity Log
  ↓
Filter / Inspect
  ↓
Diagnostic Check / Export Audit Log
```

---

# 25. Offline Sync Flow

```text
Action Created Offline
  ↓
Local Queue
  ↓
Pending Sync
  ↓
Connection Available
  ↓
Sync Attempt
  ↓
Success?
 ├─ Yes → Synced
 └─ No → Retry / Error
```

---

# 26. Notification Flow

```text
Event
  ↓
Notification Rule
  ↓
Recipient Selection
  ├─ Patient
  ├─ Health Worker
  ├─ Doctor
  ├─ Next of Kin
  └─ Facility
  ↓
Send
  ↓
Delivery Status
  ├─ Sent
  ├─ Delivered
  ├─ Failed
  └─ Unavailable
  ↓
Audit
```
