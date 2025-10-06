# Pull Request Template

## 📌 Summary
Please explain the purpose of this PR and the changes introduced.

- **Feature/Module**:  
- **Linked Issue(s)/Ticket(s)**:  

## 🏷️ Suggested Labels (keep what applies)
`idp` `automation` `scaffold` `change-mgmt` `security` `docs`

## 👤 Requestor
- **GitHub Username**: ${{ inputs.github_username || 'N/A' }}

## ✅ Checklist
- [ ] Code follows project guidelines and conventions
- [ ] Relevant documentation updated (README, ADRs, etc.)
- [ ] Tests added/updated (if applicable)
- [ ] CI/CD pipelines passing
- [ ] Security scans and compliance checks passed
- [ ] Verified environment-specific configs/secrets

---

<!--
The pipeline will append an **IDP Context** block below this line during PR creation.
Do not edit the block header—it helps automation find the insertion point.
-->

## 🧩 IDP Context (auto-added by pipeline)
<!-- The PR creation step will append details here such as:
     - Requestor identity
     - Pipeline identifier and run number
     - Execution URL
     - Source/target branches
     - Any governance links (ServiceNow, approvals)
-->
