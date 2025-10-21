#!/bin/bash
set -e

# Install WP-CLI if not present
if [ ! -f /usr/local/bin/wp ]; then
  curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
  chmod +x wp-cli.phar
  mv wp-cli.phar /usr/local/bin/wp
fi

# Wait for MariaDB to be ready
echo "Waiting for MariaDB to be ready..."
for i in {1..30}; do
  if mysqladmin ping -h"$MYSQL_HOST" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" --silent 2>/dev/null; then
    echo "MariaDB is ready!"
    break
  fi
  echo "Still waiting for MariaDB... attempt $i/30"
  sleep 2
done

# Verify connection one more time
if ! mysqladmin ping -h"$MYSQL_HOST" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" --silent 2>/dev/null; then
  echo "ERROR: Cannot connect to MariaDB after 60 seconds"
  exit 1
fi

cd /var/www/html

# Create wp-config.php file even if already done
  wp config create \
    --dbname=$MYSQL_DATABASE \
    --dbuser=$MYSQL_USER \
    --dbpass=$MYSQL_PASSWORD \
    --dbhost=$MYSQL_HOST \
    --path=/var/www/html \
    --allow-root

# Install WordPress if not already done
if ! wp core is-installed --allow-root; then
  wp core install \
    --url=https://$DOMAIN_NAME \
    --title="$WP_TITLE" \
    --admin_user=$WP_ADMIN_USER \
    --admin_password=$WP_ADMIN_PASSWORD \
    --admin_email=$WP_ADMIN_EMAIL \
    --skip-email \
    --allow-root
fi

chown -R www-data:www-data /var/www/html