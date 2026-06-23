import json
import os
from typing import Any, Dict, List

import boto3


eventbridge = boto3.client("events")
ROUTING_EVENT_BUS = os.environ.get("ROUTING_EVENT_BUS", "default")


ROUTE_ACTIONS = {
    "SECOPS": ["isolate_instance", "create_forensic_snapshot", "notify_security_oncall"],
    "IAM_TEAM": ["disable_suspicious_keys", "force_credential_rotation", "notify_iam_oncall"],
    "CLOUD_PLATFORM": ["block_exfil_path", "enable_data_access_audit", "notify_platform_oncall"],
    "SOC_L1": ["open_triage_ticket", "request_human_review"],
}


def _select_actions(team: str, severity: str) -> List[str]:
    actions = ROUTE_ACTIONS.get(team, ["open_triage_ticket"])
    if severity in {"HIGH", "CRITICAL"} and "page_immediate" not in actions:
        actions = actions + ["page_immediate"]
    return actions


def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    classification = event.get("classification", {})
    team = classification.get("routed_team", "SOC_L1")
    severity = classification.get("severity", "LOW")
    incident_id = classification.get("incident_id", "unknown")

    actions = _select_actions(team, severity)
    route_result = {
        "incident_id": incident_id,
        "routed_team": team,
        "severity": severity,
        "actions": actions,
    }

    eventbridge.put_events(
        Entries=[
            {
                "EventBusName": ROUTING_EVENT_BUS,
                "Source": "custom.incident.triage",
                "DetailType": "IncidentRouted",
                "Detail": json.dumps(route_result),
            }
        ]
    )

    return {**event, "routing": route_result}
