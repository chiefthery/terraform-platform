# Week 1 — Single EC2 Baseline (Terraform)

## What This Builds

- 1× EC2 instance (Amazon Linux 2023)
- Security Group allowing SSH from an admin CIDR (or your configured source)
- Outputs for:
    - Public IP / instance ID
    - Any values used by later automation (Ansible, monitoring)

---

## Inputs

Set in `terraform.tfvars` (created from `terraform.tfvars.example`):

- `aws_region`

- `key_name`

- `admin_cidr`

- `instance_type`

- `tags` / `project_name` (whatever you use)

---

## Prerequisites

- Terraform ≥ 1.5
- AWS credentials configured (AWS CLI or env vars)
- Existing EC2 key pair in your target region

---

## How to run

`cp terraform.tfvars.example terraform.tfvars`

`terraform fmt`

- **What this does:** auto-formats your .tf files to standard Terraform style (clean diffs, easier reviews).

`terraform init`

- **What this does:** downloads providers/modules and initializes the working directory.

`terraform validate`

- What this does: downloads the AWS provider and initializes the working directory (creates `.terraform/`).

`terraform plan`

- **What this does:** shows what Terraform will create/change before making changes.

`terraform apply`

- **What this does:** creates the EC2 instance and related resources in AWS.

---

## Validate

`terraform output`

- **What this does:** prints outputs (like public IP) after apply.

### SSH:

`ssh -i ~/.ssh/<your-key>.pem ec2-user@<public-ip>`

- **What this does:** connects to the instance using your SSH key.

### Confirm OS

- `cat /etc/os-release`

---

## Teardown

`terraform destroy`

- **What this does:** deletes all resources created by this stack using Terraform state.

---

## Notes 

Do not commit `terraform.tfvars` (contains local values).

