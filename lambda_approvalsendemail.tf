resource "aws_iam_role" "lambda_send_email_executionrole" {
  name = "lambda_send_email_executionrole"

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

resource "aws_lambda_function" "lambda_approvalsendemail_function" {
  # If the file is not in the current working directory you will need to include a 
  # path.module in the filename.
  filename      = "${path.module}/.terraform/LambdaApprovalSendEmailFunction.zip"
  function_name = "LambdaApprovalSendEmailFunction-${var.stage}"
  role          = aws_iam_role.lambda_send_email_executionrole.arn
  handler       = "approvalsendemail.handler"
  description   = "Lambda function that callback to AWS Step Functions"

  # The filebase64sha256() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the base64sha256() function and the file() function:
  # source_code_hash = "${base64sha256(file("lambda_function_payload.zip"))}"
  source_code_hash = data.archive_file.approvalsendemailsource.output_base64sha256

  runtime = "nodejs12.x"

  timeout = 25

  environment {
    variables = {
      EMAIL_SNS_TOPIC = aws_sns_topic.human_approval.arn
    }
  }
}

data "archive_file" "approvalsendemailsource" {
  type        = "zip"
  source_file = "${path.module}/lambda/approvalsendemail.js"
  output_path = "${path.module}/.terraform/LambdaApprovalSendEmailFunction.zip"
}


resource "aws_iam_role_policy" "lambda_sfn_invoke" {
  name = "lambda_sfn_invoke_policy"
  role = aws_iam_role.lambda_send_email_executionrole.id

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
          "SNS:Publish"
        ]
        Effect   = "Allow"
        Resource = "${aws_sns_topic.human_approval.arn}"
      },
    ]
  })
}