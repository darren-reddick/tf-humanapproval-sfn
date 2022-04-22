terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.56.0"
    }
  }
  #cloud {
  #  hostname     = "ec2-52-212-56-63.eu-west-1.compute.amazonaws.com"
  #  organization = "dreddick"
  #
  #  workspaces {
  #    name = "dreddick-test"
  #  }
  #}
}

