#!/bin/bash
set -euo pipefail

DATADIR="/var/lib/mysql"

echo "[ENTRYPOINT] Checking MariaDB system tables..."

if [ ! -f "$DATADIR/mysql/user.frm" ]; then
    echo "[ENTRYPOINT] No system tables found, initializing database..."
    /docker-entrypoint-initdb.d/init.sh # Generate init.sql
    mysql_install_db --user=mysql --datadir="$DATADIR"
	echo "[ENTRYPOINT] Running init SQL..."
	mysqld --user=mysql --skip-networking --bootstrap < /docker-entrypoint-initdb.d/init.sql
	echo "[ENTRYPOINT] Database initialized."
else
    echo "[ENTRYPOINT] System tables exist, skipping init."
fi

echo "[ENTRYPOINT] Starting MariaDB..."
exec mysqld_safe --nowatch || {
    echo "[ENTRYPOINT] MariaDB failed to start. Showing error log:" >&2
    ERRLOG=$(ls /var/lib/mysql/*.err 2>/dev/null | head -n1)
    if [ -f "$ERRLOG" ]; then
        tail -40 "$ERRLOG"
    else
        echo "No MariaDB error log found in /var/lib/mysql/." >&2
    fi
    exit 1
}