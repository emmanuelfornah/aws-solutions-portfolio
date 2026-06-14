import json


def build_bedrock_request(order_context):
    """
    Builds a structured prompt payload for a future Bedrock Converse API call.
    """
    return {
        "task": "Evaluate whether a lab order pattern suggests a more efficient completing panel.",
        "context": order_context,
        "required_output": {
            "decision": "suggest_alternative | flag_for_review | proceed",
            "suggested_panel": "string or null",
            "rationale": "short explanation",
            "confidence": "0.0 to 1.0"
        }
    }


def lambda_handler(event, context):
    payload = build_bedrock_request(event)

    return {
        "statusCode": 200,
        "body": json.dumps({
            "message": "Bedrock request payload prepared",
            "payload": payload
        })
    }
