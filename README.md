# Jenkins + Argo CD GitOps Lab on AWS EKS

One small platform, eight GitOps topics, all live: App of Apps, ApplicationSets, Sync Waves and Hooks, Secret management, Sealed Secrets, OIDC and RBAC, Jenkins with Argo CD, and the end to end workflow.

**The idea:** Jenkins builds the image and changes Git. Argo CD, inside the cluster, pulls Git and deploys. Jenkins never touches the cluster.

## Runbook

| Part | Where | What |
|---|---|---|
| [Part 0 - Overview](docs/00-overview.md) | - | What we build and why |
| [Part 1 - Jumpbox EC2](docs/01-jumpbox-ec2.md) | Laptop | Terraform: VPC, ECR, EC2 with Jenkins and all tools |
| [Part 2 - EKS](docs/02-eks-cluster.md) | EC2 | Terraform: EKS with 2 nodes |
| [Part 3 - Argo CD](docs/03-argocd-setup.md) | EC2 | Argo CD, users, first image |
| [Part 4 - The Lab](docs/04-the-lab.md) | EC2 + browser | The 8 topics, live |
| [Part 5 - Cleanup](docs/05-cleanup.md) | EC2, then laptop | Delete everything |

Diagrams: [diagrams/argocd-jenkins-lab.drawio](diagrams/argocd-jenkins-lab.drawio), open in draw.io.

## Repository layout

```text
infra/ec2/     Terraform, Part 1
infra/eks/     Terraform, Part 2
argocd/        Argo CD Helm values
app/           QuickKart app, Dockerfile, Jenkinsfile
gitops/        What Argo CD watches: root app, child apps, dev, prod
scripts/       fill-placeholders.sh
docs/          The runbook
diagrams/      draw.io teaching diagrams
```

## Keep Learning With Me

- YouTube: https://www.youtube.com/@BuildAutomateArchitect
- System Design playlist: https://www.youtube.com/playlist?list=PLeAHTLMwFYQ0
- Telegram: https://t.me/BuildAutomateArchitect
- Website: https://rahulchaubeyconsulting.com/
