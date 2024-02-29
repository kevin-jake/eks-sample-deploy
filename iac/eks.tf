resource "aws_eks_cluster" "main" {
  name     = "sample_mern_app"
  role_arn = aws_iam_role.master.arn

  vpc_config {
    security_group_ids      = [aws_security_group.control_plane_sg.id, aws_security_group.data_plane_sg.id]
    endpoint_private_access = true
    endpoint_public_access  = true
    subnet_ids = [aws_subnet.public_subnet.id, aws_subnet.public_subnet2.id, aws_subnet.private_subnet.id]
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Cluster handling.
  # Otherwise, EKS will not be able to properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
      aws_iam_role_policy_attachment.AmazonEKSClusterPolicy,
      aws_iam_role_policy_attachment.AmazonEKSServicePolicy,
      aws_iam_role_policy_attachment.AmazonEKSVPCResourceController,
    ]
}

 resource "aws_instance" "kubectl-server" {
    ami                         = "ami-07a6e3b1c102cdba8"
    key_name                    = "kevinprod-EC2"
    instance_type               = "t2.micro"
    associate_public_ip_address = true
    subnet_id                   = aws_subnet.public_subnet.id
    vpc_security_group_ids      = [aws_security_group.allow_tls.id]

    tags = {
      Name = "kubectl"
    }
  }

  resource "aws_eks_node_group" "node-grp" {
    cluster_name    = aws_eks_cluster.main.name
    node_group_name = "mern-node-group"
    node_role_arn   = aws_iam_role.worker.arn
    subnet_ids      = [aws_subnet.public_subnet.id, aws_subnet.private_subnet.id]
    capacity_type   = "ON_DEMAND"
    disk_size       = 20
    instance_types  = ["t2.micro"]

    remote_access {
      ec2_ssh_key               = "kevinprod-EC2"
      source_security_group_ids = [aws_security_group.allow_tls.id]
    }

    labels = {
      env = "dev"
    }

    scaling_config {
      desired_size = 2
      max_size     = 2
      min_size     = 1
    }

    update_config {
      max_unavailable = 1
    }

    depends_on = [
      aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
      aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
      aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
    ]
  }