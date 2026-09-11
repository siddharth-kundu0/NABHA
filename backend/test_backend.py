import sys
from fastapi.testclient import TestClient
from app.main import app
from app.schemas.triage import TriageEvaluationRequest
from app.services.triage_engine import ClinicalTriageEngine
from app.schemas.referral import ReferralCreate
from app.services.referral_matcher import SmartReferralMatcher

def run_tests():
    print("=== Testing RuralCare (NABHA) FastAPI Microservice ===")
    client = TestClient(app)

    # 1. Health Check
    res = client.get("/health")
    assert res.status_code == 200, f"Health check failed: {res.text}"
    print("[PASS] GET /health ->", res.json())

    # 2. ICMR Clinical Triage Engine Test
    triage_req = TriageEvaluationRequest(
        patient_id="pat-001",
        is_pregnant=True,
        gestational_age_weeks=32,
        systolic_bp=148,
        diastolic_bp=96,
        pulse=88,
        spo2=96,
        haemoglobin=7.8,
        danger_signs=["HEADACHE", "BLURRED_VISION", "PEDAL_EDEMA"],
    )
    triage_res = ClinicalTriageEngine.evaluate(triage_req)
    assert triage_res.triage_tier == "HIGH_RISK", f"Expected HIGH_RISK, got {triage_res.triage_tier}"
    assert triage_res.target_facility_type == "SUB_DISTRICT_HOSPITAL"
    print(f"[PASS] ICMR Triage Engine -> Tier: {triage_res.triage_tier}, Rationale: {triage_res.clinical_rationale[:60]}...")

    # 3. Smart Facility Matcher Test (Baramati SDH vs Daund CHC)
    ref_req = ReferralCreate(
        patient_id="pat-001",
        patient_name="Kavita Rajesh Devi",
        referring_facility="Kashti Sub-Centre",
        reason="Gestational Hypertension with Severe Anaemia",
        urgency="URGENT",
        required_specialty="Obstetrician & Gynecologist",
        requires_blood_bank=True,
    )
    best_fac, rationale, transit = SmartReferralMatcher.match_best_facility(ref_req)
    assert best_fac["id"] == "FAC-SDH-301", f"Expected Baramati SDH (FAC-SDH-301), got {best_fac['id']}"
    print(f"[PASS] Smart Matcher -> Selected: {best_fac['name']}, Rationale: {rationale[:60]}...")

    # 4. API Endpoint: POST /api/v1/referrals
    res = client.post("/api/v1/referrals", json=ref_req.model_dump())
    assert res.status_code == 200, f"Referral creation failed: {res.text}"
    ref_data = res.json()
    ref_id = ref_data["id"]
    print(f"[PASS] POST /api/v1/referrals -> Created {ref_id} with target {ref_data['target_facility_name']}")

    # 5. API Endpoint: PATCH /api/v1/referrals/{id}/status (Milestone progression)
    res = client.patch(f"/api/v1/referrals/{ref_id}/status", json={"status": "ADMITTED"})
    assert res.status_code == 200
    assert res.json()["status"] == "ADMITTED"
    print(f"[PASS] PATCH /api/v1/referrals/{ref_id}/status -> Updated to ADMITTED")

    # 6. API Endpoint: POST /api/v1/sync/batch (Offline outbox reconciliation)
    sync_payload = {
        "device_id": "asha-tablet-kashti-01",
        "role": "HEALTH_WORKER",
        "mutations": [
            {
                "id": "mut-001",
                "entity": "REFERRAL",
                "action": "STATUS_UPDATE",
                "payload": {"id": ref_id, "status": "PATIENT_ARRIVED"},
                "queued_at": "2026-09-12T08:30:00Z",
            }
        ],
    }
    res = client.post("/api/v1/sync/batch", json=sync_payload)
    assert res.status_code == 200
    assert res.json()["success"] is True
    print(f"[PASS] POST /api/v1/sync/batch -> Reconciled {res.json()['processed_count']} offline mutations")

    print("\n=== ALL BACKEND VALIDATION TESTS PASSED SUCCESSFULLY! ===")

if __name__ == "__main__":
    run_tests()
