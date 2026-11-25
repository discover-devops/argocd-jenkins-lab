# Part 1 - Build the Jumpbox EC2 with Terraform (from your laptop)

**Where:** your laptop, **Git Bash** in VS Code, folder `K:\ArgoCD_Jenkins`.
**Diagram:** page **03 Part 1 EC2 by Terraform**.
**Code:** [infra/ec2/main.tf](../infra/ec2/main.tf), [infra/ec2/user_data.sh.tftpl](../infra/ec2/user_data.sh.tftpl)

## Context

We need one machine in AWS to drive the whole lab: it creates EKS, installs Argo CD and runs Jenkins. We build it with Terraform, so the setup is code that anyone can read and rebuild.

## Concept

- **Infrastructure as Code:** Terraform reads `.tf` files and creates exactly what they describe. `plan` shows what will change, `apply` does it, `destroy` removes it.
- **Network:** a **VPC** is our private network. The **internet gateway** is its door. Two **public subnets** in two zones, because EKS in Part 2 needs at least two zones.
- **Security group:** the EC2 firewall. Port 22 for PuTTY, port 8080 for Jenkins. Open to `0.0.0.0/0` only because this lab lives for one hour.
- **IAM role, not access keys:** the EC2 gets temporary AWS credentials from its role. No keys are stored on the server.
- **Key pair in .ppk format:** created by the AWS CLI straight in PuTTY format, saved next to the Terraform code, and kept out of Git by [.gitignore](../.gitignore).
- **user_data:** a script that runs once on first boot. It installs every tool and Jenkins, so the EC2 is ready when we log in.

## Lab

### 1.1 Check the tools on your laptop

```bash
terraform -version
aws --version
git --version
gh --version
```

If one is missing, install it, then close and reopen VS Code:

```bash
winget install -e --id Hashicorp.Terraform
winget install -e --id Amazon.AWSCLI
winget install -e --id GitHub.cli
winget install -e --id PuTTY.PuTTY
```

### 1.2 Connect the AWS CLI to the new account

Use an IAM user or SSO user with admin rights in the new account, never the root user.

```bash
aws configure --profile argocd-lab
export AWS_PROFILE=argocd-lab
aws sts get-caller-identity
```

- `aws configure` asks for the access key, secret key, region `ap-south-1` and output `json`.
- `export AWS_PROFILE` makes Terraform and the AWS CLI use this account in this terminal. Run it again in every new terminal.
- `get-caller-identity` must show the new account number.

### 1.3 Put the lab files in the folder and push them to GitHub

Unzip the lab kit so that `K:\ArgoCD_Jenkins` directly contains `README.md`, `infra`, `app`, `gitops` and the other folders. Then:

```bash
cd /k/ArgoCD_Jenkins
git config --global core.autocrlf input
git init
git add .
git commit -m "Jenkins and Argo CD GitOps lab"
gh auth status || gh auth login
gh repo create discover-devops/argocd-jenkins-lab --public --source . --push
```

- `core.autocrlf input` plus our [.gitattributes](../.gitattributes) keep Linux line endings, so scripts run correctly on the EC2.
- The repository is **public**, so Argo CD can read it without credentials.
- `gh repo create --source . --push` creates the GitHub repository and pushes this folder in one step.

### 1.4 Create the infrastructure

```bash
cd /k/ArgoCD_Jenkins/infra/ec2
terraform init
terraform plan
terraform apply -auto-approve
```

- `init` downloads the AWS provider.
- `plan` lists everything Terraform will create: VPC, internet gateway, 2 subnets, route table, security group, IAM role, key pair, ECR repository and the EC2.
- `apply` creates them, about 2 minutes. Read the outputs at the end.
- Run Terraform from **Git Bash**. The key pair step uses `bash` and the AWS CLI.

### 1.5 Connect with PuTTY

```bash
terraform output putty_host
ls -l argocd-lab-key.ppk
```

| PuTTY setting | Value |
|---|---|
| Session, Host Name | the `ubuntu@...` value from the output |
| Connection, SSH, Auth, Credentials, Private key file | `K:\ArgoCD_Jenkins\infra\ec2\argocd-lab-key.ppk` |
| Session, Saved Sessions | `argocd-lab`, then **Save** |

Click **Open**, then **Accept** the host key.

### 1.6 Wait for the first boot script (on the EC2)

```bash
cloud-init status --wait
cat /var/tmp/lab-ready.txt
```

- `cloud-init status --wait` waits until user_data has finished, about 5 to 7 minutes after launch.
- `lab-ready.txt` lists the version of every tool and shows `active` for Jenkins.
- If something is missing, read `/var/log/cloud-init-output.log`.

Log out and log in again once, so the `docker` group and the lab settings in `/etc/profile.d/lab.sh` are loaded:

```bash
exit
```

### 1.7 Unlock Jenkins

```bash
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
echo $ECR_REPO
```

In your browser open the `jenkins_url` from the Terraform output, `http://<ip>:8080`:

1. Paste the unlock password.
2. **Install suggested plugins**.
3. Create the admin user with a strong password.
4. **Save and Finish**, then **Start using Jenkins**.

**Checkpoint:** PuTTY works, `lab-ready.txt` lists all tools, `echo $ECR_REPO` prints the ECR address, and the Jenkins dashboard is open.

## Interview Question

**Why use an IAM role on EC2 instead of access keys?**

A role gives the instance short lived credentials through the instance metadata service, rotated automatically. Nothing secret is stored on disk, nothing can be copied and reused forever, and access is removed by changing the role. Access keys are long lived, easy to leak in scripts or images, and hard to rotate.

---

## Keep Learning With Me

- YouTube: https://www.youtube.com/@BuildAutomateArchitect
- System Design playlist: https://www.youtube.com/playlist?list=PLeAHTLMwFYQ0
- Telegram: https://t.me/BuildAutomateArchitect
- Website: https://rahulchaubeyconsulting.com/
