provider "aws" {
  region = var.region
}

terraform {
  required_providers {
    time = {
      source  = "hashicorp/time"
    }
  }
}
