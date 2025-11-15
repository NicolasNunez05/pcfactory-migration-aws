# Auto Scaling Group
resource "aws_autoscaling_group" "pcfactory_app" {
  name                = "${var.project_name}-asg"
  vpc_zone_identifier = var.private_app_subnets
  
  min_size         = 2
  max_size         = 5
  desired_capacity = 2
  
  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }
  
  health_check_type         = "ELB"
  health_check_grace_period = 300
  
  target_group_arns = [var.target_group_arn]
  
  tag {
    key                 = "Name"
    value               = "${var.project_name}-asg-instance"
    propagate_at_launch = true
  }
  
  lifecycle {
    create_before_destroy = true
  }
}

# Scaling Policy - Scale UP (CPU > 70%)
resource "aws_autoscaling_policy" "scale_up" {
  name                   = "${var.project_name}-scale-up"
  autoscaling_group_name = aws_autoscaling_group.pcfactory_app.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 1
  cooldown               = 300
}

# Scaling Policy - Scale DOWN (CPU < 30%)
resource "aws_autoscaling_policy" "scale_down" {
  name                   = "${var.project_name}-scale-down"
  autoscaling_group_name = aws_autoscaling_group.pcfactory_app.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = -1
  cooldown               = 300
}

# CloudWatch Alarm - Scale UP
resource "aws_cloudwatch_metric_alarm" "asg_cpu_high" {
  alarm_name          = "${var.project_name}-asg-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 70
  alarm_description   = "Scale up when CPU > 70%"
  alarm_actions       = [aws_autoscaling_policy.scale_up.arn]
  
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.pcfactory_app.name
  }
}

# CloudWatch Alarm - Scale DOWN
resource "aws_cloudwatch_metric_alarm" "asg_cpu_low" {
  alarm_name          = "${var.project_name}-asg-cpu-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 30
  alarm_description   = "Scale down when CPU < 30%"
  alarm_actions       = [aws_autoscaling_policy.scale_down.arn]
  
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.pcfactory_app.name
  }
}

output "asg_name" {
  value = aws_autoscaling_group.pcfactory_app.name
}