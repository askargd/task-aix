locals {
  Owner       = "askar"
  User = "askar011"
  Environment = "dev"
  Application = "nginx-web"
}

#### Data Block ####
data "aws_vpc" "vpc_default" {
  default = true
}

data "aws_subnet" "subnet_3a" {
  filter {
    name = "tag:Name"
    values = ["eu-west-3a"]
  }
}

data "aws_subnet" "subnet_3b" {
  filter {
    name = "tag:Name"
    values = ["eu-west-3b"]
  }
}

data "aws_iam_role" "test-ssm-askar" {
  name = "test-ssm-askar"
}

data "aws_acm_certificate" "issued" {
  domain   = "askar001-test.aixkz.com"
  statuses = ["ISSUED"]
}


### Data Block ####

resource "aws_security_group" "ec2-dev-askar011" {
  name        = "launch-wizard-9"
  description = "launch-wizard-9 created 2025-06-11T09:28:34.226Z"
  vpc_id      = data.aws_vpc.vpc_default.id

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    cidr_blocks = [data.aws_vpc.vpc_default.cidr_block]
  }

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    security_groups = [aws_security_group.alb-dev-askar011.id]
  }

  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    security_groups = [aws_security_group.alb-dev-askar011.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ec2-dev-askar011"
    Owner = local.Owner
    User = local.User
    Environment = local.Environment
    Application = local.Application
    AWSService = "Security Group"
  }
}

resource "aws_security_group" "alb-dev-askar011" {
  name        = "alb-dev-askar011"
  description = "Allow http from outside to ALB"
  vpc_id      = data.aws_vpc.vpc_default.id

  ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
  }

  ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ec2-dev-askar011"
    Owner = local.Owner
    User = local.User
    Environment = local.Environment
    Application = local.Application
    AWSService = "Security Group"
  }
}

resource "aws_iam_instance_profile" "instance_profile" {
  name = "ec2-dev-instance-profile-askar011"
  role = data.aws_iam_role.test-ssm-askar.name
}

resource "aws_launch_template" "template-asg-dev-askar011" {
  name_prefix     = "ec2-nginx-dev-askar011-"
  image_id        = var.ami_id
  instance_type   = "t3.nano"
  user_data = filebase64(var.user-data)

  iam_instance_profile {
    name = "ec2-dev-instance-profile-askar011"
  }
  network_interfaces {
    security_groups = [aws_security_group.ec2-dev-askar011.id]
    associate_public_ip_address = true
  }

  lifecycle {
    create_before_destroy = false
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Owner       = local.Owner
      User = local.User
      Environment = local.Environment
      Application = local.Application
      AWSService = "ec2"
      LaunchedBy  = "ASG"
    }
  }

  tags = {
    Owner       = local.Owner
    User = local.User
    Environment = local.Environment
    Application = local.Application
    AWSService = "Launch Template"
  }
}

resource "aws_lb" "alb-dev-askar011" {
  name               = "alb-dev-askar011"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb-dev-askar011.id]
  subnets            = [data.aws_subnet.subnet_3a.id, data.aws_subnet.subnet_3b.id]

  enable_deletion_protection = false

  tags = {
      Owner       = local.Owner
      User        = local.User
      Environment = local.Environment
      Application = local.Application
      AWSService = "alb"
  }
}

resource "aws_lb_target_group" "tg-dev-askar011" {
  name     = "tg-dev-askar011"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.vpc_default.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 3
  }

  tags = {
    Name        = "tg-dev-askar011"
    Owner       = local.Owner
    User        = local.User
    Environment = local.Environment
    Application = local.Application
    AWSService = "Target Group"
  }
}

resource "aws_lb_target_group" "tg2-dev-askar011" {
  name     = "tg2-dev-askar011"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.vpc_default.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }

  tags = {
    Name        = "tg2-dev-askar011"
    Owner       = local.Owner
    User        = local.User
    Environment = local.Environment
    Application = local.Application
    AWSService = "Target Group"
  }
}

resource "aws_lb_listener" "default_action" {
  load_balancer_arn = aws_lb.alb-dev-askar011.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-Res-2021-06"
  certificate_arn = "arn:aws:acm:eu-west-3:176927891769:certificate/e1e5703f-efb2-4bf3-bc80-cbf6c9e8b562"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg-dev-askar011.arn
  }
}

resource "aws_lb_listener_rule" "main" {
  listener_arn = aws_lb_listener.default_action.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg-dev-askar011.arn
  }

  condition {
    path_pattern {
      values = ["/main"]
    }
  }

  tags = {
    Name        = "ec2-1"
    Owner       = local.Owner
    User        = local.User
    Environment = local.Environment
    Application = local.Application
    AWSService = "Listener Rule"
  }
}

resource "aws_lb_listener_rule" "http_header" {
  listener_arn = aws_lb_listener.default_action.arn
  priority     = 99

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg2-dev-askar011.arn
  }

  condition {
    http_header {
      http_header_name = "X-target-web"
      values = ["second_ec2"]
    }
  }

  tags = {
    Name        = "second_ec2"
    Owner       = local.Owner
    User        = local.User
    Environment = local.Environment
    Application = local.Application
    AWSService = "Listener Rule"
  }
}

resource "aws_autoscaling_group" "asg-dev-askar011" {
  name = "asg-dev-askar011"
  target_group_arns = [
    aws_lb_target_group.tg-dev-askar011.arn,
    aws_lb_target_group.tg2-dev-askar011.arn
  ]
  health_check_type         = "ELB"
  health_check_grace_period = 120


  min_size             = 0
  max_size             = 3
  desired_capacity     = 0


  launch_template {
    id = aws_launch_template.template-asg-dev-askar011.id
    version = "$Latest"
  }
  vpc_zone_identifier  = [data.aws_subnet.subnet_3a.id, data.aws_subnet.subnet_3b.id]

  tag {
    key = "Name"
    value = "ec2-nginx-dev-askar011"
    propagate_at_launch = true
  }
}