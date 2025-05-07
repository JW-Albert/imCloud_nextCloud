variable "aws_region" {
  description = "AWS 區域"
  type        = string
  default     = "ap-northeast-1"    # 東京區
}

variable "instance_type" {
  description = "EC2 機器型號"
  type        = string
  default     = "t3.micro"
}

variable "ami_id" {
  description = "Ubuntu 22.04 AMI ID"
  type        = string
}

variable "key_name" {
  description = "已存在的 EC2 KeyPair 名稱"
  type        = string
}

variable "bucket_name" {
  description = "S3 Bucket 名稱"
  type        = string
}
