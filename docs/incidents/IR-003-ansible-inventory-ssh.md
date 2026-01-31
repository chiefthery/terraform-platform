# IR-003 — Ansible unable to reach multiple targets via bastion

## Summary

Ansible `ping` and playbook runs failed against multiple hosts despite direct SSH access working, preventing automation and remediation workflows.

---

## Impact

Automation pipeline could not execute configuration or recovery tasks across target hosts, blocking monitoring remediation and baseline enforcement.

---

## Detection

- `ansible all -m ping` failed

- Some hosts reachable manually via SSH

- Others returned unreachable / authentication errors

---

## Root Cause

Multiple layered issues:

- Inventory file was misformatted, causing incorrect host grouping

- Missing `ansible_host` mappings

- SSH ProxyJump configuration not consistently applied

- IdentityFile not properly referenced in Ansible context

- Bastion jump chain not inherited from `~/.ssh/config`

As a result, Ansible could not resolve how to reach private targets.

---

## Resolution

1. Rebuilt inventory using explicit host variables:

```
   [targets]
   app1 ansible_host=10.x.x.x
   app2 ansible_host=10.x.x.x

   [targets:vars]
   ansible_user=ec2-user
   ansible_ssh_common_args='-o ProxyJump=bastion'
```

2. Normalized SSH config:

```
Host bastion
  HostName x.x.x.x
  User ec2-user
  IdentityFile ~/.ssh/key.pem

Host private-*
  ProxyJump bastion
  User ec2-user
  IdentityFile ~/.ssh/key.pem
```

3. Verified precedence with:

```
ansible-inventory --graph
ansible -vvv all -m ping
```

---

## Verification

- `ansible all -m ping` returned SUCCESS

- Playbooks executed across all targets

- Bastion routing confirmed in verbose output

---

## Prevention

- Standardize inventory templates

- Centralize SSH jump configuration

- Validate inventory using `ansible-inventory` before automation

- Include connectivity test stage in pipelines

---

## Lessons Learned

Automation reliability depends on consistent access patterns. Manual SSH success does not guarantee Ansible compatibility without aligned inventory and SSH configuration.
