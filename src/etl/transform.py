"""
Transformation helpers: CSV -> list[dict] (simple example).
"""
from typing import List, Dict
import csv
import io


def transform_csv_to_dicts(csv_bytes: bytes) -> List[Dict[str, str]]:
    """
    Convert CSV bytes to a list of dictionaries using the CSV header row.
    """
    text = csv_bytes.decode("utf-8")
    reader = csv.DictReader(io.StringIO(text))
    return [dict(row) for row in reader]