# E2E React App Provisioning (Reference Workflow Form)

This YAML defines a **Harness IDP Workflow Form** for provisioning a React app into a monorepo.  
It presents a guided UI for developers, validates inputs (e.g., GitHub username, repo access), and triggers the **E2E_React_App_Provisioning pipeline**.

> Treat this as a **reference template**. Copy into your POV folder and adjust the input fields, defaults, and Harness pipeline URL as needed.

---

## Purpose

- Provides a **self-service form** for developers to request new apps.  
- Captures inputs like app name, owner, description, repo, branch prefix, environment, and region.  
- Validates **GitHub permissions** to ensure requester can commit/PR.  
- Optionally toggles Jira ticket creation and automatic IDP registration.  
- Triggers the corresponding Harness pipeline with the collected parameters.

---

## Sections & Parameters

### 1. Application Details
- **project_name**: Human-readable app name (3–50 chars, alphanumeric + space/dash/underscore).  
- **project_owner**: Owner email (used in IDP metadata).  
- **project_description**: Short description (default: `Testing for POC`).  
- **token**: Harness API token (masked field).  

### 2. Repository & Branching
- **github_username**: GitHub username (validated for repo access).  
- **repoPicker**: Dropdown to select from user’s accessible GitHub repos (via proxy).  
- **repo_owner**, **repository**, **default_branch**, **visibility**: Auto-populated based on repo selection.  
- **new_branch_prefix**: Prefix for feature branches (default: `feature`).  

### 3. Permissions Check
- **validate_permissions**: Button to fetch/validate user’s GitHub repo access.  
- **resolved_permission**: Shows detected permission level (read/write/admin).  
- **permission_hint**: Warning if user lacks write access.  

### 4. Environment & Region
- **environment_name**: Dropdown (`dev`, `qa`, `prod`).  
- **aws_region**: Dropdown (`us-east-1`, `us-east-2`, `us-west-1`, `us-west-2`).  

### 5. Options
- **enable_jira**: Toggle to create a Jira Story.  
- **register_component**: Toggle to auto-register new app in Harness IDP Catalog.  

---

## Output Links

On successful execution, the workflow surfaces:  
- **Pipeline Details**: URL to the Harness pipeline run.  
- **New Branch URL**: GitHub URL for the feature branch.  
- **PR URL**: GitHub pull request link.

---

## How It Works

1. Developer fills out the form in Harness IDP.  
2. Form validates required inputs (app name, owner, repo, etc.).  
3. Optional: run **Validate GitHub Permissions** before submission.  
4. On submit, the workflow triggers the **E2E React App Provisioning pipeline** with provided parameters.  
5. After pipeline runs, links are shown back in the UI.  

---

## Notes

- `repoPicker` integrates with GitHub API proxy to show only repos the user can access.  
- `token` must be a valid Harness API Key stored securely (masked input).  
- All inputs/outputs can be customized for each POV (customer environment).  
- Default values (e.g., owner email, branch prefix) should be updated to match the target org.  

---

## Example Usage

After publishing the workflow YAML into Harness IDP, the developer portal will show a form:  

1. Enter application name and owner.  
2. Select a GitHub repo.  
3. Validate GitHub permissions.  
4. Choose environment and region.  
5. Submit → triggers the Harness pipeline, provisions app, opens PR.  

