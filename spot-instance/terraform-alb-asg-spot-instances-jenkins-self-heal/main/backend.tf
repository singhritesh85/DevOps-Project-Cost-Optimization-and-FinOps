terraform {
   backend "s3" {
     bucket         = "dolo-dempo"
     key            = "spot-price/terraform.tfstate"
     region         = "us-east-2"
     use_lockfile = true    ###dynamodb_table = "terraform-state"
   }
 }
