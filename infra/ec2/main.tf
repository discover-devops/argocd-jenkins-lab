# ---------------------------------------------------------------
# Part 1: network, IAM role, key pair, ECR and the jumpbox EC2
# ---------------------------------------------------------------

data "aws_availability_zones" "available" {
  state = "available"
}

# ---------- Network: VPC, internet gateway, 2 public subnets ----------
resource "aws_vpc" "lab" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "${var.project}-vpc"
  }
}

resource "aws_internet_gateway" "lab" {
  vpc_id = aws_vpc.lab.id
  tags = {
    Name = "${var.project}-igw"
  }
}

resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.lab.id
  cidr_block              = "10.0.${count.index + 1}.0/24"
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  tags = {
    Name                                        = "${var.project}-public-${count.index + 1}"
    Tier                                        = "public"
    "kubernetes.io/role/elb"                    = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.lab.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.lab.id
  }
  tags = {
    Name = "${var.project}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# ---------- Firewall for the jumpbox: SSH and Jenkins ----------
resource "aws_security_group" "jumpbox" {
  name        = "${var.project}-jumpbox-sg"
  description = "SSH and Jenkins for the lab jumpbox"
  vpc_id      = aws_vpc.lab.id

  ingress {
    description = "SSH for PuTTY"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
  }

  ingress {
    description = "Jenkins UI"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ---------- IAM role: the EC2 gets AWS permissions with no access keys ----------
resource "aws_iam_role" "jumpbox" {
  name = "${var.project}-jumpbox-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "jumpbox_admin" {
  role       = aws_iam_role.jumpbox.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_instance_profile" "jumpbox" {
  name = "${var.project}-jumpbox-profile"
  role = aws_iam_role.jumpbox.name
}

# ---------- Key pair in PuTTY format (.ppk), created by the AWS CLI ----------
resource "null_resource" "key_pair" {
  triggers = {
    key_name = "${var.project}-key"
    region   = var.region
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = "aws ec2 create-key-pair --region ${self.triggers.region} --key-name ${self.triggers.key_name} --key-type rsa --key-format ppk --query KeyMaterial --output text > ${self.triggers.key_name}.ppk"
  }

  provisioner "local-exec" {
    when        = destroy
    interpreter = ["bash", "-c"]
    command     = "aws ec2 delete-key-pair --region ${self.triggers.region} --key-name ${self.triggers.key_name}; rm -f ${self.triggers.key_name}.ppk"
  }
}

# ---------- ECR: private image registry for the app ----------
resource "aws_ecr_repository" "web" {
  name                 = "${var.project}-web"
  image_tag_mutability = "IMMUTABLE"
  force_delete         = true
  image_scanning_configuration {
    scan_on_push = true
  }
}

# ---------- The jumpbox: Ubuntu 24.04 with every tool and Jenkins ----------
data "aws_ssm_parameter" "ubuntu" {
  name = "/aws/service/canonical/ubuntu/server/24.04/stable/current/amd64/hvm/ebs-gp3/ami-id"
}

resource "aws_instance" "jumpbox" {
  ami                    = data.aws_ssm_parameter.ubuntu.value
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public[0].id
  vpc_security_group_ids = [aws_security_group.jumpbox.id]
  iam_instance_profile   = aws_iam_instance_profile.jumpbox.name
  key_name               = null_resource.key_pair.triggers.key_name

  user_data = templatefile("${path.module}/user_data.sh.tftpl", {
    region       = var.region
    cluster_name = var.cluster_name
    ecr_repo     = aws_ecr_repository.web.repository_url
  })

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  metadata_options {
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  tags = {
    Name = "${var.project}-jumpbox"
  }

  depends_on = [null_resource.key_pair]
}
