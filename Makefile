include envfile

help:
	@echo " Prepare and Install Kubernetes"
	@echo " ------------------------------"
	@echo "  master: installk8s initk8s installHelm"
	@echo "  prepapic:  ingress storage installapicup registry upload"
	@echo
	@echo " Deploy or Upgrade APIC"
	@echo " ------------------------------"
	@echo "  deploy: checkReady buildYaml buildYamlGwvNative deployAPIC"

checkprereq:
	# check prereq
	sh bin/checkprerq.sh

installk8s:
	# include Docker, kubelet, kubeadm, and kubectl 
	sh bin/installk8s.sh $(k8s_version)

initk8s:
	sudo kubeadm init --pod-network-cidr $(pod_network_cidr) --apiserver-advertise-address=$(apiserver_advertise_address) | tee kubeinit.log
	sudo cp kubeinit.log kubeinit.log.save
	mkdir -p ~/.kube
	sudo cp -f /etc/kubernetes/admin.conf ~/.kube/config
	sudo chmod 755 -R  ~/.kube/
	export KUBECONFIG=/etc/kubernetes/admin.conf
	kubectl apply -f https://docs.projectcalico.org/v3.3/getting-started/kubernetes/installation/hosted/rbac-kdd.yaml
	kubectl apply -f https://docs.projectcalico.org/v3.3/getting-started/kubernetes/installation/hosted/kubernetes-datastore/calico-networking/1.7/calico.yaml
	
	# Wait a few time
	bash bin/sleep.sh 60
	
	# Only one master/node
	kubectl taint nodes --all node-role.kubernetes.io/master-
	bash bin/sleep.sh 80
	kubectl get nodes

installHelm:
	tar -xzvf ./fixcentral/helm-v2.16.3-linux-amd64.tar.gz -C ./fixcentral/
	sudo cp ./fixcentral/linux-amd64/helm /usr/local/bin/helm
	sudo chmod +x /usr/local/bin/helm
	kubectl create clusterrolebinding add-on-cluster-admin --clusterrole=cluster-admin --serviceaccount=kube-system:default
	helm init
	echo "Waiting for tiller to start in cluster"
	bash bin/sleep.sh 60

getk8sstatus:
	kubectl get node
	kubectl get all -A

installapicup:
	sh bin/installapicup.sh

ingress:
	helm install --name ingress -f yaml/nginx-ingress-values.yml stable/nginx-ingress

storage:
	kubectl create -f yaml/storage-rbac.yml
	kubectl create -f yaml/hostpath-provisioner.yml

registry:
	helm install --name registry stable/docker-registry  -f yaml/docker-registry-values.yaml
	echo "Waiting for docker registry to start"
	bash bin/sleep.sh 60

upload:
	sudo docker login $(registry) -u admin -p admin
	sudo apicup registry-upload management $(sources)/management-images-kubernetes_lts_$(apicversion).tgz $(registry)
	sudo apicup registry-upload analytics $(sources)/analytics-images-kubernetes_lts_$(apicversion).tgz $(registry)
	sudo apicup registry-upload portal $(sources)/portal-images-kubernetes_lts_$(apicversion).tgz $(registry)
	sh bin/uploadidg.sh

smtp:
	sh bin/fakesmtp.sh

checkReady:
	until kubectl get nodes | grep Ready; do printf 'Waiting for network';sleep 15;done

