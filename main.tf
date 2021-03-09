# Using AWS as the provider

provider "aws" {
  region     = var.region
}

# Use a central backend for ephemeral docker with consistent tf state 

terraform {
  backend "remote" {
    hostname = "app.terraform.io"
    organization = "f5terracloud"

    workspaces {
      name = "dronenginxdemo"
    }
  }
}

# Create a VPC to launch our instances into
resource "aws_vpc" "dronenginxdemo" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "${var.name}"
    CostCode = "${var.costcode}"
    TTL = "${var.ttl}"
    Environment = "${var.environment}"
  }
}

# Create an internet gateway to give our subnet access to the outside world
resource "aws_internet_gateway" "dronenginxdemo" {
  vpc_id = aws_vpc.dronenginxdemo.id
  tags = {
    Name = "${var.name}"
    CostCode = "${var.costcode}"
    TTL = "${var.ttl}"
    Environment = "${var.environment}"
  }
}

# Grant the VPC internet access on its main route table
resource "aws_route" "internet_access" {
  route_table_id         = aws_vpc.dronenginxdemo.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.dronenginxdemo.id
}

# Create a subnet to launch our instances into
resource "aws_subnet" "dronenginxdemo" {
  vpc_id                  = aws_vpc.dronenginxdemo.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.name}"
    CostCode = "${var.costcode}"
    TTL = "${var.ttl}"
    Environment = "${var.environment}"
  }
}

# A security group for the ELB so it is accessible via the web
resource "aws_security_group" "dronenginxdemoelb" {
  name        = "dronenginxdemoelbsg"
  vpc_id      = aws_vpc.dronenginxdemo.id

  # HTTP access from anywhere
  ingress {
    from_port   = 5252
    to_port     = 5252
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # Access to Portainer 
  ingress {
    description = "Portainer inbound"
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#Security Group Creation
resource "aws_security_group" "dronenginxdemo" {
  name        = "dronenginxdemo"
  #security_group_id = "sg-drone-01"
  description = "Allow Traffic to Demo NGINX traffic"
  vpc_id      = aws_vpc.dronenginxdemo.id

  ingress {
    description = "SSH inbound"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Portainer inbound"
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
  ingress {
    description = "Nginx inbound HTTP"
    from_port   = 5252
    to_port     = 5252
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_elb" "dronenginxdemoelb" {
  name = "dronenginxdemoelb"

  subnets         = ["${aws_subnet.dronenginxdemo.id}"]
  security_groups = ["${aws_security_group.dronenginxdemoelb.id}"]
  instances       = ["${aws_instance.dronenginxdemo.id}"]

  listener {
    instance_port     = 5252
    instance_protocol = "http"
    lb_port           = 5252
    lb_protocol       = "http"
  }
    listener {
    instance_port     = 9000
    instance_protocol = "http"
    lb_port           = 9000
    lb_protocol       = "http"
  }
  tags = {
    Name = "${var.name}"
    CostCode = "${var.costcode}"
    TTL = "${var.ttl}"
    Environment = "${var.environment}"
  }
}

#Instance Creation
resource "aws_instance" "dronenginxdemo" {
  ami           = "ami-02a599eb01e3b3c5b"
  instance_type = "t2.micro"
  key_name = "JLCodeTech"
  vpc_security_group_ids = ["${aws_security_group.dronenginxdemo.id}"]
  subnet_id = aws_subnet.dronenginxdemo.id
  #security_groups = [aws_security_group.dronenginxdemo.name]
  user_data = file("install_nginx.sh")
#tag instances created
  tags = {
    Name = "${var.name}"
    CostCode = "${var.costcode}"
    TTL = "${var.ttl}"
    Environment = "${var.environment}"
  }
}

output "dronenginxdemo_outputs" {
  value = aws_elb.dronenginxdemoelb.dns_name
}