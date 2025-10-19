import boto3
from moto import mock_s3
from etl.extract import extract_from_s3


@mock_s3
def test_extract_from_s3():
    s3 = boto3.client("s3", region_name="ap-south-1")
    bucket = "test-bucket"
    key = "data.csv"
    s3.create_bucket(Bucket=bucket)
    s3.put_object(Bucket=bucket, Key=key, Body=b"a,b\n1,2\n")
    data = extract_from_s3(bucket, key, s3_client=s3)
    assert data.startswith(b"a,b")