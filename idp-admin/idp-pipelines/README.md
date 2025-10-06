# E2E React App Provisioning (Reference Pipeline)

Provision a React app into a **monorepo** scaffolded from `app-template-react-monorepo`, open a PR, optionally gate with **Jira** and **ServiceNow**, and (optionally) **register the component** in Harness IDP.

> Treat this as a **reference template**. Copy into your project and adjust connector refs, namespaces, and secrets as needed.

---

## Flow
1. (Optional) **Jira**: create tracking Story (toggle with `enable_jira`).
2. **Derive Vars**: compute branch/app paths and export for downstream steps.
3. **Access Gate**: ensure requester can commit or create a PR.
4. **Clone & Branch**: create feature branch on the monorepo.
5. **Cookiecutter**: scaffold the new app (folder `{{ project_slug }}`) into the monorepo.
6. **Direct Push**: push to the feature branch (skipped if `testing=yes`).
7. **Open PR**: create or update a PR with labels and context.
8. (Optional) **ServiceNow**: create change, wait for approval, update PR status.
9. (Optional) **Register Component**: import `{{ project_slug }}/catalog-info.yaml` into IDP (`register_component=true`).

---

## Prerequisites

### Connectors
- **Kubernetes**: e.g. `parsoneks` (delegate connector)
- **GitHub**: e.g. `parsonghharnessidpsandbox` for clone/push
- **Jira**: e.g. `account.Harness_JIRA` (if `enable_jira=true`)
- **ServiceNow**: e.g. `account.ServiceNow_Dev` (if using SNOW stage)

### Secrets
- **GitHub PAT**: referenced as `gh_token` (scopes: `repo`, and if needed `workflow`)
- **Harness API Key**: secret used in `Register Component` step, e.g. `parson-api`

> **Security**: Avoid echoing secrets; this pipeline prints only non-sensitive values.

---

## Monorepo & File Conventions

- **Repo**: `<+pipeline.variables.base_repo>` (e.g., `monorepo-idp-example`)
- **Branch**: `<+pipeline.variables.default_branch>` (default: `main`)
- **App path** (cookiecutter output): `/<project_slug>/`
- **Catalog file**: `<project_slug>/catalog-info.yaml`
- **TechDocs** in app catalog: `backstage.io/techdocs-ref: dir:.` (relative to the app folder)

---

## Variables

| Name | Type | Default | Purpose |
|---|---|---|---|
| project_name | String | (input) | Human app name |
| project_slug | String | `project_name` lowercased, spaces→`-` | Folder name in monorepo |
| project_owner | String | `todd.parson@harness.io` | Owner email used in template |
| project_description | String | `Testing for POC` | App description |
| gh_org | String | `harness-idp-sandbox` | GitHub org |
| default_branch | String | `main` | Monorepo default branch |
| base_repo | String | `monorepo-idp-example` | Monorepo name |
| new_branch_prefix | String | `feature` | Feature branch prefix |
| environment_name | String | `dev` | Used by template |
| aws_region | String | `us-east-1` | Used by template |
| enable_jira | String (enum) | `false` | Create Jira Story step |
| github_username | String | "" | Requester GH username (access/assignment) |
| testing | String (enum) | `no` | Skip DirectPush when `yes` |
| enforce_requestor_access | String (enum) | `yes` | Fail if requester lacks write |
| gh_token | Secret | `parson-gh-pat` | GitHub token |
| github_team | String | `platform-team` | Team for template metadata |
| connector_ref | String | `IDP_GitHub_Sandbox_for_Testing` | Template connector ref |
| register_component | String (enum) | `false` | Import component into IDP after merge |

---

## Connector Refs in YAML (replace as needed)

- `parsoneks` → your Kubernetes connector
- `parson` / `parsondocker` → your container registry refs
- `parsonghharnessidpsandbox` → your GitHub connector for clone/push
- `account.Harness_JIRA` and `account.ServiceNow_Dev` as appropriate

---

## Run Instructions

1. Create a new pipeline in Harness and import `*-pipeline.yml` from this folder.
2. Ensure the connectors and secrets exist, or update the YAML to your refs.
3. Provide inputs:
   - **Required**: `project_name` (derives `project_slug`), `gh_org`, `base_repo`.
   - **Optional**: toggles like `enable_jira`, `register_component`, `testing`.
4. Execute. The pipeline will open a PR and (optionally) register the IDP component after merge.

---

## Failure Modes (Exit Codes)

- **20**: Requester lacks write access (when `enforce_requestor_access=yes`)
- **21**: Timeout while waiting for PR merge
- **22**: Timeout waiting for `catalog-info.yaml` to appear on branch
- **23**: PR closed without merge

---

## Notes

- The `CookieCutter` step points to: `https://github.com/harness-idp-sandbox/app-template-react-monorepo.git`.
- The `Register Component` step uses Harness Entities Import API with `file_path = <project_slug>/catalog-info.yaml`.