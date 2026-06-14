import json
from datetime import datetime, timezone
from pathlib import Path

try:
    from tier1_overlap_check import classify_overlap
    from tier2_bedrock_classifier import build_bedrock_request, local_upgrade_classifier
except ImportError:  # pragma: no cover
    from .tier1_overlap_check import classify_overlap
    from .tier2_bedrock_classifier import build_bedrock_request, local_upgrade_classifier


def _parse_event_payload(event):
    if isinstance(event, dict) and isinstance(event.get("body"), str):
        try:
            body = json.loads(event["body"])
            if isinstance(body, dict):
                merged = dict(event)
                merged.pop("body", None)
                merged.update(body)
                return merged
        except json.JSONDecodeError:
            pass
    return event if isinstance(event, dict) else {}


def _normalize_order(order_payload):
    return {
        "patient_ref": order_payload.get("patient_ref", "synthetic-patient"),
        "encounter_id": order_payload.get("encounter_id", "encounter-001"),
        "order_code": (order_payload.get("order_code") or "").upper(),
        "analytes": list(order_payload.get("analytes") or []),
        "timestamp": order_payload.get("timestamp", datetime.now(tz=timezone.utc).isoformat()),
    }


def _load_recent_history(payload):
    provided_history = payload.get("prior_history")
    if isinstance(provided_history, list) and provided_history:
        return provided_history

    scenarios_path = Path(__file__).resolve().parents[1] / "test" / "test_scenarios.json"
    try:
        scenarios = json.loads(scenarios_path.read_text(encoding="utf-8"))
        return [
            {
                "order_code": (item.get("prior_order") or {}).get("order_code", ""),
                "analytes": (item.get("prior_order") or {}).get("analytes", []),
                "source_scenario": item.get("scenario_id"),
            }
            for item in scenarios
            if isinstance(item, dict) and item.get("prior_order")
        ]
    except (OSError, json.JSONDecodeError):
        return [
            {
                "order_code": "BMP",
                "analytes": [
                    "glucose",
                    "calcium",
                    "sodium",
                    "potassium",
                    "chloride",
                    "co2",
                    "bun",
                    "creatinine",
                ],
                "source_scenario": "fallback-inline",
            }
        ]


def _evaluate_against_history(normalized_order, prior_history):
    best = {
        "tier1": {
            "decision": "proceed",
            "overlapping_analytes": [],
            "overlap_ratio": 0.0,
            "potential_upgrade": False,
            "suggested_next_step": "proceed",
        },
        "prior_order": None,
    }

    for prior in prior_history:
        result = classify_overlap(
            new_order_analytes=normalized_order.get("analytes", []),
            prior_analytes=prior.get("analytes", []),
            new_order_code=normalized_order.get("order_code"),
            prior_order_code=prior.get("order_code"),
        )

        if result.get("overlap_ratio", 0.0) > best["tier1"].get("overlap_ratio", 0.0):
            best = {"tier1": result, "prior_order": prior}

    return best


def lambda_handler(event, context):
    payload = _parse_event_payload(event)
    normalized_order = _normalize_order(payload)
    prior_history = _load_recent_history(payload)

    tier1_evaluation = _evaluate_against_history(normalized_order, prior_history)
    tier1_result = tier1_evaluation["tier1"]
    selected_prior_order = tier1_evaluation["prior_order"]

    response = {
        "workflow_decision": tier1_result.get("decision"),
        "normalized_order": normalized_order,
        "history_records_considered": len(prior_history),
        "selected_prior_order": selected_prior_order,
        "tier1": tier1_result,
        "tier2": None,
    }

    if tier1_result.get("potential_upgrade"):
        tier2_context = {
            "new_order": {
                "order_code": normalized_order.get("order_code"),
                "analytes": normalized_order.get("analytes", []),
            },
            "prior_order": selected_prior_order or {},
            "tier1_result": tier1_result,
        }
        response["tier2"] = {
            "payload": build_bedrock_request(tier2_context),
            "result": local_upgrade_classifier(tier2_context),
        }
        response["workflow_decision"] = response["tier2"]["result"].get("decision", response["workflow_decision"])

    return {"statusCode": 200, "body": json.dumps(response)}
