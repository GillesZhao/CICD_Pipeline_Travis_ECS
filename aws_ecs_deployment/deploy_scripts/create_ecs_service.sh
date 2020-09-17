#!/bin/bash

export AWS_ACCESS_KEY_ID=`curl -s  -H "X-Vault-Token: $VAULT_TOKEN" -X GET http://$vault_server_ip:8200/v1/aws/aws_credential | jq -r .data.AWS_ACCESS_KEY_ID`

export AWS_SECRET_ACCESS_KEY=`curl -s  -H "X-Vault-Token: $VAULT_TOKEN" -X GET http://$vault_server_ip:8200/v1/aws/aws_credential | jq -r .data.AWS_SECRET_ACCESS_KEY`

if [ "$AWS_ACCESS_KEY_ID" == "null" ]||[ "$AWS_SECRET_ACCESS_KEY" == "null" ];then
   echo -e "\033[31m Vault token expired \033[0m"
   exit 1
fi

alb_target_group_name=`echo $alb_target_group_name|tr "_" "-"`

targetgrouparn=`aws elbv2 describe-target-groups | grep -w $alb_target_group_name | grep -i TargetGroupArn`
targetgrouparn=`echo ${targetgrouparn##*: \"}`
targetgrouparn=`echo ${targetgrouparn%%\"*}`


cloudmap_service=`aws servicediscovery list-services | jq -c '.Services[]| select(.Name| contains("'"$ecs_service_php_name"'"))' | jq -r .Name | grep -iFxw $ecs_service_php_name`

service_nginx_status=`aws ecs describe-services --cluster $cluster_name --services $ecs_service_nginx_name | jq -r '.services[].status'`
service_php_status=`aws ecs describe-services --cluster $cluster_name --services $ecs_service_php_name | jq -r '.services[].status'`


if [ $deletion_mark -ne 1 ];then

  if [ -z "$cloudmap_service" ];then
  aws servicediscovery create-service \
 --name $ecs_service_php_name \
 --namespace-id ns-1234567890000 \
 --health-check-custom-config "FailureThreshold=1" \
 --dns-config '{ "RoutingPolicy": "MULTIVALUE", "DnsRecords": [{"Type": "A", "TTL": 1 }]}'

    if [ $? != 0 ];then
       echo -e "\033[31m cloudmap service failed to create \033[0m"
    else
       cloudmaparn=`aws servicediscovery list-services | jq -c '.Services[]| select(.Name| contains("'"$ecs_service_php_name"'"))' | jq -r .Arn`
       echo -e "\033[34m cloudmap service created \033[0m"
    fi
  else
    cloudmaparn=`aws servicediscovery list-services | jq -c '.Services[]| select(.Name| contains("'"$ecs_service_php_name"'"))' | jq -r .Arn`
    echo -e "\033[31m cloudmap service already exists \033[0m"
  fi

else
  echo -e "\033[31m This is a resources deletion operation. \033[0m"
fi


#service nginx
if [ $deletion_mark -ne 1 ];then

 if [ "$service_nginx_status" != "ACTIVE" ];then
 aws ecs create-service \
--cluster $cluster_name \
--service-name $ecs_service_nginx_name \
--task-definition $NGINX_APP_NAME \
--load-balancers "targetGroupArn=$targetgrouparn,containerName=nginx,containerPort=80" \
--desired-count $nginx_node_desired_count \
--launch-type FARGATE \
--platform-version 1.4.0 \
--deployment-configuration "maximumPercent=200,minimumHealthyPercent=100" \
--network-configuration "awsvpcConfiguration={subnets=[subnet-1234567890000,subnet-1234567890000,subnet-1234567890000],securityGroups=[sg-1234567890000],assignPublicIp=ENABLED}" \
--health-check-grace-period-seconds 0 \
--scheduling-strategy REPLICA \


  if [ $? != 0 ];then
       echo -e "\033[31m Nginx ECS service failed to create \033[0m"
  else
       echo -e "\033[34m Nginx ECS service created. \033[0m"
  fi

 else
    aws ecs update-service --cluster "$cluster_name" --service "$ecs_service_nginx_name" --desired-count $nginx_node_desired_count --task-definition $NGINX_APP_NAME

    if [ $? != 0 ];then
       echo -e "\033[31m ECS service nginx failed to update \033[0m"
    else
       echo -e "\033[34m ECS service nginx updated with new task definition revision. \033[0m"
    fi
 fi


#service php
 if [ "$service_php_status" != "ACTIVE" ];then
 aws ecs create-service \
--cluster $cluster_name \
--service-name $ecs_service_php_name \
--task-definition $PHP_APP_NAME \
--desired-count $php_node_desired_count \
--launch-type FARGATE \
--platform-version 1.4.0 \
--deployment-configuration "maximumPercent=200,minimumHealthyPercent=100" \
--network-configuration "awsvpcConfiguration={subnets=[subnet-1234567890000,subnet-1234567890000,subnet-1234567890000],securityGroups=[sg-1234567890000],assignPublicIp=ENABLED}" \
--scheduling-strategy REPLICA \
--service-registries registryArn=$cloudmaparn

  if [ $? != 0 ];then
       echo -e "\033[31m PHP ECS service failed to create \033[0m"
  else
       echo -e "\033[34m PHP ECS service created. \033[0m"
  fi

 else
    aws ecs update-service --cluster "$cluster_name" --service "$ecs_service_php_name" --desired-count $php_node_desired_count --task-definition $PHP_APP_NAME

    if [ $? != 0 ];then
       echo -e "\033[31m ECS service php failed to update \033[0m"
    else
       echo -e "\033[34m ECS service php updated with new task definition revision. \033[0m"
    fi
 fi

else
   echo -e "\033[31m This is a resources deletion operation. \033[0m"
fi
