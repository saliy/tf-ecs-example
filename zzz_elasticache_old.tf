# resource "aws_elasticache_subnet_group" "default" {
#   name       = "${terraform.workspace}-cache-subnet"
#   subnet_ids = data.aws_subnets.main.ids
#   #   subnet_ids = ["${aws_subnet.default.*.id}"]
# }

# resource "aws_elasticache_replication_group" "default" {
#   #   replication_group_id          = var.cluster_id
#   replication_group_id = aws_ecs_cluster.demo_ecs_cluster.id
#   description          = "Redis cluster for Hashicorp ElastiCache example"
#   #   replication_group_description = "Redis cluster for Hashicorp ElastiCache example"

#   node_type            = "cache.m4.large"
#   port                 = 6379
#   parameter_group_name = "default.redis3.2.cluster.on"

#   snapshot_retention_limit = 5
#   snapshot_window          = "00:00-05:00"

#   subnet_group_name          = aws_elasticache_subnet_group.default.name
#   automatic_failover_enabled = true

#   cluster_mode {
#     replicas_per_node_group = 1
#     num_node_groups         = 2
#     # num_node_groups         = var.node_groups
#   }
# }



# elasticache/variables.tf
# variable "environment" {}
# variable "node_count" {
#   type    = number
#   default = 1
# }
# variable "node_type" {
#   type    = string
#   default = "cache.m3.medium"
# }
# variable "availability_zones" {
#   type    = list(string)
#   default = ["us-east-1a"]
#   # default = ["us-east-1a", "us-east-1b"]
# }

# environment/dev
# module "dev-elasticache" {
#   # source             	= "../../elasticache"
#   source             = "./"
#   environment        = "dev"
#   node_count         = 1
#   node_type          = "cache.m3.medium"
#   availability_zones = ["us-east-1a", "us-east-1b"]
# }


# resource "aws_elasticache_parameter_group" "default" {
#   name   = "cache-params"
#   family = "redis7"

#   parameter {
#     name  = "activerehashing"
#     value = "yes"
#   }

#   parameter {
#     name  = "min-slaves-to-write"
#     value = "2"
#   }
# }

# # elasticache/main.tf
# resource "aws_elasticache_replication_group" "elasticache-cluster" {
#   # availability_zones   = ["${var.availability_zones}"]
#   # replication_group_id = "tf-${var.environment}-rep-group"
#   # replication_group_description = "${var.environment} replication group"
#   availability_zones   = ["us-east-1a", "us-east-1b"]
#   replication_group_id = "tf-${terraform.workspace}-rep-group"
#   description          = "${terraform.workspace} replication group"
#   node_type            = "cache.t3.medium"
#   num_cache_clusters   = 2
#   parameter_group_name = "cache-params"
#   port                 = 6379
# }


