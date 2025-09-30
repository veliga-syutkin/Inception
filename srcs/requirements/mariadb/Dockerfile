# Starting point - clean Debian image (bullseye = Debian 11)
FROM debian:bullseye

# Install mariadb
RUN apt-get update && \
    apt-get install -y mariadb-server && \
    rm -rf /var/lib/apt/lists/*

# Copy and setup custom MariaDB configuration
COPY conf/50-server.cnf /etc/mysql/mariadb.conf.d/

# Copy entrypoint script and make it executable
# The entrypoint script is used to initialize the database if needed
COPY tools/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Copy initialization script and make it executable
COPY tools/init.sh /docker-entrypoint-initdb.d/init.sh
RUN echo "initialization script copied"
RUN chmod +x /docker-entrypoint-initdb.d/init.sh
RUN echo "initialization script made executable"

# Conventionnal directory for persisting database files
VOLUME ["/var/lib/mysql"]

# MariaDB port
EXPOSE 3306

# launch MariaDB 
# DEPRECATED: CMD ["mysqld_safe"]

# Use the init script to initialize the database and then launch mysqld_safe
RUN /docker-entrypoint-initdb.d/init.sh 
CMD ["/entrypoint.sh"]