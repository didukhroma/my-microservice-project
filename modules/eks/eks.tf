
# IAM role for EKS control plane (cluster)
resource "aws_iam_role" "eks" {
  name = "${var.cluster_name}-eks-cluster"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Action    = "sts:AssumeRole",
      Principal = { Service = "eks.amazonaws.com" }
    }]
  })
}

# Required policies for the control plane
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# Recommended so EKS може керувати ENI у VPC (LB target type ip тощо)
resource "aws_iam_role_policy_attachment" "eks_vpc_controller" {
  role       = aws_iam_role.eks.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
}


# EKS cluster
resource "aws_eks_cluster" "eks" {
  name     = var.cluster_name
  version  = "1.30"

  role_arn = aws_iam_role.eks.arn

  vpc_config {
    subnet_ids              = var.subnet_ids        # бажано приватні підмережі
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  access_config {
    authentication_mode                         = "API"
    bootstrap_cluster_creator_admin_permissions = true
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_iam_role_policy_attachment.eks_vpc_controller
  ]

  tags = {
    Project = "lesson-7"
    Module  = "eks"
  }
}


# IAM role for worker nodes
resource "aws_iam_role" "node" {
  name = "${var.cluster_name}-node"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = "sts:AssumeRole",
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

# Node required policies
resource "aws_iam_role_policy_attachment" "node_worker" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "node_cni" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "node_ecr_ro" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}


# Managed node group
resource "aws_eks_node_group" "default" {
  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = var.node_group_name
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = var.subnet_ids

  scaling_config {
    desired_size = var.desired_size
    min_size     = var.min_size
    max_size     = var.max_size
  }

  ami_type       = "AL2_x86_64"
  instance_types = [var.instance_type]
  capacity_type  = "ON_DEMAND"
  disk_size      = 20

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_eks_cluster.eks,
    aws_iam_role_policy_attachment.node_worker,
    aws_iam_role_policy_attachment.node_cni,
    aws_iam_role_policy_attachment.node_ecr_ro
  ]

  labels = {
    workload = "general"
  }

  tags = {
    Project = "lesson-7"
    Module  = "eks-ng"
  }
}
