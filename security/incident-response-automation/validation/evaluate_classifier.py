import json
from collections import defaultdict
from pathlib import Path


BASE_DIR = Path(__file__).parent
INCIDENTS_FILE = BASE_DIR / "fixtures" / "incidents.json"
PREDICTIONS_FILE = BASE_DIR / "fixtures" / "predictions.json"
OUTPUT_FILE = BASE_DIR / "validation-results.json"


def _safe_div(numerator: float, denominator: float) -> float:
    if denominator == 0:
        return 0.0
    return numerator / denominator


def evaluate() -> dict:
    incidents = json.loads(INCIDENTS_FILE.read_text(encoding="utf-8"))
    predictions = json.loads(PREDICTIONS_FILE.read_text(encoding="utf-8"))
    prediction_map = {entry["incident_id"]: entry["predicted_category"] for entry in predictions}

    labels = sorted({row["expected_category"] for row in incidents})
    tp = defaultdict(int)
    fp = defaultdict(int)
    fn = defaultdict(int)
    confusion_matrix = {label: {inner: 0 for inner in labels} for label in labels}

    total = len(incidents)
    correct = 0
    misclassified = []

    for row in incidents:
        incident_id = row["incident_id"]
        expected = row["expected_category"]
        predicted = prediction_map.get(incident_id, "UNKNOWN")

        if predicted == expected:
            correct += 1
            tp[expected] += 1
        else:
            fn[expected] += 1
            fp[predicted] += 1
            misclassified.append(
                {
                    "incident_id": incident_id,
                    "expected": expected,
                    "predicted": predicted,
                    "summary": row["summary"],
                }
            )

        if expected in confusion_matrix and predicted in confusion_matrix[expected]:
            confusion_matrix[expected][predicted] += 1

    per_class = {}
    macro_precision = 0.0
    macro_recall = 0.0
    macro_f1 = 0.0

    for label in labels:
        precision = _safe_div(tp[label], tp[label] + fp[label])
        recall = _safe_div(tp[label], tp[label] + fn[label])
        f1 = _safe_div(2 * precision * recall, precision + recall)
        per_class[label] = {
            "precision": round(precision, 4),
            "recall": round(recall, 4),
            "f1": round(f1, 4),
            "support": sum(1 for item in incidents if item["expected_category"] == label),
        }
        macro_precision += precision
        macro_recall += recall
        macro_f1 += f1

    class_count = len(labels)
    return {
        "dataset_size": total,
        "accuracy": round(_safe_div(correct, total), 4),
        "macro_precision": round(_safe_div(macro_precision, class_count), 4),
        "macro_recall": round(_safe_div(macro_recall, class_count), 4),
        "macro_f1": round(_safe_div(macro_f1, class_count), 4),
        "correct_predictions": correct,
        "misclassified_count": len(misclassified),
        "per_class_metrics": per_class,
        "confusion_matrix": confusion_matrix,
        "misclassified_examples": misclassified,
    }


if __name__ == "__main__":
    evaluation = evaluate()
    OUTPUT_FILE.write_text(json.dumps(evaluation, indent=2), encoding="utf-8")
    print(json.dumps(evaluation, indent=2))
