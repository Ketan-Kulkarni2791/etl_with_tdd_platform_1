"""
AWS Lambda handler that orchestrates a simple S3->Postgres ETL.
This is a minimal example demonstrating the call flow:
- Read object from S3
- Transform CSV -> dicts
- Load into RDS (Postgres)

Expect env vars:
- SOURCE_BUCKET
- SOURCE_KEY
- DB_SECRET_ARN (or DB connection details can be used)
"""

import os
import json
import logging
import boto3
import psycopg2
from psycopg2.extras import RealDictCursor

from etl.extract import extract_from_s3
from etl.transform import transform_csv_to_dicts
from etl.load import ensure_table, load_records

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def handler(event, context):
    bucket = os.getenv("SOURCE_BUCKET") or event.get("bucket")
    key = os.getenv("SOURCE_KEY") or event.get("key")
    db_url = os.getenv("DB_URL")  # alternative: use Secrets Manager

    if not (bucket and key and db_url):
        logger.error("Missing configuration: SOURCE_BUCKET, SOURCE_KEY, DB_URL required")
        return {"status": "error", "reason": "missing_configuration"}

    s3 = boto3.client("s3")
    csv_bytes = extract_from_s3(bucket, key, s3_client=s3)
    records = transform_csv_to_dicts(csv_bytes)

    # Simple DB connection - expect DB_URL in format postgres://user:pass@host:port/dbname
    conn = psycopg2.connect(db_url)
    try:
        with conn:
            with conn.cursor() as cur:
                columns = {k: "text" for k in records[0].keys()} if records else {}
                if columns:
                    ensure_table(cur, "etl_table", columns)
                    count = load_records(cur, "etl_table", records)
                else:
                    count = 0
        logger.info("Loaded %d records", count)
    finally:
        conn.close()

    return {"status": "ok", "loaded": count}