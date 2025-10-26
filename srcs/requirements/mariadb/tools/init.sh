#!/bin/bash
echo "Generating init.sql..."

cat <<EOF > /docker-entrypoint-initdb.d/init.sql
-- ========================================
-- Application User Setup
-- ========================================
-- Note: Database and root user are already configured by entrypoint.sh
-- This script only handles the application user for WordPress

-- Clean up any existing application users
DROP USER IF EXISTS '$MYSQL_USER'@'localhost';
DROP USER IF EXISTS '$MYSQL_USER'@'%';

-- Create application user with access from anywhere
CREATE USER '$MYSQL_USER'@'localhost' IDENTIFIED BY '$MYSQL_PASSWORD';
CREATE USER '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD';

-- Grant privileges on the application database only
GRANT ALL PRIVILEGES ON $MYSQL_DATABASE.* TO '$MYSQL_USER'@'localhost';
GRANT ALL PRIVILEGES ON $MYSQL_DATABASE.* TO '$MYSQL_USER'@'%';

-- Apply privileges
FLUSH PRIVILEGES;
EOF

echo "init.sql generated."
