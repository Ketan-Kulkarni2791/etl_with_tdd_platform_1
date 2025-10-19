"""
Extraction helpers - small, testable functions.
"""
from typing import BinaryIO
import boto3


def extract_from_s3(bucket: str, key: str, s3_client=None) -> bytes:
    """
    Download object from S3 and return bytes.
    s3_client can be injected for testing (e.g., moto client's boto3.client('s3')).
    """
    if s3_client is None:
        s3_client = boto3.client("s3")
    resp = s3_client.get_object(Bucket=bucket, Key=key)
    body = resp["Body"].read()
    return body