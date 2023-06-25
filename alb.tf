resource "aws_lb" "test-lb" {
  name               = "${terraform.workspace}-ecs-lb"
  load_balancer_type = "application"
  internal           = false
  subnets            = data.aws_subnets.main.ids
  tags = {
    workspace = terraform.workspace
  }
  security_groups = [aws_security_group.load_balancer_security_group.id]
}

resource "aws_security_group" "load_balancer_security_group" {
  name_prefix = "allow-all-lb"
  vpc_id      = data.aws_vpc.main.id
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    workspace = terraform.workspace
  }
}

resource "aws_lb_target_group" "lb_target_group" {
  name_prefix = "demo"
  port        = "80"
  protocol    = "HTTP"
  target_type = "instance"

  vpc_id                 = data.aws_vpc.main.id
  connection_termination = false
  ip_address_type        = "ipv4"

  deregistration_delay = 3
  slow_start           = 30

  lifecycle {
    create_before_destroy = true
  }


  health_check {
    path = "${var.healthcheck_url}?target_group=1"
    #          healthy_threshold   = 2
    port                = "traffic-port"
    unhealthy_threshold = 3
    interval            = 30
    matcher             = "200,301,302,404"
  }
}

resource "aws_lb_listener" "web-listener" {
  load_balancer_arn = aws_lb.test-lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb_target_group.arn
  }
}
