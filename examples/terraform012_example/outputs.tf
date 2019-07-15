###############################################################################
# Outputs
# terraform output summary
###############################################################################

output "summary" {
  value = <<EOF

## Outputs - 100compute layer

|  | Key Pairs |
|---|---|
| key_pair_internal | ${aws_key_pair.key_pair_internal.key_name} |
| key_pair_external | ${aws_key_pair.key_pair_external.key_name} |
| key_pair_external_bastion | ${aws_key_pair.key_pair_external_bastion.key_name} |



| ALB Name | Endpoint |
|---|---|
| ALB | ${module.alb.alb_dns_name} |

EOF


  description = "100compute Layer Outputs Summary `terraform output summary` "
}
