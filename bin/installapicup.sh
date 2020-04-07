pwd
. $(pwd)/envfile

sudo cp $sources/$apicupversion /usr/bin/apicup
sudo chmod +x /usr/bin/apicup
sudo apicup version --accept-license
