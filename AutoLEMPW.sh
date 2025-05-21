#!/bin/bash

# WordPress + LEMP Stack Setup Script with Error Handling
# Author: Aizhee
# Description: Automates the setup of WordPress with LEMP stack

#######################################
# COLORS AND STYLING
#######################################
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

#######################################
# HELPER FUNCTIONS
#######################################
print_banner() {
    clear
    echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                                                        ║${NC}"
    echo -e "${BLUE}║  ${BOLD}WordPress + LEMP Stack Setup${NC}${BLUE}                          ║${NC}"
    echo -e "${BLUE}║  ${CYAN}Automated installation and configuration tool${NC}${BLUE}         ║${NC}"
    echo -e "${BLUE}║                                                        ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_section() {
    echo ""
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}$1${NC}"
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

success_msg() {
    echo -e "${GREEN}✓ $1${NC}"
}

info_msg() {
    echo -e "${CYAN}➜ $1${NC}"
}

warning_msg() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

error_msg() {
    echo -e "${RED}✗ $1${NC}"
}

exit_with_error() {
    error_msg "$1"
    echo ""
    error_msg "Setup failed. Please check the error message above."
    exit 1
}

check_command() {
    if ! command -v "$1" &> /dev/null; then
        warning_msg "$1 not found. Attempting to install..."
        return 1
    else
        return 0
    fi
}

progress_bar() {
    local duration=$1
    local bar_size=40
    local elapsed=0
    local increment=$(bc <<< "scale=2; $duration/$bar_size")
    
    echo -e -n "${BLUE}["
    
    for ((i=0; i<bar_size; i++)); do
        echo -e -n " "
    done
    
    echo -e -n "]${NC} 0%"
    
    echo -e -n "\r${BLUE}["
    
    for ((i=0; i<bar_size; i++)); do
        sleep $increment
        echo -e -n "█"
        elapsed=$(bc <<< "scale=2; $elapsed+$increment")
        local percent=$(bc <<< "scale=0; ($elapsed/$duration)*100")
        echo -e -n "\r${BLUE}["
        for ((j=0; j<=i; j++)); do
            echo -e -n "█"
        done
        for ((j=i+1; j<bar_size; j++)); do
            echo -e -n " "
        done
        echo -e -n "]${NC} $percent%"
    done
    echo ""
}

# Check for required dependencies
check_dependencies() {
    print_section "Checking Dependencies"
    
    # Check if running as root or with sudo privileges
    if [[ $EUID -ne 0 ]] && ! sudo -n true 2>/dev/null; then
        exit_with_error "This script requires sudo privileges. Please run with sudo or as root."
    fi
    
    # Check for essential commands
    for cmd in wget curl unzip; do
        info_msg "Checking for $cmd..."
        if ! check_command $cmd; then
            info_msg "Installing $cmd..."
            sudo apt update &>/dev/null
            sudo apt install -y $cmd || exit_with_error "Failed to install $cmd"
            success_msg "$cmd installed successfully"
        else
            success_msg "$cmd is already installed"
        fi
    done
}

#######################################
# MAIN SCRIPT
#######################################
set -o errexit  # Exit on error
set -o pipefail # Exit on pipe error
set -o nounset  # Exit on undefined variable

# Handle errors
trap 'echo -e "${RED}An error occurred. Exiting...${NC}"; exit 1' ERR

# Start the script
print_banner
echo -e "${CYAN}This script will install and configure a LEMP stack with WordPress.${NC}"
echo -e "${YELLOW}Please ensure you have sudo privileges to run this script.${NC}"
echo ""
echo -e "${BOLD}Press Enter to continue or Ctrl+C to cancel...${NC}"
read -r

# Check dependencies
check_dependencies

# Prompt for user inputs with validation
print_section "Configuration Settings"

# Domain/site name with validation
while true; do
    read -p "$(echo -e ${BOLD}"Enter domain or folder name for site (e.g., example.com): "${NC})" SITE_NAME
    if [[ -z "$SITE_NAME" ]]; then
        warning_msg "Site name cannot be empty. Please try again."
    elif [[ "$SITE_NAME" =~ [^a-zA-Z0-9.-] ]]; then
        warning_msg "Site name contains invalid characters. Use only letters, numbers, dots, and hyphens."
    else
        success_msg "Site name set to: $SITE_NAME"
        break
    fi
done

