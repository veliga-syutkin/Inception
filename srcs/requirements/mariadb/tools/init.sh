#!/bin/bash
service mysql start
echo "Initializing database..."
sleep 5
mariadb -e "CREATE DATABASE IF NOT EXISTS $MYSQL_DATABASE;"
mariadb -e "DROP USER IF EXISTS '$MYSQL_USER'@'%';"
mariadb -e "DROP USER IF EXISTS '$MYSQL_USER'@'localhost';"
mariadb -e "CREATE USER '$MYSQL_USER'@'localhost' IDENTIFIED BY '$MYSQL_PASSWORD';"
mariadb -e "GRANT ALL PRIVILEGES ON $MYSQL_DATABASE.* TO '$MYSQL_USER'@'localhost';"
mariadb -e "CREATE USER '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD';"
mariadb -e "GRANT ALL PRIVILEGES ON $MYSQL_DATABASE.* TO '$MYSQL_USER'@'%';"
mariadb -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD' WITH GRANT OPTION;"
mariadb -e "FLUSH PRIVILEGES;"		# Apply changes
echo "Database initialized."
service mysql stop					# Getting ready for next step
