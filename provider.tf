provider "aws" {
  region                      = var.region
  shared_credentials_file     = "/home/user/.aws/config"
  profile                     = "dekri.ralali"
}

