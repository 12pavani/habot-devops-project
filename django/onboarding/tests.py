import json
from pathlib import Path

import pytest

from onboarding.serializers import StudentOnboardingSerializer

FIXTURES = json.loads(
    (Path(__file__).parent / "sample_payload.json").read_text()
)


def test_valid_payload_passes():
    serializer = StudentOnboardingSerializer(data=FIXTURES["valid_example"])
    assert serializer.is_valid(), serializer.errors
    assert serializer.validated_data["has_diagnosed_support_need"] is True


@pytest.mark.parametrize(
    "case",
    FIXTURES["invalid_examples"],
    ids=[c["description"] for c in FIXTURES["invalid_examples"]],
)
def test_invalid_payloads_are_rejected(case):
    serializer = StudentOnboardingSerializer(data=case["payload"])
    assert not serializer.is_valid()
