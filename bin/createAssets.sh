pwd
. $PWD/envfile

echo --------
echo get access token
echo --------

access_token=$(curl -ks  "https://$ep_cm/api/token" \
 -H 'Content-Type: application/json' \
 -H 'Accept: application/json' \
 --data-binary "{\"username\":\"admin\",\"password\":\"$admin_pass\",\"realm\":\"admin/default-idp-1\",\"client_id\":\"caa87d9a-8cd7-4686-8b6e-ee2cdc5ee267\",\"client_secret\":\"3ecff363-7eb3-44be-9e07-6d4386c48b0b\",\"grant_type\":\"password\"}" |  jq .access_token | sed -e s/\"//g  )

echo $access_token

echo --------
echo get cloud org_url
echo --------

cloud_org_url=$(curl -sk  "https://$ep_cm/api/cloud/orgs" -H "Authorization: Bearer $access_token" -H 'Accept-Encoding: gzip, deflate, br' -H 'Accept-Language: en-GB,en-US;q=0.9,en;q=0.8'  -H 'Accept: application/json'  -H 'Connection: keep-alive' --compressed | jq '.results[] | select(.name=="admin")| .url' | sed -e s/\"//g);
echo --------
echo $cloud_org_url
echo --------

echo --------
echo get user_registry
echo --------

user_registry=$(curl -sk "$cloud_org_url/user-registries" \
 -H "Authorization: Bearer $access_token" \
 -H 'Accept: application/json' \
 --compressed | jq '.results[] | select(.name=="api-manager-lur")| .url' | sed -e s/\"//g);

echo --------
echo $user_registry
echo --------

echo ---------
echo Create User $porg_user in User Registry
echo ---------

porg_user_url=$(curl -sk "$user_registry/users" \
 -H "Authorization: Bearer $access_token" \
 -H 'Content-Type: application/json' \
 -H 'Accept: application/json' \
 -H 'Connection: keep-alive' \
 --data-binary "{\"username\":\"$porg_user\",\"email\":\"apic@demo.com\",\"first_name\":\"Demo\",\"last_name\":\"User\",\"password\":\"$porg_password\"}" | jq .url | sed -e s/\"//g);

echo --------
echo $porg_user_url
echo --------

echo ---------
echo Create Provider Organization
echo ---------

porg_url=$(curl -sk "https://$ep_cm/api/cloud/orgs" \
 -H "Authorization: Bearer $access_token"\
 -H 'Content-Type: application/json'\
 -H 'Accept: application/json'\
 -H 'Connection: keep-alive'\
 --data-binary "{\"title\":\"Demo\",\"name\":\"$porg_name\",\"owner_url\":\"$porg_user_url\"}" \
 --compressed | jq .url | sed -e s/\"//g);


echo --------
echo $porg_url
echo --------


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

api=`cat $(pwd)/assets/helloAPI.json`;

echo --------
echo API to be uploaded:
echo $api
echo --------

echo ---------
echo Push Draft API 1
echo ---------

draftAPI=$(curl -sk "https://$ep_cm/api/orgs/$porg_name/drafts/draft-apis"\
 -H "Accept: application/json"\
 --compressed\
 -H "authorization: Bearer $porg_token"\
 -H "content-type: application/json"\
 -H "Connection: keep-alive"\
 --data "{\"draft_api\":$api}" );

echo $draftAPI;

product=`cat $(pwd)/assets/helloProduct.json`;
echo --------
echo Product to be uploaded:
echo $product
echo --------

echo ---------
echo Push Draft Product
echo ---------

draftProductUrl=$(curl -sk "https://$ep_cm/api/orgs/$porg_name/drafts/draft-products"\
 -H "Accept: application/json"\
 --compressed\
 -H "authorization: Bearer $porg_token"\
 -H "content-type: application/json"\
 -H "Connection: keep-alive"\
 --data "{\"draft_product\":$product}" | jq .url | sed -e s/\"//g);

echo $draftProductUrl

echo ---------
echo Publish Product
echo ---------

publish_response=$(curl -sk "https://$ep_cm/api/catalogs/$porg_name/sandbox/publish-draft-product"\
 -H "Accept: application/json"\
 --compressed\
 -H "authorization: Bearer $porg_token"\
 -H "content-type: application/json"\
 -H "Connection: keep-alive"\
 --data "{\"draft_product_url\":\"$draftProductUrl\"}" );

echo $publish_response
echo ---------
echo Hello World API and Product successfully published to new Provider Org $porg_name. Login with $porg_user / $porg_password at $ep_apim
