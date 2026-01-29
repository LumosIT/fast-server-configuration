#!/usr/bin/env bash

set -e

echo "==> Laravel installation (PHP 8.2)"

# Проверка PHP
if ! command -v php >/dev/null; then
  echo "PHP is not installed"
  exit 1
fi

PHP_VERSION=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')
if [ "$PHP_VERSION" != "8.2" ]; then
  echo "ERROR: PHP 8.2 required, current: $PHP_VERSION"
  exit 1
fi

# Проверка Composer
if ! command -v composer >/dev/null; then
  echo "Composer is not installed"
  exit 1
fi

# Ввод данных
echo
read -rp "Project directory (e.g. /var/www/myapp): " PROJECT_DIR
read -rp "Database name: " DB_NAME
read -rp "Database user: " DB_USER
read -srp "Database password: " DB_PASS
echo

# Валидация
if [[ -z "$PROJECT_DIR" || -z "$DB_NAME" || -z "$DB_USER" || -z "$DB_PASS" ]]; then
  echo "ERROR: All fields are required"
  exit 1
fi

if [ -d "$PROJECT_DIR" ] && [ "$(ls -A "$PROJECT_DIR")" ]; then
  echo "ERROR: Directory exists and is not empty"
  exit 1
fi

# Создание директории
mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"

echo "==> Creating Laravel project"

composer create-project laravel/laravel . --no-interaction

# Настройка .env
echo "==> Configuring .env"

cp .env.example .env

sed -i "s/^DB_CONNECTION=.*/DB_CONNECTION=mysql/" .env
sed -i "s/^DB_HOST=.*/DB_HOST=127.0.0.1/" .env
sed -i "s/^DB_PORT=.*/DB_PORT=3306/" .env
sed -i "s/^DB_DATABASE=.*/DB_DATABASE=${DB_NAME}/" .env
sed -i "s/^DB_USERNAME=.*/DB_USERNAME=${DB_USER}/" .env
sed -i "s/^DB_PASSWORD=.*/DB_PASSWORD=${DB_PASS}/" .env

# Генерация ключа
php artisan key:generate --force

# Права (минимально безопасные)
chown -R www-data:www-data storage bootstrap/cache
chmod -R 775 storage bootstrap/cache

echo
echo "==> Laravel installed successfully"
echo "Path: $PROJECT_DIR"
