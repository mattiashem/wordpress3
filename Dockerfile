FROM php:7.4-fpm-alpine

RUN apk add --no-cache libpng libpng-dev libjpeg-turbo-dev libwebp-dev zlib-dev libxpm-dev && docker-php-ext-install gd
RUN set -ex \
    && apk add --no-cache --virtual .phpize-deps $PHPIZE_DEPS imagemagick-dev libtool \
    && export CFLAGS="$PHP_CFLAGS" CPPFLAGS="$PHP_CPPFLAGS" LDFLAGS="$PHP_LDFLAGS" \
    && pecl install imagick-3.4.3 \
    && docker-php-ext-enable imagick \
    && apk add --no-cache --virtual .imagick-runtime-deps imagemagick \
    && apk del .phpize-deps
RUN apk update && apk add nginx php7 php7-fpm php7-json git php7-mysqli php7-mbstring php7-xml php7-ctype ca-certificates wget curl openssl php-openssl php-simplexml php-xmlwriter php-curl curl php-gd


RUN update-ca-certificates


WORKDIR /var/www
RUN wget https://wordpress.org/latest.tar.gz
RUN tar zxvf latest.tar.gz


ADD tls/ /etc/nginx/tls/
RUN chmod +r /etc/nginx/tls/*



ADD wordpress.conf /etc/nginx/nginx.conf
ADD php.ini	/etc/php7/php.ini
ADD php-fpm.conf /etc/php7/php-fpm.d/www.conf
ADD php-fpm.conf_demon /etc/php7/php-fpm.conf
RUN echo "top" >>/var/log/php7.0-fpm.log
RUN mkdir -p /repo
#RUN cp -r  /var/www/wordpress/wp-content /repo/wp-content
RUN mv /var/www/wordpress/wp-content /var/www/wordpress/wp-content_org
RUN ln -s /repo/wp-content /var/www/wordpress/wp-content 
RUN chown nginx:nginx /var/log/php7.0-fpm.log
RUN chown nginx:nginx -R wordpress
RUN chmod 775 -R wordpress


#Setup Healthx
RUN mkdir /var/www/wordpress/healthz/
RUN echo "<html><head><title>All fine</title></head></html>" > /var/www/wordpress/healthz/index.html
RUN chmod 755 /var/www/wordpress/healthz/index.html
RUN chown nginx:nginx /var/www/wordpress/healthz/


#Setup php
RUN mkdir /var/lib/php7/session
RUN chown nginx:nginx /var/lib/php7/session
RUN chmod 770 /var/lib/php7/session

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

#USER nginx


CMD /start.sh

