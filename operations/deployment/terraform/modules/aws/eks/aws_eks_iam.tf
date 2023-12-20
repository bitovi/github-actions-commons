#resource "aws_iam_instance_profile" "eks_inst_profile" {
#  name = "${var.aws_resource_identifier}-eks-inst-profile"
#  path = "/"
#  role = aws_iam_role.iam_role_worker.id
#  depends_on  = [aws_iam_role.iam_role_worker]
#}

resource "aws_iam_role" "iam_role_master" {
  name               = "${var.aws_resource_identifier}-eks-master"
  assume_role_policy = jsonencode({
    Version: "2012-10-17"
    Statement: [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
        #Sid    =  "EKSClusterAssumeRole"
      },
    ]
  })
}

resource "aws_iam_role" "iam_role_worker" {
  name               = "${var.aws_resource_identifier}-eks-worker"
  assume_role_policy = jsonencode({
    Version: "2012-10-17"
    Statement: [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

locals {
    master_policies = ["arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
  #"arn:aws:iam::aws:policy/AmazonEKSVPCResourceController",
  "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"]
    worker_policies = ["arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
  "arn:aws:iam::aws:policy/AmazonEC2FullAccess"]
}


resource "aws_iam_role_policy_attachment" "managed_policies_master" {
  count      = length(local.master_policies)
  policy_arn = element(local.master_policies, count.index)
  role       = aws_iam_role.iam_role_master.id
}

resource "aws_iam_role_policy_attachment" "managed_policies_worker" {
  count      = length(local.worker_policies)
  policy_arn = element(local.worker_policies, count.index)
  role       = aws_iam_role.iam_role_worker.id
}



resource "aws_iam_role_policy" "iam_role_policy_master" {
  name   = "${var.aws_resource_identifier}-eks-master"
  role   = aws_iam_role.iam_role_master.id
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Stmt1443103596000",
            "Effect": "Allow",
            "Action": [
                "s3:GetBucketNotification",
                "s3:GetObject",
                "s3:GetObjectAcl",
                "s3:ListBucket",
                "s3:ListBucketMultipartUploads",
                "s3:ListMultipartUploadParts",
                "s3:PutObject",
                "s3:PutObjectAcl",
                "s3:PutObjectVersionAcl"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_role_policy" "iam_role_policy_worker" {
  name   = "${var.aws_resource_identifier}-eks-worker"
  role   = aws_iam_role.iam_role_worker.id
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Stmt1443103596000",
            "Effect": "Allow",
            "Action": [
                "s3:GetBucketNotification",
                "s3:GetObject",
                "s3:GetObjectAcl",
                "s3:ListBucket",
                "s3:ListBucketMultipartUploads",
                "s3:ListMultipartUploadParts",
                "s3:PutObject",
                "s3:PutObjectAcl",
                "s3:PutObjectVersionAcl"
            ],
            "Resource": [
                "*"
            ]
        },
        {
            "Sid": "Stmt1443103919000",
            "Effect": "Allow",
            "Action": [
                "autoscaling:DescribeAutoScalingGroups",
                "autoscaling:DescribeAutoScalingInstances",
                "autoscaling:DescribeAutoScalingNotificationTypes",
                "autoscaling:DescribeLaunchConfigurations",
                "autoscaling:CreateLaunchConfiguration",
                "autoscaling:DeleteLaunchConfiguration",
                "autoscaling:DescribeTags",
                "autoscaling:SetDesiredCapacity",
                "autoscaling:TerminateInstanceInAutoScalingGroup"
            ],
            "Resource": [
                "*"
            ]
        },
        {
            "Sid": "Stmt1443103707000",
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:Describe*",
                "logs:FilterLogEvents",
                "logs:GetLogEvents",
                "logs:PutLogEvents",
                "logs:PutMetricFilter",
                "logs:PutRetentionPolicy",
                "logs:PutSubscriptionFilter",
                "logs:TestMetricFilter"
            ],
            "Resource": [
                "arn:aws:logs:*:*:*",
                "*"
            ]
        },
        {
            "Sid": "Stmt1486850980000",
            "Effect": "Allow",
            "Action": [
                "ec2:AuthorizeSecurityGroupIngress",
                "ec2:Describe*",
                "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
                "elasticloadbalancing:Describe*",
                "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
                "elasticloadbalancing:DeregisterTargets",
                "elasticloadbalancing:DescribeTargetGroups",
                "elasticloadbalancing:DescribeTargetHealth",
                "elasticloadbalancing:RegisterTargets"
            ],
            "Resource": [
                "*"
            ]
        },
        {
            "Sid": "Stmt1486851017000",
            "Effect": "Allow",
            "Action": [
                "ec2:AuthorizeSecurityGroupIngress",
                "ec2:Describe*"
            ],
            "Resource": [
                "*"
            ]
        },
        {
            "Sid": "Stmt1486851142000",
            "Effect": "Allow",
            "Action": [
                "ecr:BatchCheckLayerAvailability",
                "ecr:BatchGetImage",
                "ecr:CompleteLayerUpload",
                "ecr:GetAuthorizationToken",
                "ecr:GetDownloadUrlForLayer",
                "ecr:InitiateLayerUpload",
                "ecr:PutImage",
                "ecr:UploadLayerPart"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}
EOF
}

#resource "aws_iam_policy" "cluster_encryption" {
#    arn         = "arn:aws:iam::755521597925:policy/education-eks-bQPVPbjE-cluster-ClusterEncryption2023121918102043890000000b"
#    description = "Cluster encryption policy to allow cluster role to utilize CMK provided"
#    id          = "arn:aws:iam::755521597925:policy/education-eks-bQPVPbjE-cluster-ClusterEncryption2023121918102043890000000b"
#    name        = "education-eks-bQPVPbjE-cluster-ClusterEncryption2023121918102043890000000b"
#    name_prefix = "education-eks-bQPVPbjE-cluster-ClusterEncryption"
#    path        = "/"
#    policy      = jsonencode(
#        {
#            Statement = [
#                {
#                    Action   = [
#                        "kms:Encrypt",
#                        "kms:Decrypt",
#                        "kms:ListGrants",
#                        "kms:DescribeKey",
#                    ]
#                    Effect   = "Allow"
#                    Resource = "arn:aws:kms:us-east-1:755521597925:key/5385f123-4a12-4f60-8f05-c5dccc0ad34b"
#                },
#            ]
#            Version   = "2012-10-17"
#        }
#    )
#    policy_id   = "ANPA272EYWHSY7G6RJZIY"
#    tags_all    = {}
#}
#
#resource "aws_iam_openid_connect_provider" "oidc_provider" {
#    arn             = "arn:aws:iam::755521597925:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/5F84BFB3276B7DDD04433B7B33EAD95E"
#    client_id_list  = [
#        "sts.amazonaws.com",
#    ]
#    id              = "arn:aws:iam::755521597925:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/5F84BFB3276B7DDD04433B7B33EAD95E"
#    tags            = {
#        "Name" = "education-eks-bQPVPbjE-eks-irsa"
#    }
#    tags_all        = {
#        "Name" = "education-eks-bQPVPbjE-eks-irsa"
#    }
#    thumbprint_list = [
#        "9e99a48a9960b14926bb7f3b02e22da2b0ab7280",
#        "06b25927c42a721631c1efd9431e648fa62e1e39",
#        "414a2060b738c635cc7fc243e052615592830c53",
#        "aaa68bb211d468db8a8a19561ccba2e4043dcc80",
#    ]
#    url             = "oidc.eks.us-east-1.amazonaws.com/id/5F84BFB3276B7DDD04433B7B33EAD95E"
#}