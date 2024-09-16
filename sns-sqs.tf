# Create a s3 bucker
resource "aws_s3_bucket" "s3" {
  bucket       = "sns-sqs-velautham"

  tags = {
    Name         = "My bucket"
    Environment  = "Dev"
  }
}

# SNS topic
resource "aws_sns_topic" "sns_topic" {
  name                        = "info-topic"
  fifo_topic                  = false
}
resource "aws_sns_topic_policy" "policy" {
  arn = aws_sns_topic.sns_topic.arn

  policy = data.aws_iam_policy_document.sns_policy.json
}

data "aws_iam_policy_document" "sns_policy" {
  policy_id = "__default_policy_ID"

  statement {
    actions = [
      "SNS:Subscribe",
      "SNS:SetTopicAttributes",
      "SNS:RemovePermission",
      "SNS:Receive",
      "SNS:Publish",
      "SNS:ListSubscriptionsByTopic",
      "SNS:GetTopicAttributes",
      "SNS:DeleteTopic",
      "SNS:AddPermission",
    ]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceOwner"

      values = [
        aws_sns_topic.sns_topic.arn,
      ]
    }

    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
  
    resources = [
      aws_sns_topic.sns_topic.arn,
    ]

    sid = "__default_statement_ID"
  }
}

# SQS
resource "aws_sqs_queue" "s_queue" {
  name                        = "sqs_queue"
  fifo_queue                  = false
  
}

data "aws_iam_policy_document" "test" {
  statement {
    sid    = "First"
    effect = "Allow"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.s_queue.arn]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_sns_topic.sns_topic.arn]
    }
  }
}

resource "aws_sqs_queue_policy" "test" {
  queue_url = aws_sqs_queue.s_queue.id
  policy    = data.aws_iam_policy_document.test.json
}

resource "aws_sns_topic_subscription" "sqs_target" {
  topic_arn = aws_sns_topic.sns_topic.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.s_queue.arn
}
