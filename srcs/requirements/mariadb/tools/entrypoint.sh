#!/bin/bash
set -e

if ! mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "USE mysql;" >/dev/null 2>&1; then
    echo "Database not initialized, running init script..."
    /docker-entrypoint-initdb.d/init.sh
else
    echo "Database already initialized, skipping init."
fi

echo "STARTING MARIADB..."
exec mysqld_safe