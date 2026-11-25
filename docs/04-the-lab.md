# Part 4 - The Lab: 8 GitOps Topics, Live

**Where:** the EC2 in **PuTTY**, plus the Argo CD UI, Jenkins and GitHub in your browser.
**Before you start:** Parts 1 to 3 are done. Every new PuTTY session already has `ARGOCD_HOST` and `ECR_REPO`.

```bash
cd ~/argocd-jenkins-lab && git pull
echo "Argo CD: http://$ARGOCD_HOST"
```

| Section | Topics | Diagram page |
|---|---|---|
| 4.1 | App of Apps, ApplicationSets | 06 |
| 4.2 | Sync Waves and Hooks | 07 |
| 4.3 | Secret management, Sealed Secrets | 08 |
| 4.4 | OIDC and RBAC | 09 |
| 4.5 | Jenkins and Argo CD | 10 |
| 4.6 | End to end: promote, self heal | 11 |

---

## 4.1 App of Apps and ApplicationSets (Topics 1 and 2)

### Context

A real platform has many applications in many environments. Nobody should create them one by one by hand.

### Concept

- **App of Apps:** one **root** Application watches [gitops/apps](../gitops/apps). Every file there is itself an Application. Apply the root once, and Git decides everything else.
- **ApplicationSet:** [gitops/apps/quickkart-appset.yaml](../gitops/apps/quickkart-appset.yaml) has **one template** and **a list** (`dev`, `prod`). It generates one Application per item, each pointing at [gitops/envs/dev](../gitops/envs/dev) or [gitops/envs/prod](../gitops/envs/prod).
- Our tree: `root` creates `sealed-secrets` and the `quickkart` ApplicationSet, which creates `quickkart-dev` and `quickkart-prod`.

### Lab

```bash
cat gitops/root-app.yaml
kubectl apply -f gitops/root-app.yaml
kubectl get applications -n argocd -w
```

- This is the **only** `kubectl apply` in the lab. Everything after it comes from Git.
- Watch 4 Applications appear: `root`, `sealed-secrets`, `quickkart-dev`, `quickkart-prod`. Press **Ctrl+C** when all are **Synced** and **Healthy**, about 2 to 3 minutes.

In the Argo CD UI, click **root**. Show the tree: root, then the sealed-secrets app and the ApplicationSet, then dev and prod.

```bash
kubectl get applicationset -n argocd
echo "dev:  http://$(kubectl get svc quickkart -n quickkart-dev  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')"
echo "prod: http://$(kubectl get svc quickkart -n quickkart-prod -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')"
```

Open both addresses. Blue page for dev, green for prod, same version.

### Interview Question

**App of Apps vs ApplicationSet: when do you use each?** App of Apps groups different applications under one parent, for example a whole platform bootstrapped with one apply. An ApplicationSet generates many similar Applications from one template, for example one per environment, cluster or folder. They are often used together, as here.

---

## 4.2 Sync Waves and Hooks (Topic 3)

### Context

Some things must exist before others. The controller before secrets, config before the app, and a test after the deploy.

### Concept

- **Sync waves:** the annotation `argocd.argoproj.io/sync-wave`. Lower waves go first, and Argo CD waits for each wave to be healthy before the next.
  - Wave -1: [sealed-secrets app](../gitops/apps/sealed-secrets.yaml)
  - Wave 0: [configmap.yaml](../gitops/envs/dev/configmap.yaml)
  - Wave 1: [deployment.yaml](../gitops/envs/dev/deployment.yaml), [service.yaml](../gitops/envs/dev/service.yaml)
- **Hooks:** Jobs that run at a fixed point of a sync. [smoke-test.yaml](../gitops/envs/dev/smoke-test.yaml) is a **PostSync** hook: after the deploy, it calls `/health`.

### Lab

```bash
grep -rn "sync-wave\|hook" gitops/
kubectl get jobs -n quickkart-dev
kubectl logs job/smoke-test -n quickkart-dev
```

- The log ends with **SMOKE TEST PASSED**.
- In the UI, open `quickkart-dev`, then **Last Sync**, to show the order of the resources.

### Interview Question

