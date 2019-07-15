###############################################################################
# Terraform Remote State 
###############################################################################

# 000base
data "terraform_remote_state" "base_network" {
  backend = "s3"

  config = {
    bucket = "rs-tfstate-123456789012-ap-southeast-1"
    key    = "000base/terraform.tfstate"
    region = var.region
  }
}

###############################################################################
# Locals
###############################################################################
locals {
  vpc_id                  = data.terraform_remote_state.base_network.outputs.base_network_vpc_id
  private_subnets         = data.terraform_remote_state.base_network.outputs.base_network_private_subnets
  public_subnets          = data.terraform_remote_state.base_network.outputs.base_network_public_subnets
  PrivateAZ1              = data.terraform_remote_state.base_network.outputs.PrivateAZ1
  PrivateAZ2              = data.terraform_remote_state.base_network.outputs.PrivateAZ2
  PublicAZ1               = data.terraform_remote_state.base_network.outputs.PublicAZ1
  PublicAZ2               = data.terraform_remote_state.base_network.outputs.PublicAZ2
}

