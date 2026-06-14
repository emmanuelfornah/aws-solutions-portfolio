#!/usr/bin/env python3
"""Local synthetic end-to-end validation for LabVeritas prototype."""

import json
import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[1]
LAMBDA_DIR = PROJECT_ROOT / "lambda"

if str(LAMBDA_DIR) not in sys.path:
    sys.path.insert(0, str(LAMBDA_DIR))

from order_intake_handler import lambda_handler  # noqa: E402


def run_validation():
    scenarios_path = PROJECT_ROOT / "test" / "test_scenarios.json"
    scenarios = json.loads(scenarios_path.read_text(encoding="utf-8"))

    results = []
    for scenario in scenarios:
        event = {
            "patient_ref": "synthetic-patient",
            "encounter_id": f"enc-{scenario['scenario_id'].lower()}",
            "order_code": scenario["new_order"]["order_code"],
            "analytes": scenario["new_order"]["analytes"],
            "prior_history": [scenario["prior_order"]],
        }

        response = lambda_handler(event, None)
        body = json.loads(response["body"])
        actual = body.get("workflow_decision")
        expected = scenario.get("expected_decision")

        passed = actual == expected
        results.append({"scenario_id": scenario["scenario_id"], "passed": passed, "expected": expected, "actual": actual})

    failed = [item for item in results if not item["passed"]]
    if failed:
        failure_lines = "\n".join(
            f"- {item['scenario_id']}: expected={item['expected']}, actual={item['actual']}" for item in failed
        )
        raise AssertionError(f"Validation failed for {len(failed)} scenario(s):\n{failure_lines}")

    print(f"Validated {len(results)} synthetic scenario(s): all passed")


if __name__ == "__main__":
    run_validation()
