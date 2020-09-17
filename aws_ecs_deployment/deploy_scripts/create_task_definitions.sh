#!/bin/bash

export AWS_ACCESS_KEY_ID=`curl -s  -H "X-Vault-Token: $VAULT_TOKEN" -X GET http://$vault_server_ip:8200/v1/aws/aws_credential | jq -r .data.AWS_ACCESS_KEY_ID`

export AWS_SECRET_ACCESS_KEY=`curl -s  -H "X-Vault-Token: $VAULT_TOKEN" -X GET http://$vault_server_ip:8200/v1/aws/aws_credential | jq -r .data.AWS_SECRET_ACCESS_KEY`

if [ "$AWS_ACCESS_KEY_ID" == "null" ]||[ "$AWS_SECRET_ACCESS_KEY" == "null" ];then
   echo -e "\033[31m Vault token expired \033[0m"
   exit 1
fi

#--cli-input-json  file://task_definition.json

if [ $deletion_mark -ne 1 ];then

aws ecs register-task-definition \
--family $NGINX_APP_NAME \
--task-role-arn arn:aws:iam::1234567890:role/AmazonECSTaskExecutionRole \
--execution-role-arn arn:aws:iam::1234567890:role/AmazonECSTaskExecutionRole \
--network-mode awsvpc \
--requires-compatibilities "FARGATE" \
--cpu 256 \
--memory 512 \
--volume \
"[
        {
            \"name\": \"files_wordpress\",
            \"efsVolumeConfiguration\": {
                \"fileSystemId\": \"fs-12345678\",
                \"rootDirectory\": \"/\",
                \"transitEncryption\": \"ENABLED\",
                \"authorizationConfig\": {
                        \"iam\": \"DISABLED\"
                }
            }
        }
]" \
--container-definitions \
"[
{
    \"name\": \"nginx\",
    \"image\": \"$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$target_nginx_image_name\",
    \"cpu\": 0,
    \"memory\": 256,
    \"portMappings\": [
      {
        \"containerPort\": 80,
        \"hostPort\": 80
      }
    ],
    \"mountPoints\": [
     {
       \"readOnly\": false,
       \"sourceVolume\": \"files_wordpress\",
       \"containerPath\": \"/var/wordpress_plugins\"
     }
    ],
    \"command\": [\"sh\", \"-c\", \"nginx\", \"-g\", \"daemon off;\"],
    \"logConfiguration\": {
      \"logDriver\": \"awslogs\",
      \"options\": {
        \"awslogs-region\": \"ap-southeast-1\",
        \"awslogs-group\": \"content-site-ecs-staging\",
        \"awslogs-stream-prefix\": \"ecs-staging\"
      }
    }
}
]"

  if [ $? != 0 ];then
       echo -e "\033[31m Nginx New task definition or its new revision failed to create \033[0m"
  else
       echo -e "\033[34m Nginx New task definition or its new revision created. \033[0m"
  fi

aws ecs register-task-definition \
--family $PHP_APP_NAME \
--task-role-arn arn:aws:iam::1234567890:role/AmazonECSTaskExecutionRole \
--execution-role-arn arn:aws:iam::1234567890:role/AmazonECSTaskExecutionRole \
--network-mode awsvpc \
--requires-compatibilities "FARGATE" \
--cpu 256 \
--memory 512 \
--volume \
"[
        {
            \"name\": \"files_wordpress\",
            \"efsVolumeConfiguration\": {
                \"fileSystemId\": \"fs-12345678\",
                \"rootDirectory\": \"/\",
                \"transitEncryption\": \"ENABLED\",
                \"authorizationConfig\": {
                        \"iam\": \"DISABLED\"
                }
            }
        }
]" \
--container-definitions \
"[
  {
    \"name\": \"php\",
    \"image\": \"$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$target_php_image_name\",
    \"cpu\": 0,
    \"memory\": 256,
    \"portMappings\": [
      {
        \"containerPort\": 9000,
        \"hostPort\": 9000
      }
    ],
    \"mountPoints\": [
     {
       \"readOnly\": false,
       \"sourceVolume\": \"files_wordpress\",
       \"containerPath\": \"/var/wordpress_plugins\"
     }
    ],
    \"logConfiguration\": {
      \"logDriver\": \"awslogs\",
      \"options\": {
        \"awslogs-region\": \"ap-southeast-1\",
        \"awslogs-group\": \"content-site-ecs-staging\",
        \"awslogs-stream-prefix\": \"ecs-staging\"
      }
    }
  }
]"

  if [ $? != 0 ];then
       echo -e "\033[31m PHP New task definition or its new revision failed to create \033[0m"
  else
       echo -e "\033[34m PHP New task definition or its new revision created. \033[0m"
  fi

else
  echo -e "\033[31m This is a resources deletion operation. \033[0m"

fi
