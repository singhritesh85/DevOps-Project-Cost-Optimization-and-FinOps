#!/bin/bash
/usr/sbin/useradd -s /bin/bash -m ritesh;
mkdir /home/ritesh/.ssh;
chmod -R 700 /home/ritesh;
echo "ssh-rsa AAAAXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX ritesh@DESKTOP-0XXXXXX" >> /home/ritesh/.ssh/authorized_keys;
chmod 600 /home/ritesh/.ssh/authorized_keys;
chown ritesh:ritesh /home/ritesh/.ssh -R;
echo "ritesh  ALL=(ALL)  NOPASSWD:ALL" > /etc/sudoers.d/ritesh;
chmod 440 /etc/sudoers.d/ritesh;

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

yum install -y vim zip unzip git wget
yum install -y java-21*

while [ ! -e /dev/disk/azure/scsi1/lun0 ]; do
    echo "Waiting for device /dev/disk/azure/scsi1/lun0 to be attached..."
    sleep 5
done
echo "/dev/disk/azure/scsi1/lun0 is ready!"
mkdir /mederma;
mkfs.xfs /dev/disk/azure/scsi1/lun0;
echo "/dev/disk/azure/scsi1/lun0  /mederma  xfs  defaults 0 0" >> /etc/fstab;
mount -a;

#################################### Tools for Azure DevOps Agent ######################################

cd /opt/ && wget https://repo1.maven.org/maven2/org/apache/maven/apache-maven/3.9.11/apache-maven-3.9.11-bin.tar.gz
tar -xvf apache-maven-3.9.11-bin.tar.gz
mv /opt/apache-maven-3.9.11 /opt/apache-maven
cd /opt && wget https://nodejs.org/dist/v16.0.0/node-v16.0.0-linux-x64.tar.gz
tar -xvf node-v16.0.0-linux-x64.tar.gz
rm -f node-v16.0.0-linux-x64.tar.gz
mv /opt/node-v16.0.0-linux-x64 /opt/node-v16.0.0
cd /opt && curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin v0.69.3
echo JAVA_HOME="/usr/lib/jvm/java-21-amazon-corretto.x86_64" >> /home/demo/.bashrc
echo PATH="$PATH:$JAVA_HOME/bin:/opt/apache-maven/bin:/opt/node-v16.0.0/bin:/usr/local/bin" >> /home/demo/.bashrc
echo "demo  ALL=(ALL)  NOPASSWD:ALL" >> /etc/sudoers
cd /opt && wget https://releases.hashicorp.com/packer/1.16.0/packer_1.16.0_linux_amd64.zip
unzip packer_1.16.0_linux_amd64.zip
yes|mv /opt/packer /usr/sbin/
yum install -y https://packages.microsoft.com/config/rhel/9.0/packages-microsoft-prod.rpm
yum install -y azure-cli

#################################### Installation of Rsyslog ###########################################

yum install rsyslog -y
systemctl start rsyslog
systemctl enable rsyslog
systemctl status rsyslog
