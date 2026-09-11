# NABHA (RuralCare) - Integrated Rural Healthcare Delivery Platform

NABHA is a digital public healthcare delivery platform designed for rural and semi-urban health ecosystems, connecting Patients, Accredited Social Health Activists (ASHAs) / Community Health Workers, Medical Officers, and District Health Administrators.

## Architecture

- **Mobile Client (`flutter_app/`)**: Offline-first Flutter application featuring multi-role workflows (Patient, Community Health Worker, Doctor/Teleconsult, Emergency, Admin).
- **Backend Service (`backend/`)**: FastAPI/Python service implementing automated referral intelligence, CDS-based digital triage routing, and offline-sync conflict resolution.
- **Specifications (`*.md`)**:
  - `MASTER_SPECIFICATION_RuralCare.md`
  - `BACKEND_SPEC_FLUTTER_FIREBASE_PYTHON.md`
  - `PRD_RuralCare.md`
  - `USER_FLOWS_RuralCare.md`

## Getting Started

### Flutter Application
```bash
cd flutter_app
flutter pub get
flutter run
```

### Python Backend
```bash
cd backend
pip install -r requirements.txt
python -m uvicorn app.main:app --reload
```
