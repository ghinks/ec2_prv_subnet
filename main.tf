resource "aws_iam_role" "ssm_role" {
  name = "ssm_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EC2AssumeRole"
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
  tags = {
    Name = "ssm_role"
  }
}

resource "aws_iam_role_policy_attachment" "ssm_policy_attachment" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm_instance_profile" {
  name = "ssm_instance_profile"
  role = aws_iam_role.ssm_role.name
}

resource "aws_vpc" "ec2_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
}

resource "aws_subnet" "ec2_subnet" {
  vpc_id            = aws_vpc.ec2_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = var.availability_zone
}

resource "aws_security_group" "allow_session_manager_sg" {
  name        = "allow_session_manager"
  description = "Allow Session Manager inbound traffic"
  vpc_id      = aws_vpc.ec2_vpc.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_vpc_endpoint" "ssm-endpt" {
  count             = 1
  vpc_id            = aws_vpc.ec2_vpc.id
  vpc_endpoint_type = "Interface"
  security_group_ids = [
    aws_security_group.allow_session_manager_sg.id
  ]
  subnet_ids          = [aws_subnet.ec2_subnet.id]
  private_dns_enabled = true
  service_name        = "com.amazonaws.${var.region}.ssm"
}

resource "aws_vpc_endpoint" "ssmmsgs-endpt" {
  count             = 1
  vpc_id            = aws_vpc.ec2_vpc.id
  vpc_endpoint_type = "Interface"
  security_group_ids = [
    aws_security_group.allow_session_manager_sg.id
  ]
  subnet_ids          = [aws_subnet.ec2_subnet.id]
  private_dns_enabled = true
  service_name        = "com.amazonaws.${var.region}.ssmmessages"
}
resource "aws_instance" "ec2_ssm_instance" {
  count         = var.instance_count
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.small"
  # hard coded for private subnet
  associate_public_ip_address = false

  iam_instance_profile   = aws_iam_instance_profile.ssm_instance_profile.name
  vpc_security_group_ids = [aws_security_group.allow_session_manager_sg.id]
  subnet_id              = aws_subnet.ec2_subnet.id
  tags = {
    Name = "ec2_ssm_instance_for_load_testing-${count.index}"
  }
}