**How would you run a database migration before a new version starts?** As a PreSync hook Job, or in an earlier sync wave, so Argo CD runs it and waits for success before applying the new Deployment. If the Job fails, the sync stops and the old version keeps running.

---

## 4.3 Secrets and Sealed Secrets (Topics 4 and 5)

### Context

GitOps means everything is in Git. But a password in Git is a leak waiting to happen.

### Concept

- A Kubernetes Secret is only **base64**. That is encoding, not encryption. Anyone who can read the file can read the secret.
- **Sealed Secrets:** `kubeseal` encrypts the secret with the controller's **public** key. Only the controller in the cluster has the **private** key. The encrypted `SealedSecret` is safe in Git, and the controller turns it into a normal Secret.
- A SealedSecret is locked to its **name and namespace**. Copied to another namespace, it cannot be decrypted.

### Lab

First the problem:

```bash
kubectl create secret generic quickkart-secret -n quickkart-dev \
  --from-literal=SECRET_MESSAGE='Sealed by kubeseal, opened only inside the cluster' \
  --dry-run=client -o yaml > /tmp/plain-secret.yaml
cat /tmp/plain-secret.yaml
grep SECRET_MESSAGE /tmp/plain-secret.yaml | awk '{print $2}' | base64 -d; echo
```

- The last command reads the secret back in one line. This file must **never** go to Git.

Now the fix:

```bash
kubeseal --controller-name sealed-secrets-controller --controller-namespace kube-system \
  --format yaml < /tmp/plain-secret.yaml > gitops/envs/dev/sealed-secret.yaml
rm /tmp/plain-secret.yaml
cat gitops/envs/dev/sealed-secret.yaml
git add gitops/envs/dev/sealed-secret.yaml
git commit -m "Add sealed secret for dev"
git push
```

- The value is now a long encrypted string. Safe to commit.

Wait about a minute for Argo CD, or click **Refresh** on `quickkart-dev`, then:

```bash
kubectl get sealedsecret,secret -n quickkart-dev
kubectl rollout restart deployment quickkart -n quickkart-dev
```

- The controller created a normal Secret named `quickkart-secret`.
- Pods read environment variables only at start, so we restart them once. In production a tool like Reloader does this automatically.

Refresh the **dev** page. It now shows the secret message.

### Interview Question

**How do you manage secrets in GitOps?** Never store plain Secrets in Git. Either encrypt them for Git with Sealed Secrets or SOPS, or keep them in a secret manager such as AWS Secrets Manager or Vault and sync them in with the External Secrets Operator. Sealed Secrets is simple and self contained. External Secrets fits better when a central secret manager already exists.

---

## 4.4 OIDC and RBAC (Topic 6)

### Context

Many people use Argo CD. Not all of them should be able to deploy.

### Concept

- **Authentication, OIDC:** who you are. In companies Argo CD logs users in through an identity provider such as Keycloak, Okta or Entra ID, and reads their **groups** from the token. See diagram page **09**.
- **Authorization, RBAC:** what you may do. Policies in `argocd-rbac-cm` map users or groups to roles. Our default role is **readonly**, and `admin` keeps full rights.
- In this lab we show RBAC live with a local user, `dev1`. With OIDC, the same policy would use a group instead of a user.

### Lab

```bash
kubectl get configmap argocd-rbac-cm -n argocd -o yaml | grep -A2 "^data"
argocd account list
```

In a **private browser window**, open `http://$ARGOCD_HOST` and log in as **dev1** with password **Dev1-ReadOnly-2026**:

1. Open `quickkart-dev`. You can see everything.
2. Click **Sync**, then **Synchronize**. Argo CD answers **permission denied**.

### Interview Question

**How would you give developers sync on dev but read only on prod?** Connect Argo CD to the company identity provider with OIDC, then write RBAC policies per group and per AppProject, for example the developers group may sync applications in the dev project, and only the SRE group may sync prod.

---

## 4.5 Jenkins and Argo CD (Topic 7)

### Context

So far we changed Git by hand. In real life a pipeline builds every change and updates Git automatically.

### Concept

