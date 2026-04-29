#!/bin/bash

# ==========================================
# TechStart Solutions - Web Server Setup
# ==========================================

set -e
trap 'echo "Error occurred at line $LINENO. Exit code: $?"' ERR

LOG_FILE="/var/log/techstart-setup.log"
APP_DIR="/var/www/html"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root or with sudo"
    exit 1
fi

touch "$LOG_FILE"
chmod 644 "$LOG_FILE"

log "Starting TechStart Solutions web environment setup..."

# 1. System Updates and Core Packages
log "Updating package index..."
apt-get update

log "Installing Nginx, UFW, Curl, and OpenSSL..."
DEBIAN_FRONTEND=noninteractive apt-get install -y nginx ufw curl openssl

# 2. Generate Self-Signed SSL Certificate
log "Generating self-signed SSL certificate..."

openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/ssl/private/nginx-selfsigned.key \
    -out /etc/ssl/certs/nginx-selfsigned.crt \
    -subj "/C=IL/ST=South/L=Sderot/O=TechStart Solutions/OU=IT/CN=techstart.local"

chmod 600 /etc/ssl/private/nginx-selfsigned.key
chmod 644 /etc/ssl/certs/nginx-selfsigned.crt

# 3. Configure Nginx
log "Configuring Nginx for HTTP and HTTPS..."

cat << 'EOF' > /etc/nginx/sites-available/default
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    listen 443 ssl default_server;
    listen [::]:443 ssl default_server;

    ssl_certificate /etc/ssl/certs/nginx-selfsigned.crt;
    ssl_certificate_key /etc/ssl/private/nginx-selfsigned.key;

    root /var/www/html;
    index index.html index.htm index.nginx-debian.html;
    server_name _;

    location / {
        try_files $uri $uri/ =404;
    }
}
EOF

# 4. Create Demo Website
log "Deploying TechStart static website..."

mkdir -p "$APP_DIR"

cat << 'EOF' > "$APP_DIR/index.html"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>TechStart Solutions - WebStore</title>
    <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="bg-gray-50 text-gray-800 font-sans min-h-screen flex flex-col">
    <nav class="bg-blue-600 text-white shadow-md">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4 flex justify-between items-center">
            <div class="text-2xl font-bold">TechStart Solutions</div>
            <div class="hidden md:flex space-x-6">
                <a href="#" class="hover:text-blue-200">Dashboard</a>
                <a href="#" class="hover:text-blue-200">Store</a>
            </div>
        </div>
    </nav>

    <main class="flex-grow max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-16 text-center">
        <h1 class="text-5xl font-extrabold text-gray-900 mb-6">Welcome to the WebStore</h1>
        <p class="text-xl text-gray-600 mb-8">Your frontend server is successfully routing traffic.</p>

        <div class="bg-white p-6 rounded-lg shadow-sm border border-gray-200 inline-block text-left">
            <h2 class="text-lg font-semibold border-b pb-2 mb-4">System Status</h2>
            <ul class="space-y-2 text-green-600 font-mono text-sm">
                <li>✓ Nginx Web Server: Active</li>
                <li>✓ Port 80 HTTP: Open</li>
                <li>✓ Port 443 HTTPS: Open</li>
                <li>✓ NSG / Cloud Firewall: Ready for validation</li>
            </ul>
        </div>
    </main>

    <footer class="bg-gray-800 text-white py-6 text-center text-sm">
        <p>&copy; 2026 TechStart Solutions Lab Environment.</p>
    </footer>
</body>
</html>
EOF

# 5. Permissions
log "Setting file permissions..."

chown -R www-data:www-data "$APP_DIR"
chmod -R 755 "$APP_DIR"

# 6. Firewall Configuration
log "Configuring UFW firewall..."

ufw allow 'Nginx Full'
ufw allow OpenSSH
ufw --force enable

# 7. Validate and Restart Nginx
log "Testing Nginx configuration..."

nginx -t

log "Restarting and enabling Nginx..."

systemctl enable nginx
systemctl restart nginx

# 8. Final Status
PUBLIC_IP=$(curl -s --max-time 5 ifconfig.me || echo "UNKNOWN")

echo "================================================================"
echo "TechStart Installation Completed Successfully!"
echo "----------------------------------------------------------------"
echo "HTTP Access:  http://$PUBLIC_IP"
echo "HTTPS Access: https://$PUBLIC_IP"
echo "Note: HTTPS uses a self-signed certificate, so a browser warning is expected."
echo "Log file: /var/log/techstart-setup.log"
echo "================================================================"

log "TechStart setup completed successfully."
