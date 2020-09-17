#!/bin/bash

export AWS_ACCESS_KEY_ID=`curl -s  -H "X-Vault-Token: $VAULT_TOKEN" -X GET http://$vault_server_ip:8200/v1/aws/aws_credential | jq -r .data.AWS_ACCESS_KEY_ID`

export AWS_SECRET_ACCESS_KEY=`curl -s  -H "X-Vault-Token: $VAULT_TOKEN" -X GET http://$vault_server_ip:8200/v1/aws/aws_credential | jq -r .data.AWS_SECRET_ACCESS_KEY`

if [ "$AWS_ACCESS_KEY_ID" == "null" ]||[ "$AWS_SECRET_ACCESS_KEY" == "null" ];then
   echo -e "\033[31m Vault token expired \033[0m"
   exit 1
fi

alb_target_group_name=`echo $alb_target_group_name|tr "_" "-"`
dns_host=`echo $dns_host |tr "_" "-"`

targetgrouparn=`aws elbv2 describe-target-groups | grep -w $alb_target_group_name | grep -i TargetGroupArn`
targetgrouparn=`echo ${targetgrouparn##*: \"}`
targetgrouparn=`echo ${targetgrouparn%%\"*}`

cloudmap_service_id=`aws servicediscovery list-services | jq -c '.Services[]| select(.Name| contains("'"$ecs_service_php_name"'"))' | jq -r '.Id'`

rule_arn=`aws elbv2 describe-rules --listener-arn $alb_listener_arn | jq -c '.Rules[]| select(.Conditions[].Values[]| contains("'"$dns_host"'"))' | jq -r '.RuleArn'`

service_nginx_status=`aws ecs describe-services --cluster $cluster_name --services $ecs_service_nginx_name | jq -r '.services[].status'`
service_php_status=`aws ecs describe-services --cluster $cluster_name --services $ecs_service_php_name | jq -r '.services[].status'`

if [ $deletion_mark -eq 1 ];then

#Delete ALB listener rule
   if [ -n "$rule_arn" ];then
    aws elbv2 delete-rule \
     --rule-arn $rule_arn
    echo -e "\033[31m ALB listener rule deleted \033[0m"
   else
    echo -e "\033[31m ALB listener rule doesn't exist or already deleted \033[0m"
   fi

#Delete ALB target group
   if [ -n "$targetgrouparn" ];then
    aws elbv2 delete-target-group \
    --target-group-arn $targetgrouparn
    echo -e "\033[31m ALB target group deleted \033[0m"
   else
    echo -e "\033[31m ALB target group doesn't exist or already deleted \033[0m"
   fi

#Delete ECS service
   if [ "$service_nginx_status" == "ACTIVE" ];then
     aws ecs delete-service \
      --cluster $cluster_name \
      --service $ecs_service_nginx_name \
      --force
     echo -e "\033[31m ECS service $ecs_service_nginx_name deleted \033[0m"
   else
     echo -e "\033[31m ECS service $ecs_service_nginx_name doesn't exist or already deleted \033[0m"
   fi

   if [ "$service_php_status" == "ACTIVE" ];then
     aws ecs delete-service \
      --cluster $cluster_name \
      --service $ecs_service_php_name \
      --force
     echo -e "\033[31m ECS service $ecs_service_php_name deleted \033[0m"
   else
     echo -e "\033[31m ECS service $ecs_service_php_name doesn't exist or already deleted \033[0m"
   fi

#Delete Cloud Map services
   if [ -n "$cloudmap_service_id" ];then
     sleep 10
     aws servicediscovery delete-service \
     --id $cloudmap_service_id
     if [ $? != 0 ];then
       echo -e "\033[31m php nodes instance haven't deregisted, sleep 30s and delete again!\033[0m"
       sleep 30
       aws servicediscovery delete-service \
       --id $cloudmap_service_id
     fi
     echo -e "\033[31m Cloud Map services deleted \033[0m"
   else
     echo -e "\033[31m Cloud Map services doesn't exist or already deleted \033[0m"
   fi


# #Delete Route53 record set
# # TRAVIS_BRANCH_LOWER_CASE=`echo $route53_dns_name | tr 'A-Z' 'a-z'`
#
# route53_alias=`aws route53 list-resource-record-sets --hosted-zone-id Z14JIGC687R7OP | jq -c '.ResourceRecordSets[]| select(.Name| contains("'"$TRAVIS_BRANCH_LOWER_CASE"'"))' | jq -r .Name | grep -iFxw $TRAVIS_BRANCH_LOWER_CASE`
#
#    if [ -n "$route53_alias" ];then
#      aws route53 change-resource-record-sets \
#       --hosted-zone-id Z14JIGC687R7OP \
#       --change-batch '{ "Comment": "Route53 creating a record set", "Changes": [ { "Action": "DELETE", "ResourceRecordSet": { "Name": "'"$TRAVIS_BRANCH_LOWER_CASE"'.xxxxx.xyz.", "Type": "A", "AliasTarget":{ "HostedZoneId": "Z1LMS91P8CMLE5", "DNSName": "'"$alb_dns"'","EvaluateTargetHealth": false} } } ] }'
#
#       echo -e "\033[31m Route53 record set deleted \033[0m"
#    else
#     echo -e "\033[31m Route53 record set doesn't exist or already deleted \033[0m"
#    fi
#


#Delete task definition
   task_def_nginx_arn=`aws ecs describe-services --cluster $cluster_name --services $ecs_service_nginx_name  | jq -r '.services[].taskDefinition'`
   task_def_php_arn=`aws ecs describe-services --cluster $cluster_name --services $ecs_service_php_name  | jq -r '.services[].taskDefinition'`

   if [ -n "$task_def_nginx_arn" ];then
     aws ecs deregister-task-definition --task-definition $task_def_nginx_arn
     echo -e "\033[31m Task definition $NGINX_APP_NAME deleted \033[0m"
   else
     echo -e "\033[31m Task definition $NGINX_APP_NAME doesn't exist or already deleted \033[0m"
   fi

   if [ -n "$task_def_php_arn" ];then
     aws ecs deregister-task-definition --task-definition $task_def_php_arn
     echo -e "\033[31m Task definition $PHP_APP_NAME deleted \033[0m"
   else
     echo -e "\033[31m Task definition $PHP_APP_NAME doesn't exist or already deleted \033[0m"
   fi

else
  echo -e "\033[31m This is a resources creation operation. Nothing will be destroyed. \033[0m"
fi
