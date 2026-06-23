import json
import os
from datetime import datetime, timezone
from typing import Any, Dict

import boto3


ALLOWED_CATEGORIES = {
    "COMPROMISED_INSTANCE",
    "UNAUTHORIZED_ACCESS",
    "DATA_EXFILTRATION",
    "MALWARE_ACTIVITY",
    "CREDENTIAL_ABUSE",
    "BENIGN",
}

ALLOWED_SEVERITIES = {"LOW", "MEDIUM", "HIGH", "CRITICAL"}
ALLOWED_TEAMS = {"SECOPS", "IAM_TEAM", "CLOUD_PLATFORM", "SOC_L1"}

MODEL_ID = os.environ.get("BEDROCK_MODEL_ID", "amazon.nova-lite-v1:0")

bedrock_runtime = boto3.client("bedrock-runtime")


def _extract_incident_summary(event: Dict[str, Any]) -> str:
    detail = event.get("detail", {})
    detail_type = event.get("detail-type", "Unknown")
    source = event.get("source", "Unknown")
    finding_type = detail.get("type", "N/A")
    title = detail.get("title", "N/A")
    description = detail.get("description", "N/A")
    severity = detail.get("severity", "N/A")
    service = detail.get("service", {})
    service_name = service.get("serviceName", "N/A")

    return (
        f"source={source}\n"
        f"detail_type={detail_type}\n"
        f"service={service_name}\n"
        f"finding_type={finding_type}\n"
        f"title={title}\n"
        f"description={description}\n"
        f"severity={severity}\n"
        f"raw_detail={json.dumps(detail, default=str)}"
    )


def _extract_json_block(text: str) -> Dict[str, Any]:
    start_index = text.find("{")
    end_index = text.rfind("}")
    if start_index < 0 or end_index <= start_index:
        raise ValueError("Model output did not contain a JSON object.")
    return json.loads(text[start_index : end_index + 1])


def _validate_classification(payload: Dict[str, Any]) -> None:
    required = [
        "category",
        "severity",
        "confidence",
        "routed_team",
        "recommended_actions",
        "reasoning",
    ]
    for field in required:
        if field not in payload:
            raise ValueError(f"Missing required field in classification payload: {field}")

    if payload["category"] not in ALLOWED_CATEGORIES:
        raise ValueError(f"Unsupported category: {payload['category']}")
    if payload["severity"] not in ALLOWED_SEVERITIES:
        raise ValueError(f"Unsupported severity: {payload['severity']}")
    if payload["routed_team"] not in ALLOWED_TEAMS:
        raise ValueError(f"Unsupported routed_team: {payload['routed_team']}")

    confidence = payload["confidence"]
    if not isinstance(confidence, (int, float)) or confidence < 0 or confidence > 1:
        raise ValueError("confidence must be a float between 0 and 1.")

    actions = payload["recommended_actions"]
    if not isinstance(actions, list) or not actions:
        raise ValueError("recommended_actions must be a non-empty array.")


def _build_prompt(incident_summary: str) -> str:
    return f"""
You are a SOC incident triage classifier for AWS events.
Classify the incident and return strict JSON only with this schema:
{{
  "category": "COMPROMISED_INSTANCE|UNAUTHORIZED_ACCESS|DATA_EXFILTRATION|MALWARE_ACTIVITY|CREDENTIAL_ABUSE|BENIGN",
  "severity": "LOW|MEDIUM|HIGH|CRITICAL",
  "confidence": 0.0,
  "routed_team": "SECOPS|IAM_TEAM|CLOUD_PLATFORM|SOC_L1",
  "recommended_actions": ["action 1", "action 2"],
  "reasoning": "short justification"
}}

Routing guidance:
- IAM key misuse or policy abuse -> IAM_TEAM
- EC2 malware/crypto/backdoor indicators -> SECOPS
- S3 exfiltration or data movement anomalies -> CLOUD_PLATFORM
- Low-confidence or ambiguous incidents -> SOC_L1

Incident:
{incident_summary}
""".strip()


def _invoke_model(prompt: str) -> Dict[str, Any]:
    response = bedrock_runtime.converse(
        modelId=MODEL_ID,
        inferenceConfig={"temperature": 0.1, "maxTokens": 600},
        messages=[{"role": "user", "content": [{"text": prompt}]}],
    )
    content = response["output"]["message"]["content"]
    text_chunks = [entry["text"] for entry in content if "text" in entry]
    model_text = "\n".join(text_chunks).strip()
    classification = _extract_json_block(model_text)
    _validate_classification(classification)
    return classification


def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    incident_summary = _extract_incident_summary(event)
    classification = _invoke_model(_build_prompt(incident_summary))

    incident_id = event.get("id") or f"inc-{datetime.now(timezone.utc).strftime('%Y%m%d%H%M%S')}"
    classification["incident_id"] = incident_id
    classification["classified_at"] = datetime.now(timezone.utc).isoformat()
    classification["model_id"] = MODEL_ID
    classification["source"] = event.get("source", "unknown")
    return {"incident": event, "classification": classification}
