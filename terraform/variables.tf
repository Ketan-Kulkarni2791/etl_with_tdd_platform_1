variable "aws_region" {
  type    = string
  default = "ap-south-1"
}

variable "project_prefix" {
  type    = string
  default = "etltdd"
}

variable "s3_bucket_name" {
  type    = string
  default = "etltdd-ingest-bucket-PLACEHOLDER" # change to a unique bucket name
}

variable "lambda_zip_path" {
  type    = string
  default = "build/etl_lambda.zip"
}

variable "db_instance_class" {
  type    = string
  default = "db.t3.micro"
}

variable "db_name" {
  type    = string
  default = "etldb"
}

variable "db_username" {
  type    = string
  default = "etl_user"
}

variable "db_password" {
  type    = string
  default = "ChangeMe123!" # override in production via tfvars or secrets
}