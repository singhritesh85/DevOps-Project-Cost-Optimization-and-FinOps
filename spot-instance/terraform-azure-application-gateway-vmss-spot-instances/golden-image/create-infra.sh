#!/bin/bash

az sig create --resource-group ritesh --gallery-name nhimagegallery
az sig image-definition create --resource-group ritesh --gallery-name nhimagegallery --gallery-image-definition demo --publisher almalinux --offer almalinux-x86_64 --sku 9-gen2 --os-type linux --hyper-v-generation V2
packer plugins install github.com/hashicorp/azure 
packer plugins install github.com/hashicorp/ansible
DEXTER=`packer build -var-file=variables.json template.json | tail -7 | head -1`
image_id=`echo $DEXTER|cut -d ":" -f2`
echo $image_id
echo 'variable "image_id" { default = "'${image_id//[[:blank:]]/}'" }' > ../main/newvariable.tf
