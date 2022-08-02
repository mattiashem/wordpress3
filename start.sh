#!/bin/sh


#
#
# If we have a gitrepo set lets download that as base
#




if [ -z "$SITENAME" ];then
    echo "no name"
else
    echo "Sitename is $SITENAME"
fi



echo "Building wp config"
#######################
#######################
##Building the wp-config file
echo -e "<?php \n" > /var/www/wordpress/wp-config.php
echo -e "define('DB_NAME', '$DBNAME'); \n" >> /var/www/wordpress/wp-config.php
echo -e "define('DB_USER', '$DBUSER'); \n" >> /var/www/wordpress/wp-config.php
echo -e "define('DB_PASSWORD', '$DBPASS'); \n" >> /var/www/wordpress/wp-config.php
echo -e "define('DB_HOST', '$DBHOST'); \n" >> /var/www/wordpress/wp-config.php
echo -e "define('DB_CHARSET', 'utf8'); \n" >> /var/www/wordpress/wp-config.php
echo -e "define('DB_COLLATE', ''); \n" >> /var/www/wordpress/wp-config.php


echo  "if (strpos(\$_SERVER['HTTP_X_FORWARDED_PROTO'], 'https') !== false) ">> /var/www/wordpress/wp-config.php
echo  "       \$_SERVER['HTTPS']='on';" >> /var/www/wordpress/wp-config.php
echo -e "\n" >> /var/www/wordpress/wp-config.php



#
##if [ -z "$SITEURL" ];then
##echo -e "define('WP_SITEURL','http://$SITEURL'); \n" >> /var/www/wordpress/wp-config.php
#
##else
##	echo "no sitename"
##fi
#
##Reverse proxy
##echo -e "if ($_SERVER['HTTP_X_FORWARDED_PROTO'] == 'https') {\n" >> /var/www/wordpress/wp-config.php
##echo -e "$_SERVER['HTTPS']='on'; \n" >> /var/www/wordpress/wp-config.php
##echo -e "} \n" >> /var/www/wordpress/wp-config.php
#
##echo -e "if (isset($_SERVER["HTTP_X_FORWARDED_FOR"])) { \n" >> /var/www/wordpress/wp-config.php
##echo -e "$_SERVER['REMOTE_ADDR'] = $_SERVER["HTTP_X_FORWARDED_FOR"]; \n" >> /var/www/wordpress/wp-config.php
##echo -e "} \n" >> /var/www/wordpress/wp-config.php
#
#
#
# Set static php workers (defaults to 6 if not set)
PHP_WORKERS="${PHP_WORKERS:-6}"
#sed -i "s/^pm.max_children =.*/pm.max_children = ${PHP_WORKERS}/g" /etc/php7/php-fpm.d/www.conf
sed -i "s/^pm.max_children =.*/pm.max_children = ${PHP_WORKERS}/g" /usr/local/etc/php-fpm.d/www.conf

## Setting upp new salt and authkey
if [[ ! -z "$SALT" ]] ; then
  echo "Setting pre-defined salt!"
  echo "$SALT" >> /var/www/wordpress/wp-config.php
else
  curl https://api.wordpress.org/secret-key/1.1/salt/ >> /var/www/wordpress/wp-config.php
fi

if [ "$DEBUG" == "true" ] ; then
  echo -e "#### DEBUG ON" >> /var/www/wordpress/wp-config.php
  echo -e "define('WP_DEBUG', true); \n" >> /var/www/wordpress/wp-config.php
  echo -e "define('WP_DEBUG_LOG', '/var/log/nginx/www-error.log'); \n" >> /var/www/wordpress/wp-config.php
  echo -e "define('WP_DEBUG_DISPLAY', false); \n" >> /var/www/wordpress/wp-config.php
  echo -e "define('WPS_DEBUG', true); \n" >> /var/www/wordpress/wp-config.php
fi
echo -e "####" >> /var/www/wordpress/wp-config.php
echo -e "\$table_prefix  = 'wp_'; \n" >> /var/www/wordpress/wp-config.php
echo -e "if ( !defined('ABSPATH') )" >> /var/www/wordpress/wp-config.php
echo -e "define('ABSPATH', dirname(__FILE__) . '/'); \n" >> /var/www/wordpress/wp-config.php
echo -e "define('FS_METHOD','direct'); \n" >> /var/www/wordpress/wp-config.php
echo -e "define(\"WP_MEMORY_LIMIT\",\"${WP_MEMORY_LIMIT:-128M}\"); \n" >> /var/www/wordpress/wp-config.php
echo -e "define(\"WP_MAX_MEMORY_LIMIT\", \"${WP_MAX_MEMORY_LIMIT:-256M}\" ); \n" >> /var/www/wordpress/wp-config.php
echo -e "require_once(ABSPATH . 'wp-settings.php'); \n" >> /var/www/wordpress/wp-config.php

#wp-content
if [ -d "/repo/wp-content" ]
then
    echo "Directory /repo/wp-content exists."
else
    echo "Error: Directory /repo/wp-content does not exists copy files."
    cp -r /var/www/wordpress/wp-content_org /repo/wp-content
fi


# Set permission on the mounted folder if needed
# Do it only when necessary because it delays startup. If many files present it takes very long time
#
# THIS HAS BEEN MOVED TO SEED script


#Wordpress
chmod 664 /var/www/wordpress/wp-config.php
#chmod -R 775 /var/www/wordpress
#chown nginx:nginx -R wordpress

#touch /var/log/nginx/php-error.log && chmod 644 /var/log/nginx/php-error.log && ln -sf /proc/1/fd/1 /var/log/nginx/php-error.log
touch /var/log/nginx/www-error.log && chmod 644 /var/log/nginx/www-error.log && ln -sf /proc/1/fd/1 /var/log/nginx/www-error.log
#tail -f /var/log/nginx/www-error.log /var/log/nginx/php-error.log

echo "Starting webb service"
nginx
php-fpm
# php-fpm runs in the foreground because of  /usr/local/etc/php-fpm.d/docker.conf (inherited from php-fpm docker image)
# DONT ADD ANYTHING AFTER "php-fpm"
