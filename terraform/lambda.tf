data "archive_file" "lambda_zip" {
  type             = "zip"
  source_file      = "../index.py"
  output_file_mode = "0666"
  output_path      = "../output/index.py.zip"
}

resource "aws_lambda_layer_version" "lambda_layer" {
  filename   = "../lambda_layer.zip"
  layer_name = "word-a-day-layer"

  compatible_runtimes = ["python3.9"]
}

resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_lambda_function" "tweet-word" {
  filename      = data.archive_file.lambda_zip.output_path
  function_name = "word-a-day-tweet-prod"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "index.handler"

  layers = [aws_lambda_layer_version.lambda_layer.arn]

  # The filebase64sha256() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the base64sha256() function and the file() function:
  # source_code_hash = "${base64sha256(file("lambda_function_payload.zip"))}"
  source_code_hash = filebase64sha256("../lambda_layer.zip")

  runtime = "python3.9"

  environment {
    variables = {
      rapidAPI_key = var.rapidAPI_key,
      rapidAPI_host = var.rapidAPI_host,
      tw_consumer_key = var.tw_consumer_key,
      tw_consumer_secret = var.tw_consumer_secret,
      tw_access_token = var.tw_access_token,
      tw_access_token_secret = var.tw_access_token_secret,
    }
  }
}

resource "aws_iam_policy" "lambda_logging" {
  name        = "lambda_logging"
  path        = "/"
  description = "IAM policy for logging from a lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}