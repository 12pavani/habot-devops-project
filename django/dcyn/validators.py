"""
DCYN — Deconstructed Clean Yes/No library.

Purpose: take any of the messy ways a "yes/no" answer might arrive in an
incoming payload (true/false, "yes"/"no", "Y"/"N", 1/0) and collapse it to
a strict Python bool — or raise, if the value is ambiguous. The point is
to remove human judgment from the loop entirely: a serializer field using
this never has to guess what a value "probably" means.
"""

from __future__ import annotations

_TRUE_VALUES = {"yes", "y", "true", "1"}
_FALSE_VALUES = {"no", "n", "false", "0"}


class DCYNValidationError(ValueError):
    """Raised when a value cannot be unambiguously resolved to yes/no."""


def to_dcyn(value) -> bool:
    """
    Normalize a raw field value to a strict boolean.

    Accepts: bool, int (0/1), or str (case-insensitive) matching one of
    the known true/false tokens. Anything else — None, empty string,
    "maybe", "N/A", "unknown", partial matches — raises, rather than
    silently defaulting to False. A missing answer is not the same as
    a "no" answer, and this library never conflates the two.
    """
    if isinstance(value, bool):
        return value

    if isinstance(value, int) and value in (0, 1):
        return bool(value)

    if isinstance(value, str):
        normalized = value.strip().lower()
        if normalized in _TRUE_VALUES:
            return True
        if normalized in _FALSE_VALUES:
            return False

    raise DCYNValidationError(
        f"Value {value!r} is not an unambiguous yes/no. "
        f"Accepted: {sorted(_TRUE_VALUES | _FALSE_VALUES)}."
    )
