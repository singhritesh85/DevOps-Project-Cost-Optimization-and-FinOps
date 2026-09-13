#!/bin/bash
/usr/sbin/useradd -s /bin/bash -m ritesh;
mkdir /home/ritesh/.ssh;
chmod -R 700 /home/ritesh;
echo "ssh-rsa XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX ritesh@DESKTOP-0XXXXXX" >> /home/ritesh/.ssh/authorized_keys;
chmod 600 /home/ritesh/.ssh/authorized_keys;
chown ritesh:ritesh /home/ritesh/.ssh -R;
echo "ritesh  ALL=(ALL)  NOPASSWD:ALL" > /etc/sudoers.d/ritesh;
chmod 440 /etc/sudoers.d/ritesh;

#########################################################################################################################################################

useradd -s /bin/bash -m dexter;
echo "Password@#795" | passwd dexter --stdin;
echo "dexter  ALL=(ALL)  NOPASSWD:ALL" > /etc/sudoers.d/dexter;
chmod 440 /etc/sudoers.d/dexter;
sed -i '0,/PasswordAuthentication no/s//PasswordAuthentication yes/' /etc/ssh/sshd_config;
systemctl reload sshd;

#################################################### Installation of Required Packages ##################################################################

yum install -y kubectl google-cloud-cli-gke-gcloud-auth-plugin vim zip unzip wget git java-21*

####################################################### Installation of GitLab Runner ###################################################################

curl -L "https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.rpm.sh" | sudo bash
yum install -y gitlab-runner
###gitlab-runner register            ### Run Manually
###systemctl start gitlab-runner     ### Run Manually
###systemctl enable gitlab-runner    ### Run Manually
###systemctl status gitlab-runner    ### Run Manually

#################################################### Required configuration and Packages ################################################################

cd /opt/ && wget https://repo1.maven.org/maven2/org/apache/maven/apache-maven/3.9.11/apache-maven-3.9.11-bin.tar.gz
tar -xvf apache-maven-3.9.11-bin.tar.gz
mv /opt/apache-maven-3.9.11 /opt/apache-maven
cd /opt && wget https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-4.8.0.2856-linux.zip
unzip sonar-scanner-cli-4.8.0.2856-linux.zip
rm -f sonar-scanner-cli-4.8.0.2856-linux.zip
mv /opt/sonar-scanner-4.8.0.2856-linux/ /opt/sonar-scanner
cd /opt && wget https://nodejs.org/dist/v16.0.0/node-v16.0.0-linux-x64.tar.gz
tar -xvf node-v16.0.0-linux-x64.tar.gz
rm -f node-v16.0.0-linux-x64.tar.gz
mv /opt/node-v16.0.0-linux-x64 /opt/node-v16.0.0
cd /opt && wget https://github.com/jeremylong/DependencyCheck/releases/download/v8.4.0/dependency-check-8.4.0-release.zip
unzip dependency-check-8.4.0-release.zip
rm -f dependency-check-8.4.0-release.zip
chown -R gitlab-runner:gitlab-runner /opt/dependency-check
echo JAVA_HOME=$(dirname "$(dirname "$(readlink -f "$(which java)")")") >> /etc/profile.d/java.sh
echo PATH="$PATH:$JAVA_HOME/bin:/opt/apache-maven/bin:/opt/node-v16.0.0/bin:/opt/dependency-check/bin" >> /etc/profile.d/java.sh
echo "gitlab-runner  ALL=(ALL)  NOPASSWD:ALL" >> /etc/sudoers.d/gitlab-runner
chmod 440 /etc/sudoers.d/gitlab-runner
source /etc/profile.d/java.sh
echo $JAVA_HOME
java -version

##################################################### Installation Google-Cloud-Ops-Agent ###############################################################

curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
sudo bash add-google-cloud-ops-agent-repo.sh --also-install
systemctl status google-cloud-ops-agent

##################################################### Installation of Packer ############################################################################

cd /opt/ && wget https://releases.hashicorp.com/packer/1.16.0/packer_1.16.0_linux_amd64.zip
unzip packer_1.16.0_linux_amd64.zip
rm -f packer_1.16.0_linux_amd64.zip
yes|mv /opt/packer /usr/sbin/
packer version
