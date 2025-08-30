output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.keycloak.dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = aws_lb.keycloak.zone_id
}

output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = aws_ecr_repository.keycloak.repository_url
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.keycloak.name
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.keycloak.name
}

output "cloudwatch_log_group" {
  description = "CloudWatch log group for Keycloak"
  value       = aws_cloudwatch_log_group.keycloak.name
}

output "keycloak_url" {
  description = "URL to access Keycloak"
  value       = "https://${var.domain_name}"
}

output "keycloak_admin_console" {
  description = "URL to access Keycloak Admin Console"
  value       = "https://${var.domain_name}/admin"
}

output "db_secret_arn" {
  description = "ARN of the database credentials secret"
  value       = aws_secretsmanager_secret.db_credentials.arn
}

output "keycloak_admin_secret_arn" {
  description = "ARN of the Keycloak admin credentials secret"
  value       = aws_secretsmanager_secret.keycloak_admin.arn
}