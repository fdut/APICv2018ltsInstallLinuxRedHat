
#The container-selinux package is available from the rhel-7-server-extras-rpms channel. You can enable it using
sudo subscription-manager repos --enable=rhel-7-server-extras-rpms

# Add Docker's yum repository
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

# Install Docker CE
sudo yum install --assumeyes docker-ce-18.06.*

# Start and enable the Docker daemon service
sudo systemctl daemon-reload
sudo systemctl start docker
sudo systemctl enable docker

# Remove swap for kubernetes
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

# Add vm.max_map_count=262144 in /etc/sysctl.conf
if [ "`cat /etc/sysctl.conf | grep vm.max_map_count`" == "" ]; then
 echo "save /etc/sysctl.conf to /etc/sysctl.conf.vm.max_map_count"
 sudo cp /etc/sysctl.conf /etc/sysctl.conf.vm.max_map_count

 echo "add new propertie in /etc/sysctl.conf"
 sudo echo 'vm.max_map_count=262144' | sudo tee -a /etc/sysctl.conf
fi

# Make SELinux permissive
sudo setenforce 0

# Pass IPv4/6 traffic to iptables' chains
sudo sh -c 'echo "net.bridge.bridge-nf-call-iptables = 1" > /etc/sysctl.d/k8s.conf'
sudo sh -c 'echo "net.bridge.bridge-nf-call-ipi6tables = 1" >> /etc/sysctl.d/k8s.conf'

sudo sysctl --system

# Add Kubernetes' yum repository
sudo sh -c 'cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF'

# Install kubeadm, kubelet and kubectl
sudo yum install --assumeyes --disableexcludes kubernetes kubeadm-1.15.* kubectl-1.15.* kubelet-1.15.*

# Start and enable kubelet service
sudo systemctl daemon-reload
sudo systemctl start kubelet
sudo systemctl enable kubelet

