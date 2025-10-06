# E2E React App Provisioning (Reference Workflow Form)

This YAML defines a **Harness IDP Workflow Form (idp-forms)** for provisioning a React app into a monorepo.  
It presents a guided UI for developers, validates inputs (e.g., GitHub username, repo access), and triggers the **E2E React App Provisioning** pipeline.

> Treat this as a **reference template**. Copy into the customer admin repo and adjust placeholders, defaults, and the pipeline URL as needed.

---

## Purpose

- Provide a **self‑service form** for developers to request new apps.  
- Capture inputs: app name, owner, description, repo, branch prefix, environment, region.  
- Validate **GitHub permissions** to ensure the requester can commit/PR.  
- Optionally toggle **Jira** ticket creation and **IDP registration**.  
- Trigger the corresponding Harness pipeline with the collected parameters and render output links.

---

## Replace these placeholders before importing

| Placeholder | Meaning | Example |
|---|---|---|
| `__ACCOUNT_ID__` | Harness Account ID | `abcd1234` |
| `__ORG_ID__` | Harness Org Identifier | `sandbox` |
| `__PROJECT_ID__` | Harness Project Identifier | `parson` |

If you rename the pipeline or change its identifier, update the **`steps.trigger.input.url`** to point at your pipeline.

Pipeline URL pattern:
```
https://app.harness.io/ng/#/account/__ACCOUNT_ID__/orgs/__ORG_ID__/projects/__PROJECT_ID__/pipelines/E2E_React_App_Provisioning/executions
```

---

## Prerequisites

1. The **pipeline** exists in the target Org/Project (identifier or name should match your URL).  
2. **GitHub proxy** configured in IDP (route named `github-api`) to call GitHub REST for repo listing and permission checks.  
3. (Optional) **Jira**/**ServiceNow** connectors configured in Harness if those pipeline stages are enabled.  
4. The requester has at least **read** access to the monorepo (to appear in the repo picker) and ideally **write** (enforced by pipeline if configured).

---

## Sections & Parameters

### 1) Application Details
- **project_name** — Human-readable app name (3–50 chars, alphanumeric + space/dash/underscore).  
- **project_owner** — Owner email (used in metadata).  
- **project_description** — Short description (default: `Testing for POC`).  
- **token** — Harness API token (masked `HarnessAuthToken` widget), passed to the trigger as `apikey`.

### 2) Repository & Branching
- **github_username** — GitHub username (validated for repo access).  
- **repoPicker** — Dropdown of user-accessible repos via `proxy/github-api/user/repos?...`.  
  - Sets context: `repo_owner`, `repo_name`, `repo_full_name`, `default_branch`, `visibility`  
- **repo_owner**, **repository**, **default_branch**, **visibility** — readonly, populated from picker.  
- **new_branch_prefix** — prefix for feature branches (default: `feature`, validated).

### 3) Permissions Check
- **validate_permissions** — Button to fetch/validate the user’s permission:  
  `proxy/github-api/repos/{{parameters.repo_owner}}/{{parameters.repository}}/collaborators/{{parameters.github_username}}/permission`  
  - Writes to context: `gh_permission`, `gh_error`  
- **resolved_permission** — Shows detected permission level (read/write/admin).  
- **permission_hint** — Helper text for expectations.

### 4) Environment & Region
- **environment_name** — enum: `dev`, `qa`, `prod` (default: `dev`).  
- **aws_region** — enum: `us-east-1`, `us-east-2`, `us-west-1`, `us-west-2` (default: `us-east-1`).

### 5) Options
- **enable_jira** — create a Jira Story toggle.  
- **register_component** — automatically register in IDP Catalog toggle.

---

## Trigger mapping (how inputs map to the pipeline)

```yaml
inputset:
  project_name:        ${{ parameters.project_name }}
  project_owner:       ${{ parameters.project_owner }}
  project_description: ${{ parameters.project_description }}
  gh_org:              ${{ parameters.repo_owner }}        # from repo picker
  default_branch:      ${{ parameters.default_branch }}    # from repo picker
  base_repo:           ${{ parameters.repository }}        # from repo picker
  new_branch_prefix:   ${{ parameters.new_branch_prefix }}
  environment_name:    ${{ parameters.environment_name }}
  aws_region:          ${{ parameters.aws_region }}
  enable_jira:         ${{ parameters.enable_jira and "true" or "false" }}
  register_component:  ${{ parameters.register_component and "true" or "false" }}
  github_username:     ${{ parameters.github_username }}
```

**API key**: The `token` field is passed as `apikey` to `trigger:harness-custom-pipeline`.

---

## Output Links

The workflow surfaces these links using pipeline outputs:
- **Pipeline Details** → `${{ steps.trigger.output.PipelineUrl }}`  
- **New Branch URL** → `${{ steps.trigger.output['pipeline.stages.App_Provisioner.spec.execution.steps.Create_Branch.output.outputVariables.BRANCH_URL'] }}`  
- **PR URL** → `${{ steps.trigger.output['pipeline.stages.App_Provisioner.spec.execution.steps.Open_PR.output.outputVariables.PR_URL'] }}`

> Keep `showOutputVariables: true` and ensure the pipeline exports the same variable paths.

---

## Security notes

- The `token` uses `HarnessAuthToken` field (masked, not stored in source).  
- GitHub calls use the IDP **proxy**; scope tokens minimally.  
- The pipeline uses a Harness **secret** for `gh_token`; do not echo secrets in steps.

---

## Troubleshooting

- **Repo list empty** → GitHub proxy route misconfigured or token lacks scopes.  
- **Permission check 404/Not Found** → Username/repo mismatch or token cannot read collaborators.  
- **Trigger 404** → Pipeline URL (account/org/project/identifier) mismatch.  
- **Links blank** → Pipeline variable paths changed or `showOutputVariables` missing.

---

## Example usage

1. Publish `idp-forms/workflow.yml` into IDP (after replacing placeholders).  
2. Open the portal → **Provision** → fill application details.  
3. Pick a repo and (optionally) **Check my access**.  
4. Choose environment/region and toggles.  
5. Submit → pipeline runs → links appear on completion.

---

Happy provisioning from the IDP UI! 🚀
