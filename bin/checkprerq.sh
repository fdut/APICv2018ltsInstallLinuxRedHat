
pwd
. $(pwd)/envfile


echo "----------------------------------------------------------"
echo "    utility function"
echo "----------------------------------------------------------"

check_ep () {
	echo "Check endpoint $1"
	nslookup $1
	retVal=$?
	if [ $retVal -ne 0 ]; then
    		echo "Error with $1 -> KO"
		exit 1
	fi
}

check_file () {
	if [ -f "$1" ]; then
    		echo "$1 exist --> OK"
	else
    		echo "$1 does not exist  -> KO"
    		exit 1
	fi
}

check_directory () {
	if [ -d "$1" ]; then
	    echo "$1 exist and is a directory --> OK"
	else
	    echo "$1 does not exist  -> KO"
	    exit 1
	fi
}

check_port () {
	nc -z -v -w5 $1 $2
        if [ $? -ne 0 ]; then
                echo "--> Port $2 for $1 is unavailable"
		exit 1
        fi
}

check_ip () {
	if [ "`ip -f inet addr show | grep $1`" == "" ]; then
 		echo "ip $1 is not available --> KO"
		exit 1
	else
	    echo "ip $1 is available  -> OK"
	fi
}

echo "-----------------------------------------------------------"
echo " Check API Connect installation images"
echo "-----------------------------------------------------------"

check_file $sources/$apicupversion
check_file $sources/management-images-kubernetes_lts_$apicversion.tgz
check_file $sources/portal-images-kubernetes_lts_$apicversion.tgz
check_file $sources/portal-images-kubernetes_lts_$apicversion.tgz

check_file $sources/$dmpimagefilename
check_file $sources/$idgimagefilename

echo "-----------------------------------------------------------"
echo " Check Storage Path (Hostpath yaml -> /var/apic)"
echo "-----------------------------------------------------------"

check_directory /var/apic

echo "-----------------------------------------------------------"
echo " Check apic endpoint "
echo "-----------------------------------------------------------"

check_ep $ep_api
check_ep $ep_apim
check_ep $ep_cm
check_ep $ep_consumer
check_ep $ep_gw
check_ep $ep_gwd
check_ep $ep_ai
check_ep $ep_ac
check_ep $ep_padmin
check_ep $ep_portal

echo "-----------------------------------------------------------"
echo " Check IP  "
echo "-----------------------------------------------------------"

echo " Check api server IP"
check_ip $apiserver_advertise_address


#echo "-----------------------------------------------------------"
#echo " Check port open "
#echo "-----------------------------------------------------------"

#echo " Check SMTP port"
#check_port $smtpServer $smtpServerPort



echo "-----------------------------------------------------------"
echo " SUCCESS "
echo "-----------------------------------------------------------"
