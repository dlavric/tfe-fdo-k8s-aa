# tfe-fdo-k8s-aa
This repository will install TFE FDO on K8s in Active/Active mode with External Services configuration on AWS infrastructure with Postgres 14.9 version.


## Pre-requisites

- [X] [Terraform Enterprise FDO License](https://developer.hashicorp.com/terraform/enterprise/flexible-deployments/install/requirements/license)
- [X] [AWS Account](https://aws.amazon.com/free/?gclid=Cj0KCQiAy9msBhD0ARIsANbk0A9djPCZfMAnJJ22goFzJssB-b1RfMDf9XvUYa0NuQ8old01xs4u8wIaAts9EALw_wcB&trk=65c60aef-03ac-4364-958d-38c6ccb6a7f7&sc_channel=ps&ef_id=Cj0KCQiAy9msBhD0ARIsANbk0A9djPCZfMAnJJ22goFzJssB-b1RfMDf9XvUYa0NuQ8old01xs4u8wIaAts9EALw_wcB:G:s&s_kwcid=AL!4422!3!458573551357!e!!g!!aws%20account!10908848282!107577274535&all-free-tier.sort-by=item.additionalFields.SortRank&all-free-tier.sort-order=asc&awsf.Free%20Tier%20Types=*all&awsf.Free%20Tier%20Categories=*all)
- [X] [Terraform](https://www.terraform.io/downloads)

## Steps on how to use this repository

- Clone this repository:
```shell
git clone git@github.com:dlavric/tfe-fdo-k8s-aa.git
```

- Go to the directory where the repository is stored:
```shell
cd tfe-fdo-k8s-aa
```

- Create a file `variables.auto.tfvars` with the following content
```hcl
aws_region       = "eu-west-2" 
storage_bucket   = "daniela-k8s-storage2" 
db_identifier    = "daniela-db-docker" 
db_name          = "danieladb" 
db_username      = "postgres" 
db_password      = "password" 
eks_desired_size = 1 
eks_max_size     = 2 
eks_min_size     = 1 
```

- Export AWS environment variables
```shell
export AWS_ACCESS_KEY_ID=
export AWS_SECRET_ACCESS_KEY=
export AWS_SESSION_TOKEN=
export AWS_REGION= 
```

- Download all the Terraform dependencies for modules and providers
```shell
terraform init
```

- Verify the output is successfull
```shell
Initializing the backend...

Initializing provider plugins...
- Reusing previous version of hashicorp/aws from the dependency lock file
- Reusing previous version of vancluever/acme from the dependency lock file
- Using previously-installed hashicorp/aws v5.26.0
- Using previously-installed vancluever/acme v2.17.2

Terraform has made some changes to the provider dependency selections recorded
in the .terraform.lock.hcl file. Review those changes and commit them to your
version control system if they represent changes you intended to make.

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
```

- Apply all the changes
```shell
terraform apply
```

- Verify the output matches in number of resources
```shell
Plan: 25 to add, 0 to change, 0 to destroy.
```

- This part will only deploy the infrastructure for the TFE installation: Network, PostgreSQL DB, S3 Bucket, Redis and the EKS Cluster

- Change the directory to install TFE application
```shell
cd install-tfe
```

- Create a file `variables.auto.tfvars` with the following content (NOTE: `raw_tfe_license` is the TFE FDO License)
```hcl
tfe_namespace     = "terraform-enterprise"
registry_server   = "images.releases.hashicorp.com"
registry_username = "terraform"
raw_tfe_license   = "02MV...."
tfe_hostname      = "tfe-k8s.daniela.sbx.hashidemos.io"
tfe_version       = "v202402-1"
enc_password      = "encpassword"
replica_count     = 1
aws_region        = "eu-west-2"
email             = "your-email"
certs_bucket      = "daniela-k8s-certs3"
tfe_domain        = "daniela.sbx.hashidemos.io"
tfe_subdomain     = "tfe-k8s"
```

- Download the helm repository locally to yor computer, **Step 5** of the [official documentation](https://developer.hashicorp.com/terraform/enterprise/flexible-deployments/install/kubernetes/install#2-pull-image)
```shell
helm repo add hashicorp https://helm.releases.hashicorp.com
```

- Download all the Terraform dependencies for modules and providers
```shell
terraform init
```

- Check the output
```shell
Initializing the backend...

Initializing provider plugins...
- terraform.io/builtin/terraform is built in to Terraform
- Reusing previous version of hashicorp/aws from the dependency lock file
- Reusing previous version of vancluever/acme from the dependency lock file
- Reusing previous version of hashicorp/helm from the dependency lock file
- Reusing previous version of hashicorp/kubernetes from the dependency lock file
- Finding latest version of hashicorp/null...
- Reusing previous version of hashicorp/tls from the dependency lock file
- Using previously-installed hashicorp/aws v5.26.0
- Using previously-installed vancluever/acme v2.17.2
- Using previously-installed hashicorp/helm v2.12.1
- Using previously-installed hashicorp/kubernetes v2.27.0
- Installing hashicorp/null v3.2.2...
- Installed hashicorp/null v3.2.2 (signed by HashiCorp)
- Using previously-installed hashicorp/tls v4.0.5

Terraform has made some changes to the provider dependency selections recorded
in the .terraform.lock.hcl file. Review those changes and commit them to your
version control system if they represent changes you intended to make.

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
```

- Apply all the changes
```shell
terraform apply
```

- Verify the output matches in number of resources that are being deployed
```shell
Plan: 10 to add, 0 to change, 0 to destroy.
```

NOTE: It might take up to 18-20 minutes to create the initial user until the DNS for TFE gets picked up by your computer

## How to troubleshoot

- Make sure to execute the following command to be able to connect to the EKS cluster
```shell
aws eks update-kubeconfig --region <your-region> --name <eks-cluster-name>
```

- Check the pods
```shell
kubectl -n terraform-enterprise get pods
```

- Example output when the pod is running successfully
```shell
NAME                                   READY   STATUS    RESTARTS   AGE
terraform-enterprise-cdfd4b8d6-9c6mc   1/1     Running   0          55m
```

- Check the details of the pod, where `terraform-enterprise-cdfd4b8d6-9c6mc` is the *NAME* of the pod
```shell
kubectl -n terraform-enterprise describe pods terraform-enterprise-cdfd4b8d6-9c6mc
```

- Example output for the pod
```shell
Events:
  Type     Reason     Age                 From               Message
  ----     ------     ----                ----               -------
  Normal   Scheduled  56m                 default-scheduler  Successfully assigned terraform-enterprise/terraform-enterprise-cdfd4b8d6-9c6mc to ip-<ip>.eu-west-2.compute.internal
  Normal   Pulling    56m                 kubelet            Pulling image "images.releases.hashicorp.com/hashicorp/terraform-enterprise:v202402-1"
  Normal   Pulled     56m                 kubelet            Successfully pulled image "images.releases.hashicorp.com/hashicorp/terraform-enterprise:v202402-1" in 254ms (254ms including waiting)
  Normal   Created    56m                 kubelet            Created container terraform-enterprise
  Normal   Started    56m                 kubelet            Started container terraform-enterprise
  Warning  Unhealthy  56m (x2 over 56m)   kubelet            Readiness probe failed: Get "http://<ip>:8080/_health_check": dial tcp <ip>>:8080: connect: connection refused
  Warning  Unhealthy  53m (x19 over 56m)  kubelet            Readiness probe failed: HTTP probe failed with statuscode: 502
  ```

  - Check the logs of the container
  ```shell
  kubectl logs -f terraform-enterprise-cdfd4b8d6-9c6mc -n terraform-enterprise
  ```



## Uninstall TFE and remove the infrastructure
- From the `install-tfe/` path run
```shell
terraform destroy
```

Go to the root path and destroy the infrastructure
```shell
cd ..
terraform destroy
```