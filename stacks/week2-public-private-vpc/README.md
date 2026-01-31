# Week 2 — Public + Private VPC (Enterprise Upgrade)

## What this builds

- VPC with DNS enabled
- Public subnet (bastion + NAT Gateway)
- Private subnet (app instance, no public IP)
- Internet Gateway
- Route tables (public → IGW, private → NAT)
- Security groups (admin → bastion → app)
- 2× EC2 instances (bastion + app)

---

## Architecture (traffic story)

Admins:
Internet → Bastion (public subnet) → SSH → App (private subnet)

Outbound updates:
App (private) → NAT Gateway (public) → IGW → Internet

---

## Prerequisites
- Week 1 stack completed (key pair, AWS creds)
- Terraform >= 1.5
- Valid `terraform.tfvars`

---

## How to run

```
terraform fmt
terraform init
terraform validate
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
terraform output
```

---

## SSH into the private instance

Use ProxyJump:

`ssh -i <PATH_TO_KEY> -J ec2-user@<BASTION_PUBLIC_IP> ec2-user@<APP_PRIVATE_IP>`

### Note (See Troubleshooting)

If SSH to bastion works but ProxyJump doesn't:

1) Add identity files to .ssh/config

```
Host <NAME_FOR_BASTION>
  HostName <BASTION_PUBLIC_IP>
  User ec2-user
  IdentityFile <PATH_TO_KEY>
  IdentitiesOnly yes

Host <NAME_FOR_APP>
  HostName <APP_PRIVATE_IP>
  User ec2-user
  IdentityFile <PATH_TO_KEY>
  IdentitiesOnly yes
  ProxyJump <NAME_FOR_BASTION>
```

2) Edit permissions

`chmod 600 ~/.ssh/config`

3) SSH again

`ssh <NAME_FOR_APP>`

---

## Clean up (avoid NAT data charges)

`terraform destroy -var-file=terraform.tfvars`

