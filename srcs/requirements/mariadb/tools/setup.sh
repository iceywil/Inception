#!/bin/bash
set -e

# If the database directory already exists, it means the setup has been done.
# So, just start the server.
if [ -d "/var/lib/mysql/${SQL_DATABASE}" ]; then
    echo "MariaDB: Database already exists, skipping initialization."
else
    echo "MariaDB: Database not found, running initialization."
    
    # Start the MariaDB service temporarily.
    service mariadb start
    
    # Wait for it to be ready.
    for i in {1..30}; do
        if mysqladmin ping --silent; then
            break
        fi
        echo "MariaDB: Waiting for server to start..."
        sleep 1
    done

    # Run setup commands. The initial root user has no password.
    mysql -u root -e "CREATE DATABASE IF NOT EXISTS \`${SQL_DATABASE}\`;"
    mysql -u root -e "CREATE USER IF NOT EXISTS \`${SQL_USER}\`@'%' IDENTIFIED BY '${SQL_PASSWORD}';"
    mysql -u root -e "GRANT ALL PRIVILEGES ON \`${SQL_DATABASE}\`.* TO \`${SQL_USER}\`@'%' WITH GRANT OPTION;"
    mysql -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${SQL_ROOT_PASSWORD}';"
    mysql -u root -e "FLUSH PRIVILEGES;"

    # Shutdown the temporary server using the newly set root password.
    if ! mysqladmin -u root -p"${SQL_ROOT_PASSWORD}" shutdown; then
        echo "MariaDB: Failed to shutdown with password, trying without..." >&2
        mysqladmin shutdown || true
    fi
fi

# The main command for the container, runs MariaDB in the foreground.
echo "MariaDB: Starting server."
exec mysqld_safe
