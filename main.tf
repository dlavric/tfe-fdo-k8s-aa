# DNS
data "aws_route53_zone" "zone" {
  name = var.tfe_domain
}

# Create DNS for the Load Balancer
resource "aws_route53_record" "lb" {
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = "${var.tfe_subdomain}.${data.aws_route53_zone.zone.name}"
  type    = "CNAME"
  ttl     = "300"
  records = [aws_lb.tfe_lb.dns_name] #point it to the lb dns name
}

# Create DNS for the Bastion server
resource "aws_route53_record" "bastion" {
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = "${var.tfe_subdomain}.${data.aws_route53_zone.zone.name}-bastion"
  type    = "A"
  ttl     = "300"
  records = [aws_eip.eip.public_ip]
}


# Create Certificates
resource "tls_private_key" "private_key" {
  algorithm = "RSA"
}

resource "acme_registration" "reg" {
  account_key_pem = tls_private_key.private_key.private_key_pem
  email_address   = var.email
}

resource "acme_certificate" "certificate" {
  account_key_pem              = acme_registration.reg.account_key_pem
  common_name                  = "${var.tfe_subdomain}.${data.aws_route53_zone.zone.name}"
  subject_alternative_names    = ["${var.tfe_subdomain}.${data.aws_route53_zone.zone.name}"]
  disable_complete_propagation = true

  dns_challenge {
    provider = "route53"
    config = {
      AWS_HOSTED_ZONE_ID = data.aws_route53_zone.zone.zone_id
    }
  }
}

# Add my certificates to a S3 Bucket
resource "aws_s3_bucket" "s3bucket" {
  bucket = var.certs_bucket

  tags = {
    Name        = "Daniela FDO Bucket"
    Environment = "Dev"
  }
}

resource "aws_s3_object" "object" {
  for_each = toset(["certificate_pem", "issuer_pem", "private_key_pem"])
  bucket   = aws_s3_bucket.s3bucket.bucket
  key      = "ssl-certs/${each.key}"
  content  = lookup(acme_certificate.certificate, "${each.key}")
}

resource "aws_s3_object" "object_full_chain" {
  bucket  = aws_s3_bucket.s3bucket.bucket
  key     = "ssl-certs/full_chain"
  content = "${acme_certificate.certificate.certificate_pem}${acme_certificate.certificate.issuer_pem}"
}

# Add my TFE FDO license to a S3 Bucket
resource "aws_s3_bucket" "s3bucket_license" {
  bucket = var.license_bucket

  tags = {
    Name        = "Daniela FDO License"
    Environment = "Dev"
  }
}

resource "aws_s3_object" "object_license" {
  bucket = aws_s3_bucket.s3bucket_license.bucket
  key    = var.license_filename
  source = var.license_filename
}

# Create network
resource "aws_vpc" "vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "daniela-vpc"
  }
}

resource "aws_subnet" "publicsub" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "${var.aws_region}a"

  tags = {
    Name = "daniela-public-subnet"
  }
}

resource "aws_subnet" "privatesub" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "${var.aws_region}c"

  tags = {
    Name = "daniela-private-subnet"
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

resource "aws_route_table_association" "route_association" {
  subnet_id      = aws_subnet.publicsub.id
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

resource "aws_route_table_association" "routenat_association" {
  subnet_id      = aws_subnet.privatesub.id
  route_table_id = aws_route_table.routenat.id
}


# Create network to attach to the Bastion server
resource "aws_network_interface" "nic" {
  subnet_id       = aws_subnet.publicsub.id
  security_groups = [aws_security_group.securitygp.id]
}


# resource "aws_network_interface_sg_attachment" "sg_attachment" {
#   #security_group_id    = aws_security_group.securitygp.id
#   network_interface_id = aws_network_interface.nic.id
# }


resource "aws_eip" "eip" {
  domain                    = "vpc"
  associate_with_private_ip = aws_network_interface.nic.private_ip
  instance                  = aws_instance.bastion.id

  tags = {
    Name = "daniela-eip"
  }
}

resource "aws_eip" "nateip" {
  domain                    = "vpc"
  associate_with_private_ip = aws_network_interface.nic.private_ip

  tags = {
    Name = "daniela-eip-nat"
  }
}

# Create Bastion Server/Jump host
resource "aws_instance" "bastion" {
  ami                  = var.ami # eu-west-2 
  instance_type        = var.instance_type
  iam_instance_profile = aws_iam_instance_profile.daniela-profile.name

  credit_specification {
    cpu_credits = "unlimited"
  }

  key_name = var.key_pair

  root_block_device {
    volume_size = 50
  }

  network_interface {
    network_interface_id = aws_network_interface.nic.id
    device_index         = 0
  }

  tags = {
    Name = "daniela-tfe-bastion"
  }

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


