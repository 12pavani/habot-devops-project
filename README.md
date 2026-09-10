# Habot Connect — Junior Cloud & DevOps Engineer Hiring Project

**Candidate:** Vislavath Pavani
**Email:** vislavathpavani5123@gmail.com
**Phone:** 6009129509
**Submitted:** 13 sept 2026

## Structure

```
habot-devops-project/
├── terraform/          Task 1 — GCS + BigQuery provisioning, IAM, RLS
├── .github/workflows/  Task 2 — Poka-Yoke fail-closed CI/CD gate
├── .gitleaks.toml      Task 2 — secret scan rules
└── django/             Task 3 — DCYN validation + DRF serializer
```

Each subfolder has its own README with setup and run instructions. Start
there for details; this file is just the map.

## How the three tasks connect

The BigQuery schema in `terraform/schemas/student_onboarding.json` is the
same shape enforced by the Django model in `django/onboarding/models.py`
and validated by the serializer in `django/onboarding/serializers.py` — one
schema, checked at three layers (API, database, warehouse), rather than
three independently-maintained definitions that could drift apart. The CI
gate in `.github/workflows/ci.yml` is what stops any of those three layers
from being deployed if they violate formatting rules or leak a credential.
