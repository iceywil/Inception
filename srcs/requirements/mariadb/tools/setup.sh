#!/bin/bash

mysqld_safe &

for i in {1..30}; do
  if mysqladmin ping --silent; then
    break
  fi
  echo "En attente de MariaDB..."
  sleep 1
done


# mysqladmin -u root password ${DB_ROOT_PASSWORD}

mysql -u root -e "ALTER USER root@localhost IDENTIFIED BY '${SQL_ROOT_PASSWORD}';"
mysql -u root -p${SQL_ROOT_PASSWORD} -e "CREATE USER IF NOT EXISTS ${SQL_USER}@'%' IDENTIFIED BY '${SQL_PASSWORD}';"
mysql -u root -p${SQL_ROOT_PASSWORD} -e "CREATE DATABASE IF NOT EXISTS ${SQL_DATABASE};"
mysql -u root -p${SQL_ROOT_PASSWORD} -e "GRANT ALL PRIVILEGES ON ${SQL_DATABASE}.* TO ${SQL_USER};"

mysqladmin -p${SQL_ROOT_PASSWORD} shutdown

exec mysqld_safe