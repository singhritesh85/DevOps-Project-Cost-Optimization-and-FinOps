#!/bin/bash
/usr/sbin/useradd -s /bin/bash -m ritesh;
mkdir /home/ritesh/.ssh;
chmod -R 700 /home/ritesh;
echo "ssh-rsa XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX ritesh@DESKTOP-0XXXXXX" >> /home/ritesh/.ssh/authorized_keys;
chmod 600 /home/ritesh/.ssh/authorized_keys;
chown ritesh:ritesh /home/ritesh/.ssh -R;
echo "ritesh  ALL=(ALL)  NOPASSWD:ALL" > /etc/sudoers.d/ritesh;
chmod 440 /etc/sudoers.d/ritesh;

#################################### K8S Management ##############################################

useradd -s /bin/bash -m k8s-management;
echo "Password@#795" | passwd k8s-management --stdin;
sed -i '0,/PasswordAuthentication no/s//PasswordAuthentication yes/' /etc/ssh/sshd_config;
systemctl reload sshd;
yum install java-25* git -y
yum install -y docker && systemctl start docker && systemctl enable docker
usermod -aG docker k8s-management
chown k8s-management:k8s-management /var/run/docker.sock
cd /opt/ && wget https://repo1.maven.org/maven2/org/apache/maven/apache-maven/3.9.11/apache-maven-3.9.11-bin.tar.gz
tar -xvf apache-maven-3.9.11-bin.tar.gz
mv /opt/apache-maven-3.9.11 /opt/apache-maven
cd /opt && wget https://nodejs.org/dist/v16.0.0/node-v16.0.0-linux-x64.tar.gz
tar -xvf node-v16.0.0-linux-x64.tar.gz
rm -f node-v16.0.0-linux-x64.tar.gz
mv /opt/node-v16.0.0-linux-x64 /opt/node-v16.0.0
cd /opt && curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin v0.69.3
echo JAVA_HOME="/usr/lib/jvm/java-25-amazon-corretto.x86_64" >> /home/k8s-management/.bashrc
echo PATH="$PATH:$JAVA_HOME/bin:/opt/apache-maven/bin:/opt/node-v16.0.0/bin:/usr/local/bin" >> /home/k8s-management/.bashrc
echo "k8s-management  ALL=(ALL)  NOPASSWD:ALL" >> /etc/sudoers 
yum remove awscli -y
cd /opt && curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

############# Install kubectl #############

curl -LO https://dl.k8s.io/release/v1.32.0/bin/linux/amd64/kubectl
chmod +x kubectl
mv kubectl /usr/local/bin

############# Install Helm ################

curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 --output-dir ~/
chmod 700 ~/get_helm.sh
~/get_helm.sh

helm version
kubectl version

#################################### Installation of Rsyslog ###########################################

yum install rsyslog -y
systemctl start rsyslog
systemctl enable rsyslog
systemctl status rsyslog

################################### Installation of Velero CLI #########################################

cd /opt && wget https://github.com/vmware-tanzu/velero/releases/download/v1.16.2/velero-v1.16.2-linux-amd64.tar.gz
tar -xvf velero-v1.16.2-linux-amd64.tar.gz
rm -f velero-v1.16.2-linux-amd64.tar.gz
mv velero-v1.16.2-linux-amd64/velero /usr/local/bin/

#################################### Set Hostname for K8S Management ####################################

hostnamectl set-hostname k8s-management

#################################### Installation of crontab ###########################################

yum install cronie -y
systemctl enable crond.service
systemctl start crond.service
systemctl status crond.service
