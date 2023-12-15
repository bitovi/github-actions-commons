#resource "aws_iam_instance_profile" "eks_inst_profile" {
#  name = "${var.aws_resource_identifier}-eks-inst-profile"
#  path = "/"
#  role = aws_iam_role.iam_role_worker.id
#  depends_on  = [aws_iam_role.iam_role_worker]
#  }

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
                "autoscaling:LaunchConfigurations",
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

