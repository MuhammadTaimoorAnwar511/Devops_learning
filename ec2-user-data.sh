#!/bin/bash

# Update and upgrade system packages
sudo apt update -y
sudo apt upgrade -y

# Install Node.js and npm
sudo apt install nodejs -y
sudo apt install npm -y
sudo npm install -g serve pm2

# Install and configure Nginx
sudo apt install nginx -y
sudo systemctl start nginx
sudo systemctl enable nginx
sudo rm /etc/nginx/sites-enabled/default
sudo systemctl restart nginx

# Install and configure Docker
sudo apt-get install docker.io -y
sudo chmod 666 /var/run/docker.sock
sudo systemctl start docker
sudo systemctl enable docker
sudo apt install docker-compose
# Optional: Print completion message
echo "Initial setup completed successfully!"