- [app/Jenkinsfile](../app/Jenkinsfile) has 4 stages: **Checkout, Build image, Push to ECR, Update GitOps**.
- The image tag is `commit-buildnumber`, so every build is unique and traceable.
- Jenkins pushes to ECR with the **EC2 IAM role**, so no Docker password. It changes **only one line** in Git: the image in [gitops/envs/dev/deployment.yaml](../gitops/envs/dev/deployment.yaml).
- **Jenkins has no kubeconfig.** Argo CD sees the commit and deploys.

### Lab

**Create a GitHub token for Jenkins** (browser):

1. GitHub, **Settings**, **Developer settings**, **Personal access tokens**, **Fine-grained tokens**, **Generate new token**.
2. Name `jenkins-argocd-lab`, expiry 7 days, **Only select repositories**: `argocd-jenkins-lab`.
3. **Repository permissions**, **Contents**: **Read and write**.
4. **Generate token** and copy it.

**Add it to Jenkins:**

1. **Manage Jenkins**, **Credentials**, **System**, **Global credentials**, **Add Credentials**.
2. Kind **Username with password**. Username `discover-devops`. Password: the token. ID **`github-token`**.
3. **Create**.

**Create the pipeline job:**

1. **New Item**, name `quickkart-pipeline`, type **Pipeline**, **OK**.
2. **Pipeline** section: Definition **Pipeline script from SCM**, SCM **Git**.
3. Repository URL `https://github.com/discover-devops/argocd-jenkins-lab.git`, Branch `*/main`.
4. Script Path **`app/Jenkinsfile`**, then **Save**.

**Run it:** click **Build Now** and open the build, then **Console Output**. Then check:

```bash
cd ~/argocd-jenkins-lab && git pull
git log --oneline -3
grep image: gitops/envs/dev/deployment.yaml
```

- The newest commit is **Deploy ... to dev**, made by Jenkins.
- Within about a minute Argo CD syncs `quickkart-dev`. Refresh the dev page: the **Version** shows the new tag. Prod is unchanged.

### Interview Question

**Why does Jenkins update Git instead of running kubectl?** So the CI system never holds cluster credentials, every deployment is a reviewable commit, the cluster state always matches Git, and rollback is a git revert. If Jenkins is compromised, the attacker can only make visible Git changes, not change the cluster directly.

---

## 4.6 End to End: change, build, promote, self heal (Topic 8)

### Context

Now the full story: a developer change reaches dev automatically, and prod by a deliberate Git change.

### Concept

- Dev is updated by the pipeline. **Prod is updated only when someone changes prod's file in Git**, usually by a pull request that a lead approves.
- **Self heal:** if anyone changes the cluster by hand, Argo CD puts it back to what Git says.
- **Rollback** is `git revert` of the deploy commit.

### Lab

**1. Change the code on GitHub:** open [app/app.py](../app/app.py) on GitHub, click the pencil icon, change `<h1>QuickKart</h1>` to `<h1>QuickKart v2</h1>`, and **Commit changes**.

**2. Build:** Jenkins, **Build Now**. Refresh the dev page: it shows **QuickKart v2** and a new version.

**3. Promote to prod:** on GitHub open `gitops/envs/dev/deployment.yaml` and copy the `image:` value. Then open `gitops/envs/prod/deployment.yaml`, click the pencil icon, paste the same image, and commit with the message `Promote to prod`. Within about a minute the prod page shows the same version.

**4. Self heal:**

```bash
kubectl scale deployment quickkart -n quickkart-prod --replicas=5
kubectl get pods -n quickkart-prod -w
```

- Argo CD sees 5 instead of 2 and scales back to 2. Press **Ctrl+C**.

### Interview Question

**How do you roll back a bad release in GitOps?** Revert the commit that changed the image tag. Argo CD syncs the previous tag back. Avoid rolling back in the Argo CD UI while auto sync is on, because Git still points at the bad version and Argo CD would sync it again.

---

**Lab complete.** Run [Part 5 - Cleanup](05-cleanup.md) today.

---

## Keep Learning With Me

- YouTube: https://www.youtube.com/@BuildAutomateArchitect
- System Design playlist: https://www.youtube.com/playlist?list=PLeAHTLMwFYQ0
- Telegram: https://t.me/BuildAutomateArchitect
- Website: https://rahulchaubeyconsulting.com/
