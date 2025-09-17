# Starting point - clean Debian image
FROM debian:bullseye

# Install PHP and extensions
RUN apt-get update && \
    apt-get install -y wget php php-fpm php-mysql php-cgi php-gd php-cli php-pdo php-curl php-mbstring php-xml php-xmlrpc php-soap php-intl php-zip && \
    rm -rf /var/lib/apt/lists/*

# Download specific WordPress version
RUN wget https://wordpress.org/wordpress-${WP_VERSION}.tar.gz \
    && tar -xzf wordpress-${WP_VERSION}.tar.gz \
    && rm wordpress-${WP_VERSION}.tar.gz \
    && mv wordpress /var/www/html

EXPOSE 9000

CMD ["php-fpm7.4", "-F"]