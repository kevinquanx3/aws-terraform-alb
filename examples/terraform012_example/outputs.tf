###############################################################################
# Outputs
# terraform output summary
###############################################################################

output "summary" {
  value = <<EOF

## Outputs - 100compute layer

| ALB Name | Endpoint |
|---|---|
| ALB | ${module.alb.alb_dns_name} |

EOF


  description = "100compute Layer Outputs Summary `terraform output summary` "
}
