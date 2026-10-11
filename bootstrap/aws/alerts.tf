# ==============================================================================
# Shared alerts topic — where CloudWatch alarms send notifications
#
# Owned here rather than in an application stack so that:
#   - the subscriber email stays out of every Git repository (it comes from the
#     gitignored terraform.tfvars and lives only in local state), and never
#     appears in a CloudFormation template or a public CI log;
#   - any stack can alarm to it by name (bedrock-ai-gateway: cdk.json
#     gateway.alertTopicName).
#
# No server-side encryption: CloudWatch alarms cannot publish to a topic
# encrypted with the AWS-managed aws/sns key, and a customer-managed KMS key
# costs more than this low-volume, non-sensitive topic warrants.
#
# Email subscriptions start as "PendingConfirmation": AWS emails a link that
# must be clicked once before any alert is delivered.
# ==============================================================================

resource "aws_sns_topic" "alerts" {
  name = local.sns_topic_alerts_name

  tags = {
    Name = local.sns_topic_alerts_name
  }
}

resource "aws_sns_topic_subscription" "alerts_email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

output "alerts_topic_name" {
  description = "Alarm actions reference the topic by this name"
  value       = aws_sns_topic.alerts.name
}
