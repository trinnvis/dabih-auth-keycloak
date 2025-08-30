# Data source for the hosted zone
data "aws_route53_zone" "main" {
  name         = "trinnvis.no"
  private_zone = false
}

# A record for auth.trinnvis.no pointing to the ALB
resource "aws_route53_record" "keycloak" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_lb.keycloak.dns_name
    zone_id                = aws_lb.keycloak.zone_id
    evaluate_target_health = true
  }
}

# Optional: CNAME record for www subdomain
resource "aws_route53_record" "keycloak_www" {
  count   = var.create_www_record ? 1 : 0
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "www.${var.domain_name}"
  type    = "CNAME"
  ttl     = 300
  records = [var.domain_name]
}

variable "create_www_record" {
  description = "Whether to create a www CNAME record"
  type        = bool
  default     = false
}