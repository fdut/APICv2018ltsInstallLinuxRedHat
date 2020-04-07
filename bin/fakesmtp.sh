echo --------
echo start fakesmtp
echo --------

CURRENTPWD=$PWD
# Install java
#sudo yum install java-1.8.0-openjdk-devel --assumeyes

# Install fakesmtp
#cp -r $PWD/fixcentral/fakesmtp $HOME
#cd $HOME/fakesmtp
#java -jar fakeSMTP-2.0.jar -o ./emails/ -b -s -p 2525 &
#cd $CURRENTPWD


# Install Mailhog

FILE=$HOME/fakesmtp
if [ -d "$FILE" ]; then
    echo "$FILE is a directory and exist"
else 
    echo "Create $FILE"
    mkdir $FILE
fi

if ! [ -x "$(command -v MailHog_linux_amd64)" ]; then
	echo "Installing MailHog_linux_amd64"
	curl --silent -OL https://github.com/mailhog/MailHog/releases/download/v1.0.0/MailHog_linux_amd64
	chmod +x MailHog_linux_amd64
	mv MailHog_linux_amd64 $HOME/bin
fi

echo --------
echo start MailHog
echo --------
nohup MailHog_linux_amd64 -smtp-bind-addr ":2525" -storage "maildir" -jim-accept 1 -jim-disconnect 0 -maildir-path $HOME/fakesmtp/emails > $HOME/fakesmtp/MailHog.log 2>&1 &

retVal=$?
if [ $retVal -ne 0 ]; then
    echo "Error with $1 -> KO"
	exit 1
fi

echo "MailHog email server setup to listen on host '$(hostname)' port 2525."