# CI/CD Pipeline built by Travis-CI, Docker and AWS ECS.

## CI:
Use travis-ci instead of Jenkins or AWS CodePipeline for CI part:
Write a .travis.yml into the root directory of your github repo
```
The .travis.yml consists of:

    Definition of environment varibles and their value.
    Pre-installation settings.
    One jobs stage for building and pushing application docker images to AWS ECR(Container Repository).
    One jobs stage for deploying applications to AWS ECS.
    notifications to a slack channel.

    .travis.yml
    Dockerfile
    aws_ecs_deployment/deploy_scripts/build_docker_images.sh

```

## CD:
Use AWS ECS for Docker container orchestration platform.
I use AWS CLI to apply deployments to AWS, but we also can use terraform for IaC tools.
```
    Run AWS CLI will create Route 53 records, ALB, ECS resources.

    aws_ecs_deployment/deploy_scripts/create_xxxxx.sh

```

## Micro service for wordpress
Nginx and PHP node will be separated by 2 different services in a ECS Cluster.
Services with a github branch name will be used for staging or testing environment and "master" for production.
The nginx nodes will access php nodes with fastcgi forward traffic to a DNS name provided by AWS Cloud Map(service discovery)
```
     php-[branch name]
     nginx-[branch name]

     sed -i "/fastcgi_index/a set \$php_backend ${ecs_service_php_name}.ecs-staging;" ./aws_ecs_deployment/nginx_config/conf/conf.d/content-site.conf

```

## Get the wordpress source code
Download the wordpress package and replace the folder "themes" and wp-config.php with your own files
```  
     aws_ecs_deployment/deploy_scripts/get_xxxxx.sh

```

## Get Secrets from VAULT
Put your AWS AK/SK and wp-config with database credential into vault.
Get the secrets from vault with a token with TTL generated by root token.
```
     export AWS_ACCESS_KEY_ID=`curl -s  -H "X-Vault-Token: $VAULT_TOKEN" -X GET http://$vault_server_ip:8200/v1/aws/aws_credential | jq -r .data.AWS_ACCESS_KEY_ID`  

     curl -s  -H "X-Vault-Token: $VAULT_TOKEN" -X GET http://$vault_server_ip:8200/v1/content_site_wp_config/data/staging | jq -r .data.data.staging_wp_config > ./wordpress/wp-config.php
```

## Create and destroy resources
Put deletion mark to destroy all resources created on AWS if necessary
```
     deletion_mark=0   #create
     deletion_mark=1   #destroy
```
