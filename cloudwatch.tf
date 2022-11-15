locals {
  dimensions = {
    ClusterName = var.cluster.name
    ServiceName = aws_ecs_service.service.name
  }
}

resource "aws_cloudwatch_log_group" "log_group" {
  name              = "${var.name}-${var.environment}-log-group"
  retention_in_days = 7
}

#Cloudwatch alarm that triggers autoscaling up policy
resource "aws_cloudwatch_metric_alarm" "service_cpu_high" {
  alarm_name          = "${var.name}-${var.environment}-cpu-utilization-high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = "70"

  dimensions = local.dimensions

  alarm_actions = [aws_appautoscaling_policy.increase.arn]
}

#Cloudwatch alarm that triggers autoscaling down policy
resource "aws_cloudwatch_metric_alarm" "service_cpu_low" {
  alarm_name          = "${var.name}-${var.environment}-cpu-utilization-low"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = "10"

  dimensions = local.dimensions

  alarm_actions = [aws_appautoscaling_policy.decrease.arn]
}

resource "aws_cloudwatch_metric_alarm" "service_down_1" {
  alarm_name          = "${var.name}-${var.environment}-service-down-1"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "SampleCount"
  threshold           = "1"

  dimensions = local.dimensions

  alarm_description = "No Task Running"
  alarm_actions     = [aws_sns_topic.sns.arn]
}

resource "aws_cloudwatch_metric_alarm" "service_down_2" {
  alarm_name          = "${var.name}-${var.environment}-service-down-2"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Maximum"
  threshold           = "98"

  dimensions = local.dimensions

  alarm_description = "Server Crashed due to heavy traffic !!! "
  alarm_actions     = [aws_sns_topic.sns.arn]
}

resource "aws_cloudwatch_event_rule" "alarm" {
  name          = "${var.name}-${var.environment}-task-stopped"
  event_pattern = <<EOF
  {
   "source":[
      "aws.ecs"
   ],
   "detail-type":[
      "ECS Task State Change"
   ],
   "detail":{
      "lastStatus":[
         "STOPPED"
      ],
      "stoppedReason":[
         "Essential container in task exited"
      ],
      "clusterArn": [
      "${var.cluster.arn}"
    ]
   }
 }
EOF
}

resource "aws_cloudwatch_event_target" "target" {
  rule = aws_cloudwatch_event_rule.alarm.name
  arn  = aws_sns_topic.sns.arn
}

resource "aws_sns_topic" "sns" {
  name = "${var.name}-${var.environment}-SNS"
}
