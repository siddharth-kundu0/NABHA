from pydantic import BaseModel, Field
from typing import Optional, List

class TriageEvaluationRequest(BaseModel):
    patient_id: str
    is_pregnant: bool = False
    gestational_age_weeks: Optional[int] = None
    systolic_bp: int
    diastolic_bp: int
    pulse: int
    spo2: int
    temperature: float = 98.6
    blood_sugar: Optional[int] = None
    haemoglobin: Optional[float] = None
    danger_signs: List[str] = Field(default_factory=list, description="E.g. HEADACHE, BLURRED_VISION, BLEEDING, CONVULSIONS")

class TriageEvaluationResponse(BaseModel):
    patient_id: str
    triage_tier: str  # EMERGENCY, HIGH_RISK, ROUTINE
    urgency_level: str
    primary_risk_factor: str
    clinical_rationale: str
    recommended_action: str
    target_facility_type: str
    dispatch_108_ambulance: bool
    requires_teleconsult: bool
    alert_hospital_er: bool
