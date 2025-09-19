# define the WordPress version to install
FROM debian:bullseye

ENV WP_VERSION=6.5.2

# Install php, php-fpm and necessary extenstions for WordPress
RUN apt-get update && apt-get install -y \
    php php-fpm php-mysql wget curl tar less mariadb-client \
    && rm -rf /var/lib/apt/lists/*

# Download specific WordPress version
RUN mkdir -p /var/www/html \
    && wget https://wordpress.org/wordpress-${WP_VERSION}.tar.gz \
    && tar -xzf wordpress-${WP_VERSION}.tar.gz \
    && rm wordpress-${WP_VERSION}.tar.gz \
    && mv wordpress/* /var/www/html

# Copy custom config php-fpm
COPY conf/www.conf /etc/php/7.4/fpm/pool.d/www.conf

# Copy the setup script (install wp-cli, configure WP)
COPY tools/setup.sh /setup.sh
RUN chmod +x /setup.sh

# Expose the php-fpm port (documentational)
EXPOSE 9000

# Launch php-fpm in foreground
CMD ["/bin/bash", "-c", "/setup.sh && php-fpm7.4 -F"]