#!/bin/bash

# Define variables
WEB_DIR="/var/www/html"
NGINX_CONFIG="/etc/nginx/sites-available/default"
STYLES_FILE="$WEB_DIR/styles.css"
SCRIPT_FILE="$WEB_DIR/script.js"

echo "Updating system and installing Nginx..."
sudo apt update && sudo apt upgrade -y
sudo apt install -y nginx curl

echo "Fetching Public IP..."
PUBLIC_IP=$(curl -s ifconfig.me)

echo "Configuring Nginx to listen on the VM's Public IP ($PUBLIC_IP)..."

# Configure Nginx to listen on the VM’s Public IP
sudo tee $NGINX_CONFIG > /dev/null <<EOL
server {
    listen 80;
    listen [::]:80;
    
    server_name $PUBLIC_IP;

    root $WEB_DIR;
    index index.html;
    
    location / {
        try_files \$uri \$uri/ =404;
    }
}
EOL

echo "Creating MyDello website..."

# Remove default Nginx page
sudo rm -rf $WEB_DIR/*

# Shared navigation bar for all pages
NAV_BAR="<nav>
    <ul>
        <li><a href='index.html'>Home</a></li>
        <li><a href='about.html'>About Us</a></li>
        <li><a href='services.html'>Services</a></li>
        <li><a href='contact.html'>Contact</a></li>
    </ul>
</nav>"

# Create Home Page
sudo tee $WEB_DIR/index.html > /dev/null <<EOL
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>MyDello - Booking Made Easy</title>
    <link rel="stylesheet" href="styles.css">
    <script defer src="script.js"></script>
</head>
<body>
    <header>
        <h1>Welcome to MyDello</h1>
        <p>Your one-stop booking solution.</p>
    </header>
    $NAV_BAR
    <main>
        <section class="booking">
            <h2>Book Your Stay</h2>
            <form id="bookingForm">
                <label for="name">Full Name:</label>
                <input type="text" id="name" name="name" required>

                <label for="email">Email:</label>
                <input type="email" id="email" name="email" required>

                <label for="date">Booking Date:</label>
                <input type="date" id="date" name="date" required>

                <button type="submit">Submit Booking</button>
                <p id="confirmationMessage"></p>
            </form>
        </section>
    </main>
    <footer>
        <p>&copy; 2025 MyDello.com | All rights reserved.</p>
    </footer>
</body>
</html>
EOL

# Create About Us Page
sudo tee $WEB_DIR/about.html > /dev/null <<EOL
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>About Us - MyDello</title>
    <link rel="stylesheet" href="styles.css">
</head>
<body>
    <header>
        <h1>About MyDello</h1>
        <p>Learn more about our journey and values.</p>
    </header>
    $NAV_BAR
    <main>
        <section>
            <h2>Our Story</h2>
            <p>MyDello was founded to simplify the booking experience for travelers worldwide.</p>
        </section>
    </main>
    <footer>
        <p>&copy; 2025 MyDello.com | All rights reserved.</p>
    </footer>
</body>
</html>
EOL

# Create Services Page
sudo tee $WEB_DIR/services.html > /dev/null <<EOL
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Services - MyDello</title>
    <link rel="stylesheet" href="styles.css">
</head>
<body>
    <header>
        <h1>Our Services</h1>
        <p>Discover the range of booking services we offer.</p>
    </header>
    $NAV_BAR
    <main>
        <section>
            <h2>Booking Options</h2>
            <ul>
                <li>Hotel Reservations</li>
                <li>Flight Bookings</li>
                <li>Car Rentals</li>
                <li>Tour Packages</li>
            </ul>
        </section>
    </main>
    <footer>
        <p>&copy; 2025 MyDello.com | All rights reserved.</p>
    </footer>
</body>
</html>
EOL

# Create Contact Page
sudo tee $WEB_DIR/contact.html > /dev/null <<EOL
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Contact Us - MyDello</title>
    <link rel="stylesheet" href="styles.css">
    <script defer src="script.js"></script>
</head>
<body>
    <header>
        <h1>Contact MyDello</h1>
        <p>Get in touch with our support team.</p>
    </header>
    $NAV_BAR
    <main>
        <section>
            <h2>Contact Form</h2>
            <form id="contactForm">
                <label for="name">Your Name:</label>
                <input type="text" id="name" name="name" required>

                <label for="message">Your Message:</label>
                <textarea id="message" name="message" required></textarea>

                <button type="submit">Send Message</button>
                <p id="contactMessage"></p>
            </form>
        </section>
    </main>
    <footer>
        <p>&copy; 2025 MyDello.com | All rights reserved.</p>
    </footer>
</body>
</html>
EOL

# Create CSS File
sudo tee $STYLES_FILE > /dev/null <<EOL
body { font-family: Arial, sans-serif; text-align: center; background: #f4f4f4; }
header { background: #007bff; color: white; padding: 20px; }
nav ul { list-style: none; padding: 0; }
nav li { display: inline; margin: 10px; }
nav a { text-decoration: none; color: #007bff; }
footer { background: #222; color: white; padding: 10px; position: fixed; bottom: 0; width: 100%; }
EOL

echo "Restarting Nginx..."
sudo systemctl restart nginx

echo "Deployment complete! Access the site at: http://$PUBLIC_IP"
