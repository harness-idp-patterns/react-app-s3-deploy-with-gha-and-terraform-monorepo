# Cookiecutter — React App in a Monorepo (with Terraform & IDP)
This repository is a **cookiecutter template** that scaffolds a new React app into an existing monorepo, including:
- A minimal web app skeleton (`site/`), a project README, and a Backstage/Harness IDP catalog entry (`catalog-info.yaml`).
- An **infrastructure** starter in `infra/` (Terraform) for a static-site bucket and supporting plumbing.
- Sensible naming conventions and IDs derived from your inputs (e.g., `project_slug`, `idp_identifier`).

> **Use-case:** quickly spin up a new app area inside a DevOps monorepo, then let your platform pipelines (Harness, GitHub Actions, etc.) take it from there.

---

## What gets generated

```
react-app-s3-deploy-cookiecutter/
├── cookiecutter.json
├── {{cookiecutter.project_slug}}/
│   ├── README.md
│   ├── catalog-info.yaml
│   ├── site/
│   │   └── index.html
│   └── infra/                     # Terraform for static site bucket + basics
│       ├── backend.tf
│       ├── identity.tf
│       ├── main.tf
│       ├── outputs.tf
│       ├── providers.tf
│       ├── variables.tf
│       └── env/
│           └── terraform.tfvars   # example variables
└── .gitignore

```

### Notable files
- **`{{cookiecutter.project_slug}}/catalog-info.yaml`** — registers the component with your Developer Portal (Backstage/Harness IDP).
- **`{{cookiecutter.project_slug}}/infra/*`** — Terraform for a basic static site bucket and identity; adjust to your cloud & org patterns.
- **`{{cookiecutter.project_slug}}/README.md`** — per-project readme shown to developers in the monorepo.

---

## Prerequisites

- Python 3.8+
- [`cookiecutter`](https://cookiecutter.readthedocs.io/en/latest/): `pip install cookiecutter`
- GitHub access to your **monorepo**
- (Optional) **Terraform** CLI if you will use the included infra
- (Optional) **gh**, **jq**, **curl** if your pipelines/scripts call them

---

## Generate a project

From a working dir where you want the new folder created:
```bash
cookiecutter gh:your-org/app-template-react-monorepo
# or local path
cookiecutter /path/to/app-template-react-monorepo
```

You will be prompted for the following inputs (from `cookiecutter.json`):

| Input key | Description |
|---|---|
| `project_name` | *(Provide value at prompt)* |
| `project_slug` | *(Provide value at prompt)* |
| `idp_identifier` | *(Provide value at prompt)* |
| `project_owner` | *(Provide value at prompt)* |
| `project_description` | *(Provide value at prompt)* |
| `aws_region` | *(Provide value at prompt)* |
| `github_org` | *(Provide value at prompt)* |
| `github_repo` | *(Provide value at prompt)* |
| `environment_name` | *(Provide value at prompt)* |
| `github_team` | *(Provide value at prompt)* |
| `github_monorepo` | *(Provide value at prompt)* |
| `connector_ref` | *(Provide value at prompt)* |

> Tip: **project_name** → we derive `project_slug` (lowercase, dashes), and `idp_identifier` (slug + underscores) for IDP components.

The template creates a new folder named `{{cookiecutter.project_slug}}/` with app, infra, and catalog files. Move/commit that folder into your monorepo root as needed, or run cookiecutter from the monorepo root so it generates in-place.

---

## Post‑generation steps

1. **Commit & PR**
   - Commit the newly generated folder to your monorepo and open a PR.
   - Ensure your CODEOWNERS/approvals apply.

2. **Developer Portal registration**
   - Your `catalog-info.yaml` is ready for Backstage/Harness IDP ingestion.
   - If you register via API, you can use a job/step that posts the repo/branch/path to your IDP importer.

3. **(Optional) Terraform**
   - If you plan to host a static site, populate `infra/env/terraform.tfvars`, configure backend/credentials, and run plan/apply in a pipeline.

4. **Secrets/OIDC**
   - If using GitHub Actions with cloud OIDC, make sure the repo/Org trust and IAM role are configured.

---


---

## Using with monorepo-idp-example

This cookiecutter template is designed to work seamlessly with the
[`monorepo-idp-example`](https://github.com/harness-idp-sandbox/monorepo-idp-example) repository.

### Workflow Overview

When a new folder is scaffolded from this template and committed into
the monorepo, the GitHub Actions workflows defined in the **monorepo**
automatically detect the new app and execute CI/CD pipelines for it.

- **React CI** builds and tests the app under `{{cookiecutter.project_slug}}/site`.
- **Terraform** validates, plans, and applies the infrastructure under
  `{{cookiecutter.project_slug}}/infra`.
- **IDP Catalog Registration** (optional) registers your new component
  into the Harness IDP or Backstage catalog.

### Responsibilities

| Repository | Responsibility |
|-------------|----------------|
| **app-template-react-monorepo** | Defines the structure, variables, and files for new apps (React site + Terraform infra + catalog entry). |
| **monorepo-idp-example** | Owns and executes the GitHub Actions workflows that build, test, and register the newly scaffolded app. |

### Typical Flow

1. **Run cookiecutter** to scaffold a new app.
2. **Commit** the generated folder into your `monorepo-idp-example` repo.
3. **Open a PR** — the monorepo’s GitHub Actions will automatically detect the new path and trigger builds/tests.
4. **Merge to main** — production Terraform apply and IDP registration occur automatically (if configured).

> This separation ensures the template remains lightweight and reusable,
> while the monorepo centralizes automation, secrets, and governance.

---
