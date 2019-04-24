FROM php:apache

RUN a2enmod rewrite

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get -qq update && apt-get -qq -y --no-install-recommends install \
    curl \
    unzip \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libmcrypt-dev \
    libpng-dev \
    libjpeg-dev \
    libmemcached-dev \
    zlib1g-dev \
    imagemagick \
    jq

# install the PHP extensions we need
RUN pecl install mcrypt-1.0.2 && docker-php-ext-enable mcrypt
RUN docker-php-ext-install -j$(nproc) iconv pdo pdo_mysql mysqli gd
RUN docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/

RUN docker-php-ext-install exif && \
    docker-php-ext-enable exif

COPY ./imagemagick-policy.xml /etc/ImageMagick/policy.xml
RUN chown www-data:www-data /var/www
USER www-data

RUN curl -J -L -s -k \
  "$(curl -s https://api.github.com/repos/omeka/Omeka/releases/latest \
     | jq --raw-output '.assets[0] | .browser_download_url')" \
    -o /var/www/omeka.zip
RUN unzip -q /var/www/omeka.zip -d /var/www/ \
&&  rm /var/www/omeka.zip \
&&  rm -rf /var/www/html \
&&  mv /var/www/omeka-* /var/www/html

COPY ./db.ini /var/www/html/db.ini
COPY ./.htaccess /var/www/html/.htaccess
RUN { echo upload_max_filesize = 100M; echo post_max_size = 100M; } > php.ini

VOLUME /var/www/html/files
USER root
CMD ["apache2-foreground"]
