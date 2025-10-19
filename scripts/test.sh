#!/usr/bin/env bash
set -euo pipefail

# Convenience test runner for Unix-like shells
VENV_DIR=".venv"
PYTHON="$VENV_DIR/bin/python"

if [ ! -x "$PYTHON" ]; then
  echo "Creating virtualenv at $VENV_DIR..."
  python3 -m venv "$VENV_DIR"
fi

echo "Using python: $PYTHON"
"$PYTHON" -m pip install --upgrade pip >/dev/null
"$PYTHON" -m pip install -r requirements.txt

if [ "${1:-}" = "integration" ]; then
  if [ -z "${INTEGRATION_DB_URL:-}" ]; then
    echo "INTEGRATION_DB_URL is not set. Export it before running integration tests." >&2
    exit 1
  fi
  echo "Running integration tests..."
  "$PYTHON" -m pytest tests/integration -q
else
  echo "Running unit tests..."
  "$PYTHON" -m pytest -q
fi
