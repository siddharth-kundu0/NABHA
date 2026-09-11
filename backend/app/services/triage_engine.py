from ..schemas.triage import TriageEvaluationRequest, TriageEvaluationResponse

class ClinicalTriageEngine:
    @staticmethod
    def evaluate(req: TriageEvaluationRequest) -> TriageEvaluationResponse:
        # Check Pregnancy / Maternal guidelines first (ICMR Maternal Health Standards)
        if req.is_pregnant:
            # Tier 1: Severe Preeclampsia / Obstetric Emergency
            if (
                req.systolic_bp >= 160
                or req.diastolic_bp >= 110
                or "BLEEDING" in req.danger_signs
                or "CONVULSIONS" in req.danger_signs
                or "EPIGASTRIC_PAIN" in req.danger_signs
            ):
                return TriageEvaluationResponse(
                    patient_id=req.patient_id,
                    triage_tier="EMERGENCY",
                    urgency_level="CRITICAL",
                    primary_risk_factor="Severe Preeclampsia / Imminent Eclampsia Risk",
                    clinical_rationale=f"Blood pressure ({req.systolic_bp}/{req.diastolic_bp} mmHg) exceeds ICMR emergency threshold (>=160/110) or critical danger signs detected.",
                    recommended_action="Immediate 108 ALS Ambulance dispatch. Pre-alert Baramati SDH Emergency Room & reserve 2 units O+ blood.",
                    target_facility_type="SUB_DISTRICT_HOSPITAL",
                    dispatch_108_ambulance=True,
                    requires_teleconsult=True,
                    alert_hospital_er=True,
                )

            # Tier 2: Gestational Hypertension / Severe Anaemia
            if (
                req.systolic_bp >= 140
                or req.diastolic_bp >= 90
                or (req.haemoglobin is not None and req.haemoglobin < 9.0)
                or "HEADACHE" in req.danger_signs
                or "BLURRED_VISION" in req.danger_signs
                or "PEDAL_EDEMA" in req.danger_signs
            ):
                risk_desc = []
                if req.systolic_bp >= 140 or req.diastolic_bp >= 90:
                    risk_desc.append("Gestational Hypertension (BP >= 140/90)")
                if req.haemoglobin is not None and req.haemoglobin < 9.0:
                    risk_desc.append(f"Severe Nutritional Anaemia (Hb {req.haemoglobin} g/dL)")

                return TriageEvaluationResponse(
                    patient_id=req.patient_id,
                    triage_tier="HIGH_RISK",
                    urgency_level="URGENT",
                    primary_risk_factor="; ".join(risk_desc) if risk_desc else "Maternal Risk Symptoms",
                    clinical_rationale=f"Gestational age {req.gestational_age_weeks or 32} weeks with elevated vitals and neurological symptoms requiring specialist OB/GYN intervention.",
                    recommended_action="Initiate assisted specialist teleconsultation with Dr. Patil and generate Smart Referral to Baramati SDH.",
                    target_facility_type="SUB_DISTRICT_HOSPITAL",
                    dispatch_108_ambulance=False,
                    requires_teleconsult=True,
                    alert_hospital_er=False,
                )

            # Tier 3: Routine Maternal ANC
            return TriageEvaluationResponse(
                patient_id=req.patient_id,
                triage_tier="ROUTINE",
                urgency_level="ROUTINE",
                primary_risk_factor="Normal Pregnancy Progression",
                clinical_rationale="Vitals within safe physiological ranges for gestational age. No danger signs present.",
                recommended_action="Sub-centre routine care. Dispense 30-day supply of IFA & Calcium tablets. Next ANC visit in 14-28 days.",
                target_facility_type="SUB_CENTRE",
                dispatch_108_ambulance=False,
                requires_teleconsult=False,
                alert_hospital_er=False,
            )

        # General / Non-Pregnant Clinical Evaluation
        if req.spo2 < 90 or req.systolic_bp >= 180 or req.diastolic_bp >= 120:
            return TriageEvaluationResponse(
                patient_id=req.patient_id,
                triage_tier="EMERGENCY",
                urgency_level="CRITICAL",
                primary_risk_factor="Hypertensive Crisis / Respiratory Compromise",
                clinical_rationale=f"Critically low SpO2 ({req.spo2}%) or severe Hypertensive Crisis ({req.systolic_bp}/{req.diastolic_bp} mmHg).",
                recommended_action="Immediate ambulance transport to nearest emergency facility.",
                target_facility_type="CHC",
                dispatch_108_ambulance=True,
                requires_teleconsult=False,
                alert_hospital_er=True,
            )

        if (req.blood_sugar is not None and req.blood_sugar >= 200) or req.systolic_bp >= 140:
            return TriageEvaluationResponse(
                patient_id=req.patient_id,
                triage_tier="HIGH_RISK",
                urgency_level="URGENT",
                primary_risk_factor="Uncontrolled Diabetes / Hypertension",
                clinical_rationale=f"Blood sugar ({req.blood_sugar} mg/dL) or BP ({req.systolic_bp}/{req.diastolic_bp}) exceeds safe chronic threshold.",
                recommended_action="Doctor teleconsultation for medication adjustment and NCD care plan review.",
                target_facility_type="CHC",
                dispatch_108_ambulance=False,
                requires_teleconsult=True,
                alert_hospital_er=False,
            )

        return TriageEvaluationResponse(
            patient_id=req.patient_id,
            triage_tier="ROUTINE",
            urgency_level="ROUTINE",
            primary_risk_factor="Stable Vitals",
            clinical_rationale="All parameters within acceptable clinical limits.",
            recommended_action="Sub-centre routine follow-up.",
            target_facility_type="SUB_CENTRE",
            dispatch_108_ambulance=False,
            requires_teleconsult=False,
            alert_hospital_er=False,
        )
