###############################################################################
# Security Groups
# https://github.com/rackspace-infrastructure-automation/aws-terraform-security_group
###############################################################################

### For ALB
resource "aws_security_group" "PublicWebSecurityGroup" {
  name_prefix = "PublicWebSecurityGroup-"
  description = "Public Web Traffic"
  vpc_id      = local.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Environment     = var.environment
    Name            = "${var.environment}-PublicWebSecurityGroup"
    ServiceProvider = "Rackspace"
    Terraform       = "True"
  }

  lifecycle {
    create_before_destroy = true
  }
}

output "PublicWebSecurityGroup" {
  value       = aws_security_group.PublicWebSecurityGroup.id
  description = "Public Web Security Group"
}

###############################################################################
# Locals
###############################################################################
locals {
  PublicWebSecurityGroup  = aws_security_group.PublicWebSecurityGroup.id
}

