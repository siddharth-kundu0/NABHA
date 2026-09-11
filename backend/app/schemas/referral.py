from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime

class ReferralCreate(BaseModel):
    patient_id: str
    patient_name: str
    referring_facility: str
    target_facility_id: Optional[str] = None
    reason: str
    urgency: str = "URGENT"  # ROUTINE, URGENT, EMERGENCY
    required_specialty: str
    requires_blood_bank: bool = False
    requires_icu: bool = False

class ReferralResponse(BaseModel):
    id: str
    patient_id: str
    patient_name: str
    referring_facility: str
    target_facility_id: str
    target_facility_name: str
    reason: str
    urgency: str
    required_specialty: str
    status: str
    created_at: datetime
    expected_transit_minutes: int
    is_overdue: bool
    counter_referral_instructions: str
    recommendation_rationale: str

class ReferralStatusUpdate(BaseModel):
    status: str
    counter_referral_instructions: Optional[str] = None
