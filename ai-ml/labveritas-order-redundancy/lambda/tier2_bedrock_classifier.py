import json

try:
    from prompt_template import build_prompt
except ImportError:  # pragma: no cover
    from .prompt_template import build_prompt


def build_bedrock_request(order_context):
    """Build a Bedrock-style structured payload without making any AWS calls."""
    new_order = order_context.get("new_order", {})
    prior_order = order_context.get("prior_order", {})
    tier1_result = order_context.get("tier1_result", {})

    prompt = build_prompt(
        order_code=new_order.get("order_code", ""),
        analytes=new_order.get("analytes", []),
        prior_orders=[prior_order] if prior_order else [],
        tier1_result=tier1_result,
    )

    return {
        "modelId": "synthetic.local-classifier-v1",
        "inferenceConfig": {"temperature": 0.0, "maxTokens": 400},
        "messages": [
            {
                "role": "user",
                "content": [{"text": prompt}],
            }
        ],
        "required_output": {
            "decision": "suggest_alternative | flag_for_review | proceed",
            "suggested_panel": "string or null",
            "rationale": "short explanation",
            "confidence": "0.0 to 1.0",
        },
    }


def local_upgrade_classifier(order_context):
    """Deterministic local classifier that simulates AI reasoning for upgrades."""
    new_order = order_context.get("new_order", {})
    prior_order = order_context.get("prior_order", {})
    tier1_result = order_context.get("tier1_result", {})

    new_code = (new_order.get("order_code") or "").upper()
    prior_code = (prior_order.get("order_code") or "").upper()
    overlap_ratio = float(tier1_result.get("overlap_ratio", 0.0))
    potential_upgrade = bool(tier1_result.get("potential_upgrade", False))

    if potential_upgrade and prior_code == "BMP" and new_code == "CMP":
        return {
            "decision": "suggest_alternative",
            "suggested_panel": "LFT",
            "rationale": "Prior BMP already covers shared analytes; consider completing with LFT-only synthetic workflow.",
            "confidence": 0.91,
        }

    if overlap_ratio >= 0.8:
        return {
            "decision": "flag_for_review",
            "suggested_panel": None,
            "rationale": "High analyte overlap with recent order history in synthetic context.",
            "confidence": 0.8,
        }

    return {
        "decision": "proceed",
        "suggested_panel": None,
        "rationale": "No upgrade pattern requiring alternative recommendation.",
        "confidence": 0.65,
    }


def lambda_handler(event, context):
    payload = build_bedrock_request(event)
    classification = local_upgrade_classifier(event)

    return {
        "statusCode": 200,
        "body": json.dumps(
            {
                "message": "Synthetic Bedrock classification completed locally",
                "payload": payload,
                "classification": classification,
            }
        ),
    }
