resource "aws_sns_topic" "human_approval" {
  name = "human-approval-topic"
}

resource "aws_sns_topic_subscription" "me" {
  protocol  = "email"
  endpoint  = "darren.reddick@ecs.co.uk"
  topic_arn = aws_sns_topic.human_approval.arn
}