#!/bin/bash
/usr/sbin/useradd -s /bin/bash -m ritesh;
mkdir /home/ritesh/.ssh;
chmod -R 700 /home/ritesh;
echo "ssh-rsa XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX ritesh@DESKTOP-0XXXXXX" >> /home/ritesh/.ssh/authorized_keys;
chmod 600 /home/ritesh/.ssh/authorized_keys;
chown ritesh:ritesh /home/ritesh/.ssh -R;
echo "ritesh  ALL=(ALL)  NOPASSWD:ALL" > /etc/sudoers.d/ritesh;
chmod 440 /etc/sudoers.d/ritesh;

#################################### Jenkins Slave ##############################################

useradd -s /bin/bash -m jenkins;
echo "Password@#795" | passwd jenkins --stdin;
sed -i '0,/PasswordAuthentication no/s//PasswordAuthentication yes/' /etc/ssh/sshd_config;
systemctl reload sshd;
yum install java-21* git -y
yum install -y docker && systemctl start docker && systemctl enable docker
usermod -aG docker jenkins
chown jenkins:jenkins /var/run/docker.sock
cd /opt/ && wget https://repo1.maven.org/maven2/org/apache/maven/apache-maven/3.9.11/apache-maven-3.9.11-bin.tar.gz
tar -xvf apache-maven-3.9.11-bin.tar.gz
mv /opt/apache-maven-3.9.11 /opt/apache-maven
cd /opt && wget https://nodejs.org/dist/v16.0.0/node-v16.0.0-linux-x64.tar.gz
tar -xvf node-v16.0.0-linux-x64.tar.gz
rm -f node-v16.0.0-linux-x64.tar.gz
mv /opt/node-v16.0.0-linux-x64 /opt/node-v16.0.0
cd /opt && curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin v0.69.3
echo JAVA_HOME="/usr/lib/jvm/java-17-amazon-corretto.x86_64" >> /home/jenkins/.bashrc
echo PATH="$PATH:$JAVA_HOME/bin:/opt/apache-maven/bin:/opt/node-v16.0.0/bin:/usr/local/bin" >> /home/jenkins/.bashrc
echo "jenkins  ALL=(ALL)  NOPASSWD:ALL" >> /etc/sudoers 
yum remove awscli -y
cd /opt && curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

#################################### Installation of Packer ############################################

cd /opt && wget https://releases.hashicorp.com/packer/1.16.0/packer_1.16.0_linux_amd64.zip
unzip packer_1.16.0_linux_amd64.zip
mv packer /usr/sbin/
packer version

#################################### Installation of Rsyslog ###########################################

yum install rsyslog -y
systemctl start rsyslog
systemctl enable rsyslog
systemctl status rsyslog

#################################### Set Hostname for Jenkins Slave ####################################

hostnamectl set-hostname jenkins-slave

#################################### Installation of crontab ###########################################

yum install cronie -y
systemctl enable crond.service
systemctl start crond.service
systemctl status crond.service

