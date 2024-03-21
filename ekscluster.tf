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
          Service = "ec2.amazonaws.com"
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

