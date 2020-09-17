#!/bin/bash

github_token=`curl -s  -H "X-Vault-Token: $VAULT_TOKEN" -X GET http://$vault_server_ip:8200/v1/github_token/data/deployment | jq -r .data.data.token`

#get wordpress source code and de-tar
wget https://wordpress.org/wordpress-5.4.2.tar.gz
tar zxf wordpress-5.4.2.tar.gz

#get themes folder from repo
rm -rf ./wordpress/wp-content/themes
cp -rf ./wp-content/themes ./wordpress/wp-content/themes

#run composer install
mkdir -p /home/travis/.composer
cat << EOF >/home/travis/.composer/auth.json
{
    "bitbucket-oauth": {},
    "github-oauth": {
       "github.com": "$github_token"},
    "gitlab-oauth": {},
    "gitlab-token": {},
    "http-basic": {},
    "bearer": {}
}
EOF

cd ./wordpress/wp-content/themes
composer install --no-dev
