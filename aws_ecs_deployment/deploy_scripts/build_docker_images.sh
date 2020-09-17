#!/bin/bash

export AWS_ACCESS_KEY_ID=`curl -s  -H "X-Vault-Token: $VAULT_TOKEN" -X GET http://$vault_server_ip:8200/v1/aws/aws_credential | jq -r .data.AWS_ACCESS_KEY_ID`

export AWS_SECRET_ACCESS_KEY=`curl -s  -H "X-Vault-Token: $VAULT_TOKEN" -X GET http://$vault_server_ip:8200/v1/aws/aws_credential | jq -r .data.AWS_SECRET_ACCESS_KEY`

if [ "$AWS_ACCESS_KEY_ID" == "null" ]||[ "$AWS_SECRET_ACCESS_KEY" == "null" ];then
   echo -e "\033[31m Vault token expired \033[0m"
   exit 1
fi

if [ $deletion_mark -eq 1 ];then
   echo -e "\033[31m This is a resources deletion operation. Docker image will not be built... \033[0m"
   exit 0
fi

echo -e "\033[34m Logging in to Amazon ECR... \033[0m"

eval $(aws ecr get-login --no-include-email)

echo -e "\033[34m Entered the build phase... \033[0m"

docker build -f ./Dockerfile --build-arg base_nginx_image=$base_nginx_image_name --build-arg base_php_image=$base_php_image_name -t $target_nginx_image_name . --target $NGINX_APP_NAME

docker tag  $target_nginx_image_name $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$target_nginx_image_name

docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$target_nginx_image_name

docker build -f ./Dockerfile --build-arg base_nginx_image=$base_nginx_image_name --build-arg base_php_image=$base_php_image_name -t $target_php_image_name . --target $PHP_APP_NAME

docker tag  $target_php_image_name $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$target_php_image_name

docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$target_php_image_name
