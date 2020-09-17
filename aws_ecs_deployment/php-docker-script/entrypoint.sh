#!/bin/bash

chmod -R 755 /tmp/content-site
cp -rf /tmp/content-site /var/www/html

#link plugins to AWS EFS mountPoints
cd /var/www/html/content-site/wp-content/
rm -rf plugins

ln -s /var/wordpress_plugins/content-site/wp-content/plugins ./plugins
ln -s /var/wordpress_plugins/content-site/wp-content/upgrade ./upgrade
ln -s /var/wordpress_plugins/content-site/wp-content/uploads ./uploads
ln -s /var/wordpress_plugins/content-site/wp-content/uploads_auto_poster ./uploads_auto_poster
cd ./uploads_auto_poster
touch access_from_php_ok

/etc/init.d/cron restart &
/etc/init.d/rsyslog restart &

docker-php-entrypoint php-fpm
