#!/bin/bash
set -e

if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "Database not initialized, running init script..."
    /docker-entrypoint-initdb.d/init.sh
else
    echo "Database already initialized, skipping init."
fi

echo "STARTING MARIADB..."
exec mysqld_safe