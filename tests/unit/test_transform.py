from etl.transform import transform_csv_to_dicts


def test_transform_basic():
    csv_bytes = b"a,b,c\n1,2,3\n4,5,6\n"
    rows = transform_csv_to_dicts(csv_bytes)
    assert isinstance(rows, list)
    assert rows == [{"a": "1", "b": "2", "c": "3"}, {"a": "4", "b": "5", "c": "6"}]