FROM debian:bullseye

# Install nginx and openssl
RUN apt-get update && apt-get install -y nginx openssl && \
    rm -rf /var/lib/apt/lists/*

# Copy custom Nginx config
COPY conf/default.conf /etc/nginx/conf.d/default.conf

# Copy script to generate certificates
COPY tools/generate_certs.sh /generate_certs.sh
RUN chmod +x /generate_certs.sh

# Create certs directory
RUN mkdir -p /etc/nginx/certs

# Generate certificates at build time or startup
CMD ["/bin/bash", "-c", "/generate_certs.sh && nginx -g 'daemon off;'"]
