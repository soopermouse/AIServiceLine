provider "aws" {
  region = "us-east-1"
}

# S3 Bucket for Landing Zone
resource "aws_s3_bucket" "landing_zone" {
  bucket = "car-sales-landing-zone-${random_string.suffix.result}"
  acl    = "private"
}

# S3 Bucket for Curated Zone
resource "aws_s3_bucket" "curated_zone" {
  bucket = "car-sales-curated-zone-${random_string.suffix.result}"
  acl    = "private"
}

# Random string for unique bucket names
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "lambda_s3_processing_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Policy for Lambda to access S3
resource "aws_iam_role_policy" "lambda_s3_policy" {
  name = "lambda_s3_policy"
  role = aws_iam_role.lambda_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          "${aws_s3_bucket.landing_zone.arn}/*",
          "${aws_s3_bucket.curated_zone.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

# Lambda Layer for Pandas
resource "aws_lambda_layer_version" "pandas_layer" {
  filename   = "pandas_layer.zip" # Assumes you create a zip with Pandas
  layer_name = "pandas_layer"
  compatible_runtimes = ["python3.8"]
}

# Lambda Function
resource "aws_lambda_function" "preprocess_lambda" {
  filename      = "lambda_function.zip"
  function_name = "preprocess_car_sales"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.8"
  timeout       = 300
  layers        = [aws_lambda_layer_version.pandas_layer.arn]
}

# S3 Event Notification to Trigger Lambda
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.landing_zone.id
  lambda_function {
    lambda_function_arn = aws_lambda_function.preprocess_lambda.arn
    events             = ["s3:ObjectCreated:*"]
    filter_suffix      = ".csv"
  }
}

# Permission for S3 to invoke Lambda
resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowExecutionFromS3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.preprocess_lambda.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.landing_zone.arn
}