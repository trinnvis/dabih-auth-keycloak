variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "eu-central-1"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "dabih-auth-keycloak"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "domain_name" {
  description = "Domain name for Keycloak"
  type        = string
  default     = "auth.trinnvis.no"
}

variable "rds_instance_identifier" {
  description = "RDS instance identifier to use"
  type        = string
  default     = "dabih-database"
}

variable "database_name" {
  description = "Database name"
  type        = string
  default     = "dabih_tasks"
}

variable "db_schema" {
  description = "Database schema for Keycloak"
  type        = string
  default     = "keycloak"
}

variable "db_credentials_secret_name" {
  description = "Name of the AWS Secrets Manager secret for database credentials"
  type        = string
  default     = "rds/dabih-database/keycloak"
}

variable "db_username" {
  description = "Database username for Keycloak"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Database password for Keycloak"
  type        = string
  sensitive   = true
}

variable "keycloak_admin_user" {
  description = "Keycloak admin username"
  type        = string
  default     = "admin"
}

variable "keycloak_admin_password" {
  description = "Keycloak admin password"
  type        = string
  sensitive   = true
}

variable "task_cpu" {
  description = "CPU units for the ECS task"
  type        = string
  default     = "1024"
}

variable "task_memory" {
  description = "Memory for the ECS task in MB"
  type        = string
  default     = "2048"
}

variable "desired_count" {
  description = "Desired number of ECS tasks"
  type        = number
  default     = 1
}

variable "keycloak_version" {
  description = "Keycloak version to deploy"
  type        = string
  default     = "26.0"
}