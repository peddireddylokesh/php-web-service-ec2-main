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

# Install dependencies
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
    libpng-dev && \
    docker-php-ext-configure gd --with-freetype --with-jpeg && \
    docker-php-ext-install -j$(nproc) zip pdo pdo_mysql gd && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install kubectl separately
RUN curl -LO "https://dl.k8s.io/release/v1.28.5/bin/linux/amd64/kubectl" && \
    chmod +x kubectl && \
    mv kubectl /usr/local/bin/

# Install Composer globally
RUN curl -sS https://getcomposer.org/installer | php && \
    mv composer.phar /usr/local/bin/composer

# Enable Apache rewrite module
RUN a2enmod rewrite

# Set working directory
WORKDIR /var/www/html

# Copy application code
COPY . /var/www/html/

# Run Composer to install PHP dependencies
RUN composer install --no-dev --optimize-autoloader

# Fix permissions
RUN chown -R www-data:www-data /var/www/html && \
    chmod -R 755 /var/www/html

EXPOSE 80

CMD ["apache2-foreground"]
