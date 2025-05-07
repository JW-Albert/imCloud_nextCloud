provider "aws" {
  region = var.aws_region
}

####################
# 1. EBS Cold HDD 卷 (sc1)
####################
# 建立一顆 200GB 的 Cold HDD (sc1)
resource "aws_ebs_volume" "nextcloud_data_vol" {
  availability_zone = data.aws_availability_zones.available.names[0]
  size              = 200
  type              = "sc1"
  tags = {
    Name = "nextcloud-data-hdd"
  }
}

####################
# 2. IAM Role & Policy (若仍需 S3 可保留，否則可移除)
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
    { from_port = 22,  to_port = 22,  protocol = "tcp", cidr_blocks = ["0.0.0.0/0"] },
    { from_port = 80,  to_port = 80,  protocol = "tcp", cidr_blocks = ["0.0.0.0/0"] },
    { from_port = 443, to_port = 443, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"] },
  ]

  egress = [
    { from_port = 0, to_port = 0, protocol = "-1", cidr_blocks = ["0.0.0.0/0"] },
  ]
}

####################
# 4. EC2 Instance with sc1 卷掛載
####################
resource "aws_instance" "nextcloud" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  vpc_security_group_ids      = [aws_security_group.nextcloud_sg.id]
  associate_public_ip_address = true

  # 將 EBS 卷掛載到 /dev/xvdb
  ebs_block_device {
    device_name           = "/dev/xvdb"
    volume_id             = aws_ebs_volume.nextcloud_data_vol.id
    delete_on_termination = true
  }

  # 使用 user_data 安裝並掛載
  user_data = file("${path.module}/user_data.sh")

  tags = { Name = "Nextcloud-Server" }
}

####################
# 5. Data Source: Availability Zones
####################
data "aws_availability_zones" "available" {
  state = "available"
}

####################
# 6. Outputs
####################
output "ec2_public_ip" {
  description = "Nextcloud EC2 的公網 IP"
  value       = aws_instance.nextcloud.public_ip
}

output "hdd_volume_id" {
  description = "掛載到 EC2 的 sc1 HDD 卷 ID"
  value       = aws_ebs_volume.nextcloud_data_vol.id
}
