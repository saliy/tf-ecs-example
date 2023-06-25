resource "aws_cloudwatch_log_group" "backend" {
  name_prefix = "/ecs/${terraform.workspace}-backend-container"
  tags = {
    workspace = terraform.workspace
  }

  retention_in_days = 3
}
