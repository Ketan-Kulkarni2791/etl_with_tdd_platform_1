"""
Loading helpers - keep DB interaction generic (DB-API 2.0).
"""

from typing import List, Dict


def ensure_table(cursor, table_name: str, columns: Dict[str, str]):
    """
    Create a table if not exists. columns: {name: sql_type}
    """
    cols = ", ".join([f"{name} {sql_type}" for name, sql_type in columns.items()])
    sql = f"CREATE TABLE IF NOT EXISTS {table_name} ({cols});"
    cursor.execute(sql)


def load_records(cursor, table_name: str, records: List[Dict[str, str]]):
    """
    Insert records into DB using the provided cursor (DB-API).
    Expects cursor to be `.execute(sql, params)` capable.
    """
    if not records:
        return 0
    columns = list(records[0].keys())
    placeholders = ", ".join(["%s"] * len(columns))
    cols_sql = ", ".join(columns)
    sql = f"INSERT INTO {table_name} ({cols_sql}) VALUES ({placeholders})"
    count = 0
    for rec in records:
        params = [rec[c] for c in columns]
        # psycopg2 uses %s, sqlite3 uses ? - caller tests can adapt by monkeypatching placeholders if needed
        cursor.execute(sql, params)
        count += 1
    return count