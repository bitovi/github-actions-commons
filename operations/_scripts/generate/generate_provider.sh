#!/bin/bash

set -e

echo "In generate_provider.sh"

# Will print bitovi_provider.tf with the Terraform state file and path based on the first parameter. 
function generate_provider_aws () {
echo "
terraform {
  required_providers {
    aws = {
      source  = \"hashicorp/aws\"
      version = \"~> 5.0\"
    }
    random = {
      source  = \"hashicorp/random\"
      version = \">= 2.2\"
    }
    kubernetes = {
      source = \"hashicorp/kubernetes\"
      version = \">= 2.22\"
    }
  }

  backend \"s3\" {
    region  = \"${AWS_DEFAULT_REGION}\"
    bucket  = \"${TF_STATE_BUCKET}\"
    key     = \"tf-state-$1\"
    encrypt = true #AES-256encryption
  }
}

provider \"aws\" {
  region = \"${AWS_DEFAULT_REGION}\"
  default_tags {
    tags = local.default_tags
  }
}

provider \"aws\" {
  alias  = \"ec2\"
  region = \"${AWS_DEFAULT_REGION}\"
  default_tags {
    tags = local.ec2_tags
  }
}

provider \"aws\" {
  alias  = \"r53\"
  region = \"${AWS_DEFAULT_REGION}\"
  default_tags {
    tags = local.r53_tags
  }
}

provider \"aws\" {
  alias  = \"elb\"
  region = \"${AWS_DEFAULT_REGION}\"
  default_tags {
    tags = local.elb_tags
  }
}

provider \"aws\" {
  alias  = \"efs\"
  region = \"${AWS_DEFAULT_REGION}\"
  default_tags {
    tags = local.efs_tags
  }
}

provider \"aws\" {
  alias  = \"vpc\"
  region = \"${AWS_DEFAULT_REGION}\"
  default_tags {
    tags = local.vpc_tags
  }
}

provider \"aws\" {
  alias  = \"ecr\"
  region = \"${AWS_DEFAULT_REGION}\"
  default_tags {
    tags = local.ecr_tags
  }
}

provider \"aws\" {
  alias  = \"rds\"
  region = \"${AWS_DEFAULT_REGION}\"
  default_tags {
    tags = local.rds_tags
  }
}

provider \"aws\" {
  alias  = \"aurora\"
  region = \"${AWS_DEFAULT_REGION}\"
  default_tags {
    tags = local.aurora_tags
  }
}

" > "${GITHUB_ACTION_PATH}/operations/deployment/terraform/$1/bitovi_provider.tf"
}

generate_provider_aws aws
generate_provider_aws ecr
generate_provider_aws eks

echo "Done with generate_provider.sh"