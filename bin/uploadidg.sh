pwd
. $(pwd)/envfile

sudo docker login $registry -u admin -p admin
DMPIMGFULLNAME=`sudo docker load -i $sources/$dmpimagefilename | awk '{ print $3 }'` 
IDGIMGFULLNAME=`sudo docker load -i $sources/$idgimagefilename | awk '{ print $3 }'` 
echo "DMPIMGFULLNAME = $DMPIMGFULLNAME"
echo "IDGIMGFULLNAME = $IDGIMGFULLNAME" 

DMPIMGTARGETNAME=`apicup version --images --accept-license | grep monitor | awk '{ print $2 }' | awk -F"/" '{ print $2 }' `
IDGIMGTARGETNAME=`apicup version --images --accept-license | grep datapower-api-gateway | awk '{ print $2 }' | awk -F"/" '{ print $2 }'`

echo "DMPIMGTARGETNAME = $DMPIMGTARGETNAME"
echo "IDGIMGTARGETNAME = $IDGIMGTARGETNAME"

sudo docker tag $DMPIMGFULLNAME $registry/$DMPIMGTARGETNAME
sudo docker tag $IDGIMGFULLNAME $registry/$IDGIMGTARGETNAME

sudo docker push  $registry/$DMPIMGTARGETNAME
sudo docker push  $registry/$IDGIMGTARGETNAME

