variable "aws_access_key" {
  default = "*********************"
}

variable "aws_secret_key" {
  default = "**************"
}

variable "key_name" {
  default = "EC2_East"
}

variable "region" {
   default = "us-east-2"
 }

variable "network_address_space" {
   default = "10.1.0.0/16"
  }

variable "subnet1_address_space" {
   default = "10.1.0.0/24"
 }
