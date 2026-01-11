"""
Desirability calculation for todos.

This module provides functions to calculate the desirability score for todos
based on importance, annoyingness, time_estimate, and order.
"""

from typing import Optional, Dict, List
from app.models.todo import Todo, TimeEstimate, time_estimates_order, TodoOrderDict, annotate_integer_order

# Multipliers for the desirability formula
IMPORTANCE_MULTIPLIER = 1.0
ANNOYINGNESS_MULTIPLIER = 1.0
TIME_ESTIMATE_MULTIPLIER = 1.0
PRIORITY_MULTIPLIER = 1.0

# Exponent for priority curve: controls how aggressive the power law curve is
# Higher exponents create steeper curves, making high-priority items far more likely
# Examples: 2.0 is moderate, 3.0-4.0 is steep, 1.0 is linear
PRIORITY_EXPONENT = 10.0

# Exponent for time estimate curve: controls prioritization of shorter tasks
TIME_ESTIMATE_EXPONENT = 5.0

# Exponent for final desirability curve: controls how steeply desirable todos are favored
# Higher values make highly desirable todos far more likely to be selected
DESIRABILITY_EXPONENT = 5.0


def apply_curve(value: float, exponent: float) -> float:
    """
    Apply power law curve to a normalized value [0, 1].

    This curve makes high values disproportionately higher and low values
    lower, creating stronger differentiation.

    Args:
        value: A normalized value between 0 and 1
        exponent: The exponent to use for the power law curve

    Returns:
        The curved value between 0 and 1
    """
    return value ** exponent


def normalize_importance(importance: int) -> float:
    """
    Normalize importance value from 0-5 range to 0.0-1.0 range.

    Args:
        importance: Importance level (0-5)

    Returns:
        Normalized importance as float from 0.0 to 1.0
    """
    return importance / 5.0  # higher importance is more desirable


def normalize_annoyingness(annoyingness: int) -> float:
    """
    Normalize annoyingness value from 0-4 range to 0.0-1.0 range.

    Args:
        annoyingness: Annoyingness level (0-4)

    Returns:
        Normalized annoyingness as float from 0.0 to 1.0
    """
    return complement(annoyingness / 4.0)  # less annoying is more desirable


def normalize_time_estimate(
    time_estimate: Optional[TimeEstimate], max_time_estimate: TimeEstimate
) -> float:
    """
    Normalize a time estimate to a value between 0 and 1.0.

    Time estimates shorter than or equal to max_time_estimate are mapped to 0-1.0,
    where 0 is the minimum time estimate and 1.0 is the maximum.

    Args:
        time_estimate: The time estimate to normalize (None returns 0)
        max_time_estimate: The maximum time estimate to use for scaling

    Returns:
        A normalized value between 0 and 1.0
    """
    if time_estimate is None:
        return 0.0

    time_estimate_order = time_estimates_order[time_estimate]
    max_order = time_estimates_order[max_time_estimate]

    if max_order == 0:
        return 1.0

    normalized = complement(
        min(time_estimate_order / max_order, 1.0)
    )  # lower time estimate is more desirable
    return apply_curve(normalized, TIME_ESTIMATE_EXPONENT)


def normalize_order(todo: Todo, annotated_orders: TodoOrderDict, max_order: int) -> float:
    """
    Normalize a todo's order position to a value between 0 and 1.0.

    A todo earlier in the list (lower order) has a lower normalized value.
    A todo later in the list (higher order) has a higher normalized value.

    Args:
        todo: The Todo instance to normalize
        annotated_orders: Dictionary mapping todo_id to integer_order
        max_order: The maximum order value to use for normalization

    Returns:
        Normalized order as float from 0.0 to 1.0
    """
    todo_order = annotated_orders.get(todo.id)

    if todo_order is None:
        return 0.0

    if max_order == 0:
        return 0.0

    normalized = complement(
        min(todo_order / max_order, 1.0)
    )  # lower order (higher priority) is more desirable
    return apply_curve(normalized, PRIORITY_EXPONENT)


def complement(value: float) -> float:
    """
    Calculate the complement of a normalized value (inverts it).

    For a value in range [0, 1], returns 1 - value.
    Example: complement(0.9) = 0.1, complement(0.1) = 0.9

    Args:
        value: A float value between 0 and 1

    Returns:
        The complement as float between 0 and 1
    """
    return 1.0 - value


def calculate_desirability(
    todo: Todo,
    annotated_orders: TodoOrderDict,
    max_order: int,
    max_time_estimate: TimeEstimate = TimeEstimate.PROJECT,
) -> Optional[float]:
    """
    Calculate the desirability score for a todo.

    The desirability is calculated using the formula:
    (normalized_importance * IMPORTANCE_MULTIPLIER) +
    (normalized_annoyingness * ANNOYINGNESS_MULTIPLIER) +
    (normalized_time_estimate * TIME_ESTIMATE_MULTIPLIER) +
    (normalized_order * PRIORITY_MULTIPLIER)

    Then a power law curve is applied to the final score to amplify differences
    between highly and lowly desirable todos.

    Args:
        todo: The Todo instance to calculate desirability for
        annotated_orders: Dictionary mapping todo_id to integer_order
        max_order: The maximum order value to use for normalization
        max_time_estimate: The maximum time estimate to use for scaling (default: PROJECT)

    Returns:
        The desirability score as a float, or None if required fields are missing
    """
    # Check if required fields are present
    if todo.time_estimate is None:
        return None

    # Calculate normalized values
    norm_importance = normalize_importance(todo.importance)
    norm_annoyingness = normalize_annoyingness(todo.annoyingness)
    norm_time_estimate = normalize_time_estimate(todo.time_estimate, max_time_estimate)
    norm_priority = normalize_order(todo, annotated_orders, max_order)

    # Calculate raw desirability using the formula
    raw_desirability = (
        (norm_importance * IMPORTANCE_MULTIPLIER)
        + (norm_annoyingness * ANNOYINGNESS_MULTIPLIER)
        + (norm_time_estimate * TIME_ESTIMATE_MULTIPLIER)
        + (norm_priority * PRIORITY_MULTIPLIER)
    )

    # Normalize to [0, 1] range based on max possible value
    max_possible = (
        IMPORTANCE_MULTIPLIER + ANNOYINGNESS_MULTIPLIER +
        TIME_ESTIMATE_MULTIPLIER + PRIORITY_MULTIPLIER
    )
    if max_possible == 0:
        normalized_desirability = 0.0
    else:
        normalized_desirability = raw_desirability / max_possible

    # Apply final curve to amplify differences between highly and lowly desirable todos
    # Since normalized_desirability is in [0, 1] and we raise it to a positive exponent,
    # the result is guaranteed to be in [0, 1]
    return apply_curve(normalized_desirability, DESIRABILITY_EXPONENT)


def calculate_desirabilities(
    todos: List[Todo], max_time_estimate: TimeEstimate = TimeEstimate.PROJECT
) -> Dict[str, Optional[float]]:
    """
    Calculate desirability scores for a list of todos.

    Args:
        todos: List of Todo instances
        max_time_estimate: The maximum time estimate to use for scaling (default: PROJECT)

    Returns:
        Dictionary mapping todo_id to desirability score (or None if required fields missing)
    """
    annotated_orders = annotate_integer_order(todos)
    max_order = len(todos) - 1 if todos else 0

    desirabilities = {}
    for todo in todos:
        desirabilities[todo.id] = calculate_desirability(
            todo, annotated_orders, max_order, max_time_estimate
        )

    return desirabilities
