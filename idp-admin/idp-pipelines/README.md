# E2E React App Provisioning — **Parameterized Pipeline** (Reusable Template)

Provision a React app into a **monorepo**, open a PR, optionally gate with **Jira** and **ServiceNow**, and (optionally) **register the component** in Harness IDP — using a **parameterized pipeline** you can drop into any customer project.

> This README accompanies: `pipeline.yml`  
> Copy to a customer’s admin repo, replace the `__ALL_CAPS__` placeholders, and import into Harness.

---

## What’s in this folder

```
/idp-admin/idp-pipelines/
├─ pipeline.yml  # Parameterized pipeline
└─ README.md     # (this file)
```

---

## When to use this template

- You want a single pipeline that works across customers by replacing **only connector IDs, namespaces, and secrets**.
- You want to keep **runtime inputs** (project/app specifics) as **pipeline variables**, not hard-coded.
- You need optional **Jira** and **ServiceNow** gates and (optionally) **IDP catalog registration** after merge.

---

## Quick start (copy → replace → import → run)

1. **Copy** `pipeline.yml` into the customer admin repo at:

   ```text
   https://github.com/harness-idp-sandbox/<customer_name>-admin-repo/idp-pipelines/e2e-react-app-provisioning-pipeline.yml
   ```

2. **Replace ALL placeholders** (search for `__`):  
   `__PIPELINE_NAME__`, `__PIPELINE_IDENTIFIER__`, `__PROJECT_ID__`, `__ORG_ID__`,  
   `__JIRA_CONNECTOR__`, `__JIRA_PROJECT_KEY__`, `__K8S_CONNECTOR__`, `__DELEGATE_NAMESPACE__`,  
   `__DELEGATE_SELECTOR__`, `__REGISTRY_REF__`, `__RUNNER_IMAGE__`, `__REGISTRY_CONNECTOR_FOR_IMAGES__`,  
   `__GIT_CONNECTOR__`, `__SERVICENOW_CONNECTOR__`, `__COOKIECUTTER_TEMPLATE_URL__`,  
   `__GITHUB_ORG__`, `__MONOREPO_NAME__`, `__GH_TOKEN_SECRET__`, `__HARNESS_PLATFORM_API_KEY_SECRET__`,  
   `__CATALOG_GITHUB_CONNECTOR__` (default for Entities Import).

3. **Import** the YAML as a new pipeline in the customer’s Harness project.

4. **Run** it from IDP or straight from Pipelines with the required inputs (see **Variables** below).

---

## End‑to‑end flow

1. (Optional) **Jira** Story — if `enable_jira=true`.
2. **Derive Vars** — compute feature branch, app folder, URLs; export for downstream steps.
3. **Access Gate** — validate the requester’s GitHub permissions (fail if `enforce_requestor_access=yes` and they lack write).
4. **Clone & Branch** — clone monorepo, create feature branch, push.
5. **Cookiecutter** — scaffold the new app (folder `/<project_slug>/`) into the monorepo.
6. **Direct Push** — push rendered files to feature branch (skipped when `testing=yes`).
7. **Open PR** — create or reuse a PR; add labels and an IDP context block.
8. (Optional) **ServiceNow** — create change, set a **pending** PR status check, wait for approval, then update the check.
9. (Optional) **Register Component** — after merge, import `<project_slug>/catalog-info.yaml` into IDP Catalog.

---

## Placeholders (must replace)

| Placeholder | What it is | Example |
|---|---|---|
| `__PIPELINE_NAME__` / `__PIPELINE_IDENTIFIER__` | Display name & unique ID | `E2E React App Provisioning` / `E2E_React_App_Provisioning` |
| `__PROJECT_ID__` / `__ORG_ID__` | Harness project/org IDs | `parson` / `sandbox` |
| `__JIRA_CONNECTOR__` / `__JIRA_PROJECT_KEY__` | Jira connector & project | `account.Harness_JIRA` / `HD` |
| `__K8S_CONNECTOR__` / `__DELEGATE_NAMESPACE__` | Delegate’s K8s connector / namespace | `parsoneks` / `harness-delegate-ng` |
| `__DELEGATE_SELECTOR__` | Delegate selector label | `parson-eks-delegate` |
| `__REGISTRY_REF__` / `__RUNNER_IMAGE__` | Registry ref & runner image | `parson` / `parsontodd/harness-custom-runner:latest` |
| `__REGISTRY_CONNECTOR_FOR_IMAGES__` | Registry connector used by Container steps | `parsondocker` |
| `__GIT_CONNECTOR__` | GitHub connector (clone/push) | `parsonghharnessidpsandbox` |
| `__SERVICENOW_CONNECTOR__` | ServiceNow connector | `account.ServiceNow_Dev` |
| `__COOKIECUTTER_TEMPLATE_URL__` | Cookiecutter template repo URL | `https://github.com/harness-idp-sandbox/app-template-react-monorepo.git` |
| `__GITHUB_ORG__` / `__MONOREPO_NAME__` | Target GitHub org / monorepo | `harness-idp-sandbox` / `monorepo-idp-example` |
| `__GH_TOKEN_SECRET__` | Secret name for GitHub token | `parson-gh-pat` |
| `__HARNESS_PLATFORM_API_KEY_SECRET__` | Secret name for Platform API key | `parson-api` |
| `__CATALOG_GITHUB_CONNECTOR__` | Default connector for Entities Import | `account.harnessgithub` |

> Tip: run a find/replace for `__` to ensure you didn’t miss any.

---

## Variables (runtime inputs)

