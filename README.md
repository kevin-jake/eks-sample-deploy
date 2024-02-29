# EKS Sample Deploy

This repository contains source code to provision a sample EKS Cluster to AWS AWS using Terraform.

The Kubernetes cluster will run podinfo application and a sample nodejs application with mongodb ([Grade Book App](https://github.com/kevin-jake/grade_book_app))

## Infrastructure Setup with Terraform

This sample deployment of EKS is deployed on a default region in `ap-southeast-1`. This infrastrucature consist of one main VPC and 2 public and private subnets for each availability zones ("ap-southeast-1a", "ap-southeast-1b"). The EKS cluster is named `test-eks` and has a public and private nodegroups.

### Connect to the Kubernetes cluster

`aws eks update-kubeconfig --name test-eks --region ap-southeast-1`

## Application Deployment on Kubernetes

https://kubernetes.github.io/ingress-nginx/deploy/#quick-start

`kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/cloud/deploy.yaml`
