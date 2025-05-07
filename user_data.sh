#!/bin/bash
apt-get update
# 安裝 nginx + PHP
apt-get install -y nginx php-fpm php-mysql php-xml php-gd php-curl php-zip unzip wget

# 下載並部署 Nextcloud
cd /var/www
wget https://download.nextcloud.com/server/releases/latest.zip
unzip latest.zip
chown -R www-data:www-data nextcloud

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
