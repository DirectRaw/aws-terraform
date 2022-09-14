provider "aws" {
  region = "eu-central-1" # insert your own region
  profile = "aix-test"
  }


# Application AutoScaling resources


resource "aws_iam_role" "ecs-autoscale-role" {
  name = "test-ecs-scale-application"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "application-autoscaling.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ecs-autoscale" {
  role = aws_iam_role.ecs-autoscale-role.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceAutoscaleRole"
}


####################################################################################

variable "ecs_services" {
    description = "List of serices to enable AS"
    default = ["service1", "service2", "service3"]
}


resource "aws_appautoscaling_target" "ecs_target" {
  count = length(var.ecs_services)
  max_capacity       = 2
  min_capacity       = 1
  resource_id        = "service/test-cluster/${element(var.ecs_services, count.index)}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
  role_arn           = "arn:aws:iam::account-id:role/aws-service-role/ecs.application-autoscaling.amazonaws.com/AWSServiceRoleForApplicationAutoScaling_ECSService"
}


resource "aws_appautoscaling_policy" "ecs_target_cpu" {
  count              = length(aws_appautoscaling_target.ecs_target[*].id)
  name               = "application-scaling-policy-cpu"
  policy_type        = "TargetTrackingScaling"
  resource_id        = element(aws_appautoscaling_target.ecs_target[*].id, count.index)
  scalable_dimension = element(aws_appautoscaling_target.ecs_target[*].scalable_dimension, count.index)
  service_namespace  = element(aws_appautoscaling_target.ecs_target[*].service_namespace, count.index)

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = 80
  }
  depends_on = [aws_appautoscaling_target.ecs_target]


}
resource "aws_appautoscaling_policy" "ecs_target_memory" {
  count              = length(aws_appautoscaling_target.ecs_target[*].id)
  name               = "application-scaling-policy-memory"
  policy_type        = "TargetTrackingScaling"
  resource_id        = element(aws_appautoscaling_target.ecs_target[*].id, count.index)
  scalable_dimension = element(aws_appautoscaling_target.ecs_target[*].scalable_dimension, count.index)
  service_namespace  = element(aws_appautoscaling_target.ecs_target[*].service_namespace, count.index)

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value = 80
  }
  depends_on = [aws_appautoscaling_target.ecs_target]
}
