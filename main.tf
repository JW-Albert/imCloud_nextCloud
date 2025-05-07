provider "aws" {
  region = var.aws_region
}

####################
# 1. S3 Bucket
####################
resource "aws_s3_bucket" "nextcloud_data" {
  bucket = var.bucket_name
  acl    = "private"
}

####################
# 2. IAM Role & Policy
####################
data "aws_iam_policy_document" "ec2_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2_role" {
  name               = "nextcloud-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
}

data "aws_iam_policy_document" "s3_access" {
  statement {
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:ListBucket"
    ]
    resources = [
      aws_s3_bucket.nextcloud_data.arn,
      "${aws_s3_bucket.nextcloud_data.arn}/*"
    ]
  }
}

resource "aws_iam_policy" "nextcloud_s3_policy" {
  name   = "NextcloudS3Access"
  policy = data.aws_iam_policy_document.s3_access.json
}

resource "aws_iam_role_policy_attachment" "attach_s3" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.nextcloud_s3_policy.arn
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "nextcloud-instance-profile"
  role = aws_iam_role.ec2_role.name
}

####################
# 3. Security Group
####################
resource "aws_security_group" "nextcloud_sg" {
  name        = "nextcloud-sg"
  description = "Allow HTTP, HTTPS, SSH"
  ingress = [
    { from_port = 22,   to_port = 22,   protocol = "tcp", cidr_blocks = ["0.0.0.0/0"] },
    { from_port = 80,   to_port = 80,   protocol = "tcp", cidr_blocks = ["0.0.0.0/0"] },
    { from_port = 443,  to_port = 443,  protocol = "tcp", cidr_blocks = ["0.0.0.0/0"] },
  ]
  egress = [
    { from_port = 0, to_port = 0, protocol = "-1", cidr_blocks = ["0.0.0.0/0"] },
  ]
}

####################
# 4. EC2 Instance
####################
resource "aws_instance" "nextcloud" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  vpc_security_group_ids      = [aws_security_group.nextcloud_sg.id]
  associate_public_ip_address = true

  user_data = file("${path.module}/user_data.sh")

  tags = { Name = "Nextcloud-Server" }
}


output "ec2_public_ip" {
  description = "Nextcloud EC2 的公網 IP"
  value       = aws_instance.nextcloud.public_ip
}

output "s3_bucket" {
  description = "Nextcloud 使用的 S3 Bucket 名稱"
  value       = aws_s3_bucket.nextcloud_data.id
}