buildYaml:
	#rm -rf myinstall || true
	kubectl create ns apic || true
	apicup init myinstall  || true
	cd ./myinstall ; apicup subsys create mgmt management --k8s  || true ;
	cd ./myinstall ; apicup subsys set mgmt platform-api   $(ep_api) ;
	cd ./myinstall ; apicup subsys set mgmt api-manager-ui $(ep_apim)  ;
	cd ./myinstall ; apicup subsys set mgmt cloud-admin-ui $(ep_cm)  ;
	cd ./myinstall ; apicup subsys set mgmt consumer-api $(ep_consumer) ;
	cd ./myinstall ; apicup subsys set mgmt storage-class velox-block ;
	cd ./myinstall ; apicup subsys set mgmt namespace apic ;
	cd ./myinstall ; apicup subsys set mgmt cassandra-cluster-size 1 ;
	cd ./myinstall ; apicup subsys set mgmt cassandra-max-memory-gb 16 ;
	cd ./myinstall ; apicup subsys set mgmt cassandra-volume-size-gb 16 ;
	cd ./myinstall ; apicup subsys set mgmt registry $(registry) ;
	cd ./myinstall ; apicup subsys set mgmt mode dev ;
	#Analytics
	cd ./myinstall ; apicup subsys create analytics analytics --k8s  || true ;
	cd ./myinstall ; apicup subsys set analytics namespace apic ;
	cd ./myinstall ; apicup subsys set analytics coordinating-max-memory-gb 12 ;
	cd ./myinstall ; apicup subsys set analytics data-max-memory-gb 12 ;
	cd ./myinstall ; apicup subsys set analytics data-storage-size-gb 200 ;
	cd ./myinstall ; apicup subsys set analytics master-max-memory-gb 12 ;
	cd ./myinstall ; apicup subsys set analytics master-storage-size-gb 5 ;
	cd ./myinstall ; apicup subsys set analytics storage-class velox-block ;
	cd ./myinstall ; apicup subsys set analytics analytics-ingestion $(ep_ai) ;
	cd ./myinstall ; apicup subsys set analytics analytics-client $(ep_ac) ;
	cd ./myinstall ; apicup subsys set analytics mode dev ;
	cd ./myinstall ; apicup subsys set analytics registry $(registry) ;
	#Portal
	cd ./myinstall ; apicup subsys create portal portal --k8s  || true ;
	cd ./myinstall ; apicup subsys set portal portal-admin $(ep_padmin) ;
	cd ./myinstall ; apicup subsys set portal portal-www $(ep_portal) ;
	cd ./myinstall ; apicup subsys set portal namespace apic ;
	cd ./myinstall ; apicup subsys set portal registry $(registry) ;
	cd ./myinstall ; apicup subsys set portal storage-class velox-block ;
	cd ./myinstall ; apicup subsys set portal www-storage-size-gb 5 ;
	cd ./myinstall ; apicup subsys set portal backup-storage-size-gb 5 ;
	cd ./myinstall ; apicup subsys set portal db-storage-size-gb 12 ;
	cd ./myinstall ; apicup subsys set portal db-logs-storage-size-gb 2 ;
	cd ./myinstall ; apicup subsys set portal admin-storage-size-gb 1 ;
	cd ./myinstall ; apicup subsys set portal mode dev ;
	#Gateway
	cd ./myinstall ; apicup subsys create gw gateway --k8s || true;
	cd ./myinstall ; apicup subsys set gw api-gateway $(ep_gw)
	cd ./myinstall ; apicup subsys set gw apic-gw-service $(ep_gwd)
	cd ./myinstall ; apicup subsys set gw namespace apic ;
	cd ./myinstall ; apicup subsys set gw registry $(registry) ;
	cd ./myinstall ; apicup subsys set gw max-cpu 4 ;
	cd ./myinstall ; apicup subsys set gw max-memory-gb 8 ;
	cd ./myinstall ; apicup subsys set gw storage-class velox-block ;
	cd ./myinstall ; apicup subsys set gw replica-count 1 ;
	cd ./myinstall ; apicup subsys set gw v5-compatibility-mode false ;
	cd ./myinstall ; apicup subsys set gw enable-high-performance-peering false ;
	cd ./myinstall ; apicup subsys set gw enable-tms true ;
	cd ./myinstall ; apicup subsys set gw tms-peering-storage-size-gb 10 ;
	cd ./myinstall ; apicup subsys set gw extra-values-file $(shell pwd)/yaml/extra-values.yaml ;
	cd ./myinstall ; apicup subsys set gw image-repository datapower-api-gateway ;
	cd ./myinstall ; apicup subsys set gw image-tag "2018.4.1" ;
	cd ./myinstall ; apicup subsys set gw monitor-image-repository k8s-datapower-monitor ;
	cd ./myinstall ; apicup subsys set gw monitor-image-tag "2018.4.1" ;
	cd ./myinstall ; apicup subsys set gw mode dev ;
	#validate
	cd ./myinstall ; apicup subsys get mgmt --validate ;
	cd ./myinstall ; apicup subsys get portal --validate ;
	cd ./myinstall ; apicup subsys get analytics --validate ;
	cd ./myinstall ; apicup subsys get gw --validate ;


deployPortal:
	cd myinstall  ; apicup subsys install portal

deployMgmt:
	cd myinstall  ; apicup subsys install mgmt

deployGW:
	cd myinstall  ; apicup subsys install gw

deployAnalytics:
	cd myinstall  ; apicup subsys install analytics

deployAPIC: deployMgmt deployAnalytics deployPortal deployGW

addTopology:
	until kubectl get pod r5673b1bbde-dynamic-gateway-service-0 -n apic  | grep 1/1; do printf 'Waiting for Gateway to get ready \n';sleep 10;done
	until kubectl get pod r307b84ffe1-analytics-storage-data-0 -n apic  | grep 1/1; do printf 'Waiting for Analytics to get ready \n';sleep 10;done
	until kubectl get pod rbcb357bd8b-apic-portal-db-0 -n apic  | grep 2/2; do printf 'Waiting for Portal to get ready \n';sleep 10;done
	sh bin/changepassword.sh $(ep_cm) $(admin_email) $(admin_pass)
	sh envfile && sh bin/createDpService.sh

loadAssets:
	sh bin/createAssets.sh

createApp:
	sh bin/createApp_and_Subscription.sh


# to install docker & kube & helm & init
master : checkprereq installk8s initk8s installHelm getk8sstatus

# Prepare kube/helm/ingress/registry for apic
prepapic:  ingress storage registry smtp getk8sstatus

# deploy apic
deploy: checkReady installapicup upload buildYaml deployAPIC getk8sstatus

# configure API environnement
configureAPIC: addTopology  loadAssets createApp

# complete installation
full: master prepapic deploy configureAPIC

