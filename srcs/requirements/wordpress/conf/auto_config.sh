#!/bin/bash

# This script automates the setup of a WordPress installation.

# Create the necessary directories for WordPress files.
# These directories will be used by the Nginx container to serve the website.
mkdir -p /var/www/html

# Navigate into the web root directory.
cd /var/www/html

# Remove any existing files in the directory to ensure a clean installation.
rm -rf *

# Download the WordPress command-line interface (WP-CLI) from its official repository.
# WP-CLI is a tool to manage WordPress installations from the command line.
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar 

# Make the downloaded WP-CLI phar file executable.
chmod +x wp-cli.phar 

# Move the WP-CLI executable to a directory in the system's PATH, so it can be run as 'wp'.
mv wp-cli.phar /usr/local/bin/wp

# Download the latest version of WordPress core files.
# --allow-root is used because this script is run as the root user in the Docker container.
wp core download --allow-root

# The wp-config.php file is copied from the container's filesystem to the WordPress directory.
cp /wp-config.php /var/www/html/wp-config.php

# Replace placeholder database credentials in wp-config.php with actual values from environment variables.
# These variables (SQL_DATABASE, SQL_USER, SQL_PASSWORD) are passed to the container from the .env file.
sed -i -r "s/db1/$SQL_DATABASE/1"   wp-config.php
sed -i -r "s/user/$SQL_USER/1"  wp-config.php
sed -i -r "s/pwd/$SQL_PASSWORD/1"    wp-config.php

# Run the WordPress installation process.
# This sets up the site URL, title, admin user, and email.
# --skip-email prevents sending an email notification upon installation.
wp core install --url=$DOMAIN_NAME/ --title=$WP_TITLE --admin_user=$WP_ADMIN_USR --admin_password=$WP_ADMIN_PWD --admin_email=$WP_ADMIN_EMAIL --skip-email --allow-root

# Create an additional WordPress user with the 'author' role.
wp user create $WP_USR $WP_EMAIL --role=author --user_pass=$WP_PWD --allow-root

# Install and activate the 'Astra' theme.
wp theme install astra --activate --allow-root

# Change ownership of all files to www-data so nginx can read them
chown -R www-data:www-data /var/www/html

# Configure PHP-FPM to listen on port 9000, which is how Nginx will communicate with it.
# This changes the default socket-based communication to TCP/IP.
sed -i 's/listen = \/run\/php\/php8.2-fpm.sock/listen = 9000/g' /etc/php/8.2/fpm/pool.d/www.conf

# Create the directory for the PHP-FPM runtime.
mkdir -p /run/php

# Start the PHP-FPM service in the foreground.
# -F ensures it runs in the foreground, which is necessary for Docker containers.
# -R allows the process to run as root.
exec /usr/sbin/php-fpm8.2 -F -R