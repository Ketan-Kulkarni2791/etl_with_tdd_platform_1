<#
.SYNOPSIS
  Convenience script to run tests in PowerShell.

.DESCRIPTION
  Creates a virtualenv at .\.venv if missing, installs requirements, and runs pytest.
  By default runs unit tests. Pass -Integration to run the integration suite (requires INTEGRATION_DB_URL).

EXAMPLES
  # Run unit tests
  .\scripts\test.ps1

  # Run integration tests (must set INTEGRATION_DB_URL first)
  $env:INTEGRATION_DB_URL = 'postgres://user:pass@localhost:5432/testdb'
  .\scripts\test.ps1 -Integration
#>

param(
    [switch]$Integration
)

Set-StrictMode -Version Latest

$venvDir = ".\.venv"
$python = Join-Path $venvDir "Scripts\python.exe"

if (-not (Test-Path $python)) {
    Write-Host "Creating virtual environment at $venvDir..."
    python -m venv $venvDir
}

Write-Host "Using Python: $python"

Write-Host "Installing/ensuring requirements are present (this may take a moment)..."
& $python -m pip install --upgrade pip | Out-Null
& $python -m pip install -r requirements.txt

if ($Integration) {
    if (-not $env:INTEGRATION_DB_URL) {
        Write-Error "INTEGRATION_DB_URL is not set. Set it before running with -Integration."
        exit 1
    }
    Write-Host "Running integration tests..."
    & $python -m pytest tests/integration -q
    exit $LASTEXITCODE
} else {
    Write-Host "Running unit tests..."
    & $python -m pytest -q
    exit $LASTEXITCODE
}
