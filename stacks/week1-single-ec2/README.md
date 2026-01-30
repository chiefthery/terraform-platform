# Week 1 — Single EC2 Baseline (Terraform)

This stack is the Week 1 baseline for the terraform-platform repo.

It provisions a single AWS EC2 instance with enterprise-style tagging and clean Terraform structure (variables, outputs, tfvars template). This is the “hello world” foundation that later weeks build on (VPC segmentation, bastion access, monitoring, etc.).

---

## What This Builds

- 1× EC2 instance (Amazon Linux 2023)
- Security Group allowing SSH from an admin CIDR (or your configured source)
- Outputs for:
    - Public IP / instance ID
    - Any values used by later automation (Ansible, monitoring)

---

## Files

- `main.tf` — core resources (EC2 + SG)

- `variables.tf` — input variables (region, key_name, admin_cidr, instance_type, tags)

- `outputs.tf` — public IP, instance ID, etc.

- `terraform.tfvars.example` — template for local variable values

- `versions.tf` — provider + Terraform version constraints

---

## Prerequisites

- Terraform ≥ 1.5
- AWS credentials configured (AWS CLI or env vars)
- Existing EC2 key pair in your target region

---

## Configure Variables

`cp terraform.tfvars.example terraform.tfvars`

- **What this does:** copies the example tfvars template into the real tfvars file Terraform will read.

`vi terraform.tfvars`

- **What this does:** opens the tfvars file so you can set values like key_name and admin_cidr.

Note: terraform.tfvars should remain local only (not committed).

---

## Deploy

`terraform init`

- **What this does:** downloads providers/modules and initializes the working directory.

`terraform plan`

- **What this does:** shows what Terraform will create/change before making changes.

`terraform apply`

- **What this does:** creates the EC2 instance and related resources in AWS.

---

## Validate

`terraform output`

- **What this does:** prints outputs (like public IP) after apply.

---

## SSH:

`ssh -i ~/.ssh/<your-key>.pem ec2-user@<public-ip>`

- **What this does:** connects to the instance using your SSH key.

---

## Teardown

`terraform destroy`

- **What this does:** deletes all resources created by this stack using Terraform state.

