import sqlite3
from etl.load import ensure_table, load_records


def test_load_with_sqlite():
    conn = sqlite3.connect(":memory:")
    cur = conn.cursor()
    columns = {"a": "TEXT", "b": "TEXT"}
    ensure_table(cur, "t", columns)
    records = [{"a": "1", "b": "2"}, {"a": "3", "b": "4"}]

    # sqlite uses ? placeholders. We'll monkeypatch execute to replace %s with ? for tests.
    original_execute = cur.execute

    def execute_with_adapt(sql, params=None):
        if params is not None:
            adapted_sql = sql.replace("%s", "?")
            return original_execute(adapted_sql, params)
        return original_execute(sql)

    cur.execute = execute_with_adapt  # type: ignore
    count = load_records(cur, "t", records)
    conn.commit()
    assert count == 2

    cur.execute("SELECT COUNT(*) FROM t")
    n = cur.fetchone()[0]
    assert n == 2
    conn.close()