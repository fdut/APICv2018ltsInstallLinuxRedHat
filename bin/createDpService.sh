pwd
. $(pwd)/envfile
echo --------
echo get access token
echo --------

access_token=$(curl -sk  "https://$ep_cm/api/token" \
 -H 'Content-Type: application/json' \
 -H 'Accept: application/json' \
 --data-binary "{\"username\":\"admin\",\"password\":\"$admin_pass\",\"realm\":\"admin/default-idp-1\",\"client_id\":\"caa87d9a-8cd7-4686-8b6e-ee2cdc5ee267\",\"client_secret\":\"3ecff363-7eb3-44be-9e07-6d4386c48b0b\",\"grant_type\":\"password\"}" |  jq .access_token | sed -e s/\"//g  )


echo curl -sk  "https://$ep_cm/api/token" \
 -H 'Content-Type: application/json' \
 -H 'Accept: application/json' \
 --data-binary "{\"username\":\"admin\",\"password\":\"$admin_pass\",\"realm\":\"admin/default-idp-1\",\"client_id\":\"caa87d9a-8cd7-4686-8b6e-ee2cdc5ee267\",\"client_secret\":\"3ecff363-7eb3-44be-9e07-6d4386c48b0b\",\"grant_type\":\"password\"}"
echo $access_token

echo --------
echo get integration_ep
echo --------

curl -sk  "https://$ep_cm/api/cloud/integrations/gateway-service/datapower-gateway" -H "Authorization: Bearer $access_token" -H 'Accept-Encoding: gzip, deflate, br' -H 'Accept-Language: en-GB,en-US;q=0.9,en;q=0.8'  -H 'Accept: application/json'  -H 'Connection: keep-alive' --compressed
integration_url=$(curl -sk  "https://$ep_cm/api/cloud/integrations/gateway-service/$ep_gwType" -H "Authorization: Bearer $access_token" -H 'Accept-Encoding: gzip, deflate, br' -H 'Accept-Language: en-GB,en-US;q=0.9,en;q=0.8'  -H 'Accept: application/json'  -H 'Connection: keep-alive' --compressed | jq .url | sed -e s/\"//g)

echo --------
echo $integration_url
echo --------

orgUrl=$(curl -sk "https://$ep_cm/api/cloud/orgs" \
 -H "Authorization: Bearer $access_token" \
 -H 'Accept: application/json' \
 --compressed | jq .results[0].url | sed -e s/\"//g);

tlsServer=$(curl -sk "$orgUrl/tls-server-profiles" \
 -H "Authorization: Bearer $access_token" \
 -H 'Accept: application/json' --compressed | jq .results[0].url  | sed -e s/\"//g);

tlsClientDefault=$(curl -sk "$orgUrl/tls-client-profiles" \
 -H "Authorization: Bearer $access_token" \
 -H 'Accept: application/json' --compressed | jq '.results[] | select(.name=="tls-client-profile-default")| .url' | sed -e s/\"//g);

tlsClientAnalytics=$(curl -sk "$orgUrl/tls-client-profiles" \
 -H "Authorization: Bearer $access_token" \
 -H 'Accept: application/json' --compressed | jq '.results[] | select(.name=="analytics-client-default")| .url' | sed -e s/\"//g);

echo ---------
echo Create gateway Service
echo ---------

dpUrl=$(curl -sk "$orgUrl/availability-zones/availability-zone-default/gateway-services" \
 -H "Authorization: Bearer $access_token" \
 -H 'Content-Type: application/json' \
 -H 'Accept: application/json' \
 -H 'Connection: keep-alive' \
 --data-binary "{\"name\":\"localapigateway\",\"title\":\"Local API Gateway\",\"endpoint\":\"https://$ep_gwd\",\"api_endpoint_base\":\"https://$ep_gw\",\"tls_client_profile_url\":\"$tlsClientDefault\",\"gateway_service_type\":\"$ep_gwType\",\"visibility\":{\"type\":\"public\"},\"sni\":[{\"host\":\"*\",\"tls_server_profile_url\":\"$tlsServer\"}],\"integration_url\":\"$integration_url\"}" \
 --compressed | jq .url | sed -e s/\"//g);

echo ---------
echo Set gateway Service as default for catalogs
echo ---------

setGWdefault=$(curl -sk --request PUT "https://$ep_cm/api/cloud/settings" \
  -H "Authorization: Bearer $access_token" \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json' \
  -H 'Connection: keep-alive' \
  --data "{\"gateway_service_default_urls\": [\"$dpUrl\"]}");

echo $setGWdefault

echo ---------
echo Create Analytics Service
echo ---------

analytUrl=$(curl -sk "$orgUrl/availability-zones/availability-zone-default/analytics-services" \
 -H "Authorization: Bearer $access_token"\
 -H 'Content-Type: application/json'\
 -H 'Accept: application/json'\
 -H 'Connection: keep-alive'\
 --data-binary "{\"title\":\"Local Analytics\",\"name\":\"analytics-service\",\"endpoint\":\"https://$ep_ac\"}" \
 --compressed | jq .url | sed -e s/\"//g);

 echo ---------
 echo Associate Analytics Service with Gateway
 echo ---------

 curl -sk -X PATCH \
   "$orgUrl/availability-zones/availability-zone-default/gateway-services/localapigateway" \
 -H 'Accept: application/json' \
 -H "Authorization: Bearer $access_token"\
 -H 'Cache-Control: no-cache' \
 -H 'Content-Type: application/json' \
 --data-binary "{\"analytics_service_url\":	\"$analytUrl\" }"

echo ---------
echo Create Mail Server
echo ---------
mailServerUrl=$(curl -sk "$orgUrl/mail-servers"\
 -H "Accept: application/json"\
 --compressed\
 -H "authorization: Bearer $access_token"\
 -H "content-type: application/json"\
 -H "Connection: keep-alive"\
 --data "{\"title\":\"autoCreatedEMailServer$(date +%s)\",\"name\":\"autocreatedemailserver$(date +%s)\",\"host\":\"$smtpServer\",\"port\":$smtpServerPort,\"credentials\":{\"username\":\"$smtpUser\",\"password\":\"$smtpPass\"}}" | jq .url);

echo ---------
echo setReplyTo
echo ---------
curl -sk "https://$ep_cm/api/cloud/settings"\
 -X PUT\
 -H "Accept: application/json"\
 -H "authorization: Bearer $access_token" \
 -H "content-type: application/json"\
 --data "{\"mail_server_url\":$mailServerUrl,\"email_sender\":{\"name\":\"APIC Administrator\",\"address\":\"$admin_email\"}}"

echo ---------
echo create portal
echo ---------
curl -sk "$orgUrl/availability-zones/availability-zone-default/portal-services"\
 -H "Accept: application/json"\
 -H "authorization: Bearer $access_token"\
 -H "content-type: application/json"\
 --data "{\"title\":\"Local Portal\",\"name\":\"portal-service\",\"endpoint\":\"https://$ep_padmin\",\"web_endpoint_base\":\"https://$ep_portal\",\"visibility\":{\"group_urls\":null,\"org_urls\":null,\"type\":\"public\"}}"
