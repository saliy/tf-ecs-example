resource "random_string" "db_password" {
  length           = 32
  special          = false
  override_special = "_%@"
}

resource "aws_security_group" "psql-sg" {
  vpc_id      = data.aws_vpc.main.id
  name_prefix = "postgres-sg"
  description = "Allow SSH and PostgreSQL inbound traffic"

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "postgresql_instance" {
  allocated_storage           = var.psql_storage_size
  identifier_prefix           = "rds-${terraform.workspace}"
  storage_type                = "gp2"
  engine                      = "postgres"
  engine_version              = "13.10" # 13.7
  instance_class              = "db.t3.micro"
  username                    = "db_user"
  password                    = random_string.db_password.result
  db_name                     = "app_db"
  publicly_accessible         = true
  skip_final_snapshot         = true
  allow_major_version_upgrade = false # disable auto-update

  #  vpc_security_group_ids = [aws_security_group.sg1.id]

  lifecycle {
    create_before_destroy = true
  }
}

output "db_name" {
  description = "PSQL DB name"
  value       = aws_db_instance.postgresql_instance.db_name
  sensitive   = false
}

output "db_hostname" {
  description = "RDS instance hostname"
  value       = aws_db_instance.postgresql_instance.address
  sensitive   = false
}

output "db_port" {
  description = "RDS instance port"
  value       = aws_db_instance.postgresql_instance.port
  sensitive   = false
}

output "db_username" {
  description = "RDS instance root username"
  value       = aws_db_instance.postgresql_instance.username
  sensitive   = false
}

output "db_pass" {
  description = "RDS instance root pass"
  value       = random_string.db_password.result
  sensitive   = false
}
