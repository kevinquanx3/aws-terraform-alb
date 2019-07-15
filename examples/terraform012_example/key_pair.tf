###############################################################################
# Key Pair
###############################################################################

resource "aws_key_pair" "key_pair_internal" {
  key_name = "${var.aws_account_id}-${var.region}-${var.environment}-internal"
  public_key = file(
    "../../../scripts/${var.aws_account_id}-${var.region}-${var.environment}-internal.pem.pub",
  )
}

resource "aws_key_pair" "key_pair_external" {
  key_name = "${var.aws_account_id}-${var.region}-${var.environment}-external"
  public_key = file(
    "../../../scripts/${var.aws_account_id}-${var.region}-${var.environment}-external.pem.pub",
  )
}

resource "aws_key_pair" "key_pair_external_bastion" {
  key_name = "${var.aws_account_id}-${var.region}-${var.environment}-external-bastion"
  public_key = file(
    "../../../scripts/${var.aws_account_id}-${var.region}-${var.environment}-external-bastion.pem.pub",
  )
}

###############################################################################
# Locals
###############################################################################
locals {
  key_pair_internal         = aws_key_pair.key_pair_internal.key_name
  key_pair_external         = aws_key_pair.key_pair_external.key_name
  key_pair_external_bastion = aws_key_pair.key_pair_external_bastion.key_name
}

