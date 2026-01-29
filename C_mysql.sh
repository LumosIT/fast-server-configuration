#!/usr/bin/env bash

set -e

echo "==> Installing MySQL Server"

# Проверка root
if [ "$EUID" -ne 0 ]; then
  echo "Run as root"
  exit 1
fi

# Установка MySQL (если не установлен)
if ! command -v mysql >/dev/null; then
  apt update -y
  apt install -y mysql-server
else
  echo "MySQL already installed"
fi

# Запуск и автозапуск
systemctl enable mysql
systemctl start mysql

# Ввод данных
echo
read -rp "Database name: " DB_NAME
read -rp "Database user: " DB_USER
read -srp "Database password: " DB_PASS
echo

# Валидация
if [[ -z "$DB_NAME" || -z "$DB_USER" || -z "$DB_PASS" ]]; then
  echo "ERROR: All fields are required"
  exit 1
fi

echo "==> Creating database and user"

# SQL
mysql <<EOF
CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\`
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost'
  IDENTIFIED BY '${DB_PASS}';

GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'localhost';

FLUSH PRIVILEGES;
EOF

echo
echo "==> MySQL setup completed successfully"
echo "Database: $DB_NAME"
echo "User:     $DB_USER"
