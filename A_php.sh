#!/usr/bin/env bash

set -e

PHP_VERSION="8.2"

echo "==> Installing PHP $PHP_VERSION"

# Проверка root
if [ "$EUID" -ne 0 ]; then
  echo "Run as root"
  exit 1
fi

# Обновление системы
apt update -y
apt install -y software-properties-common ca-certificates lsb-release apt-transport-https

# Добавление PPA Ondrej (если ещё нет)
if ! grep -Rq "^deb .*ondrej/php" /etc/apt/sources.list /etc/apt/sources.list.d; then
  add-apt-repository -y ppa:ondrej/php
fi

apt update -y

# Установка PHP + расширения
apt install -y \
  php${PHP_VERSION} \
  php${PHP_VERSION}-cli \
  php${PHP_VERSION}-fpm \
  php${PHP_VERSION}-common \
  php${PHP_VERSION}-mysql \
  php${PHP_VERSION}-pgsql \
  php${PHP_VERSION}-sqlite3 \
  php${PHP_VERSION}-mbstring \
  php${PHP_VERSION}-xml \
  php${PHP_VERSION}-curl \
  php${PHP_VERSION}-zip \
  php${PHP_VERSION}-bcmath \
  php${PHP_VERSION}-intl \
  php${PHP_VERSION}-gd \
  php${PHP_VERSION}-soap \
  php${PHP_VERSION}-opcache \
  php${PHP_VERSION}-readline

# Сделать PHP 8.2 дефолтным
update-alternatives --set php /usr/bin/php${PHP_VERSION}
update-alternatives --set phar /usr/bin/phar${PHP_VERSION}
update-alternatives --set phar.phar /usr/bin/phar.phar${PHP_VERSION}

# Включение и запуск FPM
systemctl enable php${PHP_VERSION}-fpm
systemctl restart php${PHP_VERSION}-fpm

# Проверка
php -v

echo "==> PHP $PHP_VERSION installed successfully"
