# Terraform Platform

Infrastructure-as-Code labs focused on building secure, production-style AWS environments.

This repository contains the provisioning layer that supports identity, monitoring, and automation workflows.

---

## Lab Structure

### Week 1 — Single EC2 Baseline
Directory: `week1-single-ec2/`

- Provisioned single Amazon Linux instance
- Security groups and SSH access
- Output-driven workflows

### Week 2 — Public / Private VPC
Directory: `week2-public-private-vpc/`

- VPC with segmented subnets
- Bastion host
- NAT Gateway
- Private workloads
- Restricted ingress rules

### Week 3 — Observability Infrastructure
Directory: `week3-observability/`

- Monitoring host
- Prometheus / Alertmanager infrastructure
- Bastion routing
- Secure security groups
- Automation hooks

---

## Operational Notes

- State and tfvars files are excluded by design
- Example variable files are provided
- Infrastructure can be rebuilt from source

---

## Learning Objectives

- Infrastructure modularization
- Network isolation
- Secure access design
- Observability enablement
- Reproducible environments
