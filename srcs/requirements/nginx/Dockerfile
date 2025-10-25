FROM debian:bullseye

# Install nginx, openssl and gettext-base (for envsubst)
RUN apt-get update && apt-get install -y nginx openssl gettext-base && \
    rm -rf /var/lib/apt/lists/*

# Copy custom Nginx config template
COPY conf/default.conf /etc/nginx/conf.d/default.conf.template

# Copy script to generate certificates
COPY tools/generate_certs.sh /generate_certs.sh
RUN chmod +x /generate_certs.sh

# Create certs directory
RUN mkdir -p /etc/nginx/certs

# Generate certificates and substitute environment variables, then start nginx
CMD ["/bin/bash", "-c", "/generate_certs.sh && envsubst '$$DOMAIN_NAME' < /etc/nginx/conf.d/default.conf.template > /etc/nginx/conf.d/default.conf && nginx -g 'daemon off;'"]
