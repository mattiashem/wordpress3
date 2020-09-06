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
## Setting upp new salt and authkey
curl https://api.wordpress.org/secret-key/1.1/salt/ >> /var/www/wordpress/wp-config.php
#
echo -e "####" >> /var/www/wordpress/wp-config.php
echo -e "\$table_prefix  = 'wp_'; \n" >> /var/www/wordpress/wp-config.php
echo -e "define('WP_DEBUG', false); \n" >> /var/www/wordpress/wp-config.php
echo -e "if ( !defined('ABSPATH') )" >> /var/www/wordpress/wp-config.php
echo -e "define('ABSPATH', dirname(__FILE__) . '/'); \n" >> /var/www/wordpress/wp-config.php
echo -e "define('FS_METHOD','direct'); \n" >> /var/www/wordpress/wp-config.php
echo -e "define('WP_MEMORY_LIMIT','128M'); \n" >> /var/www/wordpress/wp-config.php
echo -e "define('WP_MAX_MEMORY_LIMIT', '256M' ); \n" >> /var/www/wordpress/wp-config.php
echo -e "require_once(ABSPATH . 'wp-settings.php'); \n" >> /var/www/wordpress/wp-config.php
#wp-content
if [ -d "/repo/wp-content" ]
then
    echo "Directory /repo/wp-content exists."
else
    echo "Error: Directory /repo/wp-content does not exists copy files."
    cp -r /var/www/wordpress/wp-content_org /repo/wp-content
fi



echo "Starting webb service"
php-fpm7
nginx

chown -R nginx:nginx /repo/wp-content
chmod -R 775 /repo/wp-content

#Wordpress
chmod 664 /var/www/wordpress/wp-config.php
chmod -R 775 /var/www/wordpress
chown nginx:nginx -R wordpress



tail -f /var/log/nginx/*
