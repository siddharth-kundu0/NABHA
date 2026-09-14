# Questions & Clinical Operations Architecture Guide

This document clarifies the concepts, clinical terminology, and hospital operations that were previously encountered in the application, and explains why they belong to hospital staff and how the new patient-facing views provide a clean, patient-centric experience.

---

## 1. What is an Inbound Referral Queue?

### Definition
An **Inbound Referral Queue** is a real-time clinical triage dashboard used exclusively by **Hospital Intake Officers, Medical Officers, and Emergency Staff** at secondary and tertiary hospitals (such as Sub-District Hospitals and District Hospitals).

### How it Works in NABHA / RuralCare
1. A frontline healthcare worker (such as an **ASHA worker** or **Sub-Centre Community Health Officer (CHO)**) evaluates a patient in a remote village.
2. If the patient has a condition beyond the Sub-Centre's capability (for example, severe pre-eclampsia, trauma, or neonatal distress), the health worker initiates a digital referral via their tablet or mobile device.
3. The referral immediately arrives in the higher hospital's **Inbound Referral Queue** with the patient's vitals, urgency level (Routine, Priority, Emergency), transport details (e.g. 108 Ambulance ID, driver contact), and required specialist (e.g. OB/GYN, Pediatrician).
4. This gives the hospital advance notice before the ambulance arrives.

### Why was it showing up to the patient?
In the initial prototype, the quick action tile **"Find Facility"** was mistakenly routed to the hospital staff operational screen (`FacilityOperationsScreen`) instead of a dedicated citizen-facing hospital directory (`FindFacilityScreen`). Patients should never see intake queues, triage buttons, or admission tools.

---

## 2. What does "Accept & Reserve Bed and Clinician Team" Mean?

### Definition
When a rural health worker refers an emergency patient, the receiving hospital staff uses **"Accept and Reserve Bed"** to guarantee bed, blood, and staff availability *before* the patient arrives.

### Operational Sequence
1. **Verification**: The triage officer checks if a High-Dependency bed or ICU bed is vacant, and confirms the specialist (e.g., Dr. Rahul Shinde, MD OB/GYN) is on duty.
2. **Reservation**: Upon clicking **"Accept & Reserve Bed"**:
   - The bed status transitions from *Vacant* to *Reserved for Inbound Emergency*.
   - Required blood units (e.g., 2 units of O+ blood) are locked in the facility's blood bank inventory.
   - The on-duty specialist team is alerted.
3. **ASHA Notification**: An automated notification is sent back to the referring ASHA worker's phone confirming:
   > *"Referral Accepted: Bed MCH-04 reserved at Baramati SDH. Dr. Rahul Shinde assigned."*

### Why the "+/-" Bed Capacity Buttons should not be shown to patients
The `+` and `-` buttons were administrative manual overrides for hospital ward sisters to record manual bed admissions and discharges. Showing this to patients creates severe confusion, as patients cannot admit or discharge themselves or alter hospital bed counts. In the patient view, bed availability must strictly be **read-only information** (e.g., *"12 Vacant Beds / 50 Total Beds"*).

---

## 3. What is a "Fast-Track Arrival Token Check-In"?

### Definition
Under the **Ayushman Bharat Digital Mission (ABDM)**, the **Fast-Track Arrival Pass** is a digital intake token with a QR code generated when a patient is referred or books an appointment.

### How it Works for the Patient and Hospital
1. **Patient Side**:
   - The patient receives a digital pass on their app with an arrival token (e.g. `NABHA-ABDM-ARR-11021`) and a high-contrast QR code.
   - It explains to the rural patient that they do not need to stand in long lines at the general OPD registration counter.
2. **Hospital Desk Side**:
   - Upon arriving at the hospital, the patient or accompanying 108 ambulance driver presents the QR token at the **ABDM Fast-Track Desk** or emergency triage counter.
   - The staff scans or enters the token to instantly confirm the patient has arrived on-site, linking their village vitals and records to the hospital's electronic health record (EHR) system.

---

## 4. Why was the "Find Facility" tab confusing, and how is it redesigned?

### The Problem
The previous screen displayed hospital administrative controls:
- Intake queues
- Triage action buttons
- Staff roster management
- Bed increment/decrement buttons (`+/-`)

### The Solution: Dedicated Citizen-Facing `FindFacilityScreen`
The new `FindFacilityScreen` is built 100% from the **patient's perspective**:

| Feature | Hospital Staff Operations View | Patient-Facing Facility Finder |
| :--- | :--- | :--- |
| **Search** | Staff roster & token lookup | Search hospital by name, town, or specialty |
| **Filters** | Intake triage urgency (Red/Yellow/Green) | Service filter (24x7 Emergency, ICU, Maternity, Diagnostics, Blood Bank, 108 Ambulance) |
| **Bed Status** | Interactive +/- manual edit buttons | **Read-only** clear occupancy bar (*"12 Vacant Beds / 50"* with color indicator) |
| **Specialists** | Duty shift assignment | Clear chips of on-duty specialists (OB/GYN, Pediatrician, Surgeon) |
| **Actions** | "Admit Patient", "Triage Referral" | **"Call Facility"**, **"Get Directions"**, **"Book OPD Appointment"** |

---

## 5. Summary of Architecture Fixes

1. **Patient Home Screen Routing**:
   - `strings.findFacility` now routes strictly to the new patient-friendly `FindFacilityScreen`.
   - `FacilityOperationsScreen` is isolated exclusively to the `facilityStaff` and `admin` roles.
2. **Teleconsultation Flow**:
   - Patient begins by entering medical concerns and selecting symptom chips.
   - Doctors are filtered dynamically by the specialty matching those concerns.
   - If no doctor is immediately available, the patient can book a scheduled appointment and will receive a push notification when the doctor is online.
   - If offline, requests are stored locally in `LocalCacheService` and automatically synchronized to the doctor's queue when connectivity is restored.
3. **Diagnostics Booking**:
   - Real-time test searching (CBC, Ultrasound, Blood Sugar, ECG, X-Ray).
   - Test availability status across centers.
   - Interactive booking modal with time slots and generation of ABDM Lab Token & QR Pass.
