output "vpc_id" {
  value = aws_vpc.raw-tf-vpc.id
}

output "vpc_cidr" {
  value = aws_vpc.raw-tf-vpc.cidr_block
}

output "public_subnet_ids" {
  value = aws_subnet.raw_tf_subnet[*].id
}

output "public_subnet_cidr" {
  value = aws_subnet.raw_tf_subnet[*].cidr_block
}
