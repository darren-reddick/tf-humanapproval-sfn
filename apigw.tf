resource "aws_iam_role" "iam_for_apigateway_approval" {
  name = "iam_for_apigateway_approval"

  assume_role_policy = <<-EOF
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Action": "sts:AssumeRole",
          "Principal": {
            "Service": "apigateway.amazonaws.com"
          },
          "Effect": "Allow",
          "Sid": ""
        }
      ]
    }
  EOF
}


resource "aws_iam_role_policy_attachment" "apigateway-cloudwatchlogs" {
  role       = aws_iam_role.iam_for_apigateway_approval.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

resource "aws_api_gateway_account" "api_gateway_account" {
  cloudwatch_role_arn = aws_iam_role.iam_for_apigateway_approval.arn
}

resource "aws_api_gateway_rest_api" "human_approval" {
  name        = "human_approval"
  description = "Human approval endpoint"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
  body = templatefile("${path.module}/api-definitions/human-approval.yaml", { LAMBDA_INVOKE_ARN = aws_lambda_function.lambda_approval_function.invoke_arn })


}

resource "aws_lambda_permission" "allow_apigateway" {
  statement_id  = "AllowExecutionFromApigateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_approval_function.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.human_approval.execution_arn}/*/*/*"
}

resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = aws_api_gateway_rest_api.human_approval.id
  triggers = {
    redeployment = sha1(jsonencode([aws_api_gateway_rest_api.human_approval.body]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "stage" {
  stage_name    = var.stage
  rest_api_id   = aws_api_gateway_rest_api.human_approval.id
  deployment_id = aws_api_gateway_deployment.deployment.id
}

