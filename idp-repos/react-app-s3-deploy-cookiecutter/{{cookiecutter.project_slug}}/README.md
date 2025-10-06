# {{ cookiecutter.project_name }}

{{ cookiecutter.project_description }}

> **Owner:** {{ cookiecutter.project_owner }}  
> **Team:** {{ cookiecutter.github_team }}  
> **Repo:** `{{ cookiecutter.github_org }}/{{ cookiecutter.github_monorepo }}`  
> **Folder:** `/{{ cookiecutter.project_slug }}`  
> **IDP Identifier:** `{{ cookiecutter.idp_identifier }}`

---

## Quick links

- **Repository path:** `/{{ cookiecutter.project_slug }}`
- **Open PRs (search):** https://github.com/{{ cookiecutter.github_org }}/{{ cookiecutter.github_monorepo }}/pulls?q=is%3Apr+{{ cookiecutter.project_slug }}+label%3Aidp+label%3Ascaffold+sort%3Acreated-desc
- **Developer Portal catalog entry:** _(auto-created if pipeline step “Register Component” is enabled; add link once available)_
- **Issue tracker:** _(link Jira project or GitHub Issues)_
- **ServiceNow change for this PR:** _(added by pipeline; paste link)_

> The Harness pipeline opens a **feature branch PR** (labels: `idp`, `scaffold`, `automation`, and `testing` when applicable). If change management is on, the PR gets `change:*` labels based on ServiceNow approval status.

---

## Environments & URLs

| Environment | URL | Notes |
|---|---|---|
| Dev | https://{{ cookiecutter.project_slug }}.dev.example.com | _(replace with your real dev domain)_ |
| Staging | https://{{ cookiecutter.project_slug }}.stg.example.com |  |
| Prod | https://{{ cookiecutter.project_slug }}.example.com |  |

> No ingress yet? Port-forward locally:
>
> ```bash
> # Example: adjust namespace/service as needed
> kubectl port-forward -n <namespace> svc/{{ cookiecutter.project_slug }}-web 5173:80
> # then open http://localhost:5173
> ```

---

## Getting started (local)

### Prerequisites
- Node.js ≥ 18
- Package manager: `npm` (or `pnpm`/`yarn`)
- (Optional) Docker if you run containerized locally

### Install & run

```bash
cd {{ cookiecutter.project_slug }}
npm install
npm run dev
# open http://localhost:5173
```

Common scripts (from `package.json`):

```bash
npm run dev        # start dev server
npm run build      # production build
npm run preview    # preview built app
npm test           # unit tests
npm run lint       # lint
```

### Environment variables

Create `.env` files as needed (`.env`, `.env.development`, `.env.production`):

| Variable | Example | Description |
|---|---|---|
| VITE_API_BASE_URL | `https://api.example.com` | API base URL |
| FEATURE_FLAG_X | `true` | Toggle a feature |
| LOG_LEVEL | `info` | Logging verbosity |

> Avoid committing secrets. Use your platform’s secret manager for runtime config.

---

## Build & deploy (POV defaults)

- **Branching:** The pipeline creates feature branches like `feature/{{ cookiecutter.project_slug }}-<run-number>`.
- **PRs:** Merging to the default branch (e.g., `main`) triggers CI/CD (configure in your org).  
- **Artifacts:** Either a static SPA bundle or a container image—document which path you use here.  
- **Runtime config:** Prefer **env-driven** config, injected at build/deploy.  
- **Approvals:** The PR may be gated by **ServiceNow**; labels and a commit status (`servicenow/change-approval`) indicate state.

> If your org uses Harness pipelines in-repo, see `.harness/`. For GitHub Actions, see `.github/workflows/`.

---

## Observability (fill in)

- **Logs:** _link to logging solution (e.g., CloudWatch, Elasticsearch, Datadog)_  
- **Metrics/Dashboards:** _link to dashboard_  
- **Tracing:** _link to traces_  
- **Uptime/Synthetics:** _link to monitor_

---

## Security (fill in)

