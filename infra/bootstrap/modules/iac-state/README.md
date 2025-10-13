# iac-state — Terraform Backend Module (S3 + DynamoDB)

Secure, SE‑friendly Terraform backend for POVs: creates an **S3 bucket** (versioned, encrypted, TLS‑only) and a **DynamoDB lock table**. Exposes ready‑to‑use **backend config** and a **least‑privilege IAM policy** you can attach to a GitHub OIDC role.

---

## What this module creates

- **S3 bucket** for Terraform state
  - Versioning **enabled**
  - Server‑side encryption (**AES256** by default; optional **KMS**)
  - Public access **blocked**
  - Bucket policy **denies non‑TLS** (`aws:SecureTransport = false`)
  - Randomized name: `<bucket_prefix>-<hex>`
  - Safe delete guard via `prevent_destroy` (toggle with `force_destroy`)

- **DynamoDB table** for state locks
  - `PAY_PER_REQUEST`, SSE enabled
  - (Optional) enable **PITR** in code if desired

- **Outputs** for easy wiring
  - `bucket`, `bucket_arn`, `dynamodb_table`, `dynamodb_table_arn`, `region`
  - `backend_access_policy_json` (and `backend_access_policy_encoded`)
  - `backend_hcl_example` (copy‑paste backend config)
  - (Optional to add) `backend_metadata` map

---

## Usage (minimal)

```hcl
module "iac_state" {
  source           = "./infra/bootstrap/iac-state" # or your module source
  region           = "us-east-1"
  bucket_prefix    = "tfstate"
  state_key_prefix = "repos/<org>/<repo>"
  tags = {
    Project = "terraform-backend"
    Owner   = "HarnessPOV"
  }
}
```

Then write your backend file (example from the module output):

```hcl
# backend.hcl
bucket         = "<copy: module.iac_state.bucket>"
key            = "repos/<org>/<repo>/<app-path>/terraform.tfstate"
region         = "us-east-1"
dynamodb_table = "<copy: module.iac_state.dynamodb_table>"
encrypt        = true
```

Initialize your workspace with:
```bash
terraform init -backend-config=backend.hcl
```

> **Tip:** In CI, store these values as secrets and generate `backend.hcl` on the fly.

---

## Example with OIDC role policy

Attach the generated backend policy to your GitHub OIDC role so Jobs can read/write state only under the configured prefix.

```hcl
resource "aws_iam_policy" "tf_backend" {
  name   = "tf-backend-access"
  policy = module.iac_state.backend_access_policy_json
}

resource "aws_iam_role_policy_attachment" "tf_backend_attach" {
  role       = aws_iam_role.github_oidc_role.name
  policy_arn = aws_iam_policy.tf_backend.arn
}
```

If you prefer, use the encoded variant:
```hcl
policy = base64decode(module.iac_state.backend_access_policy_encoded)
```

---

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `region` | string | `"us-east-1"` | AWS region for bucket/table |
| `bucket_prefix` | string | `"tfstate"` | Prefix for S3 bucket (random suffix auto‑added) |
| `state_key_prefix` | string | `"repos/<org>/<repo>"` | Path prefix limiting S3 access & forming backend key |
| `lock_table_name` | string | `"tfstate-locks"` | DynamoDB table name for state locks |
| `tags` | map(string) | `{ Project = "terraform-backend", Owner = "HarnessPOV" }` | Common tags |
| `use_kms` | bool | `false` | Use SSE‑KMS for S3 objects |
| `kms_key_arn` | string | `""` | Existing CMK ARN to use when `use_kms = true` |
| `kms_alias` | string | `"alias/tfstate"` | Alias (only relevant if you extend module to create a CMK) |
| `force_destroy` | bool | `false` | If `true`, allows bucket destroy (disables `prevent_destroy`) |

> PITR for DynamoDB is easy to enable by adding `point_in_time_recovery { enabled = true }` in the table resource.

---

## Outputs

| Name | Description |
|------|-------------|
| `bucket`, `bucket_arn` | State bucket name and ARN |
| `dynamodb_table`, `dynamodb_table_arn` | Lock table name and ARN |
| `region` | Region used |
| `backend_access_policy_json` | IAM policy JSON granting least‑privilege backend access to the configured prefix |
| `backend_access_policy_encoded` | Base64‑encoded policy (convenience for consumers) |
| `backend_hcl_example` | A ready‑to‑paste backend.hcl snippet |

---

## CLI helpers (optional)

If you include helper scripts next to the module (recommended for SEs):

- **`apply.sh`** — applies and writes:
  - `backend.hcl.tpl` and `backend.hcl.recommended.tpl` (using `state_key_prefix`)
  - `backend.env` with bucket/table/region/prefix & ARNs for CI secrets
- **`destroy.sh`** — guarded destroy; use `--force` only when you intend to wipe the backend

Example:
```bash
./apply.sh   # creates S3+DDB, prints NEXT_STEPS.txt
./destroy.sh # prompts before destroying; use --force for non-interactive
```

---

## FAQ

**Does this README make this a Terraform “module”?**  
A Terraform **module** is any folder with `.tf` files that can be called via `module "x" { source = "./path" }`.  
This folder already qualifies as a module because it contains `main.tf`, `variables.tf`, and `outputs.tf`.  
A README is **best practice** (and required for publishing on the Terraform Registry), but not required to be used as a local module.

**Registry considerations (optional):**  
If you plan to publish, add:
- A clear `README.md` (this file), a `LICENSE`, and semantic version tags.
- Keep `versions.tf` (your `terraform { required_version ... }` block) and provider constraints.
- Optionally add an `examples/` folder.

---

## Requirements

- Terraform ≥ **1.6.0**
- AWS provider ≥ **5.0**
- AWS IAM permissions to create S3 buckets, bucket policies, and DynamoDB

---

## Changelog

- **v1.0.0** — Initial public version with S3+DDB backend, TLS‑only policy, least‑privilege OIDC policy output, and SE‑friendly outputs.
