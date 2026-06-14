import json
from datetime import datetime


def lambda_handler(event, context):
    """
    Entry point for incoming synthetic lab order events.
    This stub normalizes the payload and returns it for downstream checks.
    """
    order = {
        "patient_ref": event.get("patient_ref", "synthetic-patient"),
        "encounter_id": event.get("encounter_id", "encounter-001"),
        "order_code": event.get("order_code"),
        "analytes": event.get("analytes", []),
        "timestamp": event.get("timestamp", datetime.utcnow().isoformat())
    }

    return {
        "statusCode": 200,
        "body": json.dumps({
            "message": "Order received",
            "normalized_order": order
        })
    }
