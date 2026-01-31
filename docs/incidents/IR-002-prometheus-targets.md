# IR-002 — Prometheus targets page not loading / targets not UP

## Summary

Prometheus targets UI did not load from browser, and/or targets appeared DOWN.

---

## Impact

Could not confirm scraping status or alert readiness.

---

## Detection

- Browser could not load `/targets`

- `curl http://localhost:9090/targets` returned HTML, but remote access failed OR targets DOWN

---

## Root cause (likely)

One or more of:

- SG ingress missing TCP 9090 from my IP

- SG egress / route rules blocking Prometheus -> targets on 9100

- node_exporter not running/listening on targets

- wrong target IPs in config

---

## Fix


- Ensure SG allows:
    - inbound 9090 to monitoring host from my IP
    - outbound from monitoring to targets on 9100 (and targets allow inbound 9100 from monitoring SG)

- Start/enable node_exporter on targets

- Validate target addresses in `prometheus.yml`

---

## Verification

- Prometheus UI loads externally

- Targets show **UP**

- `ss -ltnp | grep :9100` on targets confirms exporter listening

---

## Prevention

- Use SG-to-SG references (monitoring SG -> target SG) rather than CIDR where possible
- Keep config + infra changes version-controlled

