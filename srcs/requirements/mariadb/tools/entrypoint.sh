#!/bin/bash
DATADIR="/var/lib/mysql"
INIT_SQL="/docker-entrypoint-initdb.d/init.sql"

echo "[ENTRYPOINT] Checking for init.sql..."

# check if init.sql does not exist
if [ ! -f "$INIT_SQL" ]; then
	echo "[ENTRYPOINT] init.sql not found, generating a new one..."
	# run the initializer script directly (it writes the SQL file itself)
	sh /docker-entrypoint-initdb.d/init.sh
	echo "[ENTRYPOINT] Applying init.sql..."
	# start a temporary MariaDB instance in the background so we can apply the SQL
	# use --skip-networking to avoid exposing it during init
	mysqld_safe --skip-networking &
	MYSQ_PID=$!

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
		kill "$MYSQ_PID" >/dev/null 2>&1 || true
		exit 1
	fi

	# Double-check that we can actually connect
	if ! mysql -u root -e "SELECT 1" >/dev/null 2>&1; then
		echo "[ENTRYPOINT] Could not establish a test connection"
		kill "$MYSQ_PID" >/dev/null 2>&1 || true
		exit 1
	fi
	echo "[ENTRYPOINT] Test connection successful"

	# apply the SQL using the mysql client and check return code
	echo "[ENTRYPOINT] Executing initialization SQL..."
	if mysql -u root --verbose < "$INIT_SQL" 2>&1; then
		echo "[ENTRYPOINT] Database initialization successful"
	else
		echo "[ENTRYPOINT] Failed to initialize database"
		echo "[ENTRYPOINT] SQL Error output:"
		mysql -u root < "$INIT_SQL" 2>&1 || true
		kill "$MYSQ_PID" >/dev/null 2>&1 || true
		exit 1
	fi

	# shutdown the temporary server so we can start it normally below
	if ! mysqladmin shutdown; then
		echo "[ENTRYPOINT] Failed to shutdown temporary server"
		kill "$MYSQ_PID" >/dev/null 2>&1 || true
		exit 1
	fi

	echo "[ENTRYPOINT] Erasing init.sql content..."
	echo "" > $INIT_SQL
fi

echo "[ENTRYPOINT] Starting MariaDB..."
exec mysqld_safe