# Task 1 - Simple Time Service

The "app" directory contains a simple Python Flask application that provides the current timestamp and the IP address of the visitor.

## Overview

When accessed, the application returns a JSON response with the following information:

* **timestamp:** The current date and time on the server.
* **ip:** The IP address of the client making the request.

## Running the Application in Docker

The Python code for this service is located in the "Code" directory of this repository.

This application has been containerized and is available on Docker Hub. You can easily run it using Docker.

**Prerequisites**

**Docker:** Ensure you have Docker installed on your system. You can find installation instructions for your operating system on the official Docker website.
Running the Pre-built Docker Image (Recommended).

You can directly run the pre-built Docker image from Docker Hub or start with building the image using the Dockerfile available in this repository.

Bash

```
docker run -p 5000:5000 arun1771/my-sts-app:v2
```

Once the container is running, you can access the service by opening your web browser or using a tool like curl to the following address:

```
http://localhost:5000/
```
You should see a JSON response similar to:

JSON

```
{
  "timestamp": "2025-04-04T23:06:00.123456",
  "ip": "172.17.0.1"
}
```

# Task 2 - Terraform and Cloud

# Terraform EKS Cluster with Load Balancer

The "terraform" directory contains Terraform code to provision the following infrastructure in AWS:

* A Virtual Private Cloud (VPC) with:
    * 2 Public Subnets
    * 2 Private Subnets
* An Amazon Elastic Kubernetes Service (EKS) cluster deployed within the VPC.
* An EKS Node Group with worker nodes deployed exclusively in the **private** subnets.
* A Kubernetes Deployment running the `arun1771/my-sts-app:v2` container with 4 replicas.
* A Load Balancer (Network Load Balancer by default) deployed in the **public** subnets to expose the Kubernetes service.

## Prerequisites

* [Terraform](https://www.terraform.io/downloads.html) installed on your local machine.
* [AWS CLI](https://aws.amazon.com/cli/) configured with your AWS credentials and default region.
* `kubectl` installed on your local machine to interact with the EKS cluster after deployment.

## Deployment

This infrastructure can be deployed using only two Terraform commands:

1.  **Initialize Terraform:**

    ```bash
    terraform init
    ```

2.  **Review the planned changes:**

    ```bash
    terraform plan
    ```
    Carefully inspect the output of this command to understand the resources that will be created, modified, or destroyed.

3.  **Apply the Terraform configuration:**

    ```bash
    terraform apply -auto-approve
    ```
    This command will provision the AWS infrastructure as defined in the Terraform code. The `-auto-approve` flag will automatically approve the changes, but it's recommended to omit this flag for the initial run and manually approve after reviewing the plan.

## Post-Deployment

Once the `terraform apply` command completes successfully:

1.  **Configure `kubectl`:** Terraform outputs the necessary information to configure `kubectl` to connect to your new EKS cluster. You can typically find this in the Terraform output or by using the AWS CLI:

    ```bash
    aws eks update-kubeconfig --name <your_eks_cluster_name> --region <your_aws_region>
    ```
    *(Replace `<your_eks_cluster_name>` with `my-eks-cluster` and `<your_aws_region>` with the region you deployed to)*

2.  **Verify the Kubernetes Deployment:**

    ```bash
    kubectl get deployments -n default
    ```
    You should see the `my-sts-app-deployment` with 4 replicas ready.

3.  **Verify the Kubernetes Service and Load Balancer:**

    ```bash
    kubectl get svc -n default
    ```
    You should see the `my-sts-app-service` of type `LoadBalancer`. The external IP or hostname of the Load Balancer will be listed in the output. You can use this address to access your application.

## Cleanup

To destroy the created infrastructure, run the following command:

```bash
terraform destroy -auto-approve
