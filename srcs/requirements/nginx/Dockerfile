
# Set the base image to Debian's "bookworm" version
FROM debian:bookworm

# Update the package list, upgrade installed packages, and install nginx, curl, and openssl
# Use apt-get in scripts and install required packages in one layer.
RUN apt-get update \
 && apt-get upgrade -y \
 && apt-get install -y nginx curl openssl \
 && rm -rf /var/lib/apt/lists/*

# Create a directory for SSL certificates
# Ensure SSL directory exists before generating certificate
RUN mkdir -p /etc/nginx/ssl \
# Generate a self-signed SSL certificate and private key
 && openssl req -x509 -nodes -out /etc/nginx/ssl/inception.crt -keyout /etc/nginx/ssl/inception.key \
	-subj "/C=FR/ST=IDF/L=Paris/O=42/OU=42/CN=wscherre.42.fr/UID=wscherre"

# Create a directory for the Nginx PID file
RUN mkdir -p /var/run/nginx

# Copy the Nginx configuration file into the container
COPY conf/nginx.conf /etc/nginx/nginx.conf

# Set the correct permissions for the web root directory
RUN chmod 755 /var/www/html

# Change the owner of the web root directory to the www-data user and group
RUN chown -R www-data:www-data /var/www/html

EXPOSE 443

# Set the default command to run when the container starts, keeping Nginx in the foreground
CMD [ "nginx", "-g", "daemon off;" ]

