# Overview

Test the tooling and processes SED team is using to deploy application in an OpenStack region to Azure. This test will bake, test, deploy and form a [Consul](https://consul.io) cluster in Azure.

## Dependencies

* Packer
* Ansible
* Terraform

## Requirements

An Azure subscription.


## How to Build a Consul Cluster in Azure

#### 1. Set Azure Config Mode to ARM
```azure config mode arm```

### 2. Login to Your Azure subscription
```azure login```

NOTE: If you have multiple subscription/account, make sure you are working on the correct subscription by running the following;
```
azure account list
azure account set <AZURE_SUBSCRIPTION>
```

### 3. Create a Service Principal
3a. Create an application
```
azure ad app create --name "azurefest" --home-page "http://azurefest.demo.net" --identifier-uris "http://azurefest.demo.net" --password <password>
```
The `home-page` and `identifier-uris` are required but you can assign any non-existent url.    

3b. Create service principal for the application that you created above using its ApplicationId (AppId above)
```
azure ad sp create <AppId>
```
get the <AppId> comes from the previous step (3a)     

3c. Create role assignment for the service principal (SP)
```
azure role assignment create --objectId <ObjectId> -o Owner -c /subscriptions/<AZURE_SUBSCRIPTION>
```
get the <ObjectId> from the previous step (3b)

### 4. Assign and export the Azure environment variables.
```
export ARM_SUBSCRIPTION_ID=<your_ARM_subscription_id>
export ARM_CLIENT_SECRET=<password>
export ARM_TENANT_ID=<your_ARM_tenant_ID>
export ARM_CLIENT_ID=<your_ARM_client_ID>
```
### 5. Run terraform pre-tasks to create needed Azure resources
```
cd infra/terraform/pre-tasks
terraform plan
teraraform apply
```
### 6. Export the resource group and storage account created by terraform's pre-tasks
```
export ARM_RESOURCE_GROUP=azurefest-sed-rg
export ARM_STORAGE_ACCOUNT=azurefestpersistentsa
```
### 7. Fetch the ansible roles and start baking image
```
cd ../../consul
ansible-galaxy install --role-file=ansible/requirements.yml --roles-path=ansible/roles --force
cd packer
packer build packer.json
```
Take note of the image id/name created by packer, example: consul-osDisk.ee6c4f8c-27ad-415e-b915-f3fa9df5c9b2.vhd

### 8. Create/Update main terraform config

Create/Update the main terraform.tf with the image id/name of the baked image and other Azure resource information created from the terraform pre-tasks. One of the Consul public IP address creted from the pre-tasks is needed by terraform to remotely run `consul join command`.

### 9. Run terraform plan and apply
```
cd ../../terraform/
terraform plan
terraform apply
```
## 10. Consul cluster should be created
```
ssh -i ~/.ssh/id_rsa ubuntu@13.92.36.55 '/opt/consul/bin/consul members'
```
The IP address `13.92.36.55` is from the terraform pre-tasks.


**NOTE:**    
Delete the Azure resource group named `azurefest-sed-rg` before running this exercise.     
Changing the image id/name will not rebuild the nodes, you have to taint the nodes manually to rebuild them.    

### Azure important urls;     

https://resources.azure.com/   
http://storageexplorer.com/


### Author  
Roel Brutas    
roel_brutas@comcast.com    
