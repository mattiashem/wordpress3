from alpine


RUN apk update && apk add nginx php7 php7-fpm  php7-mysqli php7-xml ca-certificates wget curl
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
RUN chown nginx:nginx /var/log/php7.0-fpm.log
RUN chown nginx:nginx -R wordpress
RUN chmod 755 -R wordpress



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

USER nginx


CMD /start.sh


