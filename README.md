# React App → S3 (GHA + Terraform, Monorepo) — Golden Path (Harness IDP Pattern)

This repository is a **pre-packaged, reusable solution** that provisions a React static site into a **monorepo**, deploys to **S3/CloudFront** via **GitHub Actions**, and wires up **Harness IDP** workflow + pipeline orchestration.

## What’s in this repo

```
/
├─ idp-admin/
│  ├─ idp-pipelines/pipeline.yml     # Parameterized Harness pipeline (orchestrator)
│  └─ idp-forms/workflow.yml         # IDP workflow form (developer-facing)
├─ idp-repos/
│  ├─ react-app-s3-deploy-cookiecutter/   # Cookiecutter template (app + terraform + catalog)
│  └─ idp-monorepo-example/                # Example monorepo skeleton (GHA, CODEOWNERS, bootstrap)
├─ scripts/
│  └─ copy-to-customer-repo.sh       # Copy helper
└─ README.md
```

### Components

- **IDP Workflow Form** – the developer UI to request a new app.
- **Harness Pipeline** – orchestrates checks, scaffolding, PR, gates, and catalog registration (optional).
- **Cookiecutter Template** – React app + Terraform infra + catalog-info.yaml.
- **Monorepo Example** – GitHub Actions + CODEOWNERS you can copy into a real monorepo.

## How the pieces fit

```
[Developer in IDP] → fills form
  → [IDP Workflow] → triggers
    → [Harness Pipeline] → cookiecutter scaffold → branch → PR → (Jira/SNOW gates) → merge
      → [GitHub Actions in Monorepo] → build + deploy to S3/CloudFront
        → [IDP Catalog (optional)] register component after merge
```

## Quick start for SEs

1) **Copy** this pattern into the customer admin repo: `./scripts/copy-to-customer-repo.sh ../<customer>-admin-repo`  
2) **Replace placeholders** in:
   - `idp-admin/idp-pipelines/pipeline.yml`  
   - `idp-admin/idp-forms/workflow.yml`
3) **Import** the pipeline in Harness; publish the workflow in IDP.
4) **Run** the workflow and verify PR, checks, and (optional) catalog registration.

## Notes
- The cookiecutter’s `catalog-info.yaml` expects a **full connector ref** (e.g., `account.harnessgithub`), and the pipeline provides it via `connector_ref`.
- The monorepo example includes `deploy-site.yml` which expects a `project_path` (subfolder) and handles OIDC auth to AWS.
