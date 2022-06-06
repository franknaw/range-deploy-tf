
output "environment" {
  value       = var.environment
  description = "Set the environment for provisioning"
}

output "role_part_id" {
  value       = var.role_part_id
  description = "Set the environment role partition Id"
}

output "role_part" {
  value       = var.role_part
  description = "Set the environment role partition"
}

output "region" {
  value       = var.region
  description = "Region to be used"
}
