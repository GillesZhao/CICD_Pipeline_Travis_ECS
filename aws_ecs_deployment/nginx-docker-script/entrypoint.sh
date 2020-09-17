#!/bin/bash

#link plugins to AWS EFS mountPoints
cd /var/www/html/content-site/wp-content/
rm -rf plugins

ln -s /var/wordpress_plugins/content-site/wp-content/plugins ./plugins
ln -s /var/wordpress_plugins/content-site/wp-content/upgrade ./upgrade
ln -s /var/wordpress_plugins/content-site/wp-content/uploads ./uploads
ln -s /var/wordpress_plugins/content-site/wp-content/uploads_auto_poster ./uploads_auto_poster
cd ./plugins
touch access_from_nginx_ok

nginx -g "daemon off;"
