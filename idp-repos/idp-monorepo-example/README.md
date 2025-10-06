# Monorepo Example

This repository hosts multiple applications and shared libraries, provisioned and managed through **Harness IDP**.  
It is intended to demonstrate how a customer’s monorepo might be structured when new applications are scaffolded automatically via IDP pipelines.

---

## 🚨 Bootstrap Guidance (for SEs only)

> **Note:** The bootstrap setup of this monorepo is handled by **Solutions Engineers (SEs)** during POV initialization.  
> Customers typically will not perform bootstrap steps themselves.

Bootstrap includes:
- Creating this repo (e.g., `monorepo-idp-example`) under the customer’s GitHub org.  
- Adding `.harness/` and `.github/` defaults (pipeline configs, PR templates, CODEOWNERS).  
- Connecting the repo to Harness (via GitHub connector).  
- Seeding example apps or shared code if needed.  

Once the bootstrap is complete, **all new apps/services are added through the IDP Provisioning pipeline**—not by manually copying files.

---

## Repository Layout

```
/
├─ <app-1>/                 # Individual app or service
├─ <app-2>/
├─ .github/                 # PR templates, workflows, CODEOWNERS
├─ .harness/                # Harness pipelines (optional)
└─ README.md                # You are here
```

Each folder (`<app-1>`, `<app-2>`, etc.) is generated via Harness IDP using a **Cookiecutter template**.  
See the app-level `README.md` for local dev, CI/CD, and environment details.

---

## Creating a New App

1. Open the Harness IDP action **“E2E React App Provisioning”**.  
2. Fill in:
   - **Base repo**: this repo’s name (e.g. `monorepo-idp-example`)  
   - **Base branch**: usually `main`  
   - **Project details**: name, slug, owner, description, team  
3. The pipeline will:
   - Create a feature branch (`feature/<project-slug>-<sequenceId>`)  
   - Scaffold a new folder (`/<project-slug>`) with code, docs, catalog-info  
   - Commit changes and open a Pull Request  
   - (Optional) Create a Jira Story and/or ServiceNow Change  
   - (Optional) Auto-register the new component in the IDP Catalog after PR merge  

---

## Local Development (per app)

For each app (e.g., `my-app`):

```bash
cd my-app
npm install
npm run dev   # open http://localhost:5173
```

> Each app folder has its own `README.md` with details like environment variables, URLs, and CI/CD specifics.

---

## Conventions

- **Branching:** `feature/<project-slug>-<run-number>`  
- **PR Title:** `feat(idp:<run-number>): scaffold <project-slug>`  
- **App folder names:** always **kebab-case** (e.g., `my-new-app`)  
- **Docs:** Each app has `docs/` folder for TechDocs. Use ADRs for key design decisions.  
- **Ownership:** Defined in each app’s `catalog-info.yaml` and CODEOWNERS.

---

## CI/CD (high-level)

- **Scaffolding pipeline:** IDP pipeline handles branch creation, scaffolding, PR, and optional Catalog registration.  
- **Per-app pipelines:** Configured in `.harness/` or `.github/workflows/` depending on org standards.  
- **Main branch merges:** Trigger build/deploy workflows for each app.  
- **Change management:** Jira/ServiceNow approvals may gate production deploys.


---

## 🧩 GitHub Actions Workflows and Automated Triggers

The **GitHub Actions workflows** in this monorepo provide continuous integration, infrastructure automation, and optional IDP catalog registration for each app created via the **IDP Provisioning pipeline**.

### Overview

When a new app folder is scaffolded and pushed to a feature branch:
- The workflows automatically detect the new folder via **path filters** (no manual setup required).  
- Each workflow runs only for the relevant app’s files (isolated CI).  
- Once the PR is merged, the same workflows handle production apply and registration.

### Workflow Breakdown

| Workflow File | Trigger | Purpose |
|----------------|----------|----------|
| **`.github/workflows/react-ci.yml`** | `pull_request` touching `*/site/**` | Builds, lints, and tests the React app. Runs on all PRs that change files within the app’s `site/` folder. |
| **`.github/workflows/terraform.yml`** | `pull_request` and `push` to `main` touching `*/infra/**` | Validates and plans Terraform on PRs. Applies infrastructure automatically after merge. Uses OIDC to assume cloud IAM roles. |
| **`.github/workflows/idp-register.yml`** | `push` to `main` touching `*/catalog-info.yaml` | Registers or re-registers the new component with the Harness IDP / Backstage catalog via API. Optional, can be toggled off via repo secrets. |

> Each workflow is written to operate on **any app folder** without modification.  
> Path filters ensure that workflows are only triggered when files in the corresponding folder change.

### Typical Lifecycle

1. **Provisioning:**  
   - Harness IDP pipeline (`E2E_React_App_Provisioning`) scaffolds a new app folder and opens a PR.
2. **PR Validation:**  
   - `react-ci.yml` and `terraform.yml` run automatically on the PR to validate code and infrastructure.
3. **Merge to Main:**  
   - On merge, `terraform.yml` applies infrastructure and (optionally) `idp-register.yml` imports the new catalog entry.
4. **Visibility in IDP:**  
   - Within minutes, the new app appears in the Harness IDP catalog, complete with metadata, ownership, and TechDocs.

### Key Automation Principles

- **Centralized CI:** Workflows live once in `.github/workflows/`, shared by all apps.
- **Decoupled Template Logic:** The cookiecutter repo (`app-template-react-monorepo`) defines folder structure only; automation stays in this monorepo.
- **No Manual Setup:** Developers don’t need to modify or add workflow files — everything runs automatically after scaffolding.
- **Governance Ready:** Workflows can be extended to include SAST/SCA scans, approvals, and cost checks without affecting the template logic.

---


## Example Workflows

- **Add a new service:** Run provisioning pipeline → Review PR → Merge → New catalog entry appears in IDP.  
- **Update docs:** Edit `docs/` in the app folder → Commit → Docs published to IDP TechDocs.  
- **Security scan:** Triggered automatically on PRs via configured CI steps.  
- **Observability:** Add dashboards and link them in `catalog-info.yaml` so they surface in IDP.

---

## Support

- **Pipeline name:** `E2E_React_App_Provisioning`  
- **Questions about setup:** Contact your Harness SE.  
- **Day-to-day use:** Developers only need to use the IDP Provisioning flow and app-level README guidance.