| Name | Type | Default | Purpose |
|---|---|---|---|
| `project_name` | String | (input) | Human app name |
| `project_slug` | String | `project_name` lowercased, spaces→`-` | Folder name in monorepo |
| `project_owner` | String | `owner@example.com` | Owner email used in template |
| `project_description` | String | `Testing for POC` | App description |
| `gh_org` | String | `__GITHUB_ORG__` | GitHub org |
| `default_branch` | String | `main` | Monorepo default branch |
| `base_repo` | String | `__MONOREPO_NAME__` | Monorepo name |
| `new_branch_prefix` | String | `feature` | Feature branch prefix |
| `environment_name` | String | `dev` | Template input |
| `aws_region` | String | `us-east-1` | Template input |
| `enable_jira` | Enum(String) | `false` | Create Jira Story |
| `github_username` | String | "" | Requester GH username (access/assignment) |
| `testing` | Enum(String) | `no` | Skip DirectPush when `yes` |
| `enforce_requestor_access` | Enum(String) | `yes` | Fail if requester lacks write |
| `gh_token` | Secret | `__GH_TOKEN_SECRET__` | GitHub token (scopes: `repo` [+ `workflow` if GHA needs it]) |
| `github_team` | String | `platform-team` | Team for template metadata |
| `connector_ref` | String | `__CATALOG_GITHUB_CONNECTOR__` | Catalog connector for Entities Import |
| `register_component` | Enum(String) | `false` | Import component into IDP after merge |
| `platform_api_key` | Secret | `__HARNESS_PLATFORM_API_KEY_SECRET__` | Harness Platform API key for Entities Import |

---

## Connectors & secrets you’ll need

- **Kubernetes**: `__K8S_CONNECTOR__` (delegate’s K8s connector)  
- **GitHub**: `__GIT_CONNECTOR__` for clone/push; PAT secret referenced by `gh_token`  
- **Jira** (optional): `__JIRA_CONNECTOR__`  
- **ServiceNow** (optional): `__SERVICENOW_CONNECTOR__`  
- **Container registry**: `__REGISTRY_REF__` / `__REGISTRY_CONNECTOR_FOR_IMAGES__` for runner images  
- **Harness Platform API key**: secret `__HARNESS_PLATFORM_API_KEY_SECRET__` (used by Entities Import)

> **Security**: The pipeline never prints secrets. Ensure PAT scopes are minimal (usually `repo`).

---

## Conventions

- **App path**: `/<project_slug>/` (cookiecutter output)
- **Catalog file**: `<project_slug>/catalog-info.yaml`
- **Status check**: `servicenow/change-approval` is used to gate merges (if SNOW enabled).
- **Labels**: `idp`, `scaffold`, `automation`, plus `change:*` labels managed by the pipeline.

---

## Failure modes (exit codes)

- **20** — Requester lacks write access (when `enforce_requestor_access=yes`)  
- **21** — Timeout while waiting for PR merge  
- **22** — Timeout waiting for `catalog-info.yaml` to appear on the target branch  
- **23** — PR closed without merge

---

## Troubleshooting

- **“Missing GITHUB_TOKEN”** — Ensure the `gh_token` secret is set and mapped to a PAT with `repo` scope.  
- **PR status check never flips** — Confirm ServiceNow approval reached *Implement* and the pipeline’s Update PR step ran.  
- **Cookiecutter render errors** — Sanitize `project_slug` (lowercase, no spaces) or tighten filters in template.  
- **Requester blocked** — Either add the user to a team with write on the monorepo or set `enforce_requestor_access=no` (warn-only).

---

## Example values (copy/paste)

```yaml
# Top-level identifiers
__PIPELINE_NAME__: "E2E React App Provisioning"
__PIPELINE_IDENTIFIER__: "E2E_React_App_Provisioning"
__PROJECT_ID__: "parson"
__ORG_ID__: "sandbox"

# Connectors & infra
__K8S_CONNECTOR__: "parsoneks"
__DELEGATE_NAMESPACE__: "harness-delegate-ng"
__DELEGATE_SELECTOR__: "parson-eks-delegate"
__REGISTRY_REF__: "parson"
__REGISTRY_CONNECTOR_FOR_IMAGES__: "parsondocker"
__RUNNER_IMAGE__: "parsontodd/harness-custom-runner:latest"
__GIT_CONNECTOR__: "parsonghharnessidpsandbox"

# Integrations
__JIRA_CONNECTOR__: "account.Harness_JIRA"
__JIRA_PROJECT_KEY__: "HD"
__SERVICENOW_CONNECTOR__: "account.ServiceNow_Dev"

# GitHub
__GITHUB_ORG__: "harness-idp-sandbox"
__MONOREPO_NAME__: "monorepo-idp-example"
__COOKIECUTTER_TEMPLATE_URL__: "https://github.com/harness-idp-sandbox/app-template-react-monorepo.git"

# Secrets
__GH_TOKEN_SECRET__: "parson-gh-pat"
__HARNESS_PLATFORM_API_KEY_SECRET__: "parson-api"
__CATALOG_GITHUB_CONNECTOR__: "account.harnessgithub"
```

---

## Run checklist

- [ ] All `__PLACEHOLDERS__` replaced  
- [ ] Connectors exist in the target Org/Project  
- [ ] Secrets created and mapped to variable names in the pipeline  
- [ ] Branch protection requires `servicenow/change-approval` (if SNOW enabled) and CI checks  
- [ ] Cookiecutter template repo is reachable by the delegate

---

Happy provisioning! 🚀
