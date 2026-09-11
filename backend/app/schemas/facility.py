from pydantic import BaseModel
from typing import List, Dict

class FacilityResponse(BaseModel):
    id: str
    name: str
    type: str
    distance_km: float
    address: str
    contact_phone: str
    total_beds: int
    available_beds: int
    on_duty_specialists: List[str]
    available_blood_units: Dict[str, int]
    available_diagnostics: List[str]
    available_medicines: List[str]
    has_emergency_capability: bool
    has_ambulance_available: bool

class BedUpdate(BaseModel):
    available_beds: int
