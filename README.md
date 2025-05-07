# Terraform Nextcloud 部署

## 專案概述
本專案使用 Terraform 在 AWS 上自動化部署 Nextcloud，前端 Web 伺服器部署於 EC2，檔案物件儲存於 S3。透過 IAM Role 授權 EC2 存取 S3，並使用 user_data 腳本安裝並設定 Nextcloud。

## 檔案說明
- **main.tf**：定義 AWS 資源，包括 S3 Bucket、IAM Role/Policy、Instance Profile、Security Group、EC2 Instance 以及輸出 (output)。
- **variables.tf**：宣告 Terraform 變數 (AWS 區域、EC2 型號、AMI ID、Key Pair 名稱、S3 Bucket 名稱)。
- **terraform.tfvars**：設定變數實際值，請依環境修改 `ami_id`、`key_name`、`bucket_name`。
- **user_data.sh**：EC2 啟動時執行的腳本，負責安裝 Nginx、PHP、下載並部署 Nextcloud，並設定 Nginx 虛擬主機。
- **terraform_init.bat**：Windows 環境快速執行 `terraform init` 與 `terraform apply` 的批次檔。

## 前置條件
1. 安裝 Terraform 並加入 PATH。
2. 安裝 AWS CLI 並使用 `aws configure` 設定憑證與預設區域。
3. AWS 上已有 Key Pair，並下載 `.pem` 私鑰檔案。
4. 取得 Ubuntu 22.04 AMI ID (可以到這裡查: https://cloud-images.ubuntu.com/locator/ec2/)。

## 使用步驟
1. 將所有檔案放在同一資料夾 (terraform-nextcloud)。
2. 編輯 `terraform.tfvars`，填寫：
   - `ami_id`：Ubuntu AMI ID
   - `key_name`：Key Pair 名稱
   - `bucket_name`：S3 Bucket 名稱
3. (Windows) 執行 `terraform_init.bat`；(Linux/Mac) 執行：
   ```bash
   terraform init
   terraform apply
   ```
   並輸入 `yes` 確認佈署。
4. 部署完成後，記下終端機顯示的 EC2 公網 IP 與 S3 Bucket 名稱。
5. SSH 登入 EC2：
   ```bash
   ssh -i ~/.ssh/<your-key>.pem ubuntu@<EC2_PUBLIC_IP>
   ```
6. 開啟瀏覽器，連至：
   ```
   http://<EC2_PUBLIC_IP>/nextcloud
   ```
   完成 Nextcloud 安裝並建立管理員帳號。
7. 若要啟用 S3 物件儲存，修改 `/var/www/nextcloud/config/config.php`，新增：
   ```php
   'objectstore' => [
     'class'     => 'OC\\Files\\ObjectStore\\S3',
     'arguments' => [
       'bucket'      => getenv('NEXTCLOUD_S3_BUCKET'),
       'autocreate'  => true,
       'region'      => getenv('AWS_REGION'),
       'use_ssl'     => true,
       'use_path_style' => false,
     ],
   ],
   ```
   並於 `/etc/environment` 加入：
   ```
   AWS_REGION=ap-northeast-1
   NEXTCLOUD_S3_BUCKET=<bucket_name>
   ```
   最後重啟服務：
   ```bash
   sudo systemctl restart php7.4-fpm nginx
   ```

## 執行結果
- **S3 Bucket**：self-managed 私有儲存，用於 Nextcloud 檔案物件。
- **AWS IAM**：建立 EC2 專用 Role 與 Policy，授權透過 Instance Profile 存取 S3。
- **Security Group**：開放 SSH (22)、HTTP (80) 與 HTTPS (443)。
- **EC2 Instance**：Ubuntu 機器，透過 `user_data.sh` 自動安裝並設定 Nginx、PHP、Nextcloud。
- **Nextcloud**：Web 服務可供使用者登入與檔案管理，透過 S3 做後端儲存。

