resource "aws_appautoscaling_target" "target" {
  resource_id        = "service/${var.cluster.name}/${aws_ecs_service.service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
  min_capacity       = var.min_count
  max_capacity       = var.max_count
}

#automatially scaleup by one
resource "aws_appautoscaling_policy" "increase" {
  name               = "Scale Up"
  service_namespace  = "ecs"
  resource_id        = "service/${var.cluster.name}/${aws_ecs_service.service.name}"
  scalable_dimension = "ecs:service:DesiredCount"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 70
    metric_aggregation_type = "Average"
    step_adjustment {
      metric_interval_lower_bound = 0
      metric_interval_upper_bound = 15
      scaling_adjustment          = 1
    }
    step_adjustment {
      metric_interval_lower_bound = 15
      metric_interval_upper_bound = 25
      scaling_adjustment          = 2
    }
    step_adjustment {
      metric_interval_lower_bound = 25
      scaling_adjustment          = 4
    }
  }
  depends_on = [aws_appautoscaling_target.target]
}

#automatically scaledown by one
resource "aws_appautoscaling_policy" "decrease" {
  name               = "Scale Down"
  service_namespace  = "ecs"
  resource_id        = "service/${var.cluster.name}/${aws_ecs_service.service.name}"
  scalable_dimension = "ecs:service:DesiredCount"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Average"
    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment          = -1
    }
  }
  depends_on = [aws_appautoscaling_target.target]
}
