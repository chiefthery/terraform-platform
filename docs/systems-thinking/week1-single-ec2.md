# Week 1 — Single EC2 Baseline (Why it matters)

## Goal
Establish a clean Terraform “hello world” foundation that later weeks build on (network segmentation, bastion access, monitoring, automation).

## Architecture

### Resources

- EC2 instance (Amazon Linux 2023)

- Security Group: inbound SSH restricted to `admin_cidr`

- Outputs: public IP + instance ID for downstream automation

### Trust boundary

- Only admin CIDR can reach port 22
- Everything else is denied by default

---

## Key decisions

- AL2023 as a stable baseline AMI
- Outputs are treated as contract surfaces for later weeks (bastion, monitoring, Ansible)

## Verification (expected results)

After `terraform apply`:

- `terraform output` prints:
   
    - `public_ip = x.x.x.x`
  
    - `instance_id = i-...`

- SSH succeeds only from admin CIDR

- `cat /etc/os-release` confirms AL2023
