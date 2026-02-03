# Kubernetes CI RBAC Manager

This project provides an automated workflow for managing Kubernetes Service Accounts (SA) and Role-Based Access Control (RBAC) specifically tailored for CI/CD pipelines. It utilizes a template-based system to ensure consistent permission sets across different environments.

---

## Access Profiles

The system supports three distinct RBAC profiles to maintain the principle of least privilege:

* **`bot`**: Provides standard namespace-scoped permissions for managing common workloads like Pods, Deployments, and Services.
* **`helm`**: Includes additional permissions required for Helm operations, such as managing release Secrets and Ingress resources.
* **`admin`**: Grants `cluster-admin` privileges via a `ClusterRoleBinding` for full cluster automation.

---

##  Core Files

* **`Makefile`**: The primary automation engine. It handles manifest generation, deployment, and local context configuration.
* **`sa-*-tmpl.yaml`**: The source templates used to generate environment-specific YAML files.
* **`create-context_token.sh`**: A utility script that creates a new `kubectl` context using a Service Account token, allowing you to test permissions locally.

---

##  Usage Instructions

###  1. Prerequisites
Ensure you have `kubectl`, `make`, and `envsubst` (part of gettext) installed on your system.

###  2. Generate and Apply RBAC
You can generate the manifests and apply them to your cluster using the following commands:

```bash
# To generate and apply the default 'bot' profile
make gen
make apply

# To apply a specific profile like 'helm'
make RBAC_PROFILE=helm gen apply
```

### 3. Full Automation (Context Setup)
To perform the entire setup—generating RBAC, applying it, fetching the token, and creating a local test context—run:

Bash

make all RBAC_PROFILE=bot ENV=int
Note: This will create a context named int-bot in your kubeconfig.

## Security and Cleanup
The automation process generates sensitive local files to facilitate context creation:

token.txt: The decrypted Service Account token.

ca.crt: The cluster's root certificate.

Warning: These files contain sensitive credentials. Do not commit them to version control. Use the cleanup command once your context is configured:

Bash

make clean
## Verification
The create-context_token.sh script automatically verifies permissions upon context creation by running auth can-i checks. You can manually verify your access at any time:

Bash

kubectl --context <context-name> auth can-i list pods

