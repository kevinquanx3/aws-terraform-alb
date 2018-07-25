data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_elb_service_account" "main" {}

locals {
  env_list = ["Development", "Integration", "PreProduction", "Production", "QA", "Staging", "Test"]
  acl_list = ["authenticated-read", "aws-exec-read", "bucket-owner-read", "bucket-owner-full-control", "log-delivery-write", "private", "public-read", "public-read-write"]

  bucket_acl  = "${contains(local.acl_list, var.logging_bucket_acl) ? var.logging_bucket_acl:"bucket-owner-full-control"}"
  environment = "${contains(local.env_list, var.environment) ? var.environment:"Development"}"

  default_tags = {
    ServiceProvider = "Rackspace"
    Environment     = "${local.environment}"
  }

  merged_tags = "${merge(local.default_tags, var.alb_tags)}"
}

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "3.4.0"

  # Required values
  load_balancer_name = "${var.alb_name}"
  security_groups    = "${var.security_groups}"
  subnets            = "${var.subnets}"
  vpc_id             = "${var.vpc_id}"

  # Optional Values
  log_bucket_name          = "${var.create_logging_bucket ? aws_s3_bucket.log_bucket.id:var.logging_bucket_name}"
  log_location_prefix      = "${var.logging_bucket_prefix}"
  tags                     = "${var.alb_tags}"
  http_tcp_listeners_count = "${var.http_listeners_count}"
  http_tcp_listeners       = "${var.http_listeners}"
  https_listeners_count    = "${var.https_listeners_count}"
  https_listeners          = "${var.https_listeners}"
  target_groups_count      = "${var.target_groups_count}"
  target_groups            = "${var.target_groups}"
  target_groups_defaults   = "${var.target_groups_defaults}"

  enable_deletion_protection = "${var.enable_deletion_protection}"
  load_balancer_is_internal  = "${var.load_balancer_is_internal}"

  extra_ssl_certs_count = "${var.extra_ssl_certs_count}"
  extra_ssl_certs       = "${var.extra_ssl_certs}"
  idle_timeout          = "${var.idle_timeout}"

  tags = "${local.merged_tags}"
}

# create s3 bucket if needed
resource "aws_s3_bucket" "log_bucket" {
  count  = "${var.create_logging_bucket ? 1:0}"
  bucket = "${var.logging_bucket_name}"
  acl    = "${local.bucket_acl}"

  force_destroy = "${var.logging_bucket_force_destroy}"

  tags = "${local.merged_tags}"

  server_side_encryption_configuration {
    "rule" {
      "apply_server_side_encryption_by_default" {
        kms_master_key_id = "${var.logging_bucket_encryption_kms_mster_key}"
        sse_algorithm     = "${var.logging_bucket_encyption}"
      }
    }
  }

  lifecycle_rule {
    enabled = true
    prefix  = "${var.logging_bucket_prefix}"

    expiration {
      days = "${var.logging_bucket_retention}"
    }
  }
}

# s3 policy needs to be separate since you can't reference the bucket for the reference.
resource "aws_s3_bucket_policy" "log_bucket_policy" {
  count  = "${var.create_logging_bucket ? 1:0}"
  bucket = "${aws_s3_bucket.log_bucket.id}"

  policy = <<POLICY
{
  "Id": "Policy1529427095432",
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Stmt1529427092463",
      "Action": [
        "s3:PutObject"
      ],
      "Effect": "Allow",
      "Resource": "${aws_s3_bucket.log_bucket.arn}/*",
      "Principal": {
        "AWS": [
          "${data.aws_elb_service_account.main.arn}"
        ]
      }
    }
  ]
}
POLICY
}

# create r53 record with alias
resource "aws_route53_record" "zone_record_alias" {
  count   = "${var.create_internal_zone_record ? 1:0}"
  name    = "${var.internal_zone_name}"
  type    = "A"
  zone_id = "${var.route_53_hosted_zone_id}"

  alias {
    evaluate_target_health = true
    name                   = "${module.alb.dns_name}"
    zone_id                = "${module.alb.load_balancer_zone_id}"
  }
}

# enable cloudwatch/RS ticket creation
resource "aws_cloudwatch_metric_alarm" "unhealthy_host_count_alarm" {
  count = "${var.rackspace_ticket_enabled && var.target_groups_count > 0 ? var.target_groups_count:0}"

  alarm_name          = "${format("%v_unhealthy_host_count_alarm", var.alb_name)}"
  alarm_description   = "Unhealthy Host count is greater than or equal to threshold, creating ticket."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 10
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Maximum"
  threshold           = 1
  unit                = "Count"

  dimensions {
    LoadBalancer = "${module.alb.load_balancer_arn_suffix}"
    TargetGroup  = "${module.alb.target_group_arn_suffixes[count.index]}"
  }

  alarm_actions = [
    "arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:rackspace-support-emergency",
  ]

  ok_actions = [
    "arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:rackspace-support-emergency",
  ]
}

# join ec2 instances to target group
resource "aws_lb_target_group_attachment" "target_group_instance" {
  count = "${var.register_instance_targets_count > 0 ? var.register_instance_targets_count:0}"

  # to match the instances to the
  target_group_arn = "${ module.alb.target_group_arns[lookup(var.register_instance_targets[count.index], "target_group_index")] }"
  target_id        = "${ lookup(var.register_instance_targets[count.index], "instance_id") }"
}