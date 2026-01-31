# Week 2 — Public + Private VPC (Systems Thinking)

## Goal
Transition from a single-server deployment to a segmented network architecture that enforces controlled access, least privilege, and outbound-only connectivity for private workloads. This week introduces real-world infrastructure patterns used in enterprise and cloud-native environments.

---

## Architecture Overview

### Network layout

- One VPC with DNS enabled
- One public subnet
- One private subnet
- Internet Gateway attached to VPC
- NAT Gateway in public subnet

### Instances

- Bastion host (public IP)
- Application host (private IP only)

### Trust boundaries

| Layer        | Exposure         | Purpose                    |
|--------------|------------------|----------------------------|
| Internet     | Public           | Admin entry point          |
| Bastion      | Restricted SSH   | Controlled access gateway  |
| Private App  | No public IP     | Protected workload         |

---

## Traffic Design

### Inbound (administration)

Admin → Internet → IGW → Bastion → App

Only the bastion is internet-reachable. The app is never exposed directly.

### Outbound (updates / patches)

App → NAT → IGW → Internet

Private instances can patch and update without being reachable.

---

## Security Model

### Layered access

1. Security group restricts SSH to bastion from admin CIDR
2. App SG allows SSH only from bastion SG
3. No inbound rules allow internet → app

### Result

- No direct attack surface on private workloads
- All admin access is auditable
- Compromise of one layer does not expose entire network

---

## Key Design Decisions

### Why a Bastion Host

- Centralizes administrative access
- Enables logging and monitoring
- Simplifies incident response
- Prevents direct internet exposure

### Why NAT Gateway

- Enables outbound connectivity without inbound risk
- Supports patching and package installs
- Aligns with zero-trust perimeter design

### Why Separate Route Tables

- Public subnet routes to IGW
- Private subnet routes to NAT
- Prevents accidental exposure

---

## Verification Model

After deployment:

### Network

- Bastion has public IP
- App has private IP only

### Access

- SSH to bastion succeeds from admin CIDR
- SSH to app fails from internet
- SSH to app succeeds via bastion

### Routing

- App can reach external repositories
- Inbound connections to app are blocked

---

## Failure Modes Observed

### ProxyJump / SSH Resolution

Misconfigured SSH identities and jump hosts caused access failures.

Resolution:

- Normalize `~/.ssh/config`

- Enforce IdentityFile

- Validate permissions

(See IR-003)

---

## How This Enables Later Weeks

- Week 3 monitoring can target private hosts securely
- Ansible automation can route via bastion
- Identity services can be isolated
- Multi-AZ and load balancers can be layered later

---

## Enterprise Relevance

This architecture mirrors:
- Production jump-host models
- Zero-trust perimeters
- Segmented VPC designs
- Regulated environment layouts

It provides the foundation for secure scaling and automation.
