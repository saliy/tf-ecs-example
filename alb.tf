resource "aws_lb" "test-lb" {
  name               = "${terraform.workspace}-ecs-lb"
  load_balancer_type = "application"
  internal           = false
  subnets            = data.aws_subnets.main.ids
  security_groups    = [aws_security_group.lb-sg.id]
  tags = {
    workspace = terraform.workspace
  }
}

resource "aws_security_group" "lb-sg" {
  name_prefix = "lb-sg"
  vpc_id      = data.aws_vpc.main.id
  description = "Allow 443 and 80 traffic lb-sg"

  ingress {
    description = "Allow 443 from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    # ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description = "Allow traffic on 80 from anywhere for redirection"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    # ipv6_cidr_blocks = ["::/0"]
  }

  # ingress {
  #   description      = "Allow 32k-33k for app traffic"
  #   from_port        = 32700 #32768
  #   to_port          = 33000
  #   protocol         = "tcp"
  #   cidr_blocks      = ["0.0.0.0/0"]
  #   ipv6_cidr_blocks = ["::/0"]
  # }

  # ingress {
  #   description = "Allow 32k traffic"
  #   from_port   = 0
  #   to_port     = 65535
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    # ipv6_cidr_blocks = ["::/0"]
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    workspace = "${terraform.workspace}-lb-sg"
  }
}

resource "aws_lb_target_group" "lb-tg" {
  name_prefix            = "lb-tg" //"demo"
  port                   = "80"
  protocol               = "HTTP"
  target_type            = "instance"
  vpc_id                 = data.aws_vpc.main.id
  connection_termination = false
  ip_address_type        = "ipv4"
  deregistration_delay   = 3
  slow_start             = 30

  health_check {
    # path = "/healthz"
    #          healthy_threshold   = 2
    # path                = "${var.healthcheck_url}?target_group=1"
    path                = var.healthcheck_url
    port                = "traffic-port"
    unhealthy_threshold = 3
    interval            = 30
    matcher             = "200,301,302,400"
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [aws_lb.test-lb]
}


resource "aws_lb_listener" "web-listener" {
  load_balancer_arn = aws_lb.test-lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb-tg.arn
  }
}
