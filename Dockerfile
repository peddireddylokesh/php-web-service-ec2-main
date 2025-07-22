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

# Install OS and PHP dependencies
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    nano \
    curl \
    apt-transport-https \
    ca-certificates \
    gnupg \
    libzip-dev \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev && \
    docker-php-ext-configure gd --with-freetype --with-jpeg && \
    docker-php-ext-install -j$(nproc) zip pdo pdo_mysql gd && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Fix Apache to use port 8080 instead of 80 (non-root cannot bind to 80)
RUN sed -i 's/80/8080/g' /etc/apache2/ports.conf /etc/apache2/sites-available/000-default.conf

# Enable Apache rewrite module
RUN a2enmod rewrite

# Install kubectl (optional, useful if this container manages k8s)
RUN curl -LO "https://dl.k8s.io/release/v1.28.5/bin/linux/amd64/kubectl" && \
    chmod +x kubectl && \
    mv kubectl /usr/local/bin/

# Install Composer globally
RUN curl -sS https://getcomposer.org/installer | php && \
    mv composer.phar /usr/local/bin/composer

# Set working directory
WORKDIR /var/www/html

# Copy application code
COPY . /var/www/html/

# Install PHP dependencies using Composer
RUN composer install --no-dev --optimize-autoloader

# Fix permissions for Apache www-data user
RUN chown -R www-data:www-data /var/www/html && \
    chmod -R 755 /var/www/html

# Expose the updated Apache port
EXPOSE 8080

# Start Apache
CMD ["apache2-foreground"]
