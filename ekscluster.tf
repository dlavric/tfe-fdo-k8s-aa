#create IAM role for AWS EKS Cluster
resource "aws_iam_role" "daniela-cluster-role" {
  name = "daniela-cluster-eks-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = ["ec2.amazonaws.com", "eks.amazonaws.com"]
        }
      },
    ]
  })
}

#create IAM role for AWS EKS Node
resource "aws_iam_role" "daniela-node-role" {
  name = "daniela-node-eks-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
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

#attach role policy for cluster
resource "aws_iam_role_policy_attachment" "daniela-eks-cluster-policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.daniela-cluster-role.name
}

resource "aws_iam_role_policy_attachment" "daniela-eks-vpc-controller-policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.daniela-cluster-role.name
}


#attach role policy for node 
resource "aws_iam_role_policy_attachment" "daniela-eks-worker-node-policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.daniela-node-role.name
}

#attach role policy for node - EC2 container registry 
resource "aws_iam_role_policy_attachment" "daniela-eks-ec2-container-policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.daniela-node-role.name
}

#attach role policy for node - EKS CNI Policy
resource "aws_iam_role_policy_attachment" "daniela-eks-cni-policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.daniela-node-role.name
}

#attach role policy for node - S3 Bucket
resource "aws_iam_role_policy_attachment" "daniela-eks-s3-policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.daniela-node-role.name
}

#create the EKS Cluster
resource "aws_eks_cluster" "k8s-cluster" {
  name     = "daniela-eks-cluster"
  role_arn = aws_iam_role.daniela-cluster-role.arn

  vpc_config {
    subnet_ids = [aws_subnet.publicsub1.id, aws_subnet.publicsub2.id]
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Cluster handling.
  # Otherwise, EKS will not be able to properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_iam_role_policy_attachment.daniela-eks-cluster-policy,
    aws_iam_role_policy_attachment.daniela-eks-vpc-controller-policy
  ]
}

# output "endpoint" {
#   value = aws_eks_cluster.example.endpoint
# }

# output "kubeconfig-certificate-authority-data" {
#   value = aws_eks_cluster.example.certificate_authority[0].data
# }

#create the EKS nodes
resource "aws_eks_node_group" "k8s-nodes" {
  cluster_name    = aws_eks_cluster.k8s-cluster.name
  node_group_name = "daniela-eks-node-group"
  node_role_arn   = aws_iam_role.daniela-node-role.arn
  subnet_ids      = [aws_subnet.publicsub1.id, aws_subnet.publicsub2.id]
  instance_types  = ["c4.2xlarge"]

  scaling_config {
    desired_size = var.eks_desired_size
    max_size     = var.eks_max_size
    min_size     = var.eks_min_size
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.daniela-eks-worker-node-policy,
    aws_iam_role_policy_attachment.daniela-eks-cni-policy,
    aws_iam_role_policy_attachment.daniela-eks-ec2-container-policy,
    aws_iam_role_policy_attachment.daniela-eks-s3-policy
  ]
}