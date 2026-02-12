#!/bin/bash
set -e

echo "==> PokéDeck VPS Setup Script"
echo "==> This will install: Ruby, PostgreSQL, Nginx, and configure the server"

# Update system
echo "==> Updating system packages..."
apt-get update
apt-get upgrade -y

# Install dependencies
echo "==> Installing dependencies..."
apt-get install -y curl git build-essential libssl-dev libyaml-dev libreadline-dev \
  zlib1g-dev libncurses5-dev libffi-dev libgdbm-dev libpq-dev nginx certbot \
  python3-certbot-nginx

# Install PostgreSQL
echo "==> Installing PostgreSQL..."
apt-get install -y postgresql postgresql-contrib
systemctl start postgresql
systemctl enable postgresql

# Install rbenv and ruby-build
echo "==> Installing rbenv..."
if [ ! -d "/root/.rbenv" ]; then
  git clone https://github.com/rbenv/rbenv.git /root/.rbenv
  echo 'export PATH="/root/.rbenv/bin:$PATH"' >> /root/.bashrc
  echo 'eval "$(rbenv init -)"' >> /root/.bashrc
  git clone https://github.com/rbenv/ruby-build.git /root/.rbenv/plugins/ruby-build
fi

export PATH="/root/.rbenv/bin:$PATH"
eval "$(rbenv init -)"

# Install Ruby 3.3.1
echo "==> Installing Ruby 3.3.1..."
if ! rbenv versions | grep -q "3.3.1"; then
  rbenv install 3.3.1
fi
rbenv global 3.3.1

# Install bundler
echo "==> Installing bundler..."
gem install bundler --no-document

# Create deployment directory
echo "==> Creating deployment directory..."
mkdir -p /var/www/clawdeck
chown -R root:root /var/www/clawdeck

# Configure PostgreSQL
echo "==> Configuring PostgreSQL..."
sudo -u postgres psql -c "CREATE USER clawdeck WITH PASSWORD '${DB_PASSWORD}';" || echo "User already exists"
sudo -u postgres psql -c "ALTER USER clawdeck CREATEDB;" || echo "Already has CREATEDB"
sudo -u postgres psql -c "CREATE DATABASE clawdeck_production OWNER clawdeck;" || echo "Database already exists"
sudo -u postgres psql -c "CREATE DATABASE clawdeck_cache_production OWNER clawdeck;" || echo "Cache DB already exists"
sudo -u postgres psql -c "CREATE DATABASE clawdeck_queue_production OWNER clawdeck;" || echo "Queue DB already exists"
sudo -u postgres psql -c "CREATE DATABASE clawdeck_cable_production OWNER clawdeck;" || echo "Cable DB already exists"

# Optimize PostgreSQL for low memory
echo "==> Optimizing PostgreSQL for low memory..."
PG_CONF=$(sudo -u postgres psql -t -P format=unaligned -c 'SHOW config_file;')
cat >> "$PG_CONF" <<EOF

# Optimizations for 512MB-1GB RAM server
shared_buffers = 128MB
effective_cache_size = 256MB
maintenance_work_mem = 32MB
work_mem = 4MB
max_connections = 20
EOF

systemctl restart postgresql

echo "==> VPS setup complete!"
echo "==> Next steps:"
echo "    1. Clone your repository to /var/www/clawdeck"
echo "    2. Create /var/www/clawdeck/.env.production with your secrets"
echo "    3. Run systemd service setup"
