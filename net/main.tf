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
    key    = "test/net/terraform.tfstate"
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


#VPC

resource "aws_vpc" "raw-tf-vpc" {
  cidr_block = var.VPC_CIDR
  tags = {
    "Name" = "raw_tf_${var.ENV}_${local.APP}_vpc"
  }
}

#INTERNET GATEWAY

resource "aws_internet_gateway" "raw_tf_igw" {
  vpc_id = aws_vpc.raw-tf-vpc.id
  tags = {
    "Name" = "raw_tf_${var.ENV}_${local.APP}_igw"
  }
}

#SUBNETS

resource "aws_subnet" "raw_tf_subnet" {
  count                   = length(var.SUBNET_CIDR)
  vpc_id                  = aws_vpc.raw-tf-vpc.id
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  cidr_block              = var.SUBNET_CIDR[count.index]
  map_public_ip_on_launch = true
  tags = {
    "Name" = "raw_tf_${var.ENV}_${local.APP}_subnet_${count.index + 1}"
  }
}

#ROUTE TABLES

resource "aws_route_table" "public_route" {
  vpc_id = aws_vpc.raw-tf-vpc.id
  route = [{
    cidr_block                 = "0.0.0.0/0"
    gateway_id                 = aws_internet_gateway.raw_tf_igw.id
    carrier_gateway_id         = ""
    destination_prefix_list_id = ""
    egress_only_gateway_id     = ""
    instance_id                = ""
    ipv6_cidr_block            = ""
    local_gateway_id           = ""
    nat_gateway_id             = ""
    network_interface_id       = ""
    transit_gateway_id         = ""
    vpc_endpoint_id            = ""
    vpc_peering_connection_id  = ""
    } /*,
    {
      cidr_block                 = "10.10.20.0/23"
      gateway_id                 = "vgw-076e78686564983dd"
      carrier_gateway_id         = ""
      destination_prefix_list_id = ""
      egress_only_gateway_id     = ""
      instance_id                = ""
      ipv6_cidr_block            = ""
      local_gateway_id           = ""
      nat_gateway_id             = ""
      network_interface_id       = ""
      transit_gateway_id         = ""
      vpc_endpoint_id            = ""
      vpc_peering_connection_id  = ""
    }*/
  ]

  depends_on = [
    aws_internet_gateway.raw_tf_igw
  ]
  tags = {
    "Name" = "raw_tf_${var.ENV}_${local.APP}_public_route"
  }
}

resource "aws_route_table_association" "pub_subnet_associate" {
  count          = length(aws_subnet.raw_tf_subnet[*].id)
  route_table_id = aws_route_table.public_route.id
  subnet_id      = element(aws_subnet.raw_tf_subnet[*].id, count.index)
}
