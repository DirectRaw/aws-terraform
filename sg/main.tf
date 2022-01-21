provider "aws" {
  region = var.REGION
  default_tags {
    tags = {
      "Env"        = var.ENV
      "Team"       = local.TEAM
      "Managet By" = local.CREATED
      "Owner"      = local.OWNER
      "CostCenter" = "${var.ENV}_${local.COST}"
    }
  }
}

terraform {
  backend "s3" {
    bucket = "raw-tf-state-backend"
    key    = "test/sg/terraform.tfstate"
    region = "eu-west-3"
  }
}

#DATA

data "terraform_remote_state" "globalvar" {
  backend = "s3"
  config = {
    bucket = "raw-tf-state-backend"
    key    = "globalvar/terraform.tfstate"
    region = "eu-west-3"
  }
}
data "terraform_remote_state" "net" {
  backend = "s3"
  config = {
    bucket = "raw-tf-state-backend"
    key    = "test/net/terraform.tfstate"
    region = "eu-west-3"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}
data "aws_region" "current" {}


locals {
  APP     = data.terraform_remote_state.globalvar.outputs.APP
  TEAM    = data.terraform_remote_state.globalvar.outputs.TEAM
  CREATED = data.terraform_remote_state.globalvar.outputs.CREATED
  OWNER   = data.terraform_remote_state.globalvar.outputs.OWNER
  COST    = data.terraform_remote_state.globalvar.outputs.COST
}


#SECURITY GROUP

resource "aws_security_group" "raw_tf_sg" {
  name        = "raw_tf_${var.ENV}_${local.APP}_sg"
  description = "Security Group for web_app generate by Terraform"
  vpc_id      = data.terraform_remote_state.net.outputs.vpc_id

  ingress {
    description = "Allow all to port 80"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow all to port 22"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["82.200.165.82/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  dynamic "ingress" {
    for_each = ["80", "22"]
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["10.10.20.0/23"]
    }
  }
  tags = {
    "Name" = "raw_tf_${var.ENV}_${local.APP}_sg"
  }
}
