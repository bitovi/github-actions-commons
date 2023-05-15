resource "aws_launch_configuration" "main" {
  associate_public_ip_address = var.associate_public_ip_address
  iam_instance_profile        = var.iam_instance_profile
  image_id                    = var.image_id
  instance_type               = var.instance_type
  name_prefix                 = var.name_prefix
  security_groups             = var.security_groups #[aws_security_group.node.id]
  user_data_base64            = var.user_data_base64 #base64encode(local.node-userdata)
  key_name                    = var.ec2_key_pair

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "main" {
  desired_capacity     = var.desired_capacity
  launch_configuration = aws_launch_configuration.main.id
  max_size             = var.max_size
  min_size             = var.min_size
  name                 = var.asg_name
  vpc_zone_identifier  = var.vpc_zone_identifier #[aws_subnet.a.id, aws_subnet.b.id, aws_subnet.c.id]

tag {
  key                 = "kubernetes.io/cluster/${var.cluster_name}"
  value               = "owned"
  propagate_at_launch = true
}

/* [tag for tag_key, tag_value in var.common_tags: {
  key                 = tag_key
  value               = tag_value
  propagate_at_launch = true
}] */


  depends_on = [
    var.eks_worker_depends_on
  ]
}
