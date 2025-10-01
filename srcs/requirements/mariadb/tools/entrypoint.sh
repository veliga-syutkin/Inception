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
	# remove init.sql for security reasons
	rm -f /docker-entrypoint-initdb.d/init.sql
else
    echo "[ENTRYPOINT] System tables exist, skipping init."
fi

echo "[ENTRYPOINT] Starting MariaDB..."
# If init.sql exists even when system tables are present, start server in background,
# wait until it's accepting connections, apply init.sql, then wait on the server PID
if [ -f /docker-entrypoint-initdb.d/init.sql ]; then
    echo "[ENTRYPOINT] init.sql found — starting MariaDB in background to apply it..."
    mysqld_safe &
    # wait for server socket
    for i in {1..30}; do
        if mysqladmin ping >/dev/null 2>&1; then
            echo "[ENTRYPOINT] MariaDB is up (after $i s)."
            break
        fi
        sleep 1
    done
    if ! mysqladmin ping >/dev/null 2>&1; then
        echo "[ENTRYPOINT] MariaDB did not start in time; showing error log:" >&2
        ERRLOG=$(ls /var/lib/mysql/*.err 2>/dev/null | head -n1)
        if [ -f "$ERRLOG" ]; then
            tail -80 "$ERRLOG"
        else
            echo "No MariaDB error log found in /var/lib/mysql/." >&2
        fi
        exit 1
    fi

    echo "[ENTRYPOINT] Applying /docker-entrypoint-initdb.d/init.sql..."
    mysql < /docker-entrypoint-initdb.d/init.sql || {
        echo "[ENTRYPOINT] Applying init.sql failed." >&2
        exit 1
    }
    # remove init.sql to avoid re-applying it on subsequent restarts
    rm -f /docker-entrypoint-initdb.d/init.sql || true
    echo "[ENTRYPOINT] init.sql applied and removed."

    # Wait for mysqld to keep the container alive
    PIDFILE=/var/run/mysqld/mysqld.pid
    if [ -f "$PIDFILE" ]; then
        PID=$(cat "$PIDFILE")
        echo "[ENTRYPOINT] Waiting on mysqld (pid $PID) ..."
        wait $PID
    else
        # fallback: tail the error log to keep container running
        tail -f /var/log/mysql/error.log 2>/dev/null || tail -f /var/lib/mysql/*.err
    fi
else
    exec mysqld_safe || {
        echo "[ENTRYPOINT] MariaDB failed to start. Showing error log:" >&2
        ERRLOG=$(ls /var/lib/mysql/*.err 2>/dev/null | head -n1)
        if [ -f "$ERRLOG" ]; then
            tail -40 "$ERRLOG"
        else
            echo "No MariaDB error log found in /var/lib/mysql/." >&2
        fi
        exit 1
    }
fi