#################################### CloudWatch Event Rule to Monitor Spot Instances Interruption and Termination #########################################

resource "aws_cloudwatch_event_rule" "spot_interruption" {
  name        = "capture-spot-interruption"
  description = "Triggers when AWS issues a 2-minute Spot Instance termination notice"

  event_pattern = jsonencode(
    {
      source      = ["aws.ec2"]
      detail-type = ["EC2 Spot Instance Interruption Warning"]
    }
  )
}

data "aws_sns_topic" "cloudwatch_alerts" {
  name = var.sns_topic_name
}

resource "aws_cloudwatch_event_target" "sns_target" {
  rule      = aws_cloudwatch_event_rule.spot_interruption.name
  target_id = "SendToSNS"
  arn       = data.aws_sns_topic.cloudwatch_alerts.arn
}

data "aws_iam_policy_document" "sns_topic_policy" {
  # Default SNS topic owner permissions
  statement {
    sid    = "__default_statement_ID"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions = [
      "SNS:Publish",
      "SNS:RemovePermission",
      "SNS:SetTopicAttributes",
      "SNS:DeleteTopic",
      "SNS:ListSubscriptionsByTopic",
      "SNS:GetTopicAttributes",
      "SNS:AddPermission",
      "SNS:Subscribe"
    ]
    resources = [
      data.aws_sns_topic.cloudwatch_alerts.arn
    ]
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceOwner"
      values = [
        data.aws_caller_identity.G_Duty.account_id
      ]
    }
  }

  # Allow EventBridge to publish Spot interruption events
  statement {
    sid    = "AllowEventBridgePublish"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = [
        "events.amazonaws.com"
      ]
    }
    actions = [
      "SNS:Publish"
    ]
    resources = [
      data.aws_sns_topic.cloudwatch_alerts.arn
    ]
  }
}

resource "aws_sns_topic_policy" "attach_policy_to_topic" {
  arn    = data.aws_sns_topic.cloudwatch_alerts.arn
  policy = data.aws_iam_policy_document.sns_topic_policy.json
}

# EventBridge Rule for EC2 Terminated State
resource "aws_cloudwatch_event_rule" "ec2_terminated" {
  name        = "ec2-spot-terminated-rule"
  description = "Alert when a Spot Instance enters terminated state"

  event_pattern = jsonencode({
    source      = ["aws.ec2"]
    detail-type = ["EC2 Instance State-change Notification"]
    detail = {
      state = ["terminated"]
    }
  })
}

# Route to SNS Topic
resource "aws_cloudwatch_event_target" "sns_terminated_target" {
  rule      = aws_cloudwatch_event_rule.ec2_terminated.name
  target_id = "SendTerminatedToSNS"
  arn       = data.aws_sns_topic.cloudwatch_alerts.arn
}
