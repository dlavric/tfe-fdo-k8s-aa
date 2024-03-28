#!/bin/bash

if [ -z $1 ] || [ -z $2 ] || [ -z $3 ] ; then
  echo "## ERROR: Script is missing an argument, syntax should be as the following:##"
  echo "##./tfe-create-admin-user.sh <tfe_fqdn> <email address> <password dlavric user>##" 
  echo "##                      ------->>>>>example<<<<<<-------                       ##"                   
  echo "## ./tfe-create-admin-user.sh tfe-k8s.daniela.sbx.hashidemos.io daniela@tfe.com DanielaPassword##"
  exit 1
fi

HOSTNAME=$1
EMAIL_ADDRESS=$2
PASSWORD=$3

#We have to wait for TFE be fully functioning before we can continue
while true; do
    if curl -kI "https://$HOSTNAME/admin" 2>&1 | grep -w "200\|301" ;
    then
        echo "TFE is up and running"
        echo "Will continue in 1 minutes with the final steps"
        sleep 3
        break
    else
        echo "TFE is not available yet. Please wait..."
        sleep 5
    fi
done



# Get the IACT token
echo "Get the IACT token"
IACT_TOKEN=`curl -s https://$HOSTNAME/admin/retrieve-iact`

# Create the first admin user
echo "Create the first admin user called dlavric and get the token"
ADMIN_TOKEN=`curl -k --header "Content-Type: application/json" --request POST --data "{\"username\": \"dlavric\",\"email\": \"$EMAIL_ADDRESS\", \"password\": \"$PASSWORD\"}"   --url https://$HOSTNAME/admin/initial-admin-user?token=$IACT_TOKEN`

TOKEN=`echo $ADMIN_TOKEN | jq -r .token`

# create an organization named daniela-org
echo "Create the daniela-org organization"
curl -k \
 --header "Authorization: Bearer $TOKEN" \
 --header "Content-Type: application/vnd.api+json" \
 --request POST \
 --data "{\"data\": {\"type\": \"organizations\", \"attributes\": {\"name\": \"daniela-org\",\"email\": \"$EMAIL_ADDRESS\"}}}" \
 https://$HOSTNAME/api/v2/organizations      

 echo "Finished!"