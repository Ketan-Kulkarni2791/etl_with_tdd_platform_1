output "lambda_name" {
  value = aws_lambda_function.etl_func.function_name
}

output "s3_bucket" {
  value = aws_s3_bucket.ingest.bucket
}

output "rds_address" {
  value = aws_db_instance.postgres.address
}