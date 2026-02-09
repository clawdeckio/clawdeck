# PokéDeck Deployment Guide

Simple, fast deployment to DigitalOcean VPS. No Docker overhead.

## Prerequisites

1. A fresh Ubuntu 24.04 VPS (512MB RAM minimum)
2. Domain pointing to your VPS IP (clawdeck.io)
3. SSH access to the VPS

## Initial Setup (One-time)

### 1. Create VPS and Configure DNS

Create a new DigitalOcean droplet:
- Ubuntu 24.04 LTS
- 512MB RAM / 1GB RAM recommended
- Add your SSH key during creation

Update your domain DNS:
- Point `clawdeck.io` to your VPS IP
- Point `www.clawdeck.io` to your VPS IP

### 2. Run VPS Setup Script

SSH into your VPS and run the initial setup:

```bash
# SSH to your VPS
ssh root@your-vps-ip

# Set database password
export DB_PASSWORD="your_secure_password_here"

# Download and run setup script
curl -fsSL https://raw.githubusercontent.com/yourusername/clawdeck/main/script/setup_vps.sh | bash
```

This installs: Ruby, PostgreSQL, Nginx, and creates databases.

### 3. Clone Repository

```bash
cd /var/www
git clone https://github.com/yourusername/clawdeck.git clawdeck
cd clawdeck
```

### 4. Create Production Environment File

```bash
cp .env.production.example /var/www/clawdeck/.env.production
nano /var/www/clawdeck/.env.production
```

Fill in your actual values:
```
RAILS_MASTER_KEY=<from config/master.key>
DATABASE_PASSWORD=<same as DB_PASSWORD from step 2>
```

### 5. Install Dependencies and Run Migrations

```bash
export PATH="/root/.rbenv/bin:$PATH"
eval "$(rbenv init -)"
bundle install --deployment --without development test
RAILS_ENV=production bundle exec rails db:migrate
RAILS_ENV=production bundle exec rails assets:precompile
```

### 6. Install Services

```bash
bash script/install_services.sh
```

This installs:
- Systemd services for Puma and Solid Queue
- Nginx configuration
- SSL certificates via Let's Encrypt

### 7. Start Services

```bash
systemctl start puma
systemctl start solid_queue
```

Check status:
```bash
systemctl status puma
systemctl status solid_queue
```

### 8. Configure GitHub Actions

Add these secrets to your GitHub repository (Settings → Secrets and variables → Actions):

- `VPS_HOST`: Your VPS IP address
- `VPS_SSH_KEY`: Your private SSH key (the one that can access the VPS)

## Automatic Deployments

Once setup is complete, deployments are automatic:

1. Push to `main` branch
2. GitHub Actions connects to VPS
3. Pulls latest code
4. Installs dependencies
5. Runs migrations
6. Precompiles assets
7. Restarts services

**Deploy time: ~30-60 seconds**

## Manual Deployment

If you need to deploy manually:

```bash
ssh root@your-vps-ip
cd /var/www/clawdeck
git pull origin main
bundle install --deployment
RAILS_ENV=production bundle exec rails db:migrate
RAILS_ENV=production bundle exec rails assets:precompile
systemctl restart puma solid_queue
```

## Monitoring

View logs:
```bash
# Puma logs
tail -f /var/log/clawdeck/puma.log

# Solid Queue logs
tail -f /var/log/clawdeck/solid_queue.log

# Nginx logs
tail -f /var/log/nginx/access.log
tail -f /var/log/nginx/error.log
```

Check service status:
```bash
systemctl status puma
systemctl status solid_queue
systemctl status nginx
```

## Troubleshooting

**Services won't start:**
```bash
# Check service logs
journalctl -u puma -n 50 --no-pager
journalctl -u solid_queue -n 50 --no-pager
```

**Database connection errors:**
```bash
# Test PostgreSQL
sudo -u postgres psql -l
```

**SSL certificate issues:**
```bash
# Renew certificates
certbot renew
systemctl restart nginx
```

## Resource Usage

Expected memory usage on 512MB VPS:
- Puma (Rails): ~150MB
- Solid Queue: ~100MB
- PostgreSQL: ~50MB
- Nginx: ~20MB
- System: ~100MB
- **Total: ~420MB (plenty of headroom)**
