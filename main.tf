terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.76"
    }
  }
  required_version = ">=1.0"
}

locals {
  ssh_user = "admin"
  key_name = "odoo"
  private_key_path = "/home/debian/terraform2/odoo.pem"
}

provider "aws" {
  region = "us-east-2"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}
variable "aws_secret_key" {}
variable "aws_access_key" {}

resource "aws_instance" "nginx" {
  ami                         = "ami-02da2f5b47450f5a8" # Ubuntu 20.04 LTS // us-east-2
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  key_name                    = "odoo"
  vpc_security_group_ids      = ["sg-0c3641aabe8818538"]

  provisioner "remote-exec" {
    inline = ["echo 'Wait until SSH is ready'"]

    connection {
      type        = "ssh"
      user        = "admin"  #
      private_key = file(local.private_key_path)
      host        = self.public_ip
    }
  }
}

resource "null_resource" "run_ansible" {
  triggers = {
    instance_id = aws_instance.nginx.id
    public_ip   = aws_instance.nginx.public_ip
  }

  provisioner "local-exec" {
    environment = {
      CF_API_TOKEN = "tu_token_real"
    }
    command = "ansible-playbook -i admin@${aws_instance.nginx.public_dns}, --private-key ${local.private_key_path} aws-odoo.yml"
  }
}

