import sqlite3
from etl.load import ensure_table, load_records


def test_load_with_sqlite():
    conn = sqlite3.connect(":memory:")
    cur = conn.cursor()
    columns = {"a": "TEXT", "b": "TEXT"}
    ensure_table(cur, "t", columns)
    records = [{"a": "1", "b": "2"}, {"a": "3", "b": "4"}]

    # sqlite uses ? placeholders. Create a proxy cursor that adapts %s -> ?
    class ProxyCursor:
        def __init__(self, real):
            self._real = real

        def execute(self, sql, params=None):
            if params is not None:
                sql = sql.replace("%s", "?")
                return self._real.execute(sql, params)
            return self._real.execute(sql)

        def executemany(self, sql, seq_of_params):
            adapted_sql = sql.replace("%s", "?")
            return self._real.executemany(adapted_sql, seq_of_params)

        def __getattr__(self, name):
            return getattr(self._real, name)

    proxy = ProxyCursor(cur)
    cur = proxy
    count = load_records(cur, "t", records)
    conn.commit()
    assert count == 2

    cur.execute("SELECT COUNT(*) FROM t")
    n = cur.fetchone()[0]
    assert n == 2
    conn.close()