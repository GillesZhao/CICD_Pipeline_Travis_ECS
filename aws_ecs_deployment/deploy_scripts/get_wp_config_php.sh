#!/bin/bash

curl -s  -H "X-Vault-Token: $VAULT_TOKEN" -X GET http://$vault_server_ip:8200/v1/content_site_wp_config/data/staging | jq -r .data.data.staging_wp_config > ./wordpress/wp-config.php
TRAVIS_PULL_REQUEST_BRANCH=`echo $TRAVIS_PULL_REQUEST_BRANCH|tr "_" "-"`
sed -i "/APP_ENV/a define('WP_SITEURL', 'http://"$TRAVIS_PULL_REQUEST_BRANCH".content-site.xxxxx.com');\ndefine('WP_HOME', 'http://"$TRAVIS_PULL_REQUEST_BRANCH".content-site.xxxxx.com');" ./wordpress/wp-config.php
