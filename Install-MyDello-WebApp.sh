#!/bin/bash

# Error handling
set -e
trap 'echo "Error occurred at line $LINENO. Exit code: $?"' ERR

# Define variables
LOG_FILE="/var/log/mydello-setup.log"
APP_DIR="/var/www/mydello"
NGINX_CONFIG="/etc/nginx/sites-available/mydello"
NODE_VERSION="20.x"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   log "This script must be run as root or with sudo"
   exit 1
fi

# Create log file
touch "$LOG_FILE"
chmod 644 "$LOG_FILE"

log "Starting MyDello setup..."

# Get Public IP
PUBLIC_IP=$(curl -s ifconfig.me)
if [[ -z "$PUBLIC_IP" ]]; then
    log "Failed to fetch public IP"
    exit 1
fi
log "Public IP: $PUBLIC_IP"

# Update system
log "Updating system packages..."
apt update && apt upgrade -y

# Install essential packages
log "Installing essential packages..."
apt install -y curl wget git build-essential nginx ufw fail2ban

# Install Node.js
log "Installing Node.js ${NODE_VERSION}..."
curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION} | bash -
apt install -y nodejs

# Install PM2 globally
log "Installing PM2..."
npm install -p pm2@latest -g

# Configure firewall
log "Configuring firewall..."
ufw allow 'Nginx Full'
ufw allow ssh
ufw --force enable

# Create application directory
log "Creating application directory..."
mkdir -p $APP_DIR
cd $APP_DIR

# Initialize Next.js project
log "Creating Next.js project..."
npx create-next-app@latest . --typescript --tailwind --eslint --app --src-dir --import-alias "@/*" --no-git --use-npm

# Install additional dependencies
log "Installing additional dependencies..."
npm install lucide-react @radix-ui/react-alert-dialog @radix-ui/react-dialog @radix-ui/react-dropdown-menu @radix-ui/react-label @radix-ui/react-select @radix-ui/react-slot @radix-ui/react-tabs class-variance-authority clsx

# Create directory structure
log "Creating project structure..."
mkdir -p src/{components,styles}

# Configure Nginx
log "Configuring Nginx..."
cat > $NGINX_CONFIG <<EOL
server {
    listen 80;
    listen [::]:80;
    server_name $PUBLIC_IP;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }

    # Enable gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 10240;
    gzip_proxied expired no-cache no-store private auth;
    gzip_types text/plain text/css text/xml text/javascript application/x-javascript application/xml application/javascript;
    gzip_disable "MSIE [1-6]\.";

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-XSS-Protection "1; mode=block";
    add_header X-Content-Type-Options "nosniff";
    add_header Referrer-Policy "no-referrer-when-downgrade";
}
EOL

# Enable Nginx site
ln -sf $NGINX_CONFIG /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Create the main page component
log "Creating main page component..."
cat > $APP_DIR/src/app/page.tsx <<EOL
'use client';

import React from 'react';

export default function Home() {
  return (
    <div className="min-h-screen flex flex-col">
      {/* Navigation */}
      <nav className="bg-white shadow-md">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between h-16 items-center">
            <div className="text-2xl font-bold text-blue-600">MyDello</div>
            <div className="hidden md:flex space-x-8">
              <a href="#" className="text-gray-700 hover:text-blue-600">Home</a>
              <a href="#" className="text-gray-700 hover:text-blue-600">Flights</a>
              <a href="#" className="text-gray-700 hover:text-blue-600">Hotels</a>
              <a href="#" className="text-gray-700 hover:text-blue-600">Packages</a>
            </div>
            <button className="bg-blue-600 text-white px-6 py-2 rounded-lg hover:bg-blue-700 transition-colors">
              Sign In
            </button>
          </div>
        </div>
      </nav>

      {/* Hero Section */}
      <div className="bg-gradient-to-r from-blue-600 to-blue-800 text-white py-16">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
          <h1 className="text-4xl md:text-6xl font-bold mb-6">Travel Made Simple</h1>
          <p className="text-xl md:text-2xl mb-8 text-blue-100">
            Discover the world with our best deals
          </p>
        </div>
      </div>

      {/* Main Content */}
      <main className="flex-grow max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
          {/* Hotels Card */}
          <div className="bg-white rounded-lg shadow-lg overflow-hidden">
            <div className="p-6">
              <h2 className="text-2xl font-bold mb-4">Hotels</h2>
              <p className="text-gray-600 mb-6">Find the best hotels deals</p>
              <button className="w-full bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 transition-colors">
                Search Hotels
              </button>
            </div>
          </div>

          {/* Flights Card */}
          <div className="bg-white rounded-lg shadow-lg overflow-hidden">
            <div className="p-6">
              <h2 className="text-2xl font-bold mb-4">Flights</h2>
              <p className="text-gray-600 mb-6">Find the best flights deals</p>
              <button className="w-full bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 transition-colors">
                Search Flights
              </button>
            </div>
          </div>

          {/* Packages Card */}
          <div className="bg-white rounded-lg shadow-lg overflow-hidden">
            <div className="p-6">
              <h2 className="text-2xl font-bold mb-4">Packages</h2>
              <p className="text-gray-600 mb-6">Find the best packages deals</p>
              <button className="w-full bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 transition-colors">
                Search Packages
              </button>
            </div>
          </div>
        </div>
      </main>

      {/* Footer */}
      <footer className="bg-gray-800 text-white py-8">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
          <p>&copy; 2025 MyDello. All rights reserved.</p>
        </div>
      </footer>
    </div>
  );
}
EOL

# Update layout.tsx
cat > $APP_DIR/src/app/layout.tsx <<EOL
import './globals.css'
import type { Metadata } from 'next'
import { Inter } from 'next/font/google'

const inter = Inter({ subsets: ['latin'] })

export const metadata: Metadata = {
  title: 'MyDello - Travel Made Simple',
  description: 'Find the best travel deals with MyDello',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en">
      <body className={inter.className}>{children}</body>
    </html>
  )
}
EOL

# Update globals.css
cat > $APP_DIR/src/app/globals.css <<EOL
@tailwind base;
@tailwind components;
@tailwind utilities;
EOL

# Set correct permissions
log "Setting permissions..."
chown -R www-data:www-data $APP_DIR
chmod -R 755 $APP_DIR

# Build the application
log "Building the application..."
cd $APP_DIR
npm run build

# Create PM2 ecosystem file
cat > ecosystem.config.js <<EOL
module.exports = {
  apps: [{
    name: 'mydello',
    script: 'npm',
    args: 'start',
    cwd: '${APP_DIR}',
    env: {
      NODE_ENV: 'production',
      PORT: 3000
    }
  }]
}
EOL

# Start PM2 with the application
log "Starting application with PM2..."
pm2 start ecosystem.config.js
pm2 save

# Enable PM2 startup script
log "Enabling PM2 startup script..."
pm2 startup systemd -u www-data --hp $APP_DIR
systemctl enable pm2-www-data

# Restart Nginx
log "Restarting Nginx..."
systemctl restart nginx

# Final message
echo "================================================================"
echo "Installation Completed Successfully!"
echo "----------------------------------------------------------------"
echo "Your website is now available at: http://$PUBLIC_IP"
echo "You can manage the application using PM2 commands:"
echo "  - pm2 status"
echo "  - pm2 logs mydello"
echo "  - pm2 restart mydello"
echo "================================================================"
