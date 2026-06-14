def build_prompt(order_code, analytes, prior_orders):
    return f"""
You are assisting with synthetic laboratory utilization review.

Current order:
- order_code: {order_code}
- analytes: {analytes}

Recent prior orders/results:
{prior_orders}

Task:
Determine whether the current order should proceed, be flagged for review,
or suggest an alternative completing panel with less analyte redundancy.

Rules:
- Do not provide diagnosis or treatment advice.
- Use only the provided structured data.
- Return concise JSON only.
""".strip()
