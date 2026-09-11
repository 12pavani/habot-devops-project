from django.db import models

# Fixed region list — matches the analyst_region_map used by the
# row-level security policy in terraform/policies/rls_policies.sql.
# A closed choice set instead of a free-text field is itself a
# mistake-proofing control: it's impossible to onboard a student into
# a region the RLS policy doesn't know about.

REGION_CHOICES = [
    ("dubai", "Dubai"),
    ("abu_dhabi", "Abu Dhabi"),
    ("sharjah", "Sharjah"),
]


class StudentOnboarding(models.Model):
    student_id = models.UUIDField(unique=True)
    parent_id = models.UUIDField()
    student_age = models.PositiveSmallIntegerField()
    has_diagnosed_support_need = models.BooleanField()
    consent_data_sharing = models.BooleanField()
    region = models.CharField(max_length=20, choices=REGION_CHOICES)
    submitted_at = models.DateTimeField()
    ingested_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        app_label = "onboarding"

    def __str__(self) -> str:
        return f"StudentOnboarding({self.student_id})"
