# Manual steps

These are the manual steps using the Azure Portal to create the Kubernetes environment where the TFE container can be deployed

## diagram
Here is a diagram of what we create

![](../diagram/diagram_tfe_fdo_azure_external_kubernetes.png)  

# Create the Azure infrastructure

- Create a resource group where all the resources will fall under  
![](media/20240123152619.png)   
![](media/20240123152643.png)   

- Create a network   
![](media/20240123152737.png)  
![](media/20240123152803.png)  
![](media/20240123153251.png)   
![](media/20240123153355.png)   


- create an network security group     
![](media/20240123153453.png)   
![](media/20240123153504.png)   
  - Go to the inbound security rules and add the following ports 
    - 22 ssh
    - 80 http
    - 443 https
    - 5432 postgresql
    - 6379 redis non-ssl
    - 6380 redis ssl    
The overview should look like the following   
![](media/20240123154517.png)   

- create a NAT gateway   
![](media/20240123154550.png)   
![](media/20240123154611.png)   
![](media/20240123154639.png)   

- create subnets  
public subnet  
![](media/20240123154823.png)  
private1 subnet  
![](media/20240123154910.png)  
![](media/20240123155716.png)  
private2 subnet  
![](media/20240123160428.png)  
overview  
![](media/20240123160458.png)   


- PostgreSQL Flex   
![](media/20240123155120.png)  
![](media/20240123155140.png)  
![](media/20240123155900.png)  
![](media/20240123155814.png)   
add a database called tfe  
![](media/20240123164756.png)  


- After the database is create you need to change the following because of this article https://support.hashicorp.com/hc/en-us/articles/4548903433235-Terraform-Enterprise-External-Services-mode-with-Azure-Database-for-PostgreSQL-Flexible-Server-Failed-to-Initialize-**Plugins**
Select CITEXT, HSTORE, and UUID-OSSP  
![](media/20240123161355.png)  
Result should be    
![](media/20240123161412.png)  

- Redis Cache  
![](media/20240123160556.png)  
![](media/20240123160709.png)  
![](media/20240123160729.png)  
![](media/20240123160740.png)   

- Storage account   
![](media/20240123161829.png)  
![](media/20240123161912.png)  
![](media/20240123162045.png)  
![](media/20240123162108.png)  
![](media/20240123162132.png)  
![](media/20240123162148.png)  


- create a container   
![](media/20240123162725.png)   

save the keys and all   
![](media/20240123162822.png)   

- Create the Azure Kubernetes Service   
![](media/20240123162923.png)  
![](media/20240123163009.png)   
![](media/20240123163132.png)  
![](media/20240123163152.png)  
![](media/20240123163206.png)  
![](media/20240123163231.png)  

# deploying the TFE helm chart 

- Make sure you can connect to the Kubernetes cluster
```
az aks get-credentials --resource-group tfe11-manual --name tfe11
```
- check that you see the pods from all namespace. This should give some results
```
kubectl get pods -A
```
- create the namespace
```
kubectl create namespace terraform-enterprise
```
- create the docker secret
```
kubectl create secret docker-registry terraform-enterprise --docker-server=images.releases.hashicorp.com --docker-username=terraform --docker-password="license_content_from_hashicorp" -n terraform-enterprise
```
- Have the yaml file with the correct values
```
replicaCount: 1
tls:
  certData: "xxxxxxx=="
  keyData: "xxxxxxxx=="
  caCertData: "xxxxxxx=="
image:
  repository: images.releases.hashicorp.com
  name: hashicorp/terraform-enterprise
  tag: v202312-1
env:
  variables:
    TFE_HOSTNAME: tfe11.aws.munnep.com
    TFE_IACT_SUBNETS: "0.0.0.0/0"

    # Database Settings
    TFE_DATABASE_USER: tfe
    TFE_DATABASE_PASSWORD: "xxxxxxx"
    TFE_DATABASE_HOST: tfe11.postgres.database.azure.com
    TFE_DATABASE_NAME: tfe
    TFE_DATABASE_PARAMETERS: "sslmode=require"
    
    # Redis settings
    TFE_REDIS_HOST: tfe11.redis.cache.windows.net:6379
    TFE_REDIS_PASSWORD: xxxxx
    TFE_REDIS_USE_AUTH: true
    
    # Object storage settings.
    TFE_OBJECT_STORAGE_TYPE: "azure"
    TFE_OBJECT_STORAGE_AZURE_ACCOUNT_NAME: patricktfe11manual
    TFE_OBJECT_STORAGE_AZURE_CONTAINER: tfe11
    TFE_OBJECT_STORAGE_AZURE_ACCOUNT_KEY: 
  secrets:
    TFE_DATABASE_PASSWORD: "xxxxxxx"
    TFE_ENCRYPTION_PASSWORD:  "xxxxxx"
    TFE_LICENSE: "your_license"
```
- install the helm chart 
```
helm install terraform-enterprise hashicorp/terraform-enterprise -n terraform-enterprise --values overrides.yaml
```
- After a few minutes the pod should be up and running
```
kubectl get pods -n terraform-enterprise --watch
NAME                                    READY   STATUS              RESTARTS   AGE
terraform-enterprise-64d7bc4b6b-2l9rt   0/1     ContainerCreating   0          16s
terraform-enterprise-64d7bc4b6b-2l9rt   0/1     Running             0          26s
terraform-enterprise-64d7bc4b6b-2l9rt   1/1     Running             0          2m51s
```
- This should also have created a loadbalancer. If not uninstall the helm chart and install it again. 
```
kubectl get services -n terraform-enterprise                              
NAME                   TYPE           CLUSTER-IP    EXTERNAL-IP     PORT(S)         AGE
terraform-enterprise   LoadBalancer   10.0.18.149   52.146.55.195   443:32625/TCP   67s
```
- Create an A records in you DNS to connect to the TFE environment   
![](media/20240123171232.png)   
- Connect to the environment on your url and see the login screen   
![](media/20240123171414.png)   
- Get the token to create the first admin user
```
kubectl exec -it terraform-enterprise-64d7bc4b6b-xdzgd -n terraform-enterprise -- tfectl admin token
391ad31a26c7cccc2484ec3aea071782231486bdb79894d97bc32bff5af949ba
```
- Go to a browser with the token from above   
https://tfe11.aws.munnep.com/admin/account/new?token=391ad31a26c7cccc2484ec3aea071782231486bdb79894d97bc32bff5af949ba
- Fill in the following information  
![](media/20240124084009.png)  
- Now you can login and create a new organization
![](media/20240124084035.png)
- Create a workspace and do a run to verify all is working correctly  
![](media/20240124084400.png)