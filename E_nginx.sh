#!/usr/bin/env bash

set -e

PHP_VERSION="8.2"
NGINX_USER="www-data"

echo "==> Installing and configuring Nginx for Laravel"

# Проверка root
if [ "$EUID" -ne 0 ]; then
  echo "Run as root"
  exit 1
fi

# Установка nginx
if ! command -v nginx >/dev/null; then
  apt update -y
  apt install -y nginx
else
  echo "Nginx already installed"
fi

systemctl enable nginx
systemctl start nginx

# Ввод данных
echo
read -rp "Laravel project path (e.g. /var/www/myapp): " PROJECT_PATH
read -rp "Domain name (leave empty for IP access): " DOMAIN

# Валидация
if [ ! -d "$PROJECT_PATH" ]; then
  echo "ERROR: Project directory does not exist"
  exit 1
fi

PUBLIC_PATH="$PROJECT_PATH/public"

if [ ! -d "$PUBLIC_PATH" ]; then
  echo "ERROR: $PUBLIC_PATH not found (is this a Laravel project?)"
  exit 1
fi

SERVER_NAME="_"
CONF_NAME="laravel"

if [ -n "$DOMAIN" ]; then
  SERVER_NAME="$DOMAIN www.$DOMAIN"
  CONF_NAME="$DOMAIN"
fi

CONF_FILE="/etc/nginx/sites-available/$CONF_NAME"

echo "==> Creating nginx config: $CONF_FILE"

cat > "$CONF_FILE" <<EOF
server {
    listen 80;
    server_name $SERVER_NAME;

    root $PUBLIC_PATH;
    index index.php index.html;

    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-Content-Type-Options "nosniff";

    charset utf-8;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    error_page 404 /index.php;

    location ~ \.php\$ {
        fastcgi_pass unix:/run/php/php${PHP_VERSION}-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$realpath_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }
}
EOF

# Включение сайта
ln -sf "$CONF_FILE" /etc/nginx/sites-enabled/

# Отключение дефолтного сайта (если есть)
if [ -f /etc/nginx/sites-enabled/default ]; then
  rm /etc/nginx/sites-enabled/default
fi

# Проверка конфигурации
nginx -t

# Перезапуск
systemctl reload nginx

# Права
echo "==> Setting permissions"

chown -R $NGINX_USER:$NGINX_USER "$PROJECT_PATH"
find "$PROJECT_PATH" -type d -exec chmod 755 {} \;
find "$PROJECT_PATH" -type f -exec chmod 644 {} \;

chmod -R 775 "$PROJECT_PATH/storage" "$PROJECT_PATH/bootstrap/cache"

echo
echo "==> Nginx configured successfully"
if [ -n "$DOMAIN" ]; then
  echo "Access your app via: http://$DOMAIN"
else
  echo "Access your app via server IP"
fi
