server {
    listen 80;
    listen [::]:80;

    server_name api.ekeflicks.com;

    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
    listen [::]:443 ssl;
    http2 on;

    server_name api.ekeflicks.com;

    ssl_certificate /etc/ssl/cloudflare/api.ekeflicks.com.pem;
    ssl_certificate_key /etc/ssl/cloudflare/api.ekeflicks.com.key;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 1d;
    ssl_session_tickets off;

    client_max_body_size 2G;



    # Compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1000;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml;

    # Django / Gunicorn
    location / {
        proxy_pass http://127.0.0.1:8000;

        proxy_http_version 1.1;

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;

        proxy_connect_timeout 60s;
        proxy_send_timeout 600s;
        proxy_read_timeout 600s;
    }

    location /contracts/producer/ {
        alias /var/www/Ekeflicks/contracts/producer/;
        autoindex off;

        add_header Cache-Control "public, max-age=3600";
        add_header X-Content-Type-Options "nosniff";

        types {
           application/pdf pdf;
        }
    }

    access_log /var/log/nginx/api.ekeflicks.com.access.log;
    error_log /var/log/nginx/api.ekeflicks.com.error.log;
}
