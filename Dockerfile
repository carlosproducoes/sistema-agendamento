FROM php:8.3-fpm

# set your user name, ex: user=carlos
ARG user=admin
ARG uid=1000

# Set time zone
ENV TZ=America/Sao_Paulo
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN printf '[Date]\ndate.timezone="%s"\n', $TZ > /usr/local/etc/php/conf.d/tzone.ini

# Install dependencies
RUN apt-get update && apt-get install -y \
    nano \
    zip \
    unzip \
    curl \
    gnupg \
    git \
    libzip-dev \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    && docker-php-ext-configure zip \
    && docker-php-ext-install zip pdo_mysql mbstring exif pcntl bcmath gd sockets

# Install Node.js 
RUN curl -fsSL https://deb.nodesource.com/setup_16.x | bash - \
    && apt-get install nodejs -y
    
# Set the working directory in the container
WORKDIR /var/www

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Create system user to run Composer and Artisan Commands
RUN useradd -G www-data,root -u $uid -d /home/$user $user
RUN mkdir -p /home/$user/.composer && \
    chown -R $user:$user /home/$user

# Copy the rest of your application code
COPY . .
    
# Install Laravel dependencies using Composer
RUN composer install --no-scripts --no-autoloader

# Install npm dependencies
COPY package.json ./
RUN npm install

# Copy the .env.example to .env
COPY .env.example .env

# Generate application key
RUN php artisan key:generate

# Copy custom configurations PHP
COPY docker/php/custom.ini /usr/local/etc/php/conf.d/custom.ini

USER $user