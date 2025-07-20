FROM php:8.0-apache

# Build arguments
ARG BUILD_DATE
ARG VERSION
ARG VCS_REF

# Labels
LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.name="PHP Web Service" \
      org.label-schema.version=$VERSION \
      org.label-schema.vcs-ref=$VCS_REF \
      maintainer="Peddireddy Lokesh"

# Install dependencies and kubectl
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    libzip-dev \
    nano \
    curl \
    apt-transport-https \
    ca-certificates \
    gnupg \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) zip pdo pdo_mysql gd \
    && curl -LO "$(curl -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
    && install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl \
    && rm kubectl

# Enable Apache rewrite module
RUN a2enmod rewrite

# Set the working directory
WORKDIR /var/www/html

# Copy the application code
COPY . /var/www/html/

# Set permissions
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html

# Expose port 80
EXPOSE 80

# Start Apache in foreground
CMD ["apache2-foreground"]
