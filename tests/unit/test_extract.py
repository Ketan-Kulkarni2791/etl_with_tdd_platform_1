import boto3
try:
    # moto exposes mock_s3 in some versions; prefer it if present
    from moto import mock_s3 as _moto_mock_s3  # type: ignore

    def s3_decorator(func):
        return _moto_mock_s3(func)
except Exception:
    # Fallback to moto.mock_aws() which returns a decorator/context-manager in moto v5
    from moto import mock_aws as _moto_mock_aws  # type: ignore

    def s3_decorator(func):
        return _moto_mock_aws()(func)

from etl.extract import extract_from_s3


@s3_decorator
def test_extract_from_s3():
    s3 = boto3.client("s3", region_name="ap-south-1")
    bucket = "test-bucket"
    key = "data.csv"
    # For region-specific endpoints, CreateBucket requires a LocationConstraint
    s3.create_bucket(Bucket=bucket, CreateBucketConfiguration={"LocationConstraint": "ap-south-1"})
    s3.put_object(Bucket=bucket, Key=key, Body=b"a,b\n1,2\n")
    data = extract_from_s3(bucket, key, s3_client=s3)
    assert data.startswith(b"a,b")