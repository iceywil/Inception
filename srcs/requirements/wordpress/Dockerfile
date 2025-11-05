# Set the base image to Debian's "bookworm" version
FROM debian:bookworm

# Update the package list
RUN apt update
# Upgrade installed packages to their latest versions
RUN apt upgrade -y

# Install wget and curl utilities
RUN apt-get -y install wget curl

# Install PHP 8.2 and required extensions for WordPress, along with the MariaDB client
# Install PHP 8.2 to match the auto_config.sh expectations (it edits /etc/php/8.2/...)
RUN apt-get install -y \
	php8.2 \
	php8.2-fpm \
	php8.2-mysql \
	mariadb-client

# Copy the configuration files and scripts into a temporary directory in the container
# Don't run site-setup at build time. Copy the helper scripts and run them when the
# container starts so the runtime services (php-fpm/mysql) are available.
COPY conf/ /tmp/tools/
# Make the auto_config.sh script executable
RUN chmod +x /tmp/tools/auto_config.sh

# Copy the WordPress configuration template to a known path for use by the auto_config.sh script
# Provide wp-config template at a known path used by auto_config.sh
COPY conf/wp-config.php /wp-config.php

# Set the default command to run the auto_config.sh script when the container starts
CMD ["/bin/bash", "/tmp/tools/auto_config.sh"]
