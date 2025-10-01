DATADIR="/var/lib/mysql"
INIT_SQL="/docker-entrypoint-initdb.d/init.sql"

echo "[ENTRYPOINT] Checking for init.sql..."

#check if init.sql does not exists
if [ -f "$INIT_SQL" = false ]; then
	echo "[ENTRYPOINT] init.sql not found, generating a new one..."
	sh /tools/init.sh > $INIT_SQL
	echo "[ENTRYPOINT] Applying init.sql..."
	mysql -u root < $INIT_SQL
	echo "[ENTRYPOINT] Erasing init.sql content..."
	echo "" > $INIT_SQL
fi

echo "[ENTRYPOINT] Starting MariaDB..."
exec mysqld_safe