- **Dependency scanning:** _tool & dashboard link_  
- **SAST/Secrets scanning:** _tool & dashboard link_  
- **Container scan:** _tool & dashboard link_  
- **AuthN/Z:** _how this app authenticates; link to provider/config_

---

## Operations (fill in)

- **Runbooks:** _link to runbook_  
- **On-call:** _rotation / contact_  
- **SLOs/SLIs:** _targets and dashboards_  
- **Release process:** _versioning, tagging, change management_  
- **CMDB/Service Registry:** _record system/service in CMDB and keep `owner`, `tier`, `criticality` in sync_

---

## Architecture

- **Stack:** React + Vite (SPA) _(adjust if different)_
- **Directory layout:**
  ```
  {{ cookiecutter.project_slug }}/
  ├─ src/
  │  ├─ components/
  │  ├─ pages/
  │  ├─ assets/
  │  └─ index.tsx
  ├─ public/
  ├─ docs/                 # TechDocs content
  ├─ catalog-info.yaml     # IDP/Backstage descriptor
  ├─ package.json
  ├─ tsconfig.json
  └─ README.md
  ```
- **Key decisions:** capture ADRs under `docs/adrs/` (template below).

---

## TechDocs

This component ships with TechDocs.

- **Docs path:** `./docs`  
- **Backstage annotation (in `catalog-info.yaml`):**
  ```yaml
  metadata:
    annotations:
      backstage.io/techdocs-ref: dir:./docs
  ```
- Edit Markdown in `docs/` and open a PR. Your CI/Harness pipeline publishes or previews docs.

---

## IDP Catalog

- **Descriptor location:** `{{ cookiecutter.project_slug }}/catalog-info.yaml`  
- **Registration:** If your pipeline flag `register_component` is `true`, the **Register Component** step calls the Entities Import API to add this component to the IDP Catalog after PR merge.  
- **Post-registration:** Add links (runbooks, dashboards), `owner`, `system`, `tags`, and any `links:` in `catalog-info.yaml` so the Developer Portal page is useful.

---

## ADR template (example)

Create files like `docs/adrs/0001-title.md`:

```markdown
# ADR-0001: Title
Date: 2025-01-01
Status: Accepted

## Context
Why are we changing something?

## Decision
What did we choose and why?

## Consequences
Trade-offs, follow-ups, risks.
```

---

## 30‑minute post‑provision checklist (edit to fit your org)

- [ ] **Docs:** Update `docs/` home page and add at least one ADR.  
- [ ] **IDP metadata:** Confirm `owner`, `system`, `tags`, `links` in `catalog-info.yaml`.  
- [ ] **CODEOWNERS:** Add or update your team for this folder.  
- [ ] **CI/CD:** Ensure build/test steps exist and are green for this folder path.  
- [ ] **Change Mgmt:** If required, link the ServiceNow change to the PR and verify gate status.  
- [ ] **CMDB:** Create/update the service record; align ownership, tier, criticality, URLs.  
- [ ] **Observability:** Create dashboards for logs/metrics/uptime and wire alerts.  
- [ ] **Security:** Enable dependency/SAST/container scans and fix criticals.  
- [ ] **Runtime config:** Document env vars and where secrets live.  
- [ ] **URLs/Ingress:** Decide URL pattern and configure DNS/ingress.

---

## Troubleshooting

- **Dev server not starting:** Check Node version (`node -v`), remove `node_modules`, re‑install.  
- **CORS errors:** Set `VITE_API_BASE_URL` correctly or add a local proxy.  
- **Blank screen in prod:** Ensure correct `base` path in Vite config if app serves from a sub-path.  
- **Not in IDP after merge:** Confirm the registration step ran and that `catalog-info.yaml` exists at the expected path.  
- **Docs show repo root:** Confirm `backstage.io/techdocs-ref: dir:./docs` and check docs publish logs.

---

## Contributing

- See **CODEOWNERS** for required reviewers and rules.  
- Follow org PR workflow (branch naming, approvals).

---

## License

_(Add your license or link here)_
