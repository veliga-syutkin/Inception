# Starting point - clean Debian image
FROM debian:bullseye

# Install mariadb
RUN apt-get update && \
    apt-get install -y mariadb-server && \
    rm -rf /var/lib/apt/lists/*

# # Copier la configuration personnalisée (optionnel)
# COPY conf/50-server.cnf /etc/mysql/mariadb.conf.d/

# # Copier un script d’initialisation (optionnel)
# COPY tools/init.sh /docker-entrypoint-initdb.d/init.sh
# RUN chmod +x /docker-entrypoint-initdb.d/init.sh

# Conventionnal directory for persisting database files
VOLUME ["/var/lib/mysql"]

# MariaDB port
EXPOSE 3306

# launch MariaDB 
CMD ["mysqld_safe"]