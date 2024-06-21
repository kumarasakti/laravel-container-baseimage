FROM php:8.3-alpine3.20

ARG WWWGROUP=1000
ARG WWWUSER=1000
ARG NODE_VERSION=18
ARG POSTGRES_VERSION=15
ARG PHPIZE_DEPS="autoconf dpkg-dev dpkg file g++ gcc libc-dev make pkgconf re2c"

WORKDIR /var/www/html

ENV TZ=UTC

RUN echo $TZ > /etc/timezone
RUN apk add --no-cache --virtual bash zip unzip curl sqlite git nodejs npm
ADD https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/
RUN chmod +x /usr/local/bin/install-php-extensions
RUN sed -i 's/bin\/ash/bin\/bash/g' /etc/passwd

RUN install-php-extensions \
    mysqli pdo_pgsql \
    sqlite3 fileinfo xml \
    gd curl pcntl \
    imap exif mbstring \
    xml zip bcmath \
    soap intl readline \
    ldap msgpack igbinary \
    redis swoole opcache \
    memcached redis pcov \
    zip json

RUN apk add --no-cache \
    imagemagick-dev \
    libtool \
    && apk add --no-cache --virtual .build-deps $PHPIZE_DEPS \
    && git clone https://github.com/Imagick/imagick \
    && cd imagick \
    && phpize \
    && ./configure \
    && make \
    && make install \
    && docker-php-ext-enable imagick \
    && cd .. \
    && rm -rf imagick \
    && apk del .build-deps

RUN ln -s /usr/bin/php83 /usr/bin/php

RUN curl -sS https://getcomposer.org/installer -o composer-setup.php
RUN php composer-setup.php --install-dir=/usr/local/bin --filename=composer
RUN rm -rf composer-setup.php

RUN mkdir -p /run/php/
RUN touch /run/php/php8.3-fpm.pid
COPY ./config/php-fpm.conf /usr/local/etc/php-fpm.conf
COPY ./config/php.ini /usr/local/etc/php/php.ini

EXPOSE 8000


CMD ["php", "-a"]