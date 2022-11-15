resource "aws_ecs_service" "service" {
  name            = "${var.environment}-${var.name}-ECS-Service"
  cluster         = var.cluster.id
  task_definition = aws_ecs_task_definition.task_definition.arn
  desired_count   = var.initial_count
  launch_type     = "FARGATE"

  network_configuration {
    security_groups = var.security_groups
    subnets         = var.private_subnets
  }

  dynamic "load_balancer" {
    for_each = var.target_group_arn == null ? [] : [var.target_group_arn]
    iterator = target_group_arn
    content {
      target_group_arn = target_group_arn.value
      container_name   = var.name
      container_port   = var.container_port
    }
  }
}
