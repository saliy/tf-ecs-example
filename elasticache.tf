resource "aws_elasticache_subnet_group" "elasticache-subnets" {
  name       = "${terraform.workspace}-redis-subnets"
  subnet_ids = data.aws_subnets.main.ids
}

resource "aws_elasticache_cluster" "main-ecc" {
  cluster_id           = "${terraform.workspace}-redis-cluster"
  engine               = "redis"
  node_type            = "cache.t2.micro" # "cache.m4.large"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis6.x"
  engine_version       = "6.2"
  port                 = 6379

  subnet_group_name = "${terraform.workspace}-redis-subnets"

  # security_group_ids = [
  #   aws_default_security_group.default.id
  # ]
  # # availieble in AWS provides > 4.8.0
  # log_delivery_configuration {
  #   destination      = aws_cloudwatch_log_group.elasticache_cluster.name
  #   destination_type = "cloudwatch-logs"
  #   log_format       = "text"
  #   log_type         = "slow-log"
  # }
  tags = {
    workspace = terraform.workspace
  }
}

resource "aws_security_group" "ecc-sg" {
  name_prefix = "aws-ecc-sg"
  vpc_id      = data.aws_vpc.main.id
  description = "Allow 6379 to ElastiCache Redis"

  ingress {
    description = "Allow 6379"
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    # ipv6_cidr_blocks = ["::/0"]
    # security_groups = [aws_default_security_group.default.id, aws_security_group.lb-sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    # ipv6_cidr_blocks = ["::/0"]
    # security_groups = [aws_default_security_group.default.id, aws_security_group.lb-sg.id]
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    workspace = "${terraform.workspace}-ecc-sg"
  }

  depends_on = [aws_elasticache_cluster.main-ecc]
}

resource "aws_elasticache_user" "testUser" {
  user_id       = "testUserId"
  user_name     = "testUserName"
  access_string = "on ~* +@all"
  engine        = "REDIS"
  # passwords     = ["password123456789"]

  authentication_mode {
    type      = "password"
    passwords = ["password12341234", "password56785678"]
  }

  tags = {
    workspace = terraform.workspace
  }
}

output "redis_host1" {
  value = aws_elasticache_cluster.main-ecc.cache_nodes[0].address
}

output "REDIS_URL" {
  value     = "redis://${aws_elasticache_user.testUser.user_name}:${tolist(aws_elasticache_user.testUser.authentication_mode[0].passwords)[0]}@${aws_elasticache_cluster.main-ecc.cache_nodes.0.address}:${aws_elasticache_cluster.main-ecc.cache_nodes.0.port}"
  sensitive = true
}

output "POSTGRESS_URL" {
  value     = "postgresql://${aws_db_instance.postgresql_instance.username}:${random_string.db_password.result}@${aws_db_instance.postgresql_instance.address}:${aws_db_instance.postgresql_instance.port}/${aws_db_instance.postgresql_instance.db_name}"
  sensitive = true
}
