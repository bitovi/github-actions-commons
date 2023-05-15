/* terraform {
  required_version = ">= 0.13"
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}
provider "aws" {
  region = "us-east-1"
}
/* 
provider "aws" {
  region  = "us-east-1"
  version = ">= 4.0"
  
  default_tags {
    tags = local.common_tags
  }
} */

/* provider "random" {
  version = "~> 2.2.1"
}  */


terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.30"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 2.2"
    }
  }

  backend "s3" {
    region  = "us-east-1"
    bucket  = "bitovi-eks-statefile"
    key     = "erraform.tfstate"
    encrypt = true #AES-256encryption
  }
}

provider "aws" {
  region = var.aws-region
  default_tags {
    tags = merge(
      local.common_tags
    )
  }
}