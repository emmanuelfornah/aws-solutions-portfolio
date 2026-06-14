from __future__ import annotations

from typing import Iterable, List, Optional, Sequence


def normalize_analyte_name(analyte: str) -> str:
    """Normalize analyte names for deterministic comparison."""
    if analyte is None:
        return ""
    return str(analyte).strip().lower().replace(" ", "_").replace("-", "_")


def normalize_analyte_list(analytes: Iterable[str]) -> List[str]:
    """Normalize and de-duplicate analyte names."""
    normalized = {normalize_analyte_name(item) for item in (analytes or []) if normalize_analyte_name(item)}
    return sorted(normalized)


def compare_new_to_prior_analytes(new_order_analytes: Sequence[str], prior_order_analytes: Sequence[str]) -> List[str]:
    """Return sorted overlapping analytes between current and prior order."""
    new_set = set(normalize_analyte_list(new_order_analytes))
    prior_set = set(normalize_analyte_list(prior_order_analytes))
    return sorted(new_set.intersection(prior_set))


def compute_overlap_ratio(new_order_analytes: Sequence[str], overlapping_analytes: Sequence[str]) -> float:
    """Compute overlap as overlap_count/new_order_count."""
    new_count = len(normalize_analyte_list(new_order_analytes))
    if new_count == 0:
        return 0.0
    ratio = len(set(overlapping_analytes)) / float(new_count)
    return round(ratio, 3)


def _is_likely_upgrade(
    new_order_code: str,
    prior_order_code: str,
    new_order_analytes: Sequence[str],
    prior_order_analytes: Sequence[str],
    overlap_ratio: float,
) -> bool:
    new_code = (new_order_code or "").upper()
    prior_code = (prior_order_code or "").upper()
    new_set = set(normalize_analyte_list(new_order_analytes))
    prior_set = set(normalize_analyte_list(prior_order_analytes))

    bmp_to_cmp = prior_code == "BMP" and new_code == "CMP" and prior_set and prior_set.issubset(new_set)
    generic_subset_upgrade = bool(prior_set) and prior_set.issubset(new_set) and len(new_set) > len(prior_set)

    return (bmp_to_cmp or generic_subset_upgrade) and overlap_ratio >= 0.5


def classify_overlap(
    new_order_analytes: Sequence[str],
    prior_analytes: Sequence[str],
    new_order_code: Optional[str] = None,
    prior_order_code: Optional[str] = None,
):
    overlapping_analytes = compare_new_to_prior_analytes(new_order_analytes, prior_analytes)
    overlap_ratio = compute_overlap_ratio(new_order_analytes, overlapping_analytes)
    potential_upgrade = _is_likely_upgrade(
        new_order_code or "",
        prior_order_code or "",
        new_order_analytes,
        prior_analytes,
        overlap_ratio,
    )

    if not overlapping_analytes:
        return {
            "decision": "proceed",
            "overlapping_analytes": [],
            "overlap_ratio": 0.0,
            "potential_upgrade": False,
            "suggested_next_step": "proceed",
        }

    if potential_upgrade:
        return {
            "decision": "flag_for_review",
            "overlapping_analytes": overlapping_analytes,
            "overlap_ratio": overlap_ratio,
            "potential_upgrade": True,
            "suggested_next_step": "invoke_tier2_classifier",
        }

    return {
        "decision": "flag_for_review",
        "overlapping_analytes": overlapping_analytes,
        "overlap_ratio": overlap_ratio,
        "potential_upgrade": False,
        "suggested_next_step": "manual_review",
    }
