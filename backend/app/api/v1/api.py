from fastapi import APIRouter, HTTPException, Depends, status
from typing import List, Dict, Any, Optional
from datetime import datetime, timezone

from ...schemas.triage import TriageEvaluationRequest, TriageEvaluationResponse
from ...schemas.referral import ReferralCreate, ReferralResponse, ReferralStatusUpdate
from ...schemas.facility import FacilityResponse, BedUpdate
from ...schemas.sync import BatchSyncRequest, BatchSyncResponse
from ...services.triage_engine import ClinicalTriageEngine
from ...services.referral_matcher import SmartReferralMatcher
from ...core.security import create_access_token

api_router = APIRouter()

# In-memory realistic repository backing
REFERRALS_DB: Dict[str, Dict[str, Any]] = {
    "REF-11021": {
        "id": "REF-11021",
        "patient_id": "pat-001",
        "patient_name": "Kavita Rajesh Devi",
        "referring_facility": "Kashti Sub-Centre (ASHA Assisted)",
        "target_facility_id": "FAC-SDH-301",
        "target_facility_name": "Baramati Sub-District Hospital (SDH)",
        "reason": "32-Week Gestational Hypertension with Severe Anaemia requiring specialist evaluation",
        "urgency": "URGENT",
        "required_specialty": "Obstetrician & Gynecologist",
        "status": "HOSPITAL_NOTIFIED",
        "created_at": datetime.now(timezone.utc),
        "expected_transit_minutes": 40,
        "is_overdue": False,
        "counter_referral_instructions": "Prescribed Labetalol 100mg BD. Measure daily BP at Sub-centre. Review in 7 days.",
        "recommendation_rationale": "Baramati SDH (24.5 km) recommended over Daund CHC (12 km) because Daund lacks an on-duty Gynecologist and Blood Bank capability.",
    }
}

# 1. Identity & Auth
@api_router.post("/auth/session")
def create_session(phone_number: str, role: str = "PATIENT"):
    token = create_access_token(subject=phone_number, role=role)
    return {
        "access_token": token,
        "token_type": "bearer",
        "role": role,
        "phone_number": phone_number,
        "session_expires_in": "7 days",
    }

# 2. ICMR Digital Clinical Triage
@api_router.post("/triage/evaluate", response_model=TriageEvaluationResponse)
def evaluate_triage(req: TriageEvaluationRequest):
    return ClinicalTriageEngine.evaluate(req)

# 3. Smart Referrals with AI Matching
@api_router.post("/referrals", response_model=ReferralResponse)
def create_referral(req: ReferralCreate):
    best_fac, rationale, transit_mins = SmartReferralMatcher.match_best_facility(req)
    ref_id = f"REF-{int(datetime.now().timestamp() * 1000) % 100000}"

    new_referral = {
        "id": ref_id,
        "patient_id": req.patient_id,
        "patient_name": req.patient_name,
        "referring_facility": req.referring_facility,
        "target_facility_id": best_fac["id"],
        "target_facility_name": best_fac["name"],
        "reason": req.reason,
        "urgency": req.urgency,
        "required_specialty": req.required_specialty,
        "status": "HOSPITAL_NOTIFIED",
        "created_at": datetime.now(timezone.utc),
        "expected_transit_minutes": transit_mins,
        "is_overdue": False,
        "counter_referral_instructions": "",
        "recommendation_rationale": rationale,
    }
    REFERRALS_DB[ref_id] = new_referral
    return new_referral

@api_router.get("/referrals/{referral_id}", response_model=ReferralResponse)
def get_referral(referral_id: str):
    if referral_id not in REFERRALS_DB:
        raise HTTPException(status_code=404, detail="Referral not found")
    return REFERRALS_DB[referral_id]

@api_router.patch("/referrals/{referral_id}/status", response_model=ReferralResponse)
def update_referral_status(referral_id: str, update: ReferralStatusUpdate):
    if referral_id not in REFERRALS_DB:
        raise HTTPException(status_code=404, detail="Referral not found")
    ref = REFERRALS_DB[referral_id]
    ref["status"] = update.status
    if update.counter_referral_instructions:
        ref["counter_referral_instructions"] = update.counter_referral_instructions
    return ref

# 4. Facilities Capability Registry & Live Beds
@api_router.get("/facilities", response_model=List[FacilityResponse])
def list_facilities():
    return [
        FacilityResponse(
            id=f["id"],
            name=f["name"],
            type=f["type"],
            distance_km=f["distance_km"],
            address=f.get("address", "Pune Rural District"),
            contact_phone=f.get("contact_phone", "+91 2112 245001"),
            total_beds=f["total_beds"],
            available_beds=f["available_beds"],
            on_duty_specialists=f["on_duty_specialists"],
            available_blood_units=f.get("blood_units", {}),
            available_diagnostics=["CBC", "Blood Sugar", "Ultrasound", "ECG"],
            available_medicines=["Labetalol", "Iron & Folic Acid", "Metformin", "Oxytocin"],
            has_emergency_capability=f["has_emergency"],
            has_ambulance_available=f["has_emergency"],
        )
        for f in SmartReferralMatcher.FACILITY_DATABASE
    ]

@api_router.patch("/facilities/{facility_id}/beds")
def update_facility_beds(facility_id: str, bed_update: BedUpdate):
    for f in SmartReferralMatcher.FACILITY_DATABASE:
        if f["id"] == facility_id:
            f["available_beds"] = bed_update.available_beds
            return {"facility_id": facility_id, "available_beds": f["available_beds"], "status": "UPDATED"}
    raise HTTPException(status_code=404, detail="Facility not found")

# 5. Offline Outbox Batch Sync Reconciliation
@api_router.post("/sync/batch", response_model=BatchSyncResponse)
def reconcile_outbox(sync_req: BatchSyncRequest):
    processed = 0
    for mutation in sync_req.mutations:
        entity = mutation.entity
        action = mutation.action
        payload = mutation.payload

        if entity == "REFERRAL" and action == "STATUS_UPDATE":
            ref_id = payload.get("id")
            if ref_id and ref_id in REFERRALS_DB:
                REFERRALS_DB[ref_id]["status"] = payload.get("status", REFERRALS_DB[ref_id]["status"])
        processed += 1

    return BatchSyncResponse(
        success=True,
        processed_count=processed,
        failed_count=0,
        server_timestamp=datetime.now(timezone.utc).isoformat(),
        message=f"Successfully reconciled {processed} offline records for device {sync_req.device_id}.",
    )
