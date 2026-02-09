# Quick Start: Deploy PokéDeck in 10 Minutes

## What You'll Get

- ✅ **Fast deployments**: ~30-60 seconds (not 7+ minutes)
- ✅ **Low memory**: Runs perfectly on 512MB RAM
- ✅ **Auto-deploy**: Push to main → automatic deployment
- ✅ **Simple**: No Docker complexity
- ✅ **Reliable**: Like your Hatchbox app

## Step 1: Create VPS (2 minutes)

1. Create DigitalOcean Droplet:
   - Ubuntu 24.04 LTS
   - $4-6/month (512MB or 1GB RAM)
   - Add your SSH key

2. Point DNS to VPS IP:
   - `clawdeck.io` → your VPS IP
   - `www.clawdeck.io` → your VPS IP

## Step 2: Setup VPS (5 minutes)

```bash
# SSH to VPS
ssh root@YOUR_VPS_IP

# Set database password
export DB_PASSWORD="choose_a_secure_password"

# Run setup script
curl -fsSL https://raw.githubusercontent.com/clawdeckio/clawdeck/main/script/setup_vps.sh | bash

# Clone repository
cd /var/www
git clone https://github.com/YOUR_GITHUB_USERNAME/clawdeck.git clawdeck
cd clawdeck

# Create environment file
cp .env.production.example .env.production
nano .env.production
# Fill in: RAILS_MASTER_KEY (from config/master.key) and DATABASE_PASSWORD

# Install dependencies and setup
export PATH="/root/.rbenv/bin:$PATH"
eval "$(rbenv init -)"
bundle install --deployment --without development test
RAILS_ENV=production bundle exec rails db:migrate
RAILS_ENV=production bundle exec rails assets:precompile

# Install services
bash script/install_services.sh

# Start services
systemctl start puma solid_queue
```

## Step 3: Configure GitHub Actions (1 minute)

Add these secrets to your GitHub repo (Settings → Secrets):

- `VPS_HOST`: Your VPS IP address
- `VPS_SSH_KEY`: Your private SSH key (content of `~/.ssh/id_rsa`)

## Step 4: Deploy! (30 seconds)

```bash
# On your laptop
git push origin main
```

GitHub Actions will automatically deploy. Check progress in Actions tab.

## Verify Deployment

Visit https://clawdeck.io

Check services:
```bash
ssh root@YOUR_VPS_IP
systemctl status puma solid_queue nginx
```

## Future Deployments

Just push to main:
```bash
git push origin main
```

Deploys automatically in 30-60 seconds!

## Troubleshooting

**Services won't start?**
```bash
journalctl -u puma -n 50
journalctl -u solid_queue -n 50
```

**Need to restart?**
```bash
systemctl restart puma solid_queue
```

**Check logs:**
```bash
tail -f /var/log/clawdeck/puma.log
```

See DEPLOYMENT.md for detailed documentation.
