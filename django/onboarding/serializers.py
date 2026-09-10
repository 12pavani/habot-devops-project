from rest_framework import serializers

from dcyn.validators import DCYNValidationError, to_dcyn
from .models import StudentOnboarding, REGION_CHOICES

MIN_STUDENT_AGE = 3
MAX_STUDENT_AGE = 18


class DCYNBooleanField(serializers.Field):
    """
    A field that accepts any raw DCYN-style input (yes/no, Y/N,
    true/false, 1/0) and always serializes to a strict bool. Ambiguous
    input is a validation error, not a silent default — see
    dcyn/validators.py for why.
    """

    def to_internal_value(self, data):
        try:
            return to_dcyn(data)
        except DCYNValidationError as exc:
            raise serializers.ValidationError(str(exc)) from exc

    def to_representation(self, value):
        return bool(value)


class StudentOnboardingSerializer(serializers.ModelSerializer):
    has_diagnosed_support_need = DCYNBooleanField()
    consent_data_sharing = DCYNBooleanField()

    class Meta:
        model = StudentOnboarding
        fields = [
            "student_id",
            "parent_id",
            "student_age",
            "has_diagnosed_support_need",
            "consent_data_sharing",
            "region",
            "submitted_at",
        ]

    def validate_student_age(self, value: int) -> int:
        if not (MIN_STUDENT_AGE <= value <= MAX_STUDENT_AGE):
            raise serializers.ValidationError(
                f"student_age must be between {MIN_STUDENT_AGE} and {MAX_STUDENT_AGE} "
                f"inclusive — got {value}."
            )
        return value

    def validate_region(self, value: str) -> str:
        valid = {code for code, _ in REGION_CHOICES}
        if value not in valid:
            raise serializers.ValidationError(
                f"region must be one of {sorted(valid)} — got {value!r}. "
                f"No free-text or placeholder regions are accepted."
            )
        return value

    def validate_consent_data_sharing(self, value: bool) -> bool:
        # Hard business rule, enforced here rather than left to the
        # caller to remember: onboarding cannot proceed without consent.
        # This is deliberately a serializer-level validator, not a
        # database constraint, so the API rejects it before any write.
        if value is not True:
            raise serializers.ValidationError(
                "consent_data_sharing must be explicitly true to onboard a student."
            )
        return value
