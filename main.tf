terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.70"
    }
  }
}

provider "aws" {
  profile = "default"
  region = "ap-southeast-1"
}

variable "instance_tags" {
  type = list
  default = ["vm1", "vm2", "vm3"]
}

resource "aws_key_pair" "my_keypair" {
  key_name   = "my_keypair"
  public_key = file("~/.ssh/id_rsa.pub")
}

resource "aws_security_group" "secure_web" {
  name        = "secure-web"
  description = "Allow HTTP, HTTPS, SSH"

  tags = {
    Name = "secure_web"
  }
}

resource "aws_security_group_rule" "outgoing" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = "${aws_security_group.secure_web.id}"
}

resource "aws_security_group_rule" "allow_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = "${aws_security_group.secure_web.id}"
}

resource "aws_security_group_rule" "allow_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = "${aws_security_group.secure_web.id}"
}

resource "aws_security_group_rule" "allow_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"] # Change this with your public ip address, if you want to more secure
  security_group_id = "${aws_security_group.secure_web.id}"
}

resource "aws_instance" "ec2" {
  count = 1
  ami           = "ami-055d15d9cfddf7bd3" # ubuntu 20.04 region ap-southeast-1
  instance_type = "t2.nano"
  key_name = "${aws_key_pair.my_keypair.key_name}"
  vpc_security_group_ids = ["${aws_security_group.secure_web.id}"]

  tags = {
    Name = element(var.instance_tags, count.index)
  }
}
