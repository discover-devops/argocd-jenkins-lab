# Part 0 - Lab Overview: Jenkins + Argo CD GitOps on AWS EKS

Diagram: [diagrams/argocd-jenkins-lab.drawio](../diagrams/argocd-jenkins-lab.drawio), pages **01 Full Picture** and **02 Lab Roadmap**.

## Context

You have learned eight GitOps topics one by one. In a company they never run alone. They run together, on one cluster, for one application. In this lab we build one small platform and show all eight topics on it, live.

## Concept

**The one idea of this lab:** Jenkins builds the image and changes Git. Argo CD, inside the cluster, pulls Git and deploys. **Jenkins never touches the cluster. Git is the only door to production.**

| # | Topic | Where you see it |
|---|---|---|
| 1 | App of Apps | One `root` Application creates every other Application |
| 2 | ApplicationSets | One template makes `quickkart-dev` and `quickkart-prod` |
| 3 | Sync Waves and Hooks | Controller first, ConfigMap next, app last, then a smoke test |
| 4 | Secret management | A plain Secret is only base64, anyone can read it |
| 5 | Sealed Secrets | Encrypted in Git, decrypted only in the cluster |
| 6 | OIDC and RBAC | User `dev1` can look, but cannot sync |
| 7 | Jenkins and Argo CD | Jenkins builds, pushes to ECR, commits the new tag |
| 8 | End to end | Code change to dev, then a Git change promotes to prod |

## What is in this repository

| Folder | What it holds |
|---|---|
| [infra/ec2](../infra/ec2) | Terraform, Part 1: VPC, subnets, security group, IAM role, key pair, ECR, jumpbox EC2 |
| [infra/eks](../infra/eks) | Terraform, Part 2: EKS cluster and 2 worker nodes |
| [argocd/values.yaml](../argocd/values.yaml) | Helm settings for Argo CD, Part 3 |
| [app](../app) | The QuickKart web app, its Dockerfile and the Jenkinsfile |
| [gitops](../gitops) | Everything Argo CD watches: root app, child apps, dev and prod |
| [scripts](../scripts) | Helper to fill your account values into the files |
| [diagrams](../diagrams) | draw.io teaching diagrams, one page per topic |

## The parts

| Part | Where you run it | What happens |
|---|---|---|
| [Part 1](01-jumpbox-ec2.md) | Laptop, Git Bash | Terraform builds the network, ECR and the jumpbox EC2, which is also Jenkins |
| [Part 2](02-eks-cluster.md) | EC2, PuTTY | Terraform builds EKS. kubectl connects |
| [Part 3](03-argocd-setup.md) | EC2, PuTTY | Argo CD, users, first image, fill the repo |
| [Part 4](04-the-lab.md) | EC2 + browser | **The lab: all 8 topics, live** |
| [Part 5](05-cleanup.md) | EC2, then laptop | Delete everything |

**Time:** Parts 1 to 3 take about 45 minutes, most of it waiting for AWS. Part 4 takes about 60 minutes.

**Cost:** EKS, 2 t3.large nodes, the EC2 and the load balancers bill every hour. Run Part 5 the same day.

## Interview Question

**Walk me through git push to production in a GitOps setup.**

The developer pushes code. Jenkins builds and tests it, pushes the image to the registry with a unique tag, and commits that tag to the GitOps repository. Argo CD, running inside the cluster, sees the commit and syncs the change. Promotion to the next environment is another Git change, often through a pull request. The CI system never holds cluster credentials, every deployment is a commit, and rollback is a git revert.

---

## Keep Learning With Me

- YouTube: https://www.youtube.com/@BuildAutomateArchitect
- System Design playlist: https://www.youtube.com/playlist?list=PLeAHTLMwFYQ0
- Telegram: https://t.me/BuildAutomateArchitect
- Website: https://rahulchaubeyconsulting.com/
