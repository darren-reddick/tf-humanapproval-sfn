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
  filename      = data.archive_file.approvalsendemailsource.output_path
  function_name = "LambdaApprovalSendEmailFunction-${var.stage}"
  role          = aws_iam_role.lambda_send_email_executionrole.arn
  handler       = "approvalSendEmailHandler"
  description   = "Lambda function that callback to AWS Step Functions"

  source_code_hash = data.archive_file.approvalsendemailsource.output_base64sha256

  runtime = "go1.x"

  timeout = 25

  environment {
    variables = {
      EMAIL_SNS_TOPIC = aws_sns_topic.human_approval.arn
    }
  }
}

data "archive_file" "approvalsendemailsource" {
  type        = "zip"
  source_file = "${path.module}/bin/approvalSendEmailHandler"
  output_path = "${path.module}/bin/approvalSendEmailHandler.zip"
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