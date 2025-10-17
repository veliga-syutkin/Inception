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

	# First create the database only
	echo "[ENTRYPOINT] Creating database..."
	if ! mysql --skip-password --protocol=socket -h localhost -e "CREATE DATABASE IF NOT EXISTS \`$MYSQL_DATABASE\`;" 2>&1; then
		echo "[ENTRYPOINT] Failed to create database"
		kill "$MYSQL_PID" >/dev/null 2>&1 || true
		exit 1
	fi
	echo "[ENTRYPOINT] Database created successfully"

	# Shutdown the temporary server
	echo "[ENTRYPOINT] Shutting down temporary server..."
	if ! mysqladmin --skip-password --protocol=socket -h localhost shutdown; then
		echo "[ENTRYPOINT] Failed to shutdown temporary server"
		kill "$MYSQL_PID" >/dev/null 2>&1 || true
		exit 1
	fi

	# Start a new instance with skip-grant-tables for user setup
	echo "[ENTRYPOINT] Starting temporary server for user setup..."
	mysqld_safe --skip-networking --skip-grant-tables --socket=/var/run/mysqld/mysqld.sock &
	MYSQL_PID=$!

	# Wait for the server to be ready
	echo "[ENTRYPOINT] Waiting for MariaDB to be ready..."
	_ready=0
	for i in {1..30}; do
		if mysqladmin --skip-password ping -u root --silent; then
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

	# First set the root password while in skip-grant-tables mode
	echo "[ENTRYPOINT] Setting root password..."
	if ! mysql --skip-password --protocol=socket -h localhost <<-EOSQL
		-- Clean up anonymous users and remote root access
		DELETE FROM mysql.user WHERE User='';
		DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
		
		-- Update root password by directly modifying the user table
		UPDATE mysql.global_priv 
		SET priv=JSON_SET(
			COALESCE(priv,'{}'),
			'$.plugin', 'mysql_native_password',
			'$.authentication_string', CONCAT('*', UPPER(SHA1(UNHEX(SHA1('${MYSQL_ROOT_PASSWORD}')))))
		)
		WHERE User='root';
		
		-- Make sure privileges are updated
		FLUSH PRIVILEGES;
	EOSQL
	then
		echo "[ENTRYPOINT] Failed to set root password"
		kill "$MYSQL_PID" >/dev/null 2>&1 || true
		exit 1
	fi
	echo "[ENTRYPOINT] Root password set successfully"

	# Restart server without skip-grant-tables to apply remaining configuration
	echo "[ENTRYPOINT] Restarting MariaDB for final configuration..."
	if ! mysqladmin --skip-password --protocol=socket -h localhost shutdown; then
		echo "[ENTRYPOINT] Failed to shutdown server"
		kill "$MYSQL_PID" >/dev/null 2>&1 || true
		exit 1
	fi

	# Start with networking enabled for final configuration
	mysqld_safe --socket=/var/run/mysqld/mysqld.sock --datadir=/var/lib/mysql --user=mysql &
	MYSQL_PID=$!

	# Wait for server
	_ready=0
	for i in {1..30}; do
		if mysqladmin -u root -p"${MYSQL_ROOT_PASSWORD}" --protocol=socket -h localhost ping --silent 2>/dev/null; then
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

	# Now apply the rest of the user configuration
	echo "[ENTRYPOINT] Setting up users and privileges..."
	if mysql -u root -p"$MYSQL_ROOT_PASSWORD" --protocol=socket -h localhost < "$INIT_SQL"; then
		echo "[ENTRYPOINT] User setup successful"
	else
		echo "[ENTRYPOINT] Failed to setup users"
		kill "$MYSQL_PID" >/dev/null 2>&1 || true
		exit 1
	fi

	# Final shutdown before normal startup
	if ! mysqladmin -u root -p"$MYSQL_ROOT_PASSWORD" --protocol=socket -h localhost shutdown; then
		echo "[ENTRYPOINT] Failed to shutdown temporary server"
		kill "$MYSQL_PID" >/dev/null 2>&1 || true
		exit 1
	fi

	echo "[ENTRYPOINT] Erasing init.sql content..."
	echo "" > $INIT_SQL
fi

echo "[ENTRYPOINT] Starting MariaDB..."
exec mysqld_safe --socket=/var/run/mysqld/mysqld.sock --datadir=/var/lib/mysql --user=mysql --bind-address=0.0.0.0