# Web root path with validation
WEB_ROOT="/var/www/$SITE_NAME"
read -p "$(echo -e ${BOLD}"Enter the full path to the web root [${CYAN}$WEB_ROOT${NC}${BOLD}]: "${NC})" WEB_ROOT_INPUT
if [[ ! -z "$WEB_ROOT_INPUT" ]]; then
    WEB_ROOT="$WEB_ROOT_INPUT"
fi
success_msg "Web root set to: $WEB_ROOT"

# MySQL root password with validation
while true; do
    read -sp "$(echo -e ${BOLD}"Enter MySQL root password: "${NC})" MYSQL_ROOT_PASS
    echo ""
    if [[ -z "$MYSQL_ROOT_PASS" ]]; then
        warning_msg "MySQL root password cannot be empty. Please try again."
    elif [[ ${#MYSQL_ROOT_PASS} -lt 8 ]]; then
        warning_msg "Password should be at least 8 characters long. Please try again."
    else
        read -sp "$(echo -e ${BOLD}"Confirm MySQL root password: "${NC})" MYSQL_ROOT_PASS_CONFIRM
        echo ""
        if [[ "$MYSQL_ROOT_PASS" != "$MYSQL_ROOT_PASS_CONFIRM" ]]; then
            warning_msg "Passwords don't match. Please try again."
        else
            success_msg "MySQL root password set successfully"
            break
        fi
    fi
done

# Database name with validation
while true; do
    read -p "$(echo -e ${BOLD}"Enter name for new MySQL database [${CYAN}${SITE_NAME//./_}_db${NC}${BOLD}]: "${NC})" DB_NAME_INPUT
    DB_NAME=${DB_NAME_INPUT:-${SITE_NAME//./_}_db}
    if [[ "$DB_NAME" =~ [^a-zA-Z0-9_] ]]; then
        warning_msg "Database name contains invalid characters. Use only letters, numbers, and underscores."
    else
        success_msg "Database name set to: $DB_NAME"
        break
    fi
done

# Database user with validation
while true; do
    read -p "$(echo -e ${BOLD}"Enter MySQL username for WordPress [${CYAN}${SITE_NAME//./_}_user${NC}${BOLD}]: "${NC})" DB_USER_INPUT
    DB_USER=${DB_USER_INPUT:-${SITE_NAME//./_}_user}
    if [[ "$DB_USER" =~ [^a-zA-Z0-9_] ]]; then
        warning_msg "Username contains invalid characters. Use only letters, numbers, and underscores."
    else
        success_msg "Database user set to: $DB_USER"
        break
    fi
done

# Database password with validation and generation option
while true; do
    read -p "$(echo -e ${BOLD}"Generate a secure password? [Y/n]: "${NC})" GEN_PASS
    if [[ -z "$GEN_PASS" || "$GEN_PASS" =~ ^[Yy]$ ]]; then
        DB_PASS=$(openssl rand -base64 12)
        success_msg "Generated password: $DB_PASS"
        break
    else
        read -sp "$(echo -e ${BOLD}"Enter password for $DB_USER: "${NC})" DB_PASS
        echo ""
        if [[ -z "$DB_PASS" ]]; then
            warning_msg "Password cannot be empty. Please try again."
        elif [[ ${#DB_PASS} -lt 8 ]]; then
            warning_msg "Password should be at least 8 characters long. Please try again."
        else
            read -sp "$(echo -e ${BOLD}"Confirm password: "${NC})" DB_PASS_CONFIRM
            echo ""
            if [[ "$DB_PASS" != "$DB_PASS_CONFIRM" ]]; then
                warning_msg "Passwords don't match. Please try again."
            else
                success_msg "Database password set successfully"
                break
            fi
        fi
    fi
done

# Confirm settings before proceeding
print_section "Configuration Summary"
echo -e "Site Name:      ${CYAN}$SITE_NAME${NC}"
echo -e "Web Root:       ${CYAN}$WEB_ROOT${NC}"
echo -e "Database Name:  ${CYAN}$DB_NAME${NC}"
echo -e "Database User:  ${CYAN}$DB_USER${NC}"
echo -e "MySQL Password: ${CYAN}[HIDDEN]${NC}"
echo ""
read -p "$(echo -e ${BOLD}"Proceed with installation? [Y/n]: "${NC})" PROCEED

if [[ ! -z "$PROCEED" && ! "$PROCEED" =~ ^[Yy]$ ]]; then
    info_msg "Setup canceled by user."
    exit 0
fi

# Update and install packages
print_section "Installing LEMP Stack Components"
info_msg "Updating package repositories..."
{
    sudo apt update && 
    sudo apt upgrade -y
} || exit_with_error "Failed to update packages"
success_msg "Packages updated successfully"

info_msg "Installing NGINX, MariaDB, PHP and required components..."
{
    sudo apt install -y nginx mariadb-server php-fpm php-mysql \
    php-curl php-xml php-mbstring php-zip php-gd curl unzip wget
} || exit_with_error "Failed to install LEMP components"
success_msg "LEMP components installed successfully"

# Enable and start services
print_section "Configuring Services"
info_msg "Enabling services to start on system boot..."
{
    # Enable services to start on boot
    sudo systemctl enable nginx
    sudo systemctl enable mariadb
    
    # Also enable PHP-FPM (determine installed PHP version)
    PHP_VERSION=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')
    sudo systemctl enable php$PHP_VERSION-fpm
    
    # Verify services are enabled
    NGINX_ENABLED=$(systemctl is-enabled nginx)
    MARIADB_ENABLED=$(systemctl is-enabled mariadb)
    PHP_ENABLED=$(systemctl is-enabled php$PHP_VERSION-fpm)
    
    if [[ "$NGINX_ENABLED" == "enabled" && "$MARIADB_ENABLED" == "enabled" && "$PHP_ENABLED" == "enabled" ]]; then
        success_msg "All services configured to start automatically on system boot"
    else
        warning_msg "Some services may not start automatically on boot:"
        [[ "$NGINX_ENABLED" != "enabled" ]] && warning_msg "- Nginx: $NGINX_ENABLED"
        [[ "$MARIADB_ENABLED" != "enabled" ]] && warning_msg "- MariaDB: $MARIADB_ENABLED"
        [[ "$PHP_ENABLED" != "enabled" ]] && warning_msg "- PHP-FPM: $PHP_ENABLED"
    fi
} || warning_msg "Issues encountered while enabling services. Website may not start automatically on boot."

info_msg "Starting services..."
{
    sudo systemctl start nginx || true
    sudo systemctl start mariadb || true
    sudo systemctl start php$PHP_VERSION-fpm || true
} || warning_msg "Issues encountered while starting services. Will try to continue."

# Check if services are running
if ! systemctl is-active --quiet nginx; then
    warning_msg "NGINX is not running. Attempting to start..."
    sudo systemctl start nginx || exit_with_error "Failed to start NGINX"
fi

if ! systemctl is-active --quiet mariadb; then
    warning_msg "MariaDB is not running. Attempting to start..."
    sudo systemctl start mariadb || exit_with_error "Failed to start MariaDB"
fi

success_msg "Services started successfully"

# Secure MySQL
print_section "Configuring Database"
info_msg "Securing MySQL..."
{
    sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '$MYSQL_ROOT_PASS'; FLUSH PRIVILEGES;"
} || exit_with_error "Failed to set MySQL root password"
success_msg "MySQL secured successfully"

# Create MySQL DB and user
info_msg "Creating database and user..."
{
    sudo mysql -uroot -p"$MYSQL_ROOT_PASS" <<MYSQL_SCRIPT
CREATE DATABASE IF NOT EXISTS $DB_NAME DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;
MYSQL_SCRIPT
} || exit_with_error "Failed to create database or user"
success_msg "Database and user created successfully"

# Download WordPress
print_section "Setting Up WordPress"
info_msg "Downloading WordPress..."
{
    if [ -f "/tmp/latest.zip" ]; then
        rm /tmp/latest.zip
    fi
    if [ -d "/tmp/wordpress" ]; then
        rm -rf /tmp/wordpress
    fi
    wget -q https://wordpress.org/latest.zip -O /tmp/latest.zip
    unzip -q /tmp/latest.zip -d /tmp
} || exit_with_error "Failed to download WordPress"
success_msg "WordPress downloaded successfully"

# Move to web root
info_msg "Setting up WordPress files..."
{
    sudo mkdir -p "$WEB_ROOT"
    
    # Backup existing files if any
    if [ "$(ls -A "$WEB_ROOT" 2>/dev/null)" ]; then
        BACKUP_DIR="$WEB_ROOT.backup.$(date +%Y%m%d%H%M%S)"
        warning_msg "Web root directory not empty. Creating backup at $BACKUP_DIR"
        sudo mv "$WEB_ROOT" "$BACKUP_DIR"
        sudo mkdir -p "$WEB_ROOT"
    fi
    
    sudo cp -r /tmp/wordpress/* "$WEB_ROOT"
    sudo chown -R www-data:www-data "$WEB_ROOT"
    sudo chmod -R 755 "$WEB_ROOT"
} || exit_with_error "Failed to set up WordPress files"
success_msg "WordPress files set up successfully"

# Create wp-config.php
info_msg "Configuring wp-config.php..."
{
    sudo cp "$WEB_ROOT/wp-config-sample.php" "$WEB_ROOT/wp-config.php"
    sudo sed -i "s/database_name_here/$DB_NAME/" "$WEB_ROOT/wp-config.php"
    sudo sed -i "s/username_here/$DB_USER/" "$WEB_ROOT/wp-config.php"
    sudo sed -i "s/password_here/$DB_PASS/" "$WEB_ROOT/wp-config.php"
    
    # Add additional security settings
    sudo sed -i "/table_prefix/a define('WP_DEBUG', false);" "$WEB_ROOT/wp-config.php"
    sudo sed -i "/table_prefix/a define('DISALLOW_FILE_EDIT', true);" "$WEB_ROOT/wp-config.php"
} || exit_with_error "Failed to configure wp-config.php"
success_msg "wp-config.php configured successfully"

# Add salts
info_msg "Adding security keys and salts..."
{
    SALT=$(curl -s https://api.wordpress.org/secret-key/1.1/salt/)
    sudo sed -i "/AUTH_KEY/d;/SECURE_AUTH_KEY/d;/LOGGED_IN_KEY/d;/NONCE_KEY/d;/AUTH_SALT/d;/SECURE_AUTH_SALT/d;/LOGGED_IN_SALT/d;/NONCE_SALT/d" "$WEB_ROOT/wp-config.php"
    sudo awk -v salt="$SALT" '
        /@since 2.6.0/ { print; print salt; next }
        { print }
    ' "$WEB_ROOT/wp-config.php" | sudo tee "$WEB_ROOT/wp-config.php.tmp" > /dev/null
    sudo mv "$WEB_ROOT/wp-config.php.tmp" "$WEB_ROOT/wp-config.php"
} || exit_with_error "Failed to add security keys and salts"
success_msg "Security keys and salts added successfully"

# Setup Nginx config
print_section "Configuring NGINX"
info_msg "Creating Nginx configuration for $SITE_NAME..."
{
    NGINX_CONF="/etc/nginx/sites-available/$SITE_NAME"
    
    # Backup existing config if it exists
    if [ -f "$NGINX_CONF" ]; then
        sudo cp "$NGINX_CONF" "$NGINX_CONF.backup.$(date +%Y%m%d%H%M%S)"
    fi
    
    sudo tee "$NGINX_CONF" > /dev/null <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name $SITE_NAME www.$SITE_NAME;
    root $WEB_ROOT;

    index index.php index.html index.htm;

    # Logging
    access_log /var/log/nginx/$SITE_NAME.access.log;
    error_log /var/log/nginx/$SITE_NAME.error.log;

    # WordPress permalinks
    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    # PHP handling
    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    # Security settings
    location ~ /\.ht {
        deny all;
    }
    
    # Deny access to hidden files
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    # Cache static files
    location ~* \.(jpg|jpeg|png|gif|ico|css|js)\$ {
        expires 30d;
        add_header Cache-Control "public, no-transform";
    }
}
EOF

    # Enable the site
    sudo ln -sf "$NGINX_CONF" /etc/nginx/sites-enabled/
    
    # Remove default site if enabled
    if [ -f "/etc/nginx/sites-enabled/default" ]; then
        sudo rm /etc/nginx/sites-enabled/default
    fi
} || exit_with_error "Failed to create Nginx configuration"
success_msg "Nginx configuration created successfully"

# Test and reload Nginx
info_msg "Testing and reloading Nginx..."
{
    sudo nginx -t
    sudo systemctl reload nginx
} || exit_with_error "Nginx configuration test failed"
success_msg "Nginx configuration tested and reloaded successfully"

# Create a basic health check file
info_msg "Creating health check file..."
{
    sudo tee "$WEB_ROOT/health.php" > /dev/null <<EOF
<?php
// Health check file
header('Content-Type: application/json');
echo json_encode([
    'status' => 'ok',
    'server' => 'wordpress',
    'php_version' => PHP_VERSION,
    'time' => date('Y-m-d H:i:s'),
]);
EOF
    sudo chown www-data:www-data "$WEB_ROOT/health.php"
    sudo chmod 644 "$WEB_ROOT/health.php"
} || warning_msg "Failed to create health check file"

# Create installation summary
print_section "Installation Summary"
info_msg "Creating installation summary..."
{
    SUMMARY_FILE="$HOME/wordpress_installation_summary.txt"
    
    cat > "$SUMMARY_FILE" <<EOF
WordPress Installation Summary
=============================
Date: $(date)

Site Information:
----------------
Site Name: $SITE_NAME
Web Root: $WEB_ROOT

Database Information:
-------------------
Database Name: $DB_NAME
Database User: $DB_USER
Database Password: $DB_PASS

Access Information:
-----------------
Website URL: http://$SITE_NAME
Admin URL: http://$SITE_NAME/wp-admin

Next Steps:
----------
1. Complete the WordPress installation by visiting http://$SITE_NAME
2. Set up an SSL certificate (not required for local testing)
3. Install essential WordPress plugins for security and performance
4. Set up regular backups

Boot Configuration:
-----------------
Nginx: $NGINX_ENABLED
MariaDB: $MARIADB_ENABLED
PHP-FPM: $PHP_ENABLED

Note: If any service shows as "disabled", you can enable it with:
sudo systemctl enable [service-name]
EOF

    chmod 600 "$SUMMARY_FILE"
} || warning_msg "Failed to create installation summary"
success_msg "Installation summary created at $SUMMARY_FILE"

# VS Code installation
print_section "Additional Tools"
read -p "$(echo -e ${BOLD}"Do you want to install VS Code and open the WordPress folder? [Y/n]: "${NC})" INSTALL_VSCODE

if [[ -z "$INSTALL_VSCODE" || "$INSTALL_VSCODE" =~ ^[Yy]$ ]]; then
    # Install VS Code if not installed
    if ! command -v code &> /dev/null; then
        info_msg "Installing Visual Studio Code..."
        {
            wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
            sudo install -o root -g root -m 644 microsoft.gpg /etc/apt/trusted.gpg.d/
            sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'
            sudo apt update
            sudo apt install -y code
            rm microsoft.gpg
        } || warning_msg "Failed to install VS Code. You can install it manually later."
        success_msg "Visual Studio Code installed successfully"
    else
        success_msg "Visual Studio Code is already installed"
    fi
    
    if command -v code &> /dev/null; then
        info_msg "Opening $WEB_ROOT in VS Code..."
        code "$WEB_ROOT" || warning_msg "Failed to open VS Code"
    fi
fi

# Final message
print_section "Setup Complete"
echo -e "${GREEN}${BOLD}WordPress + LEMP stack has been successfully installed!${NC}"
echo ""
echo -e "${BOLD}Website URL:${NC} ${CYAN}http://$SITE_NAME${NC}"
echo -e "${BOLD}Admin Dashboard:${NC} ${CYAN}http://$SITE_NAME/wp-admin${NC}"
echo -e "${BOLD}Installation Summary:${NC} ${CYAN}$HOME/wordpress_installation_summary.txt${NC}"
echo ""
echo -e "${YELLOW}${BOLD}Next Steps:${NC}"
echo -e "1. Complete the WordPress installation by visiting the website URL"
echo -e "2. Set up an SSL certificate using Let's Encrypt for better security"
echo -e "3. Install essential WordPress plugins (security, caching, SEO)"
echo ""
echo -e "${YELLOW}${BOLD}Note:${NC} Nginx and MariaDB are configured to start automatically on boot."
echo ""
echo -e "${BOLD}Thank you for using the WordPress + LEMP Stack Setup Script!${NC}"
echo -e "${CYAN}Made by Aizhee${NC}"
echo ""

# Hosts file update
read -p "$(echo -e ${BOLD}"Would you like to add an entry to your /etc/hosts file for local testing? [y/N]: "${NC})" UPDATE_HOSTS

if [[ "$UPDATE_HOSTS" =~ ^[Yy]$ ]]; then
    info_msg "Adding $SITE_NAME to /etc/hosts..."
    if ! grep -q "$SITE_NAME" /etc/hosts; then
        echo "127.0.0.1 $SITE_NAME www.$SITE_NAME" | sudo tee -a /etc/hosts > /dev/null
        success_msg "Added $SITE_NAME to /etc/hosts"
    else
        success_msg "$SITE_NAME already exists in /etc/hosts"
    fi
fi

exit 0