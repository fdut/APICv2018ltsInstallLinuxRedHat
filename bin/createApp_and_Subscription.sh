#!/bin/bash
pwd
. $(pwd)/envfile
source $(pwd)/envfile

echo ---------
echo Login as the pOrg Owner and get token
echo ---------
porg_token=$(curl -sk \
  "https://$ep_cm/api/token" \
-H 'Accept: application/json' \
-H 'Cache-Control: no-cache' \
-H 'Content-Type: application/json' \
--data-binary "{\"username\":\"${porg_user}\",\"password\":\"${porg_password}\",\"realm\":\"provider/default-idp-2\",\"client_id\":\"caa87d9a-8cd7-4686-8b6e-ee2cdc5ee267\",\"client_secret\":\"3ecff363-7eb3-44be-9e07-6d4386c48b0b\",\"grant_type\":\"password\"}" |  jq .access_token | sed -e s/\"//g  );

echo --------
echo $porg_token
echo --------

echo ---------
echo Get Sandbox Test Org Url
echo ---------

consumerorg=$(curl -sk --request GET \
  --url "https://$ep_cm/api/catalogs/$porg_name/sandbox/consumer-orgs" \
  --header 'Accept: application/json' \
  -H "authorization: Bearer $porg_token" \
   --header 'cache-control: no-cache' | jq '.results[] | select(.name=="sandbox-test-org")| .url' | sed -e s/\"//g);

echo $consumerorg;

echo ---------
echo Create App
echo ---------

app=$(curl -sk "$consumerorg/apps" \
-H 'Content-Type: application/json' \
-H 'Accept: application/json' \
-H 'Connection: keep-alive' \
  -H "authorization: Bearer $porg_token" \
   --data-binary '{"title":"Demo Client","name":"demo-client","redirect_endpoints":[]}' --compressed);

appurl=$(echo $app | jq .url | sed -e s/\"//g);

echo $appurl

app_clientid=$(echo $app | jq .client_id | sed -e s/\"//g);

echo ---------
echo Get Published Product
echo ---------

publishedprod=$(curl -sk --request GET \
  --url "https://$ep_cm/api/catalogs/$porg_name/sandbox/products/helloworld/1.0.0" \
  --header 'Accept: application/json' \
  -H "authorization: Bearer $porg_token" \
   --header 'cache-control: no-cache' | jq .url | sed -e s/\"//g);

echo $publishedprod;

echo "ClientID: $app_clientid"
if [ -n "$app_clientid" ]
then
      echo "App already exists"
      appurl_temp=$(echo $consumerorg | sed -e s/consumer-orgs/apps/g )
      appurl="$appurl_temp/demo-client"
      credentialurl=$(curl -sk \
      --url "$appurl" \
      --header 'Accept: application/json' \
      -H "authorization: Bearer $porg_token" \
       --header 'cache-control: no-cache' | jq .app_credential_urls | sed -e s/\"//g);
       echo "credentials: $credentialurl"

      app_clientid=$(curl -sk \
       --url $credentialurl \
       --header 'Accept: application/json' \
       -H "authorization: Bearer $porg_token" \
        --header 'cache-control: no-cache' | jq .client_id | sed -e s/\"//g);
       echo $app_clientid
fi

echo ---------
echo Subscribe to Product
echo ---------

subscriptionURL=$(curl -sk "$appurl/subscriptions" \
-H 'Content-Type: application/json' \
-H 'Accept: application/json' \
-H 'Connection: keep-alive' \
--header "Authorization: Bearer $porg_token" \
--data-binary "{\"product_url\":\"$publishedprod\",\"plan\":\"default-plan\"}" | jq .url | sed -e s/\"//g);

echo $subscriptionURL;

echo "while true; do clear; curl -kv https://$ep_gw/demo/sandbox/hello -H 'x-ibm-client-id: $app_clientid'; sleep 10;  done" > assets/demo-client.sh

chmod +x assets/demo-client.sh

echo "*********************************************"
echo " "
echo " "
echo " Endpoint for cloud manager : https://$ep_cm/manager    admin/$admin_pass"
echo " "
echo " Endpoint for API manager : https://$ep_apim/manager    $porg_user/$porg_password"
echo " "
echo " Endpoint for API Gateway : https://$ep_gw/manager"
echo " "
echo " ------"
echo " "
echo " Use assets/demo-client.sh to test the API"
echo " "
echo "*********************************************"