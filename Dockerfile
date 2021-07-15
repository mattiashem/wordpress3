FROM php:7.4-fpm-alpine

ARG WP_VERSION=5.7.2

RUN apk add --no-cache libpng libpng-dev libjpeg-turbo-dev libwebp-dev zlib-dev libxpm-dev && docker-php-ext-install gd
RUN set -ex \
    && apk add --no-cache --virtual .phpize-deps $PHPIZE_DEPS imagemagick-dev libtool \
    && export CFLAGS="$PHP_CFLAGS" CPPFLAGS="$PHP_CPPFLAGS" LDFLAGS="$PHP_LDFLAGS" \
    && pecl install imagick-3.4.3 \
    && docker-php-ext-enable imagick \
    && apk add --no-cache --virtual .imagick-runtime-deps imagemagick \
    && apk del .phpize-deps
RUN apk --update --no-cache add nginx ca-certificates wget curl openssl libxml2-dev curl bash mariadb-client less sudo


# Installing php7-mysqli doesnt work. This is the way to install. I assume the `docker-php-ext-install` script solves problems with versioning. We could use php:7.4-fpm image but alpine package can have a mysqli package that requires different version. FIXME

# A ticket describing this
# How do you get php-mysql extensions installed for php:7-fpm-alpine #279
# https://github.com/docker-library/php/issues/279
RUN docker-php-ext-install -j$(nproc) mysqli pdo pdo_mysql json xml ctype 

RUN update-ca-certificates

# install wp-cli
RUN curl -o /bin/wp-cli.phar https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
COPY wp-su.sh /bin/wp
RUN chmod +x /bin/wp-cli.phar /bin/wp

WORKDIR /var/www
#RUN wget https://wordpress.org/latest.tar.gz
RUN wget https://wordpress.org/wordpress-${WP_VERSION}.tar.gz
RUN tar zxvf wordpress-${WP_VERSION}.tar.gz

ADD tls/ /etc/nginx/tls/
RUN chmod +r /etc/nginx/tls/*

RUN mkdir -p /repo

# The official php docker image is using the /usr/local/etc/php path
ADD wordpress.conf /etc/nginx/nginx.conf
ADD php.ini	/usr/local/etc/php/php.ini
ADD php-fpm.conf /usr/local/etc/php-fpm.d/www.conf
ADD php-fpm.conf_demon /usr/local/etc/php-fpm.conf
RUN mv /var/www/wordpress/wp-content /var/www/wordpress/wp-content_org
RUN ln -s /repo/wp-content /var/www/wordpress/wp-content 

#Setup Healthx
RUN mkdir /var/www/wordpress/healthz/
RUN echo "<html><head><title>All fine</title></head></html>" > /var/www/wordpress/healthz/index.html
RUN chmod 755 /var/www/wordpress/healthz/index.html
RUN chown nginx:nginx /var/www/wordpress/healthz/

# cta: temp disable. building new image
#Setup php
#RUN mkdir /var/lib/php7/session
#RUN chown nginx:nginx /var/lib/php7/session
#RUN chmod 770 /var/lib/php7/session

#Fix locales
#RUN apk update && apk add locale -y
#RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

#Fix nginx
RUN chown nginx:nginx -R /var/lib/nginx/
RUN chown root:nginx /var/log/nginx
RUN chmod 775 -R /var/log/nginx
RUN mkdir /run/php
RUN chown nginx:nginx /run/php
RUN chmod 771 /run/php


ADD start.sh /
RUN chown nginx /start.sh
RUN chmod 711 /start.sh

# link these log files to STDOUT 
RUN ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log 

#USER nginx

CMD /start.sh

ENTRYPOINT ["/usr/bin/env"]
