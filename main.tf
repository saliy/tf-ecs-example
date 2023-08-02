terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }

    random = "~> 3.4.3"
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region     = var.region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  alias      = "region-main"
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_availability_zones" "all" {
  state = "available"
}
data "aws_ec2_instance_types" "all_t" {
  filter {
    name   = "instance-type"
    values = ["t1.*", "t2.*", "t3.*"]
  }

}

data "aws_ec2_instance_type_offering" "preferred" {
  for_each = toset(data.aws_availability_zones.all.names)

  filter {
    name   = "instance-type"
    values = data.aws_ec2_instance_types.all_t.instance_types
  }

  filter {
    name   = "location"
    values = [each.value]
  }

  location_type = "availability-zone"

  preferred_instance_types = concat([var.main_instance_type], data.aws_ec2_instance_types.all_t.instance_types)
}

locals {
  aws_availability_zones_with_preferred_instances = keys({ for az, details in data.aws_ec2_instance_type_offering.preferred : az => details.instance_type if details.instance_type == var.main_instance_type })
}
