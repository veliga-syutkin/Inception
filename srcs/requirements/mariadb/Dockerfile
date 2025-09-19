# Starting point - clean Debian image (bullseye = Debian 11)
FROM debian:bullseye

# Install mariadb
RUN apt-get update && \
    apt-get install -y mariadb-server && \
    rm -rf /var/lib/apt/lists/*

# Copy and setup custom MariaDB configuration
COPY conf/50-server.cnf /etc/mysql/mariadb.conf.d/

# Copy initialization script and make it executable
COPY tools/init.sh /docker-entrypoint-initdb.d/init.sh
RUN chmod +x /docker-entrypoint-initdb.d/init.sh

# Conventionnal directory for persisting database files
VOLUME ["/var/lib/mysql"]

# MariaDB port
EXPOSE 3306

# launch MariaDB 
CMD ["mysqld_safe"]