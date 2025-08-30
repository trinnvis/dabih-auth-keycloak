# DNS Configuration for auth.trinnvis.no
# =====================================
# This file provides instructions for setting up DNS externally
# The domain should point to the ALB DNS name
#
# IMPORTANT: DNS must be configured externally (not managed by Terraform)
# 
# Required DNS Record:
# --------------------
# Type: CNAME
# Name: auth.trinnvis.no
# Value: Use the output from 'tofu output alb_dns_name'
# TTL: 300 (5 minutes)
#
# To get the ALB DNS name, run:
#   tofu output alb_dns_name
#
# Example DNS record:
#   auth.trinnvis.no. 300 IN CNAME dabih-auth-keycloak-alb-XXXXXXXXX.eu-central-1.elb.amazonaws.com.

# ACM Certificate for HTTPS
resource "aws_acm_certificate" "keycloak" {
  domain_name       = var.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name        = "${var.project_name}-certificate"
    Environment = var.environment
  }
}

# Output certificate validation records
output "certificate_validation_required" {
  value = aws_acm_certificate.keycloak.status == "PENDING_VALIDATION" ? true : false
  description = "Whether certificate validation is required"
}

output "certificate_status" {
  value       = aws_acm_certificate.keycloak.status
  description = "Current certificate status"
}

output "certificate_arn" {
  value       = aws_acm_certificate.keycloak.arn
  description = "Certificate ARN"
}

output "certificate_validation_records" {
  value = [
    for dvo in aws_acm_certificate.keycloak.domain_validation_options : {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  ]
  description = "DNS records required for certificate validation"
}

# Instructions for certificate validation and DNS configuration
output "dns_configuration_instructions" {
  value = <<-EOT
    ============================================
    DNS CONFIGURATION REQUIRED
    ============================================
    
    1. CNAME Record for Application:
       Name:  auth.trinnvis.no
       Type:  CNAME
       Value: ${aws_lb.keycloak.dns_name}
       TTL:   300
    
    2. Certificate Validation:
       Status: ${aws_acm_certificate.keycloak.status}
       
       ${aws_acm_certificate.keycloak.status == "PENDING_VALIDATION" ? 
       "ACTION REQUIRED: Add DNS validation records for the certificate.\nCheck the 'certificate_validation_records' output for the exact records to add.\nAlternatively, run this command:\naws acm describe-certificate --certificate-arn ${aws_acm_certificate.keycloak.arn} --region ${var.aws_region} --query 'Certificate.DomainValidationOptions[0].ResourceRecord' --output json" : 
       "Certificate is validated and ready to use."}
    
    3. Testing DNS:
       After adding the CNAME record, test with:
       - nslookup auth.trinnvis.no
       - dig auth.trinnvis.no
       - curl -I https://auth.trinnvis.no/health/ready
    
    4. Troubleshooting:
       - DNS propagation can take up to 48 hours
       - Use 'dig @8.8.8.8 auth.trinnvis.no' to check Google DNS
       - Check certificate status: aws acm describe-certificate --certificate-arn ${aws_acm_certificate.keycloak.arn} --region ${var.aws_region}
       - Keycloak health check: https://auth.trinnvis.no/health/ready
       - Admin console: https://auth.trinnvis.no/admin
    
    ============================================
  EOT
  description = "Instructions for DNS configuration"
}