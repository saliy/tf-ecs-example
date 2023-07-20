data "aws_ami" "amazon_linux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-*-ebs"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["amazon", "self"]
}

resource "aws_security_group" "ec2_sg" {
  name_prefix = "allow-all-ec2-"
  description = "allow all traffic"
  vpc_id      = data.aws_vpc.main.id

  # ingress {
  #   from_port       = 80
  #   to_port         = 80
  #   protocol        = "tcp"
  #   description     = "Port 80 Access from ALB"
  #   security_groups = [aws_security_group.lb-sg.id]
  # }

  # ingress {
  #   from_port       = 443
  #   to_port         = 443
  #   protocol        = "tcp"
  #   description     = "HTTPS Access from ALB to download Docker Images"
  #   security_groups = [aws_security_group.lb-sg.id]
  # }

  ingress {
    from_port   = 0 //32768
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    # ipv6_cidr_blocks = ["::/0"]
    # description     = "Allow 32k+ traffic from alb"
    description     = "Allow all traffic from alb and vpc"
    security_groups = [aws_default_security_group.default.id, aws_security_group.lb-sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    # ipv6_cidr_blocks = ["::/0"]
    description     = "Allow all traffic to alb and vpc"
    security_groups = [aws_default_security_group.default.id, aws_security_group.lb-sg.id]
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_launch_template" "template" {
  name_prefix = "launch_tmpl"
  image_id    = data.aws_ami.amazon_linux.id

  iam_instance_profile {
    name = aws_iam_instance_profile.ecs_service_role.name
  }

  instance_type = var.main_instance_type
  user_data = base64encode(<<EOL
#!/bin/bash
echo "ECS_CLUSTER=${aws_ecs_cluster.cluster.name}" >> /etc/ecs/ecs.config
EOL
  )
}


data "aws_ec2_instance_type_offerings" "offerings" {
  filter {
    name   = "instance-type"
    values = [var.main_instance_type]
  }

  location_type = "availability-zone-id"
}



resource "aws_autoscaling_group" "asg" {
  name_prefix = "${terraform.workspace}-asg"

  launch_template {
    id      = aws_launch_template.template.id
    version = "$Latest"
  }

  min_size                  = 1
  max_size                  = 10
  desired_capacity          = 4
  health_check_type         = "EC2"
  health_check_grace_period = 120
  termination_policies      = ["AllocationStrategy", "OldestInstance"]

  availability_zones = local.aws_availability_zones_with_preferred_instances

  target_group_arns     = [aws_lb_target_group.lb-tg.arn]
  protect_from_scale_in = true

  lifecycle {
    #    ignore_changes        = [desired_capacity]
    create_before_destroy = true
  }
}
