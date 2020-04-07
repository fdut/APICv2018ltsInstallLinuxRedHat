
# install yum-utils
sudo yum install yum-utils --assumeyes

# Install make
sudo yum install make --assumeyes

# install nslookup
sudo yum install bind-utils --assumeyes

# install nmap-ncat to use neat to test port open
sudo yum install nmap-ncat --assumeyes

FILE=$HOME/bin
if [ -d "$FILE" ]; then
    echo "$FILE already exist"
else 
    echo "Create $FILE"
    mkdir $FILE
fi

# Install jq
wget -O jq https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64
chmod +x ./jq
sudo cp jq $HOME/bin

# Install apicops
wget -O apicops https://github.com/ibm-apiconnect/apicops/releases/download/v0.2.69/apicops-linux 
chmod +x ./apicops
sudo cp apicops $HOME/bin

# Create directory for apic k8s log 
sudo mkdir /var/apic

