terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.4.0"
}

provider "aws" {
  region = var.aws_region
}

# S3 bucket for ingest
resource "aws_s3_bucket" "ingest" {
  bucket = var.s3_bucket_name
  acl    = "private"
  tags = {
    Name = "etl-ingest-bucket"
  }
}

# IAM role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "${var.project_prefix}-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# Attach managed policy for basic lambda logging
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Optional inline policy to allow S3 read and SecretsManager/RDS access - tailor to least privilege
resource "aws_iam_policy" "lambda_policy" {
  name   = "${var.project_prefix}-lambda-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject"
        ]
        Effect   = "Allow"
        Resource = "${aws_s3_bucket.ingest.arn}/*"
      },
      {
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Effect = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

# Lambda - using archive file created by CI/CD (path via var)
data "local_file" "lambda_zip" {
  filename = var.lambda_zip_path
  # This data source only ensures file exists locally when running terraform from local/CI. In other contexts,
  # you might upload to S3 and reference there.
}

resource "aws_lambda_function" "etl_func" {
  function_name = "${var.project_prefix}-etl"
  filename      = var.lambda_zip_path
  role          = aws_iam_role.lambda_role.arn
  handler       = "handlers.etl_handler.handler"
  runtime       = "python3.11"
  source_code_hash = filebase64sha256(var.lambda_zip_path)
  timeout       = 900
  environment {
    variables = {
      SOURCE_BUCKET = aws_s3_bucket.ingest.bucket
    }
  }
}

# Basic CloudWatch log group is created automatically by Lambda; add retention
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.etl_func.function_name}"
  retention_in_days = 14
}

# RDS Postgres - simplified example (NOT production ready). You should place in a VPC/subnets
resource "aws_db_instance" "postgres" {
  allocated_storage    = 20
  engine               = "postgres"
  engine_version       = "15.3"
  instance_class       = var.db_instance_class
  name                 = var.db_name
  username             = var.db_username
  password             = var.db_password
  skip_final_snapshot  = true
  publicly_accessible  = true
  storage_encrypted    = false
}

# Secrets manager storing DB credentials (optionally)
resource "aws_secretsmanager_secret" "db_secret" {
  name = "${var.project_prefix}-db-secret"
}

resource "aws_secretsmanager_secret_version" "db_secret_value" {
  secret_id     = aws_secretsmanager_secret.db_secret.id
  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
    host     = aws_db_instance.postgres.address
    dbname   = var.db_name
  })
}

# Placeholders for Step Function, etc (example state machine calling the lambda)
resource "aws_iam_role" "stepfn_role" {
  name = "${var.project_prefix}-stepfn-role"
  assume_role_policy = data.aws_iam_policy_document.stepfn_assume.json
}

data "aws_iam_policy_document" "stepfn_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["states.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "stepfn_policy" {
  name   = "${var.project_prefix}-stepfn-policy"
  role   = aws_iam_role.stepfn_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "lambda:InvokeFunction"
        ],
        Resource = [aws_lambda_function.etl_func.arn]
      }
    ]
  })
}

resource "aws_sfn_state_machine" "etl_machine" {
  name     = "${var.project_prefix}-etl-machine"
  role_arn = aws_iam_role.stepfn_role.arn
  definition = jsonencode({
    StartAt = "RunETL",
    States = {
      RunETL = {
        Type = "Task",
        Resource = aws_lambda_function.etl_func.arn,
        End = true
      }
    }
  })
}

output "lambda_function_name" {
  value = aws_lambda_function.etl_func.function_name
}

output "s3_bucket" {
  value = aws_s3_bucket.ingest.bucket
}

output "rds_endpoint" {
  value = aws_db_instance.postgres.address
}