# GitHub OIDC Role Module (Terraform)

This module provisions an **IAM Role and optional OIDC Provider** for use with GitHub Actions.
It allows workflows in specified organizations, repositories, and branches (or tags, PRs, environments)
to assume an AWS role using the OIDC federation trust.

---

## 📦 Module Overview

| Capability | Description |
|-------------|--------------|
| **IAM Role** | Role trusted by GitHub’s OIDC provider (token.actions.githubusercontent.com) |
| **OIDC Provider** | Can create or reuse an existing provider |
| **Scoped Trust** | Restricts allowed subjects to specific orgs, repos, branches, tags, or environments |
| **Backend Policy (optional)** | Attaches path-scoped S3+DynamoDB access for Terraform remote state |
| **Least Privilege Ready** | Accepts JSON from `iac-state` module to restrict state access |

---

## 🧩 Inputs

| Variable | Description | Default |
|-----------|--------------|----------|
| `region` | AWS region for IAM operations | `us-east-1` |
| `github_org` | GitHub organization name | **(required)** |
| `github_repo` | Repository name (optional, empty = all repos in org) | `""` |
| `allowed_subjects` | List of allowed refs or subjects (branches, tags, pull_request, environment:dev) | `["refs/heads/main"]` |
| `role_name` | Name of the IAM Role | `gha-oidc-role` |
| `session_duration_seconds` | Max STS session duration | `3600` |
| `create_oidc_provider` | Whether to create the OIDC provider | `false` |
| `existing_oidc_provider_arn` | ARN of an existing OIDC provider | `""` |
| `oidc_thumbprint_list` | List of provider thumbprints | `[6938fd4d98ba…]` |
| `attach_backend_access` | Attach backend access policy to role | `false` |
| `backend_access_policy_json` | JSON policy (preferred, from iac-state output) | `""` |
| `tfstate_bucket_arn` | Fallback: S3 bucket ARN for Terraform state | `""` |
| `lock_table_arn` | Fallback: DynamoDB table ARN for locks | `""` |
| `tags` | Map of resource tags | `{}` |

---

## 🚀 Usage

```hcl
module "oidc" {
  source = "./infra/bootstrap/modules/oidc"

  github_org  = "harness-idp-sandbox"
  github_repo = "customer-monorepo"

  allowed_subjects = [
    "refs/heads/main",
    "pull_request",
    "environment:dev"
  ]

  existing_oidc_provider_arn = "arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com"
  attach_backend_access      = true
  backend_access_policy_json = module.iac_state.backend_access_policy_json
}
```

---

## 🛠️ apply.sh

The helper script automates Terraform apply:

```bash
export GITHUB_ORG=harness-idp-sandbox
export GITHUB_REPO=monorepo-idp-example
export ALLOWED_SUBJECTS="refs/heads/main,pull_request"
export ROLE_NAME=gha-oidc-role
export ATTACH_BACKEND_ACCESS=true
export BACKEND_POLICY_JSON="$(terraform -chdir=../iac-state output -raw backend_access_policy_json)"

./apply.sh
```

After creation, the script writes **oidc.env**:

```bash
AWS_GHA_ROLE_ARN=arn:aws:iam::123456789012:role/gha-oidc-role
AWS_REGION=us-east-1
```

Add these as **GitHub Secrets** for your CI/CD workflow.

---

## 🧹 destroy.sh

Safely destroys the OIDC resources with confirmation:

```bash
./destroy.sh
# or bypass prompt
./destroy.sh --yes
```

---

## 🔒 Example Trust Policy

Example generated trust condition for an org/repo with multiple refs:

```json
{
  "Effect": "Allow",
  "Action": "sts:AssumeRoleWithWebIdentity",
  "Principal": { "Federated": "arn:aws:iam::<acct>:oidc-provider/token.actions.githubusercontent.com" },
  "Condition": {
    "StringEquals": { "token.actions.githubusercontent.com:aud": "sts.amazonaws.com" },
    "StringLike": {
      "token.actions.githubusercontent.com:sub": [
        "repo:harness-idp-sandbox/monorepo-idp-example:ref:refs/heads/main",
        "repo:harness-idp-sandbox/monorepo-idp-example:pull_request",
        "repo:harness-idp-sandbox/monorepo-idp-example:environment:dev"
      ]
    }
  }
}
```

---

## 🧩 Outputs

| Output | Description |
|---------|-------------|
| `role_arn` | ARN of the IAM Role for GitHub Actions |
| `oidc_provider_arn` | ARN of the created or existing OIDC provider |

---

## 🧱 Integration with `iac-state`

Pass the JSON output from your Terraform state backend module:

```hcl
backend_access_policy_json = module.iac_state.backend_access_policy_json
```

This ensures your OIDC role has **least privilege access** to the correct S3 prefix and DynamoDB table for state locking.

---

## 🧠 Notes for Sales Engineers

- SEs should **never modify IAM trust logic manually**—use the input variables or environment overrides in `apply.sh`.
- Always test with a **sandbox AWS account** first.
- Set `CREATE_OIDC_PROVIDER=true` only if the account has no provider yet.
- Use the `.env` file to populate repo/org secrets automatically in Harness IDP pipelines.
