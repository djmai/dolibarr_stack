# Base image con PHP y extensiones necesarias
FROM php:8.2-fpm

# # Instalar dependencias y extensiones PHP
# Instalar dependencias necesarias para PHP y NGINX
RUN apt-get update && apt-get install -y \
    nginx \
    && docker-php-ext-install mysqli pdo pdo_mysql

ADD --chmod=0755 https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/

# Instalar extensiones necesarias
RUN install-php-extensions imap pgsql gd calendar intl zip 

# Instalación de xdebug
# RUN install-php-extensions xdebug

# Instalación de mysql-client
RUN apt-get update && apt-get install -y default-mysql-client

# Copiar configuración personalizada de NGINX
COPY ./nginx/nginx.conf /etc/nginx/nginx.conf

# Copiar configuración personalizada para XDebug
# COPY xdebug.ini /usr/local/etc/php/conf.d/xdebug.ini

# Cambiar el directorio raíz de la aplicación
WORKDIR /app

# Cambiar permisos de la aplicación
RUN chown -R www-data:www-data /app

# Exponer el puerto para NGINX
EXPOSE 80

# Iniciar NGINX y PHP-FPM
CMD ["sh", "-c", "php-fpm -D && nginx -g 'daemon off;'"]
