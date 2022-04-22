resource "aws_sfn_state_machine" "sfn" {
  name     = "HumanApprovalMachine"
  role_arn = aws_iam_role.sfn.arn

  definition = <<EOF
{
  "StartAt": "Lambda Callback",
  "TimeoutSeconds": 3600,
  "States": {
    "Lambda Callback": {
      "Type": "Task",
      "Resource": "arn:aws:states:::lambda:invoke.waitForTaskToken",
      "Parameters": {
        "FunctionName": "${aws_lambda_function.lambda_approvalsendemail_function.arn}",
        "Payload": {
          "ExecutionContext.$": "$$",
          "APIGatewayEndpoint": "${aws_api_gateway_stage.stage.invoke_url}",
          "SNSTopicArn": "${aws_sns_topic.human_approval.arn}"
        }
      },
      "Next": "ManualApprovalChoiceState"
    },
    "ManualApprovalChoiceState": {
      "Type": "Choice",
      "Choices": [
        {
          "Variable": "$.Status",
          "StringEquals": "Approved! Task approved",
          "Next": "ApprovedPassState"
        },
        {
          "Variable": "$.Status",
          "StringEquals": "Rejected! Task rejected",
          "Next": "RejectedPassState"
        }
      ]
    },
    "ApprovedPassState": {
      "Type": "Pass",
      "End": true
    },
    "RejectedPassState": {
      "Type": "Pass",
      "End": true
    }
  }
}
EOF
}

resource "aws_iam_role" "sfn" {
  name = "iam_for_sfn"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "states.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    Name = "iam_for_sfn"
  }
}

resource "aws_iam_role_policy" "sfn_lambda_invoke" {
  name = "sfn_lambda_invoke_policy"
  role = aws_iam_role.sfn.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "lambda:InvokeFunction",
        ]
        Effect   = "Allow"
        Resource = "${aws_lambda_function.lambda_approvalsendemail_function.arn}"
      },
    ]
  })
}

resource "aws_lambda_permission" "allow_sfn" {
  statement_id  = "AllowExecutionFromSfn"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_approvalsendemail_function.function_name
  principal     = "states.amazonaws.com"
}