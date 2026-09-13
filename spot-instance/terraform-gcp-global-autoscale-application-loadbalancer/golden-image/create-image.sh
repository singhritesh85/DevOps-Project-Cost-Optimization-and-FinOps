#!/bin/bash

packer plugins install github.com/hashicorp/googlecompute
packer plugins install github.com/hashicorp/ansible
DEXTER=`packer build template.json | tail -1`;
image_name=`echo $DEXTER | cut -d ":" -f2- | cut -d ":" -f2`;
echo $image_name;
echo 'variable "source_image" { default = "'${image_name//[[:blank:]]/}'" }' > ../main/newvariable.tf
