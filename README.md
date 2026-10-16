# End-to-End Django DevOps Project on AWS

A hands-on DevOps project demonstrating how to containerize, deploy, automate, and monitor a Django web application using AWS, Terraform, Docker, Kubernetes, Jenkins, and Prometheus/Grafana.

## Table of Contents

- [Project Overview](#project-overview)
- [Architecture](#architecture)
- [Technology Stack](#technology-stack)
- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)
- [1. Run the Application Locally](#1-run-the-application-locally)
- [2. Build and Test the Docker Image](#2-build-and-test-the-docker-image)
- [3. Provision AWS Infrastructure with Terraform](#3-provision-aws-infrastructure-with-terraform)
- [4. Configure Kubernetes and EKS](#4-configure-kubernetes-and-eks)
- [5. Deploy the Application](#5-deploy-the-application)
- [6. Jenkins CI/CD Pipeline](#6-jenkins-cicd-pipeline)
- [7. Prometheus and Grafana Monitoring](#7-prometheus-and-grafana-monitoring)
- [8. Validation and Troubleshooting](#8-validation-and-troubleshooting)
- [Security Best Practices](#security-best-practices)
- [Project Status](#project-status)

## Project Overview

The project uses a Django web application with a MySQL database to demonstrate a practical cloud-native delivery workflow.

The infrastructure was provisioned with Terraform, container images were stored in Amazon ECR, and the application was deployed to Amazon EKS. Jenkins automated the build and deployment workflow, while Prometheus and Grafana were used for monitoring and visualization.

### Key learning outcomes

- Infrastructure as Code using Terraform.
- Docker image creation and container management.
- AWS infrastructure, IAM, networking, ECR, EKS, and EFS.
- Kubernetes Deployments, Services, StatefulSets, Secrets, and persistent storage.
- Jenkins pipeline automation.
- Monitoring with Prometheus and Grafana.
- Troubleshooting application, database, networking, and deployment failures.
- AWS resource cleanup and cost awareness.

## Architecture

```text
Developer
    |
    v
GitHub Repository
    |
    v
Jenkins CI/CD
    |
    +---- Build Docker Image
    |
    +---- Push Image to Amazon ECR
    |
    v
Amazon EKS
    |
    +---- Django Deployment
    |       |
    |       v
    |    Django Service
    |
    +---- MySQL StatefulSet
    |       |
    |       v
    |    Persistent Storage
    |
    v
Application and Database

Monitoring:
Prometheus ---> Grafana
```

Terraform provisions the cloud infrastructure. Jenkins builds and publishes application images, Kubernetes runs the application, and Prometheus/Grafana provide monitoring and visualization.

> Note: This diagram represents the project workflow. ArgoCD-based GitOps, public ingress/domain configuration, and complete application-level monitoring are not claimed as finished implementations.

## Technology Stack

| Category | Technologies |
|---|---|
| Application | Python, Django |
| Database | MySQL |
| Version control | Git, GitHub |
| Containerization | Docker |
| Infrastructure as Code | Terraform |
| Cloud | AWS |
| Container registry | Amazon ECR |
| Orchestration | Kubernetes, Amazon EKS |
| Storage | Amazon EFS |
| CI/CD | Jenkins |
| Monitoring | Prometheus, Grafana |
| Operating environment | Windows, PowerShell, Amazon Linux |

## Project Structure

```text
End-to-End-DevOps-Project/
├── Jenkins_cicd/
│   ├── manage.py
│   ├── Dockerfile
│   ├── app/
│   └── basic/
├── Terraform/
│   ├── provider.tf
│   ├── main.tf
│   ├── vpc/
│   ├── ec2/
│   ├── eks/
│   ├── efs/
│   ├── ecr/
│   └── Route53_ACM/
├── Kubernetes with ArgoCD/
├── kubernetes-manual/
├── jenkins-deploy-rbac.yaml
├── aws-auth-backup.yaml
├── .gitignore
└── README.md
```

The exact contents of individual Terraform modules and Kubernetes directories may evolve as the project is updated.

## Prerequisites

Install the following tools on your development machine:

- Git
- Python and pip
- Docker Desktop
- AWS CLI
- Terraform
- `kubectl`

You also need an AWS account, configured AWS credentials, suitable IAM permissions, and an EC2 key pair if your Terraform configuration uses SSH access.

Verify the installations:

```powershell
git --version
python --version
pip --version
docker --version
aws --version
terraform version
kubectl version --client
```

Check your AWS identity and region:

```powershell
aws sts get-caller-identity
aws configure list
aws configure get region
```

The project was developed in the Mumbai AWS Region:

```text
ap-south-1
```

Never put AWS access keys, passwords, private keys, or database credentials in this repository.

## 1. Run the Application Locally

Open PowerShell in the repository root:

```powershell
cd "$HOME\Downloads\End-to-End-DevOps\End-to-End-DevOps-Project"
```

Move to the Django application directory:

```powershell
cd .\Jenkins_cicd
```

Create and activate a virtual environment:

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
```

Install the dependencies if a `requirements.txt` is present:

```powershell
pip install -r requirements.txt
```

Apply Django migrations:

```powershell
python manage.py migrate
```

Start the development server:

```powershell
python manage.py runserver
```

Open the application:

```text
http://127.0.0.1:8000/
```

Test the HTTP response from another PowerShell terminal:

```powershell
Invoke-WebRequest http://127.0.0.1:8000/ -UseBasicParsing
```

Stop the local server with `Ctrl+C`.

**Database note:** The application has been configured to use MySQL in the Kubernetes deployment. Local execution requires the database configuration and MySQL service expected by the Django settings.

## 2. Build and Test the Docker Image

From the repository root:

```powershell
cd "$HOME\Downloads\End-to-End-DevOps\End-to-End-DevOps-Project"
```

Build the image using the application's Dockerfile:

```powershell
docker build -t django-web-app:local .\Jenkins_cicd
```

List local images:

```powershell
docker images
```

Run a container if the image is designed to start the application directly:

```powershell
docker run --rm -p 8000:8000 django-web-app:local
```

Test the endpoint:

```powershell
Invoke-WebRequest http://127.0.0.1:8000/ -UseBasicParsing
```

This container command tests the web application process. A separate MySQL service or correctly configured database environment may be required for database-dependent pages to work.

Useful Docker commands:

```powershell
docker ps
docker ps -a
docker logs <container-name-or-id>
docker stop <container-name-or-id>
docker rmi django-web-app:local
```

Replace placeholders such as `<container-name-or-id>` with the actual value.

## 3. Provision AWS Infrastructure with Terraform

Terraform configuration is stored in the `Terraform/` directory.

The infrastructure developed for this project included:

- VPC, subnets, routing, and security groups.
- Jenkins and monitoring EC2 instances.
- Amazon ECR.
- Amazon EKS and a managed worker node group.
- Amazon EFS and the EFS CSI driver.
- IAM roles and policies.
- An S3 backend for Terraform state.

### Initialize Terraform

```powershell
cd "$HOME\Downloads\End-to-End-DevOps\End-to-End-DevOps-Project\Terraform"
```

Initialize the working directory:

```powershell
terraform init
```

Check the configuration:

```powershell
terraform fmt -recursive
terraform validate
```

Review the Terraform state:

```powershell
terraform workspace show
terraform state list
```

Create and review a plan:

```powershell
terraform plan
```

Apply the plan only after reviewing the proposed changes:

```powershell
terraform apply
```

Type `yes` only after verifying the resources, region, and expected cost.

### Terraform state backend

The project used an S3 backend in `ap-south-1`, with the state key:

```text
end-to-end-devops/terraform.tfstate
```

Check the backend configuration in `Terraform/provider.tf` before initializing or rebuilding.

Useful commands:

```powershell
terraform state list
terraform state show <resource-address>
terraform output
```

**Important:** Some AWS resources were manually deleted during cost cleanup. The existing Terraform state may therefore contain stale resource records. Before rebuilding, reconcile the state with the actual AWS resources and review `terraform plan`. Do not blindly apply the old state or run `terraform destroy` against it.

## 4. Configure Kubernetes and EKS

The EKS cluster used during the project was named `testing_k8s`.

After the cluster has been recreated, configure local `kubectl` access:

```powershell
aws eks update-kubeconfig `
  --region ap-south-1 `
  --name testing_k8s
```

Verify the cluster connection:

```powershell
kubectl cluster-info
kubectl get nodes -o wide
kubectl get namespaces
```

Check the system pods:

```powershell
kubectl get pods -n kube-system
```

Check EKS from the AWS CLI:

```powershell
aws eks describe-cluster `
  --region ap-south-1 `
  --name testing_k8s `
  --query "cluster.{Name:name,Status:status,Version:version}" `
  --output table
```

Check managed node groups:

```powershell
aws eks list-nodegroups `
  --region ap-south-1 `
  --cluster-name testing_k8s
```

### Kubernetes resources

The application environment used the `dev` namespace:

```powershell
kubectl get all -n dev
kubectl get deployments -n dev
kubectl get pods -n dev -o wide
kubectl get services -n dev
kubectl get pvc -n dev
kubectl get pv
```

Inspect the storage class:

```powershell
kubectl get storageclass
kubectl describe storageclass efs-sc
```

Inspect the MySQL workload:

```powershell
kubectl get statefulset -n dev
kubectl get pods -n dev
kubectl describe pod mysql-0 -n dev
```

## 5. Deploy the Application

The application was deployed to the `dev` namespace with a Django Deployment and a MySQL StatefulSet.

### Check the namespace and resources

```powershell
kubectl get namespace
kubectl get all -n dev
kubectl get secrets -n dev
kubectl get configmaps -n dev
```

Sensitive values should be stored in Kubernetes Secrets or an appropriate secrets manager, not committed to GitHub.

### Check MySQL

```powershell
kubectl get statefulset mysql -n dev
kubectl get pod mysql-0 -n dev
kubectl get service mysql-service -n dev
kubectl logs mysql-0 -n dev --tail=100
```

The database configuration used these logical values:

```text
DB_NAME=django_crud
DB_HOST=mysql-service
DB_PORT=3306
DB_USER=root
```

The database password is read from `mysql-secret`. Do not put the actual password in this README.

### Check Django

```powershell
kubectl get deployment django-deployment -n dev
kubectl rollout status deployment/django-deployment -n dev
kubectl get pods -n dev -o wide
kubectl logs deployment/django-deployment -n dev --tail=100
```

Check the service:

```powershell
kubectl get service django-service -n dev
kubectl describe service django-service -n dev
```

### Access the application with port forwarding

If `django-service` is a ClusterIP service, forward its port to your local machine:

```powershell
kubectl port-forward service/django-service 8000:8000 -n dev
```

Keep that terminal running, then open:

```text
http://127.0.0.1:8000/
```

Test the endpoint:

```powershell
Invoke-WebRequest http://127.0.0.1:8000/ -UseBasicParsing
```

Stop port forwarding with `Ctrl+C`.

### Update the image

After building and pushing a new image, update the Deployment with the correct ECR URI and tag:

```powershell
kubectl set image deployment/django-deployment `
  <container-name>=<AWS_ACCOUNT_ID>.dkr.ecr.ap-south-1.amazonaws.com/python_web_application:<image-tag> `
  -n dev
```

Replace `<container-name>` with the container name from the Deployment specification.

Verify the rollout:

```powershell
kubectl rollout status deployment/django-deployment -n dev
kubectl rollout history deployment/django-deployment -n dev
```

If needed, return to a previous revision:

```powershell
kubectl rollout undo deployment/django-deployment -n dev
```

## 6. Jenkins CI/CD Pipeline

The Jenkins pipeline was used to automate application delivery.

The workflow is:

1. Retrieve source code from GitHub.
2. Build the Docker image.
3. Authenticate to Amazon ECR.
4. Push the image to ECR.
5. Update the Kubernetes Deployment.
6. Verify the rollout.

The Jenkins job used for the project was named `django-devops-pipeline`.

### Validate the Jenkins host

Run these commands on the Jenkins EC2 instance:

```bash
whoami
git --version
docker --version
aws --version
kubectl version --client
```

Confirm AWS credentials and permissions:

```bash
aws sts get-caller-identity
aws configure get region
```

The Jenkins instance needs the correct IAM permissions to push to ECR and deploy to EKS. Avoid storing long-lived AWS access keys in a Jenkinsfile.

### ECR login

Run on the Jenkins host after setting the correct AWS region and account ID:

```bash
export AWS_REGION=ap-south-1
export AWS_ACCOUNT_ID=<AWS_ACCOUNT_ID>
export ECR_REPOSITORY=python_web_application

aws ecr get-login-password --region "$AWS_REGION" \
  | docker login \
      --username AWS \
      --password-stdin \
      "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"
```

### Build and push an image

Run from the directory containing the application's Dockerfile:

```bash
docker build -t "$ECR_REPOSITORY:$BUILD_NUMBER" .
```

Tag the image:

```bash
docker tag "$ECR_REPOSITORY:$BUILD_NUMBER" \
  "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY:$BUILD_NUMBER"
```

Push it to ECR:

```bash
docker push \
  "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY:$BUILD_NUMBER"
```

These commands assume that the ECR repository already exists and that the Jenkins IAM role has the required permissions.

### Verify the ECR image

```bash
aws ecr describe-images \
  --region ap-south-1 \
  --repository-name python_web_application
```

### Verify deployment permissions

```bash
kubectl auth can-i patch deployments -n dev
kubectl auth can-i watch deployments -n dev
kubectl auth can-i get pods -n dev
```

The Jenkins deployment identity must be authorized in the EKS cluster. Verify its role mapping and Kubernetes RBAC configuration when rebuilding.

## 7. Prometheus and Grafana Monitoring

Prometheus and Grafana were installed on a dedicated EC2 instance during the project.

- **Prometheus:** collects metrics from configured scrape targets.
- **Grafana:** visualizes metrics using Prometheus as a data source.

### Check services on the monitoring EC2 instance

Connect to the monitoring server using your own current SSH key and instance address.

Check Prometheus:

```bash
sudo systemctl status prometheus
```

Check Grafana:

```bash
sudo systemctl status grafana-server
```

If a service is stopped, inspect its logs before restarting it:

```bash
sudo journalctl -u prometheus -n 100 --no-pager
sudo journalctl -u grafana-server -n 100 --no-pager
```

Restart when appropriate:

```bash
sudo systemctl restart prometheus
sudo systemctl restart grafana-server
```

### Check Prometheus configuration

The configuration file is commonly located at:

```text
/etc/prometheus/prometheus.yml
```

Open it:

```bash
sudo nano /etc/prometheus/prometheus.yml
```

A basic Prometheus scrape configuration is:

```yaml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: prometheus
    static_configs:
      - targets: ['localhost:9090']
```

Save the file, validate it if the Prometheus configuration-check utility is installed, and restart Prometheus:

```bash
sudo systemctl restart prometheus
sudo systemctl status prometheus
```

### Optional: monitor Node Exporter

Node Exporter exposes Linux host metrics, typically on port `9100`. It must be installed and running before adding it as a scrape target.

After installation, add the following under `scrape_configs` in `prometheus.yml`:

```yaml
  - job_name: node_exporter
    static_configs:
      - targets: ['localhost:9100']
```

Restart Prometheus:

```bash
sudo systemctl restart prometheus
```

Verify the exporter endpoint locally:

```bash
curl http://localhost:9100/metrics
```

In the Prometheus web interface, open **Status → Targets** and verify that the `node_exporter` target is `UP`.

This target configuration is valid when Node Exporter runs on the same host as Prometheus. If the exporter runs on a different machine, use a reachable address instead.

### Grafana setup

Open Grafana at:

```text
http://<MONITORING_PUBLIC_IP>:3000/
```

In Grafana:

1. Open **Connections → Data sources**.
2. Add a Prometheus data source.
3. Set the URL to `http://localhost:9090` when Prometheus and Grafana run on the same EC2 host.
4. Select **Save & Test**.
5. Create a dashboard and add Prometheus queries.

Example PromQL query:

```promql
up
```

To show the number of successful scrape targets:

```promql
sum(up)
```

Do not expose Grafana or Prometheus publicly without appropriate access controls. Prefer restricted security-group rules, secure authentication, and private networking.

## 8. Validation and Troubleshooting

### Terraform

```powershell
terraform fmt -recursive
terraform validate
terraform plan
terraform state list
```

Always inspect the plan before applying changes.

### Kubernetes

```powershell
kubectl get pods -n dev
kubectl describe pod <pod-name> -n dev
kubectl logs <pod-name> -n dev --tail=100
kubectl get events -n dev --sort-by=.metadata.creationTimestamp
```

For a Deployment:

```powershell
kubectl describe deployment django-deployment -n dev
kubectl rollout status deployment/django-deployment -n dev
kubectl rollout history deployment/django-deployment -n dev
```

### Common problems

| Problem | Useful checks |
|---|---|
| Pod stuck in `Pending` | `kubectl describe pod <pod-name> -n dev` |
| Container restarting | `kubectl logs <pod-name> -n dev --previous` |
| Django cannot connect to MySQL | Check `DB_HOST`, Service DNS, Secret, and MySQL logs |
| `ImagePullBackOff` | Verify ECR URI/tag, IAM permissions, and image availability |
| Jenkins cannot deploy | Check `kubectl` installation, EKS access, and RBAC |
| Terraform shows unexpected changes | Inspect `terraform plan`, backend configuration, and current AWS resources |
| Prometheus target is down | Check the target address, service status, port, and security-group rules |
| Grafana cannot query Prometheus | Check the data-source URL and Prometheus service |

### Inspect AWS resources

```powershell
aws sts get-caller-identity
aws ec2 describe-instances --region ap-south-1
aws eks list-clusters --region ap-south-1
aws ecr describe-repositories --region ap-south-1
aws rds describe-db-instances --region ap-south-1
```

## Security Best Practices

- Never commit AWS credentials, `.pem` keys, database passwords, or tokens.
- Keep Terraform state private; it can contain sensitive information.
- Use IAM roles instead of long-lived access keys wherever possible.
- Restrict SSH, Jenkins, Grafana, and Prometheus access.
- Store application secrets outside source code.
- Review Terraform plans before applying changes.
- Use least-privilege IAM and Kubernetes RBAC permissions.
- Remove unused cloud resources when finished testing.

## Project Status

This project was implemented and tested in stages, including local Django validation, Docker image builds, Terraform-managed AWS infrastructure, EKS deployment, Jenkins-based image delivery, and Prometheus/Grafana setup.

The AWS infrastructure was subsequently cleaned up to reduce ongoing costs. The project repository and local files remain available for future rebuilding and practice.

Some advanced components—such as a complete ArgoCD GitOps workflow, public ingress/domain configuration, and fully verified Node Exporter monitoring—are not represented as completed features.

## Author

**Ayush Kamble**

- GitHub: [Aayush024](https://github.com/Aayush024)
- Project repository: [End-to-End-DevOps-Project](https://github.com/Aayush024/End-to-End-DevOps-Project)

