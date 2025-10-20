# ETL TDD Self-Service Platform (Python 3.11 + AWS + Terraform + GitHub Actions)

Overview
--------
This repository demonstrates a TDD-first ETL self-service platform:
- Python 3.11 code (ETL library + AWS Lambda handler)
- Unit tests (pytest) and mocks (moto) for TDD
- Integration test scaffold (runs only if env var RUN_INTEGRATION=1)
- Terraform to provision AWS resources (S3, Lambda, Step Functions, RDS Postgres, IAM, Secrets Manager, CloudWatch)
- Scripts to package Lambda
- GitHub Actions workflows:
  - CI on PRs: run tests, lint, terraform fmt check & validate
  - CD on push to main: run terraform apply (requires AWS secrets)

Project layout
--------------
- src/etl/        ETL module (extract, transform, load)
- src/handlers/   Lambda entrypoint
- tests/          Unit and integration tests (TDD-first)
- terraform/      Terraform configs for AWS infra
- .github/workflows CI/CD pipelines
- scripts/        packaging and helper scripts
- requirements.txt Python deps

TDD workflow (recommended)
--------------------------
1. Write/extend tests under tests/unit/ (fail locally)
2. Implement/modify code under src/ to satisfy tests
3. Commit tests+code together
4. Create a PR — CI runs tests and terraform checks
5. After review, merge to main — CD can deploy infra

Quick local setup
-----------------
1. Install Python 3.11 and create a venv:
   python3.11 -m venv .venv && source .venv/bin/activate

2. Install deps:
   pip install -r requirements.txt

3. Run unit tests:
   pytest -q

4. To run integration tests (requires local Postgres):
   export RUN_INTEGRATION=1
   pytest tests/integration -q

Running tests (Windows PowerShell)
---------------------------------
If you're on Windows (PowerShell), use the workspace virtualenv and these commands:

```powershell
# create venv (if not already created)
python -m venv .venv
.\.venv\Scripts\Activate.ps1
# install deps
pip install -r requirements.txt
# run all tests (unit + integration if enabled)
& ".\.venv\Scripts\python.exe" -m pytest -q
```

Enabling integration tests
--------------------------
- The integration tests are skipped by default. To enable them set the env var `RUN_INTEGRATION=1`.
- Integration tests expect `INTEGRATION_DB_URL` to be set to a Postgres connection string, for example:

```powershell
$env:RUN_INTEGRATION = '1'
$env:INTEGRATION_DB_URL = 'postgres://user:pass@localhost:5432/testdb'
& ".\.venv\Scripts\python.exe" -m pytest tests/integration -q
```

Notes
-----
- For Windows PowerShell, use the `Activate.ps1` activation script. On non-Windows shells use the shell-appropriate activation command.
- The test suite uses `moto` to mock AWS services and `psycopg2-binary` for Postgres integration tests.

Packaging Lambda locally
------------------------
scripts/package_lambda.sh will create `build/etl_lambda.zip` containing handler code and dependencies (for small deployments). For production use, build in a Lambda-compatible environment or use an image-based Lambda.

Terraform notes
---------------
- Terraform configs live in /terraform.
- The TF files include placeholders for networking (VPC, subnets) and RDS sizing — adjust for your account.
- For lambda packaging, terraform uses an archive built from `src/handlers`. For CI/CD we zip before terraform apply.

GitHub Actions
--------------
- .github/workflows/ci.yml: runs tests and terraform checks on PRs
- .github/workflows/cd.yml: applies terraform on push to main (requires AWS credentials as repo secrets)

Security
--------
- Secrets (DB password, AWS creds) must be stored in GitHub Actions secrets or AWS Secrets Manager when running in production.
- RDS is created as an example but is not secured to production standards in this scaffold — please add VPC/subnets/security group controls in terraform for production.

Next steps
----------
- Customize Terraform for your environment (VPC, subnets, database subnet group, multi-AZ, backups)
- Add a Lambda-layer packaging pipeline for dependencies that are compiled
- Expand Step Function with retries/error handling and add metrics + CloudWatch Alarms
- Add a service catalog or a self-service UI (e.g., a small Flask app) to let users trigger ETL jobs
