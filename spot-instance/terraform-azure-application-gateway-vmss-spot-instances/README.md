# Azure-VMSS
```
Please provide the information in the terraform script as wriiten below
1. Use your own .pfx file in vmss directory and provide it's password in file module/application-gateway.tf and module/sonarqube-azuredevopsagent.tf.
2. Provide tenant id, subscription id, client id and client secret in the file template.json.
3. Provide public SSH key in the file custom_data.sh.
4. Provide tenant id and subscription id in the file provider.tf.
5. Provide the Email-ID in the file module/vmss.tf on which you want to get the notification for autoscaling.
6. I have used Azure CLI to create Azure Compute Gallery and gallery image definition which is idempotent in nature that means if Azure Compute Gallery or gallery image definition already exists then it will not create the resource but will not through any error in create-infra.sh.
7. To create the end-to-end infrastructure I have created a shell script create-infra.sh, provide execute permission to this file and run the shell script.
8. For deletion of the resources you can use terraform destroy -auto-approve.
````
