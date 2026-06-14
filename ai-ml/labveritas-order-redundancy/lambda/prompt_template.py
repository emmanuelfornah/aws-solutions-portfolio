def build_prompt(order_code, analytes, prior_orders, tier1_result=None):
    """Create constrained prompt text for synthetic Bedrock-style reasoning."""
    constraints = [
        "Use only the provided structured data.",
        "No diagnosis.",
        "No treatment advice.",
        "Return concise JSON output only.",
    ]

    response_schema = {
        "decision": "suggest_alternative | flag_for_review | proceed",
        "suggested_panel": "string or null",
        "rationale": "short non-clinical operational explanation",
        "confidence": "0.0 to 1.0",
    }

    return (
        "You are assisting with synthetic laboratory utilization review.\n\n"
        f"current_order={{'order_code': '{order_code}', 'analytes': {analytes}}}\n"
        f"prior_orders={prior_orders}\n"
        f"tier1_result={tier1_result or {}}\n\n"
        "Constraints:\n"
        + "\n".join(f"- {item}" for item in constraints)
        + "\n\nReturn JSON with schema:\n"
        + str(response_schema)
    )
