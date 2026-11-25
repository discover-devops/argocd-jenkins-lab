# Part 3 - Install Argo CD and Prepare the Lab

**Where:** the EC2, in **PuTTY**.
**Diagram:** page **05 Push vs Pull**.
**Code:** [argocd/values.yaml](../argocd/values.yaml), [scripts/fill-placeholders.sh](../scripts/fill-placeholders.sh)

## Context

The cluster is empty. We install Argo CD, the GitOps agent, and prepare everything the live lab needs: a read only user, the first image in ECR, and our repository filled with this account's values.

## Concept

- **Pull model:** Argo CD runs **inside** the cluster and pulls desired state from Git. Nothing outside needs cluster credentials.
- **Argo CD parts:** `server` is the UI and API. `repo-server` reads Git. `application-controller` compares Git with the cluster and applies changes. `applicationset-controller` makes Applications from templates.
- **Our settings** in [argocd/values.yaml](../argocd/values.yaml): plain HTTP (no domain in this lab), check Git every 60 seconds, a local user `dev1`, and read only as the default role.
- **LoadBalancer Service:** AWS gives the Argo CD UI an address. No domain or certificate in this lab. Production adds HTTPS and SSO.

## Lab

### 3.1 Install Argo CD

```bash
cd ~/argocd-jenkins-lab
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update argo
helm install argocd argo/argo-cd --namespace argocd --create-namespace --values argocd/values.yaml
```

Wait until the command returns by itself, then:

```bash
kubectl get pods -n argocd
```

Every pod becomes **Running** within 1 to 2 minutes.

### 3.2 Open the Argo CD UI

```bash
kubectl get svc argocd-server -n argocd
ARGOCD_HOST=$(kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "export ARGOCD_HOST=$ARGOCD_HOST" >> ~/.bashrc
ARGOCD_PASS=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo "UI:       http://$ARGOCD_HOST"
echo "User:     admin"
echo "Password: $ARGOCD_PASS"
```

- Run the first line until `EXTERNAL-IP` shows a name ending in `elb.amazonaws.com`.
- Open the UI address with **http**. A new load balancer can take 2 to 3 minutes to answer.

### 3.3 Give the read only user dev1 a password

```bash
argocd login $ARGOCD_HOST --username admin --password "$ARGOCD_PASS" --plaintext --grpc-web
argocd account update-password --account dev1 --current-password "$ARGOCD_PASS" --new-password 'Dev1-ReadOnly-2026'
argocd account list
```

- `--plaintext` because this lab has no HTTPS. `--grpc-web` lets the CLI work through the load balancer.
- `dev1` was created by `accounts.dev1: login` in the values file. It gets the default role, **readonly**.

### 3.4 Build and push the first image

```bash
cd ~/argocd-jenkins-lab
echo $ECR_REPO
FIRST_TAG=$(git rev-parse --short HEAD)-manual
aws ecr get-login-password | docker login --username AWS --password-stdin ${ECR_REPO%/*}
docker build --build-arg APP_VERSION=$FIRST_TAG -t $ECR_REPO:$FIRST_TAG app
docker push $ECR_REPO:$FIRST_TAG
echo $FIRST_TAG
```

- The tag is the git commit ID, never `latest`. ECR is set to immutable tags.
- Docker logs in to ECR with the EC2's IAM role. No password.

### 3.5 Fill in this account's values and push

```bash
cd ~/argocd-jenkins-lab
bash scripts/fill-placeholders.sh discover-devops $FIRST_TAG
git add .
git commit -m "Fill lab values: ECR, image tag, GitHub user, chart version"
git push
```

- The script replaces `__ECR_REPO__`, `__IMAGE_TAG__`, `__GITHUB_USER__` and `__SS_CHART__` in `app` and `gitops`, and checks that none are left.
- On your laptop, run `git pull` later so your copy matches GitHub.

**Checkpoint:** the Argo CD UI opens, `dev1` exists, the image is in ECR, and GitHub shows the filled files. **The platform is ready. Part 4 is the live lab.**

## Interview Question

**Which Argo CD component actually applies changes to the cluster?**

The application controller. The repo server only clones Git and renders manifests, and has no cluster access. The API server serves the UI, CLI and RBAC. The controller compares the rendered desired state with the live state, reports Synced or OutOfSync, and applies changes during a sync.

---

## Keep Learning With Me

- YouTube: https://www.youtube.com/@BuildAutomateArchitect
- System Design playlist: https://www.youtube.com/playlist?list=PLeAHTLMwFYQ0
- Telegram: https://t.me/BuildAutomateArchitect
- Website: https://rahulchaubeyconsulting.com/
