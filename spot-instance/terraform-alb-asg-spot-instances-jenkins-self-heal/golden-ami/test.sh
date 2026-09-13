#!/bin/bash
packer plugins install github.com/hashicorp/amazon
packer plugins install github.com/hashicorp/ansible
TEST=`packer build template.json | tail -2`
AMI_ID=`echo $TEST|cut -d ":" -f2`
echo $AMI_ID
echo 'variable "AMI_ID" { default = "'${AMI_ID//[[:blank:]]/}'"  }' > ../main/newvariable.tf
