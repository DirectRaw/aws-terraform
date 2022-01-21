output "public_ip" {
  value = aws_instance.raw_tf_ec2[*].public_ip
}

output "private_ip" {
  value = aws_instance.raw_tf_ec2[*].private_ip
}

output "subnet_id" {
  value = aws_instance.raw_tf_ec2[*].subnet_id
}

output "key_name" {
  description = "Name of the keypair"
  value       = aws_key_pair.keypair[*].key_name
}

output "secret" {
  description = "AWS SecretManager Secret resource"
  value       = aws_secretsmanager_secret.secret_key[*].name
}