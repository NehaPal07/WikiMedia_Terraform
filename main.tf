provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region = var.region
}

data "aws_availability_zones" "available" {}

data "aws_ami" "aws-linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name    = "name"
    values  = ["amzn-ami-hvm*"]
  }

  filter {
    name    = "root-device-type"
    values  = ["ebs"]
  }

  filter {
    name    = "virtualization-type"
    values  = ["hvm"]
  }
}


resource "aws_vpc" "vpc" {
  cidr_block           = var.network_address_space
  }

resource "aws_internet_gateway" "igw" {
   vpc_id = aws_vpc.vpc.id
}

resource "aws_subnet" "subnet1" {
  cidr_block           = var.subnet1_address_space
  vpc_id               = aws_vpc.vpc.id
  map_public_ip_on_launch = "true"
  availability_zone       = data.aws_availability_zones.available.names[0]
 }
# ROUTING#
resource "aws_route_table" "rtb" {
  vpc_id = aws_vpc.vpc.id


  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

# Route table associatiion with public subnets
resource "aws_route_table_association" "rta-subnet1" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.rtb.id
}




resource "aws_security_group" "aws_sg" {
  name        = "aws_sg"
  vpc_id       = aws_vpc.vpc.id

# allow http from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

# SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
# Outbound internet access
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}


resource "aws_instance" "MediaWiki" {
  ami                    = data.aws_ami.aws-linux.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.subnet1.id
  vpc_security_group_ids = [aws_security_group.aws_sg.id]
  key_name               = var.key_name


  user_data = <<EOF
                #! /bin/bash
                sudo yum update -y
                sudo yum install -y php
                sudo yum install -y php-mysql
                sudo yum install -y php-gd
                sudo yum install -y php-xml
                sudo yum install -y mariadb-server
                sudo yum install -y mariadb
                sudo yum install -y php-mbstring
                sudo yum install -y httpd

                sudo systemctl start mariadb
                mysql_secure_installation

                sudo systemctl enable mariadb
                sudo systemctl enable httpd

                sudo yum install wget unzip

                sudo wget https://releases.wikimedia.org/mediawiki/1.34/mediawiki-1.34.2.tar.gz
                sudo tar -zxf /home/ec2-user/mediawiki-1.34.2.tar.gz
                sudo cp -Rf mediawiki-1.34.2 /var/www
                sudo ln -s mediawiki-1.34.2/ mediawiki
                sudo chown -R apache:apache /var/www/mediawiki-1.34.2
                sudo service httpd restart
                sudo firewall-cmd --permanent --zone=public --add-service=http
                sudo firewall-cmd --permanent --zone=public --add-service=https
                sudo systemctl restart firewalld
           EOF

  tags = {
    Name = "Ec2-User"
}
}
