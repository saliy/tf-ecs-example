resource "aws_ecs_cluster" "cluster" {
  name = "${terraform.workspace}_ecs_cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"

  }


  tags = {
    workspace = terraform.workspace
  }
}


resource "aws_ecs_task_definition" "task_definition" {
  family                   = "${terraform.workspace}-web-family"
  network_mode             = "bridge"
  requires_compatibilities = ["EC2"]
  execution_role_arn       = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ecsTaskExecutionRole"
  task_role_arn            = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ecsTaskExecutionRole"

  memory = 1024

  container_definitions = jsonencode([
    {
      name      = "backend-redis",
      image     = "bitnami/redis:6.2.5",
      essential = true,
      memory    = 384,
      environment = [
        {
          "name" : "ALLOW_EMPTY_PASSWORD",
          "value" : "yes"
        },
      ],
      portMappings = [
        {
          "hostPort" : 6379,
          "protocol" : "tcp",
          "containerPort" : 6379
        }
      ]

    },
    {
      name      = "backend",
      image     = "nginx:latest",
      essential = true,
      memory    = 128,
      healthCheck = {
        command : ["CMD-SHELL", "curl -f http://localhost:${var.app_port}${var.healthcheck_url} || exit 1"],
        startPeriod : 20
      },
      logConfiguration = {
        logDriver : "awslogs",
        options : {
          awslogs-group : aws_cloudwatch_log_group.backend.name,
          awslogs-region : var.region
        }
      },
      portMappings = [
        {
          "hostPort" : 0,
          "protocol" : "tcp",
          "containerPort" : var.app_port
        }
      ]
    }
  ])
}



resource "aws_ecs_service" "web" {
  name            = "${terraform.workspace}-web-service"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.task_definition.arn
  desired_count   = 1

  deployment_maximum_percent = 400

  load_balancer {
    target_group_arn = aws_lb_target_group.lb_target_group.arn
    container_name   = "backend"
    container_port   = 80
  }

  force_new_deployment              = false
  health_check_grace_period_seconds = 60
  propagate_tags                    = "NONE"
  wait_for_steady_state             = false

  deployment_controller {
    type = "ECS"
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  launch_type = "EC2"
}