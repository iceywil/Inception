#!/bin/bash
set -euo pipefail

# This script automates the setup of a WordPress installation.

# Create the necessary directories for WordPress files.
mkdir -p /var/www/html
cd /var/www/html

# Download WP-CLI if not already present
if [ ! -x /usr/local/bin/wp ]; then
	echo "Installing wp-cli..."
	curl -s -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
	chmod +x wp-cli.phar
	mv wp-cli.phar /usr/local/bin/wp
fi

# Download the latest version of WordPress core files if not already present
if [ ! -f index.php ]; then
	echo "Downloading WordPress core..."
	wp core download --allow-root
fi

# Copy the wp-config template into place
cp /wp-config.php /var/www/html/wp-config.php

# Replace placeholder database credentials in wp-config.php with actual values from environment variables.
# Use '|' as delimiter to avoid errors if values contain '/'. Use global replacement for safety.
sed -i "s|db1|${SQL_DATABASE}|g" wp-config.php
sed -i "s|user|${SQL_USER}|g" wp-config.php
sed -i "s|pwd|${SQL_PASSWORD}|g" wp-config.php

# Wait for MariaDB to become reachable before attempting WP install. This avoids intermittent failures
# when the WordPress container starts before the DB is ready.
echo "Waiting for MariaDB at 'mariadb' to accept connections..."
max_attempts=100
attempt=0
until mysql -h mariadb -u"${SQL_USER}" -p"${SQL_PASSWORD}" -e 'SELECT 1;' >/dev/null 2>&1; do
	attempt=$((attempt+1))
	if [ "$attempt" -ge "$max_attempts" ]; then
		echo "ERROR: Could not connect to MariaDB after ${max_attempts} attempts." >&2
		echo "Dumping current /var/www/html/wp-config.php for debugging:" >&2
		sed -n '1,200p' wp-config.php >&2 || true
		exit 1
	fi
	echo "MariaDB not ready yet (attempt ${attempt}/${max_attempts}), sleeping 2s..."
	sleep 5
done
echo "MariaDB is reachable. Proceeding with WordPress setup."

# Run the WordPress installation process only if the site isn't already installed
if ! wp core is-installed --allow-root >/dev/null 2>&1; then
	echo "Running wp core install..."
	wp core install --url="${DOMAIN_NAME}/" --title="${WP_TITLE}" --admin_user="${WP_ADMIN_USR}" --admin_password="${WP_ADMIN_PWD}" --admin_email="${WP_ADMIN_EMAIL}" --skip-email --allow-root

	# Create an additional WordPress user with the 'author' role.
	wp user create "${WP_USR}" "${WP_EMAIL}" --role=author --user_pass="${WP_PWD}" --allow-root || true

	# Install and activate the 'Astra' theme if available
	wp theme install astra --activate --allow-root || true
else
	echo "WordPress already installed, skipping wp core install."
fi

# Ensure correct ownership so the webserver can read/write files
chown -R www-data:www-data /var/www/html || true

# Configure PHP-FPM to listen on port 9000 (TCP) rather than socket
sed -i 's|listen = /run/php/php8.2-fpm.sock|listen = 9000|g' /etc/php/8.2/fpm/pool.d/www.conf || true

# Ensure /run/php exists
mkdir -p /run/php

# Start PHP-FPM in foreground
exec /usr/sbin/php-fpm8.2 -F -R