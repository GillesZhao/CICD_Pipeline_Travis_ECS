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

rule_host_head_value=`aws elbv2 describe-rules --listener-arn $alb_listener_arn | jq -c '.Rules[]| select(.Conditions[].Values[]| contains("'"$dns_host"'"))' | jq -r .Conditions[].Values[] | grep -iFxw $dns_host`

if [ $deletion_mark -ne 1 ];then

  if [ -z "$rule_host_head_value" ];then
    aws elbv2 create-rule \
    --listener-arn $alb_listener_arn \
    --priority $RANDOM \
    --conditions '{ "Field": "host-header", "HostHeaderConfig": { "Values":["'"$dns_host"'"]  }  }' \
    --actions Type=forward,TargetGroupArn=$targetgrouparn
    if [ $? != 0 ];then
       echo -e "\033[31m listener rule failed to create \033[0m"
    else
       echo -e "\033[34m listener rule created \033[0m"
    fi
  else
    echo -e "\033[31m listener rule already exists \033[0m"
  fi

else
  echo -e "\033[31m This is a resources deletion operation. \033[0m"
fi
