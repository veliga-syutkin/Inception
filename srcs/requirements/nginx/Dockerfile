# Starting point - clean Debian image
FROM debian:bullseye

# Install nginx
RUN apt-get update && \
	apt-get install -y nginx && \
	rm -rf /var/lib/apt/lists/*

# Conventionnal directory for persisting nginx files
VOLUME ["/etc/nginx/certs"]

# Nginx port
EXPOSE 443

# launch Nginx
CMD ["nginx", "-g", "daemon off;"]