#!/bin/bash
apt-get update
apt-get install -y nginx php-fpm php-mysql php-xml php-gd php-curl php-zip unzip wget

# 格式化 & 掛載 sc1 HDD (/dev/xvdb)
mkfs.ext4 /dev/xvdb
mkdir -p /mnt/nextcloud_data
echo '/dev/xvdb /mnt/nextcloud_data ext4 defaults 0 2' >> /etc/fstab
mount -a

# 部署 Nextcloud，並將 data 圖錄至 /mnt/nextcloud_data
cd /var/www
wget https://download.nextcloud.com/server/releases/latest.zip
unzip latest.zip
chown -R www-data:www-data nextcloud
mv nextcloud/data /mnt/nextcloud_data
ln -s /mnt/nextcloud_data /var/www/nextcloud/data

# Nginx 設定
cat >/etc/nginx/sites-available/nextcloud <<'EOF'
server {
    listen 80;
    server_name _;
    root /var/www/nextcloud/;
    index index.php index.html;

    location / {
        try_files $uri $uri/ /index.php$request_uri;
    }

    location ~ \.php$ {
        fastcgi_pass unix:/run/php/php7.4-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    }
}
EOF
ln -sf /etc/nginx/sites-available/nextcloud /etc/nginx/sites-enabled/
systemctl restart nginx
