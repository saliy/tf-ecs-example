#Get Linux AMI ID using SSM Parameter endpoint in 'region-main'
data "aws_ssm_parameter" "linuxAmi" {
  provider = aws.region-main
  name     = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

#Create key-pair for logging into EC2
resource "aws_key_pair" "main-key" {
  provider   = aws.region-main
  key_name   = "main_vpc_key"
  public_key = file("~/.ssh/id_rsa_aws.pub")
}

# Create subnet # 1 in us-east-1
resource "aws_subnet" "subnet-bastion" {
  provider                = aws.region-main
  availability_zone       = data.aws_availability_zones.all.names.0 # element(data.aws_availability_zones.all, 0)
  vpc_id                  = data.aws_vpc.main.id
  map_public_ip_on_launch = true
  cidr_block              = "172.31.176.0/20"
}

#Create and bootstrap EC2 in 'region-main'
resource "aws_instance" "bastion-main-vpc" {
  provider                    = aws.region-main
  ami                         = data.aws_ssm_parameter.linuxAmi.value
  instance_type               = "t2.nano"
  key_name                    = aws_key_pair.main-key.key_name
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_default_security_group.default.id]
  subnet_id                   = aws_subnet.subnet-bastion.id

  cpu_options {
    core_count       = 1
    threads_per_core = 2
  }

  tags = {
    Name = "bastion-main-vpc"
  }
  # ???
  #   depends_on = [aws_main_route_table_association.set-master-default-rt-assoc]
  depends_on = [data.aws_vpc.main]
}
