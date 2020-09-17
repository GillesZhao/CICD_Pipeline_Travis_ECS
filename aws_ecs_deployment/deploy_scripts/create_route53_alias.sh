#!/bin/bash

export AWS_ACCESS_KEY_ID=`curl -s  -H "X-Vault-Token: $VAULT_TOKEN" -X GET http://$vault_server_ip:8200/v1/aws/aws_credential | jq -r .data.AWS_ACCESS_KEY_ID`

export AWS_SECRET_ACCESS_KEY=`curl -s  -H "X-Vault-Token: $VAULT_TOKEN" -X GET http://$vault_server_ip:8200/v1/aws/aws_credential | jq -r .data.AWS_SECRET_ACCESS_KEY`

if [ "$AWS_ACCESS_KEY_ID" == "null" ]||[ "$AWS_SECRET_ACCESS_KEY" == "null" ];then
   echo -e "\033[31m Vault token expired \033[0m"
   exit 1
fi

#route53_dns_lower_case=`echo $route53_dns | tr 'A-Z' 'a-z'`

route53_alias=`aws route53 list-resource-record-sets --hosted-zone-id 1234567890000 | jq -c '.ResourceRecordSets[]| select(.Name| contains("'"$route53_dns"'"))' | jq -r .Name | grep -iFxw $route53_dns`

if [ $deletion_mark -ne 1 ];then

  if [ -z "$route53_alias" ];then

   aws route53 change-resource-record-sets --hosted-zone-id 1234567890000 --change-batch '{ "Comment": "Route53 creating a record set", "Changes": [ { "Action": "CREATE", "ResourceRecordSet": { "Name": "'"$route53_dns"'", "Type": "A", "AliasTarget":{ "HostedZoneId": "1234567890000", "DNSName": "'"$alb_dns"'","EvaluateTargetHealth": false} } } ] }'

   if [ $? != 0 ];then
       echo -e "\033[31m Route53 alias DNS A record failed to create \033[0m"
   else
       echo -e "\033[34m Route53 alias DNS A record created. \033[0m"
   fi
  else
   echo -e "\033[31m Route53 alias DNS A record already exists \033[0m"
  fi

else
  echo -e "\033[31m This is a resources deletion operation. \033[0m"
fi
