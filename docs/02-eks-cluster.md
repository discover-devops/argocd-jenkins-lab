# Part 2 - Build the EKS Cluster with Terraform (from the EC2)

**Where:** the EC2, in **PuTTY**.
**Diagram:** page **04 Part 2 EKS by Terraform**.
**Code:** [infra/eks/main.tf](../infra/eks/main.tf)

## Context

The jumpbox is ready. Now it builds the Kubernetes cluster where Argo CD and QuickKart will run. We run this Terraform from the EC2, so the EC2's IAM role becomes the cluster admin and kubectl works from here without any extra setup.

## Concept

- **Control plane:** the Kubernetes API, run and patched by AWS. We only give it an IAM role.
- **Managed node group:** 2 EC2 worker nodes that run our pods. They need their own IAM role to join the cluster and pull images from ECR.
- **Access entries:** EKS decides who may use kubectl. `bootstrap_cluster_creator_admin_permissions` makes whoever creates the cluster an admin, which is our jumpbox role.
- **Subnet tags:** Part 1 tagged the subnets with `kubernetes.io/role/elb`, so when a Service asks for a LoadBalancer, AWS knows where to put it.

## Lab

### 2.1 Log in to GitHub and get the lab repository

```bash
gh auth login --hostname github.com --git-protocol https --web
git config --global user.name "Rahul Chaubey"
git config --global user.email "discover.devops@gmail.com"
cd ~
git clone https://github.com/discover-devops/argocd-jenkins-lab.git
cd argocd-jenkins-lab
ls
```

- `gh auth login` shows a code. Open `https://github.com/login/device`, sign in as **discover-devops** and enter it. Git on this server can now push.
- The clone is the same repository you pushed from the laptop.

### 2.2 Create the cluster

```bash
cd ~/argocd-jenkins-lab/infra/eks
terraform init
terraform apply -auto-approve
```

- Terraform finds the 2 subnets from Part 1 by their tags, then creates the cluster role, the cluster, the node role and the node group.
- This takes **12 to 15 minutes**. Explain the concepts while it runs.

### 2.3 Connect kubectl

```bash
$(terraform output -raw connect_command)
kubectl get nodes -o wide
kubectl get pods -n kube-system
```

- `connect_command` runs `aws eks update-kubeconfig`, which writes the cluster login into `~/.kube/config`.
- You should see **2 nodes Ready** and the system pods Running.

**Checkpoint:** 2 Ready nodes.

## Interview Question

**How does EKS decide who can run kubectl, and who is admin right after creation?**

EKS authenticates callers with their IAM identity. Access entries, managed through the EKS API, map IAM users and roles to Kubernetes permissions. The older aws-auth ConfigMap does the same inside the cluster. With bootstrap cluster creator admin permissions enabled, the identity that created the cluster gets an admin access entry automatically, so in this lab the jumpbox role is admin.

---

## Keep Learning With Me

- YouTube: https://www.youtube.com/@BuildAutomateArchitect
- System Design playlist: https://www.youtube.com/playlist?list=PLeAHTLMwFYQ0
- Telegram: https://t.me/BuildAutomateArchitect
- Website: https://rahulchaubeyconsulting.com/
