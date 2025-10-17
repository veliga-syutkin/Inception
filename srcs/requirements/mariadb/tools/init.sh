#!/bin/bash
echo "Generating init.sql..."

HOSTNAME=$(hostname)

cat <<EOF > /docker-entrypoint-initdb.d/init.sql
-- First set up root access and privileges
ALTER USER 'root'@'localhost' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' WITH GRANT OPTION;

-- Create root access from anywhere (for development)
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD' WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON *.* TO 'root'@'$HOSTNAME' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD' WITH GRANT OPTION;

-- Create the database
CREATE DATABASE IF NOT EXISTS $MYSQL_DATABASE;

-- Set up application user
DROP USER IF EXISTS '$MYSQL_USER'@'%';
DROP USER IF EXISTS '$MYSQL_USER'@'localhost';
DROP USER IF EXISTS '$MYSQL_USER'@'wordpress.srcs_inception';

CREATE USER '$MYSQL_USER'@'localhost' IDENTIFIED BY '$MYSQL_PASSWORD';
CREATE USER '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD';
CREATE USER '$MYSQL_USER'@'wordpress.srcs_inception' IDENTIFIED BY '$MYSQL_PASSWORD';

GRANT ALL PRIVILEGES ON $MYSQL_DATABASE.* TO '$MYSQL_USER'@'localhost';
GRANT ALL PRIVILEGES ON $MYSQL_DATABASE.* TO '$MYSQL_USER'@'%';
GRANT ALL PRIVILEGES ON $MYSQL_DATABASE.* TO '$MYSQL_USER'@'wordpress.srcs_inception';

-- Make sure privileges are applied
FLUSH PRIVILEGES;
EOF

echo "init.sql generated."
