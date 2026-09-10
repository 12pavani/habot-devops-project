# Task 2: Poka-Yoke CI/CD Build Gate

**File:** `.github/workflows/ci.yml` (must live at repo root under
`.github/workflows/` — GitHub only picks up workflows from that exact path).

Three parallel jobs, all required checks:

1. **`secret-scan`** — runs [gitleaks](https://github.com/gitleaks/gitleaks)
   against full git history, using `.gitleaks.toml` (extends gitleaks'
   default rules, plus custom patterns for GCP service-account keys and
   Django `SECRET_KEY`). Any match fails the job — no soft-fail, no
   override.
2. **`python-lint`** — `black --check` and `flake8` against `django/`.
3. **`terraform-validate`** — `terraform fmt -check` and `terraform validate`
   against `terraform/`.

A fourth job, **`build-gate-summary`**, aggregates the three and exits
non-zero if any failed — so with branch protection requiring this check,
a PR with a hardcoded secret or a formatting violation **cannot be merged**,
full stop. That's the "fail-closed" behavior the brief asks for: the
default state on any doubt is "blocked," not "warn and proceed."

**To demonstrate the fail-closed trigger for the presentation:** commit a
dummy value like `AWS_SECRET_KEY = "AKIAABCDEFGHIJKLMNOP"` into any tracked
file on a branch, open a PR, and screenshot the `secret-scan` job failing
red within seconds — that's the artifact for slide requirement (b).

---

# Task 3: Schema Mapping & DCYN Validation

**Files:** `django/dcyn/validators.py`, `django/onboarding/models.py`,
`django/onboarding/serializers.py`, `django/onboarding/sample_payload.json`,
`django/onboarding/tests.py`

- **`dcyn/validators.py`** — the DCYN library. `to_dcyn()` takes any raw
  representation of yes/no (`true/false`, `"Y"/"N"`, `"yes"/"no"`, `1/0`)
  and returns a strict `bool`, or raises `DCYNValidationError` on anything
  ambiguous (`"maybe"`, `"N/A"`, `null`, empty string). This is the
  "eliminate human judgment" requirement — the library never guesses.
- **`onboarding/models.py`** — mirrors the BigQuery schema from Task 1
  (`terraform/schemas/student_onboarding.json`), so the same shape is
  enforced at the database, API, and warehouse layers.
- **`onboarding/serializers.py`** — `StudentOnboardingSerializer`:
  - `student_age` must be 3–18 inclusive
  - `region` must be one of a closed choice set (no free text — matches
    the RLS policy's `analyst_region_map`)
  - `has_diagnosed_support_need` / `consent_data_sharing` run through the
    DCYN field, so any ambiguous input is rejected before it reaches the
    database
  - `consent_data_sharing` must resolve to `True` — onboarding is refused
    without explicit consent, enforced at the API layer, not left as a
    downstream check
- **`sample_payload.json`** — one valid payload and four invalid ones
  (out-of-range age, ambiguous DCYN value, missing consent, free-text
  region), used directly by `tests.py`.

## Running the tests

```bash
cd django
pip install -r requirements.txt
pytest onboarding/tests.py -v
```

**Submitted by:** [YOUR FULL NAME] — [YOUR EMAIL] — [YOUR PHONE]
