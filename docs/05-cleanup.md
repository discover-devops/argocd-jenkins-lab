# Part 5 - Cleanup: Delete Everything

**Diagram:** page **12 Cleanup Order**.

## Context

EKS, the nodes, the EC2 and the load balancers bill every hour. We delete everything in the reverse order of creation.

## Concept

- Load balancers created by Kubernetes Services are **not** in Terraform. If they still exist, Terraform cannot delete the VPC. So we remove them first, through Kubernetes.
- Delete the Applications before Argo CD, so Argo CD does not recreate anything.

## Lab

### 5.1 Remove the apps and their load balancers (EC2, PuTTY)

```bash
kubectl delete application root -n argocd
kubectl delete applicationset quickkart -n argocd
kubectl delete application --all -n argocd
helm uninstall argocd -n argocd
kubectl delete namespace quickkart-dev quickkart-prod argocd
sleep 60
kubectl get svc -A | grep LoadBalancer || echo "No load balancers left"
```

- Deleting the namespaces deletes the LoadBalancer Services, and AWS removes their load balancers.
- The last line must print **No load balancers left**.

### 5.2 Delete EKS (EC2, PuTTY)

```bash
cd ~/argocd-jenkins-lab/infra/eks
terraform destroy -auto-approve
```

About 10 minutes.

### 5.3 Delete the jumpbox, network and ECR (laptop, Git Bash)

```bash
export AWS_PROFILE=argocd-lab
cd /k/ArgoCD_Jenkins/infra/ec2
terraform destroy -auto-approve
```

- This also deletes the ECR repository with its images, and the key pair and `.ppk` file.

### 5.4 Check (laptop)

```bash
aws eks list-clusters --region ap-south-1
aws ec2 describe-instances --region ap-south-1 --filters "Name=tag:Project,Values=argocd-lab" "Name=instance-state-name,Values=running,stopped" --query "Reservations[].Instances[].InstanceId" --output text
aws elb describe-load-balancers --region ap-south-1 --query "LoadBalancerDescriptions[].LoadBalancerName" --output text
aws ec2 describe-vpcs --region ap-south-1 --filters "Name=tag:Project,Values=argocd-lab" --query "Vpcs[].VpcId" --output text
```

Every command should print nothing, or an empty list.

The GitHub repository stays. It is your teaching material. Delete the Jenkins GitHub token under GitHub, Settings, Developer settings.

## Interview Question

**terraform destroy fails on the VPC with a dependency error. What is the usual cause?** Resources created outside Terraform that live in the VPC, most often load balancers or their network interfaces and security groups created by Kubernetes. Delete them through Kubernetes first, wait for AWS to remove them, then run destroy again.

---

## Keep Learning With Me

- YouTube: https://www.youtube.com/@BuildAutomateArchitect
- System Design playlist: https://www.youtube.com/playlist?list=PLeAHTLMwFYQ0
- Telegram: https://t.me/BuildAutomateArchitect
- Website: https://rahulchaubeyconsulting.com/
