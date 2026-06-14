def find_overlap(new_order_analytes, prior_analytes):
    """
    Returns a sorted list of overlapping analytes.
    """
    return sorted(set(new_order_analytes).intersection(set(prior_analytes)))


def classify_overlap(new_order_analytes, prior_analytes):
    overlap = find_overlap(new_order_analytes, prior_analytes)

    if not overlap:
        return {
            "decision": "proceed",
            "overlapping_analytes": []
        }

    return {
        "decision": "flag_for_review",
        "overlapping_analytes": overlap
    }
