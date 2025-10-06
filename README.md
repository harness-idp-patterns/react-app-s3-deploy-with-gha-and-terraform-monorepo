# e2e-provisioning-react-monorepo (Reusable Template)

This template bundles everything an SE needs to demo and replicate an **end-to-end React app provisioning flow into a monorepo** using **Harness IDP**.

It includes:
- **IDP Workflow Form** (the developer-facing IDP form)
- **Harness Pipeline** (the orchestrator that does the real work)
- **Cookiecutter Template** (the React app + scaffolding logic)
- **Monorepo + GitHub Actions** (where code lands, PRs get checked, and infra/app deploys happen)

It’s designed so SEs can copy this folder, tweak a few config values (connectors, org/project IDs, repo names), and be ready to run within minutes.

---

## How the pieces fit

```
[Developer in IDP]
      │ chooses "Provision React App" + fills form
      ▼
[IDP Workflow Form]
      │ validates inputs (e.g., repo dropdown, naming)
      ▼
[Harness Pipeline]
      │ 1) checks GH permissions for requester
      │ 2) scaffolds via Cookiecutter
      │ 3) opens PR in the monorepo
      │ 4) (optional) creates Jira/SNOW, waits on approval
      │ 5) updates PR status checks / merges when ready
      ▼
[Monorepo (GitHub)]
      │ GH Actions run checks/build/plan/apply as applicable
      │ App/infra created; PR merged to default branch
      ▼
[Outputs]
- New app folder in monorepo
- Links back to PR, pipeline run, and any tickets
```

---

## What’s included in this folder

```
/reusable-templates/e2e-provisioning-react-monorepo/
├─ workflow/                # IDP Workflow (form) YAML
│  └─ e2e-provisioning-react-monorepo-workflowform.yml
├─ pipeline/                # Harness pipeline YAML
│  └─ e2e-provisioning-react-monorepo-pipeline.yml
├─ cookiecutter/            # Minimal React template (safe defaults)
│  ├─ cookiecutter.json
│  └─ {{cookiecutter.project_slug}}/... (src, README, etc.)
├─ monorepo-examples/       # Example GHA + CODEOWNERS you can copy over
│  ├─ .github/workflows/
│  │  ├─ pr-checks.yml
│  │  └─ infra.yml
│  └─ CODEOWNERS
└─ README.md                # (this file)
```

---

## Typical end-to-end flow

1. **Developer** clicks **Provision** in IDP, fills the form (app name, GH username/org/repo, env/region, optional Jira/SNOW).
2. **Workflow → Pipeline** kicks off:
   - Validates the user has write access to the monorepo.
   - Pulls Cookiecutter, renders a new app folder (e.g., `/apps/<slug>/`).
   - Creates a feature branch and commits the scaffold.
   - Opens a PR with clear title/body and links back to the pipeline/workflow.
   - (Optional) Creates Jira/SNOW and **sets a PR status check** that blocks merge until approved.
3. **GitHub Actions** run on the PR:
   - Lint/tests/build; optionally terraform/atlantis plan.
4. **Approvals & Merge**:
   - When approvals are met (PR + SNOW), the pipeline flips the PR check, and (optionally) merges.
5. **Post-merge**:
   - GH Actions deploy (e.g., static site to S3/CloudFront), or infra applies.
   - Workflow exposes links: Pipeline run, PR, tickets, and (if available) app URL.

---

## Quick start for SEs (copy → tweak → run)

1. **Copy this folder** into your shareable repo under `harness_instances/<account_name>`.
2. **Edit** the 4 files called out above with your org/project/connector/repo names.
3. **Copy** the example GH workflows + CODEOWNERS into the *target monorepo* (or ensure equivalents already exist).
4. **Import** the pipeline & workflow into Harness (or `harness-manager` API) and publish the workflow in IDP.
5. **Test** by provisioning a sample app; verify the PR checks, approvals, and merge behavior.

---

## Variables checklist (find & replace)

- `orgIdentifier`, `projectIdentifier`
- `connectorRef` values: GitHub, Jira, ServiceNow
- GitHub:
  - `OWNER` (org), `REPO` (monorepo), `DEFAULT_BRANCH`
- Paths:
  - Where to place new app (`/` vs `/apps/<slug>/`)
- Cookiecutter:
  - `project_name`, `project_slug`, `github_org`, `github_team`

