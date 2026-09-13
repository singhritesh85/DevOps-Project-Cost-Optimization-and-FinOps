#!/bin/bash

useradd -s /bin/bash -m dexter;
echo "Password@#795" | passwd dexter --stdin;
echo "dexter  ALL=(ALL)  NOPASSWD:ALL" >> /etc/sudoers
sed -i '0,/PasswordAuthentication no/s//PasswordAuthentication yes/' /etc/ssh/sshd_config;
echo "dexter  ALL=(ALL)  NOPASSWD:ALL" > /etc/sudoers.d/dexter;
systemctl reload sshd;
