#!/bin/bash
DATADIR="/var/lib/mysql"
INIT_SQL="/docker-entrypoint-initdb.d/init.sql"

echo "[ENTRYPOINT] Checking for init.sql..."

# Initialize database if not already done
if [ ! -d "$DATADIR/mysql" ]; then
    echo "[ENTRYPOINT] Initializing MariaDB data directory..."
    mysql_install_db --datadir="$DATADIR" --user=mysql >/dev/null
fi

# check if init.sql does not exist
if [ ! -f "$INIT_SQL" ]; then
	echo "[ENTRYPOINT] init.sql not found, generating a new one..."
	# run the initializer script directly (it writes the SQL file itself)
	sh /docker-entrypoint-initdb.d/init.sh
	echo "[ENTRYPOINT] Applying init.sql..."
	
	# start a temporary MariaDB instance in the background so we can apply the SQL
	# use --skip-networking to avoid exposing it during init
	# Initialize with no password for root to allow first connection
	# Ensure mysql directory exists and has correct permissions
	echo "[ENTRYPOINT] Setting up MySQL runtime directory..."
	mkdir -p /var/run/mysqld
	chown -R mysql:mysql /var/run/mysqld
	chmod -R 777 /var/run/mysqld
	echo "[ENTRYPOINT] MySQL runtime directory configured"

	# Start MySQL with debugging and socket configuration
	mysqld_safe --skip-networking --skip-grant-tables --socket=/var/run/mysqld/mysqld.sock &
	MYSQL_PID=$!

	# wait for the server to be ready (timeout after 30s)
	echo "[ENTRYPOINT] Waiting for MariaDB to be ready..."
	
	_ready=0
	for i in {1..30}; do
		if mysqladmin ping -u root --silent; then
			echo "[ENTRYPOINT] MariaDB is ready"
			_ready=1
			break
		fi
		echo "[ENTRYPOINT] Still waiting... attempt $i/30"
		sleep 1
	done

	if [ "$_ready" -ne 1 ]; then
		echo "[ENTRYPOINT] MariaDB did not become ready in time"
		kill "$MYSQL_PID" >/dev/null 2>&1 || true
		exit 1
	fi

	# When using skip-grant-tables, we don't need authentication
	echo "[ENTRYPOINT] Testing connection..."
	
	echo "[ENTRYPOINT] Checking MySQL status before connection..."
	ps aux | grep mysql
	echo "[ENTRYPOINT] Socket directory contents:"
	ls -la /var/run/mysqld/
	
	echo "[ENTRYPOINT] Attempting connection with verbose output..."
	if ! mysql --skip-password --protocol=socket -h localhost -v -e "SELECT 1" > >(tee /tmp/mysql.log) 2>&1; then
		echo "[ENTRYPOINT] Connection failed. Debug information:"
		echo "MySQL Log output:"
		cat /tmp/mysql.log
		echo "Process status:"
		ps aux | grep mysql
		echo "Socket status:"
		ls -l /var/run/mysqld/
		echo "Socket permissions:"
		stat /var/run/mysqld/mysqld.sock || true
		echo "Current user:"
		id
		kill "$MYSQL_PID" >/dev/null 2>&1 || true
		exit 1
	fi
	echo "[ENTRYPOINT] Test connection successful"

	# apply the SQL using the mysql client and check return code
	echo "[ENTRYPOINT] Executing initialization SQL..."
	if mysql --skip-password --protocol=socket -h localhost --verbose < "$INIT_SQL" 2>&1; then
		echo "[ENTRYPOINT] Database initialization successful"
	else
		echo "[ENTRYPOINT] Failed to initialize database"
		echo "[ENTRYPOINT] SQL Error output:"
		mysql --skip-password --protocol=socket -h localhost < "$INIT_SQL" 2>&1 || true
		kill "$MYSQL_PID" >/dev/null 2>&1 || true
		exit 1
	fi

	# shutdown the temporary server so we can start it normally below
	if ! mysqladmin --skip-password --protocol=socket -h localhost shutdown; then
		echo "[ENTRYPOINT] Failed to shutdown temporary server"
		kill "$MYSQL_PID" >/dev/null 2>&1 || true
		exit 1
	fi

	echo "[ENTRYPOINT] Erasing init.sql content..."
	echo "" > $INIT_SQL
fi

echo "[ENTRYPOINT] Starting MariaDB..."
exec mysqld_safe