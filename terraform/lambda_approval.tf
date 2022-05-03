resource "aws_iam_role" "lambda_apigateway_iam_role" {
  name = "lambda_apigateway_iam_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_lambda_function" "lambda_approval_function" {
  # If the file is not in the current working directory you will need to include a 
  # path.module in the filename.
  filename      = data.archive_file.approvalsource.output_path
  function_name = "LambdaApprovalFunction-${var.stage}"
  role          = aws_iam_role.lambda_apigateway_iam_role.arn
  handler       = "approvalHandler"
  description   = "Lambda function that callback to AWS Step Functions"

  # The filebase64sha256() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the base64sha256() function and the file() function:
  # source_code_hash = "${base64sha256(file("lambda_function_payload.zip"))}"
  source_code_hash = data.archive_file.approvalsource.output_base64sha256

  runtime = "go1.x"


}

data "archive_file" "approvalsource" {
  type        = "zip"
  source_file = "${path.module}/../bin/approvalHandler"
  output_path = "${path.module}/../bin/approvalHandler.zip"
}


resource "aws_iam_role_policy" "lambda_apigateway_policy" {
  name = "lambda_sfn_invoke_policy"
  role = aws_iam_role.lambda_apigateway_iam_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Action = [
          "states:SendTaskFailure",
          "states:SendTaskSuccess"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}
