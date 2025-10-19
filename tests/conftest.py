import sys
from pathlib import Path

# Ensure the project's `src` directory is on sys.path so tests can import `etl`.
ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "src"
sys.path.insert(0, str(SRC))
