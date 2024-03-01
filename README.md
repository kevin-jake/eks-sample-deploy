# EKS Sample Deploy

This repository contains source code to provision a sample EKS Cluster to AWS AWS using Terraform.

Amazon Elastic Kubernetes Service (EKS) is a managed Kubernetes service provided by Amazon Web Services (AWS). It simplifies the process of running Kubernetes clusters on AWS infrastructure.

The Kubernetes cluster will run podinfo application and a sample nodejs application with mongodb ([Grade Book App](https://github.com/kevin-jake/grade_book_app))

## Infrastructure Setup with Terraform

This sample deployment of EKS is deployed on a default region in `ap-southeast-1`. This infrastrucature consist of one main VPC and 2 public and private subnets for each availability zones ("ap-southeast-1a", "ap-southeast-1b"). The EKS cluster is named `test-eks` and has a public and private nodegroups.

To setup the infrastructure go to IaC directory and run the commands below, make sure that you have Terraform installed and AWS Account is configured in your local machine.

Guide on how to install terraform ([Install Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli))
Guide on how to setup AWS CLI ([Setup AWS](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html))

```
cd IaC
terraform init
terraform plan
terraform apply
```

This will create the AWS EKS cluster in your AWS account.

### Terraform templates

| templates    | Description                                                                                                                                                                                                                                     |
| ------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| providers.tf | Configures the providers, in the provider file for this project AWS is set with a default region of ap-southeast-1                                                                                                                              |
| eks.tf       | Defines the resources and configurations for an Amazon EKS (Elastic Kubernetes Service) cluster. This also where the 2 public nodegroups and 1 private nodegroup is defined                                                                     |
| iam.tf       | This is where the required Identity and Access Management (IAM) roles, policies, and permissions for the EKS cluster is defined                                                                                                                 |
| network.tf   | Specifies the network settings, such as VPC (Virtual Private Cloud), subnets, routing, and gateways. There is one main vpc and a default 2 public and private subnets for each availability zones. This could be modified in the sing variables |
| sg.tf        | Sets up Security Groups to control inbound and outbound traffic for resources to allow access and traffice to the application deployed in the EKS cluster                                                                                       |

### variables.tf

Using variables you can modify some of the parameters of the EKS cluster

| Variable Name              | Type         | Default Value                          | Description                                        |
| -------------------------- | ------------ | -------------------------------------- | -------------------------------------------------- |
| eks_cluster_name           | string       |                                        | The name of the EKS cluster                        |
| environment_tag            | string       |                                        | Environment tag for the VPC                        |
| vpc_cidr_block             | string       | 10.0.0.0/16                            | CIDR block range for the VPC                       |
| private_subnet_cidr_blocks | list(string) | ["10.0.0.0/24", "10.0.1.0/24"]         | CIDR block range for the private subnet            |
| public_subnet_cidr_blocks  | list(string) | ["10.0.2.0/24", "10.0.3.0/24"]         | CIDR block range for the public subnet             |
| availability_zones         | list(string) | ["ap-southeast-1a", "ap-southeast-1b"] | List of availability zones for the selected region |
| region                     | string       | ap-southeast-1                         | AWS region to deploy to                            |

### output.tf

This file defines the output values that will be shown after Terraform applies the configuration.

| Output Name      | Description                    | Value                         |
| ---------------- | ------------------------------ | ----------------------------- |
| cluster_endpoint | Endpoint for EKS control plane | aws_eks_cluster.main.endpoint |
| region           | AWS region                     | var.region                    |
| cluster_name     | Kubernetes Cluster Name        | aws_eks_cluster.main.name     |

### Connect to the Kubernetes cluster

After the terraform apply run successfully. You can now connect to your cluster using the command below:

`aws eks update-kubeconfig --name test-eks --region ap-southeast-1`

## Application Deployment on Kubernetes

Once you are connected to the Kubernetes cluster you can now run deployments and provision application. To start provisioning you can take podinfo as your example application.

### Ingress

Install nginx ingress using this guide ([Install Nginx ingress](https://kubernetes.github.io/ingress-nginx/deploy/#quick-start)).

Or simply run this command

`kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/cloud/deploy.yaml`

### podinfo

In the podinfo directory. You can see manifests files that are defined with numerical prefix. This is to ensure that the application of each manifests files is in the correct order.

| File Name                  | Description                                                                                                                                                                 |
| -------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 01-podinfo-ns.yaml         | Namespace for Podinfo. Namespace name is defined as `podinfo`                                                                                                               |
| 02-podinfo-deployment.yaml | Deployment for Podinfo. This is where we define the container image to use and expose the port `9898` to access the web ui of the application.                              |
| 03-podinfo-hpa.yaml        | Horizontal Pod Autoscaler. This is where the autoscaling rules are defined. Maximum number of pods is `4` and minimum number is `2`                                         |
| 04-podinfo-svc.yaml        | Service for Podinfo. This is where the service port `9898` is exposed in type `NodePort`                                                                                    |
| 05-podinfo-ingress.yaml    | Ingress for Podinfo. This is where we expose the service into an nginx ingress. Make sure that nginx ingress controller is installed in the cluster to publicly access this |

Run this command to get the loadbalancer public address to access the application.

`kubectl get ingress -n podinfo`

### grade-book-nodejs

This directory uses a sample application based from ([Grade Book App](https://github.com/kevin-jake/grade_book_app)).

The manifests files are defined with numerical prefix to also ensure that the application of each manifests files are in the correct order.

| File Name          | Description                                                                                                                                                                                                                                                         |
| ------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 01-namespace.yaml  | Namespace for grade-book-nodejs. Namespace name is defined as `gradebook-app`                                                                                                                                                                                       |
| 02-deployment.yaml | Deployment for grade-book-nodejs and mongodb database. Mongo deployment have a volume mount of `mongo-storage` and exposed port of `27107` and uses the `mongo` image. The nodeapp deployment exposes port `3000` and uses the image `kevinjake/node-gradebook-app` |
| 03-svc.yaml        | Service for Podinfo. Mongo service port is `27107` is exposed in type `NodePort`. Nodeapp service port is `3000` is exposed in type `NodePort`                                                                                                                      |
| 04-ingress.yaml    | Ingress for Podinfo. This is where we expose the service into an nginx ingress. Make sure that nginx ingress controller is installed in the cluster to publicly access this. The application is accessible in a `<alb address>/grade-book-nodejs`                   |

Run this command to get the loadbalancer public address to access the application.

`kubectl get ingress -n gradebook-app`

To test the app please refer to this section [Testing](https://github.com/kevin-jake/grade_book_app?tab=readme-ov-file#pseudo-code)

## Improvements

- The tfstate or the terraform state of this sample deployment is stored only locally. We can use configure the backend to use cloud providers to store the data state files and have a more persisted and in-sync state.
- We can also implement a module approach on deploying our EKS cluster there a lot of modules that we can use one is using the official module from terraform and AWS: [AWS EKS Terraform module](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest).
- We can also define the Kubernetes resources in our terraform template for an extended management of our Kubernetes cluster within terraform.
- For Kubernetes manifests files, we can simply make helm charts to make it easier to organize and make the manifests files reusable.
- We can also implement a CI/CD pipeline, possibly using Jenkins or Github Actions, that will automatically update our cluster when a git push happened within the Grade Book Application.
- There are still a security improvement that we can do by specifying the security groups and also isolating pods into private nodes. Example of these are those pods that are not supposed to be accessed by the public like mongodb.

### Clean up

To clean everything just follow the commands below

```
kubectl delete -f k8s/podinfo
kubectl delete -f k8s/grade-book-app

kubectl config unset current-context

cd IaC
terraform destroy
```
