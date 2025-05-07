variable "aws_region" {
  description = "AWS 區域"
  type        = string
  default     = "ap-northeast-1"    # 東京區，可依需求調整
}

variable "instance_type" {
  description = "EC2 機器型號（最便宜 t3.nano）"
  type        = string
  default     = "t3.nano"
}

variable "ami_id" {
  description = "Ubuntu 22.04 AMI ID"
  type        = string
}

variable "key_name" {
  description = "已存在的 EC2 KeyPair 名稱"
  type        = string
}

variable "volume_size" {
  description = "掛載到 EC2 的 EBS 卷大小 (GB)"
  type        = number
  default     = 200
}
