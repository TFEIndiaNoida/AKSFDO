# Creating a TFE external installation on Kubernetes - Azure  

With this repository you will install a Terraform Enterprise environment on a Azure Kubernetes cluster (AKS) using Terraform. Kubernetes only supports an active-active configuration with an external Redis database. 

The manual steps for creating a TFE external installation on Kubernetes can be found [here](manual_steps/README.md)

# Creating the infrastructure

We create the infrastructure according to the following diagram for the kubernetes environment
![](diagram/diagram_tfe_fdo_azure_external_kubernetes.png)  

# Prerequisites
## AWS
We will be using AWS for creating the DNS records. 

## Azure
Make sure you have an Azure account. Please make sure the az cli tool is installed and confired to get the AKS configuration downloaded

## Install terraform  
See the following documentation [How to install Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)

## kubectl
Make sure kubectl is available on your system. Please see the documentation [here](https://kubernetes.io/docs/tasks/tools/).

## helm
Make sure helm is available on your system. Please see the documentation [here](https://helm.sh/docs/intro/install/)

# How to

- Clone this repository
```
https://github.com/munnep/tfe_fdo_azure_external_kubernetes
```
- Set your AWS credentials
```
export AWS_ACCESS_KEY_ID=
export AWS_SECRET_ACCESS_KEY=
export AWS_SESSION_TOKEN=
```

## Now you will need to create the infrastructure for AKS
- Go into the directory `tfe_fdo_azure_external_kubernetes/infra`
```
cd tfe_fdo_aws_external_kubernetes/infra
```
- Create a file called `variables.auto.tfvars` with the following contents
```
# General
tag_prefix        = "tfeeks"                                            # General prefix used in the code and naming
# Azure    
vnet_cidr         = "10.211.0.0/16"                                    # Network for the VPC to be created
postgres_user     = "tfe"                                              # Postgres user to be used 
postgres_password = "Password#1"                                       # Password for the postgres user
storage_account   = "tfeeksramit"                                     # Name of the storage account to be created which should be unique
subscription_id   = "e7ab925a-7628-4300-a90b-511d946a4e7c"                  # subscription ID

``````
- Initialize terraform
```
terraform init
```
- Create the Azure resources
```
terraform apply
```
- The output should be the following
```
Apply complete! Resources: 24 added, 0 changed, 0 destroyed.

Outputs:

cluster_name = "tfeeks"
container_name = "tfeeks-container"
kubernetes_configuration = "az aks get-credentials --resource-group tfeeks --name tfeeks"
pg_address = "tfeeks-psqlflexibleserver.postgres.database.azure.com"
pg_dbname = "tfe"
pg_password = <sensitive>
pg_user = "tfe"
prefix = "tfeeks"
redis_host = "tfeeks-redis.redis.cache.windows.net"
redis_port = 6379
redis_primary_access_key = <sensitive>
storage_account = "tfeeksramit"
storage_account_key = <sensitive>
```
- The kubernetes environment is created from an infrastructure standpoint.   

## Now you will need to deploy Terraform Enterprise on to this cluster

- Go to the directory `../tfe`
```
cd ../tfe
```
- Create a file called `variables.auto.tfvars` with the following contents
```
dns_hostname               = "tfeeks"                                   # Hostname used for TFE
dns_zonename               = "tf-support.hashicorpdemo.com"                          # DNS zone where the hostname record can be created
certificate_email          = "ramit.bansal@hashicorp.com"             # email address used for creating valid certificates
tfe_encryption_password    = "Password#1"                              # encryption key used by TFE
replica_count              = 1                                         # Number of replicas for TFE you would like to have started
tfe_license                = "02MV4UU43BK5HGYYTOJZWFQMTMNNEWU33JJUZFU3COGJMTITL2LF2E6VCZGVGUGMBQLFKGW52MK5ITEWSEJF2E4MSNPBHEIQTLJZKESMCNPJATKSLJO5UVSM2WPJSEOOLULJMEUZTBK5IWST3JJJUVSMSRGRGUORTKLFJTANKOPJVXOTCUKUYU4RCZORHEORTKJZ4TANKZNJIXUTSUNMYFUVDDGNGUIQLJJRBUU4DCNZHDAWKXPBZVSWCSOBRDENLGMFLVC2KPNFEXCSLJO5UWCWCOPJSFOVTGMRDWY5C2KNETMSLKJF3U22SVORGUIULUJVCGYVKNKRATMTLKJE3E22TLOVHVIRJVJ5KGGMSOKRATIV3JJFZUS3SOGBMVQSRQLAZVE4DCK5KWST3JJF4U2RCJGFGFIQJQJRKECNKWIRAXOT3KIF3U62SBO5LWSSLTJFWVMNDDI5WHSWKYKJYGEMRVMZSEO3DULJJUSNSJNJEXOTLKKV2E2RCVORGUI3CVJVVE2NSOKRVTMTSUNN2U6VDLGVLWSSLTJFXFE3DDNUYXAYTNIYYGCVZZOVMDGUTQMJLVK2KPNFEXSTKEJEYUYVCBGFGFIQJVKZCES6SPNJKTKT3KKU2UY2TLGVHVM33JJRBUU53DNU4WWZCXJYYES2TPNFSEOVTZMNWUM3LCGNFHISLJO5UVU3LYNBNDGTLJJ5XHIOLGKE6T2LTGKNVFI5KVNBMWENCPNJ4WUL2TIFHG4R2WKNLXSQSGMN2DG52JJNEVM3DRKBBGEYK2G5MVSR3GNZSU62DTIJYUQNSUINGHGV2IIZUUC2LWGJEVUSZUIZZVCK3YNBGVUQ2MF44VMRC2GFSEC23DME2GIVRQGMZTQUDXNVLGYYLWJJIDI4CKPBEUSOKEGZKUMTCVMFLFA2TLK5FHIY2EGZYGC3BWN5HWMR3OJMZHUUCLJJJG2R2IKYZWKWTXOFDGKK3PG5VS64ZLIFKE42CQLJTVGL2LKZMWOL2LFNWEOUDXJQ3WUQTYJE3UOT3BNM3FKYLJMFEG6ZLLGBJFI3ZXGJCFCPJ5"             # Your TFE license in raw text
tfe_release                = "v202502-2"                               # The version of TFE application you wish to be deployed   
load_balancer_type         = "external"                                # If you would like to have an "internal" or "external" loadbalancer
# AWS
region                     = "ap-south-1"                              # To create the DNS record on AWS     
# Azure
subscription_id   = "e7ab925a-7628-4300-a90b-511d946a4e7c"                  # subscription ID

```
- Initialize the environment
```
terraform init
```
- Create the environment
```
terraform apply
```
- This will create 6 resources
```
Apply complete! Resources: 7 added, 0 changed, 0 destroyed.

Outputs:

execute_script_to_create_user_admin = "./configure_tfe.sh tfeeks.tf-support.hashicorpdemo.com ramit.bansal@hashicorp.com Password#1"
tfe_application_url = "https://tfeeks.tf-support.hashicorpdemo.com"
```
- Execute the `configure_tfe.sh tfeeks.tf-support.hashicorpdemo.com ramit.bansal@hashicorp.com Password#1` script to do the following
  - Create a user called admin with the password specified
  - Create an organization called test
- login to the application on url https://tfe19.aws.munnep.com

## Extra notes

- Documentation about the Internal Load balancer on Azure can be found [here](https://learn.microsoft.com/en-us/azure/aks/internal-lb?tabs=set-service-annotations#create-an-internal-load-balancer)
