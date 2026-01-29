🔐 Установка SSL через Certbot (Nginx)
Установка certbot
apt update
apt install -y certbot python3-certbot-nginx

Получение SSL-сертификата
certbot --nginx -d example.com -d www.example.com

Только проверка (dry-run)
certbot renew --dry-run

Обновление сертификатов вручную
certbot renew

Посмотреть установленные сертификаты
certbot certificates