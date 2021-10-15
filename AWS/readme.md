<!-- https://markdownlivepreview.com/ -->
# EKS with Istio, Terraform and Helm 3

### Prerequisites :

- AWS creds set with  admin user permissions (verify with aws s3 ls , it should return empty output or a bucket name)

- AWS IAM authenticator

    https://docs.aws.amazon.com/eks/latest/userguide/install-aws-iam-authenticator.html

- AWS Cli

    https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html


- kubectl( v19-20)

    https://kubernetes.io/docs/tasks/tools/

- terraform 1.0 ( 0.15.5)
    https://www.terraform.io/downloads.html
    https://learn.hashicorp.com/tutorials/terraform/install-cli

- HELM 3 

    https://helm.sh/docs/intro/install/


### 1. Terrafom variable.tf : Update domain_hosted_zone

Set this to the Route53 Hosted Zone ID 

### 2. Terrafom variable.tf :  Update domain_name

Set this to the Route53 domain name
This will be used to map to the Load Balancer DNS name and to access the apps
DNS "A" record with wildcard will be created 

### 3. AWS CLI : Create S3 bucket to store terraform state

Create S3 bucket(random salt, is generating random id to use for bucket name, as names for buckets should be globally unique ): 


    export RANDOM_SALT=$(xxd -l 5 -c 5 -p < /dev/random);
    aws s3api create-bucket --bucket tf-state-eks-$RANDOM_SALT --region us-east-1 --acl private;
    aws s3api put-public-access-block --bucket tf-state-eks-$RANDOM_SALT --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true";

Set  "bucket" value to the name of created S3 bucket in provider.tf : 

    bucket = "tf-state-eks-8b2a91c8b2"


### 4. Terraform : Download modules and initilise Terraform configuration

    terraform init

### 5. Terraform : Apply the configuration


    terraform apply

### 6. Kubectl : Export the kubeconfig file, that will be generated after Terraform apply

In "terraform outputs", you will see a command like '''export KUBECONFIG=./kubeconfig_test-eks-P4k92Nq0;'''. This is just example


Run it and verify that connection to the cluster works 

    kubectl get po
    kubectl get ns


### 7. Deploy the test app 

    helm upgrade apps  ./apps --values ./apps/values.yaml --install 

## 8. Check if Examle nginx app is available : 

Visit in browser :

    https://nginx.< domainName >

For example: 

    https://nginx.test.globaloptiix.com

## 8. Check if HTTP Bin s available : 

curl -I "https://qa.test.globaloptiix.com/status/200"

### Clean Up

    helm delete apps
    terraform destroy


### Additional information ; 

##### Checking istio virtual services : 
    kubectl get virtualservice -n applications    
##### Istio source for Helm charts : folder manifests/charts
    https://github.com/istio/istio/releases/download/1.11.2/istio-1.11.2-osx.tar.gz

