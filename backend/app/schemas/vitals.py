from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime

class VitalsBase(BaseModel):
    systolic_bp: int = Field(..., ge=50, le=300, description="Systolic Blood Pressure in mmHg")
    diastolic_bp: int = Field(..., ge=30, le=200, description="Diastolic Blood Pressure in mmHg")
    pulse: int = Field(..., ge=30, le=250, description="Heart Rate in beats per minute")
    spo2: int = Field(..., ge=50, le=100, description="Oxygen Saturation percentage")
    temperature: float = Field(default=98.6, ge=90.0, le=110.0, description="Body temperature in Fahrenheit")
    blood_sugar: Optional[int] = Field(default=None, ge=20, le=800, description="Random or fasting blood sugar in mg/dL")
    haemoglobin: Optional[float] = Field(default=None, ge=2.0, le=25.0, description="Haemoglobin level in g/dL")
    is_from_ble_device: bool = Field(default=False, description="Whether reading was captured via verified BLE sensor")

class VitalsCreate(VitalsBase):
    patient_id: str
    recorded_by_id: str
    recorded_by_role: str = "HEALTH_WORKER"

class VitalsResponse(VitalsBase):
    id: str
    patient_id: str
    recorded_by_id: str
    recorded_by_role: str
    recorded_at: datetime

    class Config:
        from_attributes = True
