### Data Block ###

data "aws_vpc" "prod" {
    id = var.vpc_id
}

data "aws_subnet" "subnet-3b-1" {
    id = var.subnet_3b-1
}

data "aws_subnet" "subnet-3b-2" {
    id = var.subnet_3b-2
}

data "aws_nat_gateway" "test" {
    id = var.natgw_id
}

data "aws_region" "current" {}

### Data Block ###


### IAM ###
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.app_name}-${var.environment}-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.app_name}-${var.environment}-ecs-task-execution-role"
    Environment = var.environment
  }
}


resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}


resource "aws_iam_role" "ecs_task_role" {
  name = "${var.app_name}-${var.environment}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.app_name}-${var.environment}-ecs-task-role"
    Environment = var.environment
  }
}

### IAM ###


### Security Group ###
resource "aws_security_group" "ecs_tasks_sg" {
  name_prefix = "${var.app_name}-${var.environment}-ecs-"
  description = "Security Group for ECS Tasks"
  vpc_id      = data.aws_vpc.prod.id

  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.app_name}-${var.environment}-ecs"
    User = var.username
    Environment = var.environment
    Application = var.app_name
  }
}

resource "aws_security_group" "alb_sg" {
  name_prefix = "${var.app_name}-${var.environment}-alb-"
  description = "Security Group for Application Load Balancer"
  vpc_id      = data.aws_vpc.prod.id

  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    cidr_blocks = ["82.200.165.82/32"]
  }

  egress {
    from_port   = 1024
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["82.200.165.82/32"]
  }

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.ecs_tasks_sg.id]
  }

  tags = {
    Name = "${var.app_name}-${var.environment}-alb-sg"
    User = var.username
    Environment = var.environment
    Application = var.app_name
  }
}

### Security Group ###

resource "aws_lb" "alb_ecs" {
  name               = "${var.app_name}-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [data.aws_subnet.subnet-3b-1.id, data.aws_subnet.subnet-3b-2.id]

  enable_deletion_protection = false

  tags = {
    Name = "${var.app_name}-${var.environment}-alb"
    User = var.username
    Environment = var.environment
    Application = var.app_name
  }
}

resource "aws_lb_target_group" "target_group_1" {
  name     = "${var.app_name}-${var.environment}-tg"
  port     = var.container_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.prod.id
  target_type = "ip"

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
    Name        = "${var.app_name}-${var.environment}-tg"
    User = var.username
    Environment = var.environment
    Application = var.app_name
  }
}

resource "aws_lb_listener" "default_action" {
  load_balancer_arn = aws_lb.alb_ecs.arn
  port              = var.container_port
  protocol          = "HTTP"
  #ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-Res-2021-06"
  #certificate_arn = "arn:aws:acm:eu-west-3:176927891769:certificate/e1e5703f-efb2-4bf3-bc80-cbf6c9e8b562"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group_1.arn
  }
}

resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/ecs/${var.app_name}-${var.environment}"
  retention_in_days = 7

  tags = {
    Name        = "${var.app_name}-${var.environment}-logs"
    Environment = var.environment
    Application = var.app_name
  }
}


# data "aws_ecr_repository" "ecr" {
#   name = "test_ecr"
# }

# data "aws_ecr_image" "service_image" {
#   repository_name = "nginx"
#   image_tag       = "latest"
# }

resource "aws_ecs_cluster" "main_ecs" {
  name = "${var.app_name}-${var.environment}-ecs_cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name = aws_ecs_cluster.main_ecs.name

  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 1
    capacity_provider = "FARGATE"
  }
}

resource "aws_ecs_task_definition" "main" {
  family                   = "${var.app_name}-${var.environment}"
  network_mode             = "awsvpc"
  requires_compatibilities   = ["FARGATE"]
  cpu       = 512
  memory    = 1024
  
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn           = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = var.app_name
      image     = var.container_image
      cpu = 10
      memory = 20
      essential = true
      portMappings = [
        {
          containerPort = var.container_port
          protocol = "tcp"
        }
      ]


      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs_logs.name
          awslogs-region = data.aws_region.current.name
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture = "X86_64"
  }

  tags = {
    Name        = "${var.app_name}-${var.environment}-task"
    Environment = var.environment
    User = var.username
  }
}


resource "aws_ecs_service" "nginx" {
  name            = "${var.app_name}-${var.environment}-service"
  cluster         = aws_ecs_cluster.main_ecs.id
  task_definition = aws_ecs_task_definition.main.arn
  desired_count   = 1
  # iam_role        = aws_iam_role.ecs_task_execution_role.arn
  # depends_on      = [aws_lb.alb_ecs]
  load_balancer {
    target_group_arn = aws_lb_target_group.target_group_1.arn
    container_name   =  var.app_name
    container_port   = var.container_port
  }

  network_configuration {
    subnets = [data.aws_subnet.subnet-3b-2.id]
    security_groups = [aws_security_group.ecs_tasks_sg.id]
    assign_public_ip = "false"
  }
}

resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity = 5
  min_capacity = 1
  resource_id = "service/${aws_ecs_cluster.main_ecs.name}/${aws_ecs_service.nginx.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace = "ecs"
}

resource "aws_appautoscaling_policy" "test_cpu" {
  name = "test-cpu"
  policy_type = "TargetTrackingScaling"
  resource_id = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = 10
  }
}

# resource "aws_cloudwatch_metric_alarm" "foobar" {
#   alarm_name                = "terraform-test-foobar5"
#   comparison_operator       = "GreaterThanOrEqualToThreshold"
#   evaluation_periods        = 2
#   metric_name               = "CPUUtilization"
#   namespace                 = "AWS/EC2"
#   period                    = 120
#   statistic                 = "Average"
#   threshold                 = 80
#   alarm_description         = "This metric monitors ec2 cpu utilization"
#   insufficient_data_actions = []
# }