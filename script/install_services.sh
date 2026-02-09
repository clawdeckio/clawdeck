#!/bin/bash
set -e

echo "==> Installing PokéDeck Services"

# Create log directory
mkdir -p /var/log/clawdeck

# Install systemd services
echo "==> Installing systemd services..."
cp /var/www/clawdeck/config/systemd/puma.service /etc/systemd/system/
cp /var/www/clawdeck/config/systemd/solid_queue.service /etc/systemd/system/

# Reload systemd
systemctl daemon-reload

# Enable services to start on boot
systemctl enable puma
systemctl enable solid_queue

# Install Nginx configuration
echo "==> Installing Nginx configuration..."
cp /var/www/clawdeck/config/nginx/clawdeck.conf /etc/nginx/sites-available/clawdeck
ln -sf /etc/nginx/sites-available/clawdeck /etc/nginx/sites-enabled/clawdeck
rm -f /etc/nginx/sites-enabled/default

# Test Nginx configuration
nginx -t

# Setup SSL with Let's Encrypt
echo "==> Setting up SSL..."
mkdir -p /var/www/certbot
certbot --nginx -d clawdeck.io -d www.clawdeck.io --non-interactive --agree-tos --email ${CERTBOT_EMAIL:-admin@clawdeck.io}

# Restart Nginx
systemctl restart nginx
systemctl enable nginx

echo "==> Services installed successfully!"
echo "==> To start the application, run:"
echo "    systemctl start puma"
echo "    systemctl start solid_queue"
