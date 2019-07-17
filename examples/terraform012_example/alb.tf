###############################################################################
# Locals
###############################################################################
locals {
  acm_certificate_arn = "arn:aws:acm:ap-southeast-1:626499166183:certificate/62b14545-0608-4b1f-b0c4-81b4452dde3e"
}

###############################################################################
# ALB
# https://github.com/rackspace-infrastructure-automation/aws-terraform-alb
###############################################################################

module "alb" {
  source          = "github.com/rackspace-infrastructure-automation/aws-terraform-alb//?ref=tf_0.12-upgrade"
  alb_name        = "alb-tf-012-demo"
  security_groups = [local.PublicWebSecurityGroup]
  subnets         = local.public_subnets
  vpc_id          = local.vpc_id

  http_listeners_count = 1

  http_listeners = [
    {
      port     = 80
      protocol = "HTTP"
    },
  ]

  https_listeners_count = 1

  https_listeners = [
    {
      port            = 443
      certificate_arn = local.acm_certificate_arn
    },
  ]

  target_groups_count = 1

  target_groups = [
    {
      "name"                             = "alb-tg"
      "backend_protocol"                 = "HTTP"
      "backend_port"                     = 80
      "stickiness_enabled"               = "true"
      "cookie_duration"                  = "86400"
      "deregistration_delay"             = "30"
      "health_check_path"                = "/"
      "health_check_port"                = "traffic-port"
      "health_check_healthy_threshold"   = "5"
      "health_check_unhealthy_threshold" = "2"
      "health_check_timeout"             = "5"
      "health_check_interval"            = "30"
      "health_check_matcher"             = "200-404"
    },
  ]

  alb_tags = {
    Name            = "alb"
    Environment     = var.environment
    ServiceProvider = "Rackspace"
  }
}

output "alb" {
  value       = module.alb
  description = "ALB"
}

###############################################################################
# Locals
###############################################################################
locals {
  alb_dns_name      = module.alb.alb_dns_name
  target_group_arns = module.alb.target_group_arns
}