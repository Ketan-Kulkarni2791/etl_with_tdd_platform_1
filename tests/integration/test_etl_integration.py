import os
import pytest
import psycopg2
from etl.transform import transform_csv_to_dicts
from etl.load import ensure_table, load_records

# Integration tests are skipped unless RUN_INTEGRATION=1
pytestmark = pytest.mark.skipif(
    os.getenv("RUN_INTEGRATION") != "1", reason="Integration tests disabled"
)


def test_postgres_load_full_flow():
    """
    Requires a running Postgres and environment variable INTEGRATION_DB_URL like:
    postgres://user:pass@localhost:5432/testdb
    """
    db_url = os.getenv("INTEGRATION_DB_URL")
    assert db_url, "Set INTEGRATION_DB_URL to run this test"

    conn = psycopg2.connect(db_url)
    try:
        with conn:
            with conn.cursor() as cur:
                columns = {"a": "text", "b": "text"}
                ensure_table(cur, "int_t", columns)
                records = transform_csv_to_dicts(b"a,b\n1,2\n3,4\n")
                count = load_records(cur, "int_t", records)
                assert count == 2
    finally:
        conn.close()