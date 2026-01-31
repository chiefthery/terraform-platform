# IR-001 — Grafana not reachable from browser

## Summary

Grafana UI was not accessible via browser despite container running.

---

## Impact

Unable to validate dashboards and confirm end-to-end monitoring UX.

---

## Detection

Browser timeout / refused connection on port 3000.

---

## Root cause

Security group ingress did not allow TCP 3000 from my IP (or was attached to the wrong instance).

---

## Fix

Updated SG rules to allow inbound TCP 3000 from my IP to the monitoring instance.

---

## Verification

- Browser loads Grafana login page

- `docker compose ps` shows Grafana healthy

- `ss -ltnp | grep :3000` confirms listener

---

## Prevention

- Add SG rule as code (Terraform) to avoid console drift
- Maintain a “required ports” checklist per stack
