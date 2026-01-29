#!/usr/bin/env bash

set -e

COMPOSER_BIN="/usr/local/bin/composer"
EXPECTED_PHP_VERSION="8.2"

echo "==> Installing Composer"

# Проверка root
if [ "$EUID" -ne 0 ]; then
  echo "Run as root"
  exit 1
fi

# Проверка PHP
if ! command -v php >/dev/null; then
  echo "PHP is not installed"
  exit 1
fi

PHP_VERSION=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')

if [ "$PHP_VERSION" != "$EXPECTED_PHP_VERSION" ]; then
  echo "Warning: PHP version is $PHP_VERSION, expected $EXPECTED_PHP_VERSION"
fi

# Если уже установлен
if [ -f "$COMPOSER_BIN" ]; then
  echo "Composer already installed:"
  composer --version
  exit 0
fi

# Установка зависимостей
apt update -y
apt install -y curl unzip

# Скачивание installer
cd /tmp
curl -sS https://getcomposer.org/installer -o composer-setup.php

# Проверка подписи
EXPECTED_SIGNATURE=$(curl -sS https://composer.github.io/installer.sig)
ACTUAL_SIGNATURE=$(php -r "echo hash_file('sha384', 'composer-setup.php');")

if [ "$EXPECTED_SIGNATURE" != "$ACTUAL_SIGNATURE" ]; then
  echo "ERROR: Invalid Composer installer signature"
  rm composer-setup.php
  exit 1
fi

# Установка
php composer-setup.php --install-dir=/usr/local/bin --filename=composer

# Очистка
rm composer-setup.php

# Проверка
composer --version

echo "==> Composer installed successfully"
