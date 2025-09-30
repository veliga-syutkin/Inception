#!/bin/bash
# service mysql start
echo "Initializing database..."

mariadb -h localhost -e "CREATE DATABASE IF NOT EXISTS $MYSQL_DATABASE;"
mariadb -h localhost -e "DROP USER IF EXISTS '$MYSQL_USER'@'%';"
mariadb -h localhost -e "DROP USER IF EXISTS '$MYSQL_USER'@'localhost';"
mariadb -h localhost -e "CREATE USER '$MYSQL_USER'@'localhost' IDENTIFIED BY '$MYSQL_PASSWORD';"
mariadb -h localhost -e "GRANT ALL PRIVILEGES ON $MYSQL_DATABASE.* TO '$MYSQL_USER'@'localhost';"
mariadb -h localhost -e "CREATE USER '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD';"
mariadb -h localhost -e "GRANT ALL PRIVILEGES ON $MYSQL_DATABASE.* TO '$MYSQL_USER'@'%';"
mariadb -h localhost -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD' WITH GRANT OPTION;"
mariadb -h localhost -e "FLUSH PRIVILEGES;"		# Apply changes
echo "Database initialized."
