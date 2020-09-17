#!/bin/bash

export AWS_ACCESS_KEY_ID=`curl -s  -H "X-Vault-Token: $VAULT_TOKEN" -X GET http://$vault_server_ip:8200/v1/aws/aws_credential | jq -r .data.AWS_ACCESS_KEY_ID`

export AWS_SECRET_ACCESS_KEY=`curl -s  -H "X-Vault-Token: $VAULT_TOKEN" -X GET http://$vault_server_ip:8200/v1/aws/aws_credential | jq -r .data.AWS_SECRET_ACCESS_KEY`

if [ "$AWS_ACCESS_KEY_ID" == "null" ]||[ "$AWS_SECRET_ACCESS_KEY" == "null" ];then
   echo -e "\033[31m Vault token expired \033[0m"
   exit 1
fi

alb_target_group_name=`echo $alb_target_group_name|tr "_" "-"`

alb_target_group=`aws elbv2  describe-target-groups --load-balancer-arn $alb_arn |jq -c '.TargetGroups[]|select(.TargetGroupName| contains("'"$alb_target_group_name"'"))' | jq -r '.TargetGroupName' | grep -Fxw $alb_target_group_name`

if [ $deletion_mark -ne 1 ];then
  if [ -z $alb_target_group ];then
    aws elbv2 create-target-group \
    --name $alb_target_group_name \
    --protocol HTTP \
    --port 80 \
    --target-type ip \
    --vpc-id vpc-1234567890000 \
    --health-check-path /readme.html \
    --matcher HttpCode=200

    if [ $? != 0 ];then
       echo -e "\033[31m ALB target group failed to create \033[0m"
    else
       echo -e "\033[34m ALB target group created. \033[0m"
    fi
  else
    echo -e "\033[31m ALB target group already exists. \033[0m"
  fi
else
  echo -e "\033[31m This is a resources deletion operation. \033[0m"
fi
