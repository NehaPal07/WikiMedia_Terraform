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
 # key_name               = var.key_name
 # public_IP              = var.public_ip



  connection  {

    type        = "ssh"
    host        = self.public_ip
    user        = "ec2-user"
   # private_key = file(var.private_key_path)
   }

  provisioner "remote-exec" {
       inline = [
          "sudo yum install nginx -y",
          "sudo service nginx start",
          "echo '<html><head><title> Green Team server </title></head><body><h1> Hello Nginx2 through Terraform</h1></body></html>'",
         ]
     }
  tags = {
    Name = "Media-Instance"
  }

}

output "Terra-Ansible1" {
  value = aws_instance.MediaWiki.public_ip
}
