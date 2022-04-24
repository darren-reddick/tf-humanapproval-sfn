provider "aws" {
  region = var.region

}

#provider_installation {
#  filesystem_mirror {
#    path    = "/usr/share/terraform/providers"
#    include = ["*/*/*"]
#  }
#
#}