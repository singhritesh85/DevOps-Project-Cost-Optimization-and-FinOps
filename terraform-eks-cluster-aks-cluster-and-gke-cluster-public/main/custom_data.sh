#!/bin/bash
/usr/sbin/useradd -s /bin/bash -m ritesh;
mkdir /home/ritesh/.ssh;
chmod -R 700 /home/ritesh;
echo "ssh-rsa XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX ritesh@DESKTOP-0XXXXXX" >> /home/ritesh/.ssh/authorized_keys;
chmod 600 /home/ritesh/.ssh/authorized_keys;
chown ritesh:ritesh /home/ritesh/.ssh -R;
echo "ritesh  ALL=(ALL)  NOPASSWD:ALL" > /etc/sudoers.d/ritesh;
chmod 440 /etc/sudoers.d/ritesh;
#################################### Set Hostname for Azure VM Instance ################################

hostnamectl set-hostname demo-azure-vm

##################################### create a user to login using SSH #################################
useradd -s /bin/bash -m demo;
echo "Password@#795" | passwd demo --stdin;
echo "Password@#795" | passwd root --stdin;
sed -i '0,/PasswordAuthentication no/s//PasswordAuthentication yes/' /etc/ssh/sshd_config;
echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
sed -i '0,/PasswordAuthentication no/s//PasswordAuthentication yes/' /etc/ssh/sshd_config.d/50-cloud-init.conf
echo "PermitRootLogin yes" >> /etc/ssh/sshd_config.d/50-cloud-init.conf
systemctl reload sshd;
echo "demo  ALL=(ALL)  NOPASSWD:ALL" >> /etc/sudoers
####################################################################

yum install -y vim zip unzip git wget java-17*

while [ ! -e /dev/sdb ]; do
    echo "Waiting for device /dev/sdb to be attached..."
    sleep 5
done
echo "/dev/sdb is ready!"
mkdir /mederma;
mkfs.xfs /dev/sdb;
echo "/dev/sdb  /mederma  xfs  defaults 0 0" >> /etc/fstab;
mount -a;

############# K8S-Management ##############

yum -y install dnf-plugins-core
yum config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum install docker-ce docker-ce-cli containerd.io -y
systemctl start docker && systemctl enable docker
usermod -aG docker demo
newgrp docker
cd /opt/ && wget https://repo1.maven.org/maven2/org/apache/maven/apache-maven/3.9.11/apache-maven-3.9.11-bin.tar.gz
tar -xvf apache-maven-3.9.11-bin.tar.gz
mv /opt/apache-maven-3.9.11 /opt/apache-maven
cd /opt && wget https://nodejs.org/dist/v16.0.0/node-v16.0.0-linux-x64.tar.gz
tar -xvf node-v16.0.0-linux-x64.tar.gz
rm -f node-v16.0.0-linux-x64.tar.gz
mv /opt/node-v16.0.0-linux-x64 /opt/node-v16.0.0
cd /opt && curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin v0.69.3
echo JAVA_HOME="/usr/lib/jvm/java-17-openjdk-17.0.19.0.10-1.el8.x86_64" >> /home/demo/.bashrc
echo PATH="$PATH:$JAVA_HOME/bin:/opt/apache-maven/bin:/opt/node-v16.0.0/bin:/usr/local/bin" >> /home/demo/.bashrc
echo "demo  ALL=(ALL)  NOPASSWD:ALL" >> /etc/sudoers

############# Install kubectl #############

curl -LO https://dl.k8s.io/release/v1.34.0/bin/linux/amd64/kubectl
chmod +x kubectl
mv kubectl /usr/local/bin

############# Install Helm ################

curl -fsSL -o ~/get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 ~/get_helm.sh
~/get_helm.sh

helm version
kubectl version

#################################### Installation of Rsyslog ###########################################

yum install rsyslog -y
systemctl start rsyslog
systemctl enable rsyslog
systemctl status rsyslog

############################################# Install AWS CLI ##########################################

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

########################################## Install Google Cloud CLI ####################################

sudo tee -a /etc/yum.repos.d/google-cloud-sdk.repo << EOM
[google-cloud-cli]
name=Google Cloud CLI
baseurl=https://packages.cloud.google.com/yum/repos/cloud-sdk-el9-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=0
gpgkey=https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOM

sudo dnf install libxcrypt -y
sudo dnf install google-cloud-cli -y
sudo dnf install google-cloud-cli-gke-gcloud-auth-plugin -y

############################################ Install Azure CLI #########################################

sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo sh -c 'echo -e "[azure-cli]\nname=Azure CLI\nbaseurl=https://packages.microsoft.com/yumrepos/azure-cli\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/azure-cli.repo'
sudo dnf install azure-cli -y
