# Create network
resource "aws_vpc" "vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "daniela-vpc"
  }
}

resource "aws_subnet" "publicsub1" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "${var.aws_region}a"

  tags = {
    Name = "daniela-public-subnet1"
  }
}

resource "aws_subnet" "publicsub2" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "${var.aws_region}a"

  tags = {
    Name = "daniela-public-subnet2"
  }
}

resource "aws_subnet" "privatesub1" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "${var.aws_region}c"

  tags = {
    Name = "daniela-private-subnet1"
  }
}

resource "aws_subnet" "privatesub2" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "${var.aws_region}c"

  tags = {
    Name = "daniela-private-subnet2"
  }
}


resource "aws_internet_gateway" "internetgw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "daniela-internet-gateway"
  }
}

resource "aws_route_table" "route" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internetgw.id
  }

  tags = {
    Name = "daniela-route"
  }
}

resource "aws_route_table_association" "route_association1" {
  subnet_id      = aws_subnet.publicsub1.id
  route_table_id = aws_route_table.route.id
}

resource "aws_route_table_association" "route_association2" {
  subnet_id      = aws_subnet.publicsub2.id
  route_table_id = aws_route_table.route.id
}

resource "aws_security_group" "securitygp" {

  vpc_id = aws_vpc.vpc.id

  ingress {
    description = "https-access"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "ssh-access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "db-access"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "redis-access"
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "redis-int-access"
    from_port   = 6380
    to_port     = 6380
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  ingress {
    description = "vault-access"
    from_port   = 8201
    to_port     = 8201
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "egress-rule"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    type = "daniela-security-group"
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nateip.id
  subnet_id     = aws_subnet.publicsub.id

  tags = {
    Name = "daniela-nat-gateway"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.internetgw]
}

resource "aws_route_table" "routenat" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "daniela-routenat"
  }
}

resource "aws_route_table_association" "routenat_association1" {
  subnet_id      = aws_subnet.privatesub1.id
  route_table_id = aws_route_table.routenat.id
}

resource "aws_route_table_association" "routenat_association2" {
  subnet_id      = aws_subnet.privatesub2.id
  route_table_id = aws_route_table.routenat.id
}

# Create roles and policies to attach to the instance
resource "aws_iam_role" "daniela-role" {
  name = "daniela-role-docker"

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

resource "aws_iam_instance_profile" "daniela-profile" {
  name = "daniela-profile-docker"
  role = aws_iam_role.daniela-role.name
}

resource "aws_iam_role_policy" "daniela-policy" {
  name = "daniela-policy-docker"
  role = aws_iam_role.daniela-role.id

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : "s3:ListBucket",
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject"
        ],
        "Resource" : [
          "arn:aws:s3:::*/*"
        ]
      }
    ]
  })
}



# Create External Services: AWS S3 Bucket
resource "aws_s3_bucket" "s3bucket_data" {
  bucket        = var.storage_bucket
  force_destroy = true

  tags = {
    Name        = "Daniela FDO Storage"
    Environment = "Dev"
  }
}

# Create External Services: Postgres 14.x DB
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "daniela-db-subnetgroup"
  subnet_ids = [aws_subnet.publicsub.id, aws_subnet.privatesub.id]

  tags = {
    Name = "daniela-db-subnet-group"
  }
}


