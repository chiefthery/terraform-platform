# IR-004 — Prometheus config conflict caused alerts/rules to be ignored

## Summary

Alerting behavior became inconsistent after Prometheus was started in two different ways (Docker Compose and a separate manual run). Prometheus and/or Alertmanager appeared “up,” but rules and configuration changes were not taking effect as expected.

---

## Impact

- Alert rules were not loading reliably
- Troubleshooting became ambiguous because multiple Prometheus instances were responding on different containers/ports
- Increased time-to-diagnosis due to config ambiguity (which Prometheus instance was “the real one”?)

---

## Detection

Symptoms included one or more of:

- UI showed Prometheus running, but updated rules did not appear

- `/targets` looked correct but alerts did not fire

- Container logs showed configuration paths that did not match expected files

- Multiple containers existed for Prometheus, making it unclear which was serving traffic

---

## Root Cause

Prometheus was running as **two separate instances**:
1. One managed by **Docker Compose** (with its own volume mounts and config path)
2. Another started manually (or via a separate container run) using a different config/rules directory

Because each instance referenced different files and mounts, updates were made to one set of files while the active Prometheus instance was reading from another.

Contributing factors:
- Config file path/volume mounts differed between the two runs
- Container naming made it easy to “exec” into the wrong Prometheus container
- Port mappings made both appear reachable, masking the duplication

---

## Resolution

1. Identified duplicate Prometheus containers:

`docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Ports}}"`

2. Determined which instance should be canonical:
    - Kept the **Docker Compose** stack as the source of truth

3. Stopped and removed the non-canonical Prometheus container:

```
docker stop <non_compose_prometheus>
docker rm <non_compose_prometheus>
```

4. Verified Compose configuration and mounts were correct:

```
docker compose ps
docker compose logs prometheus --tail=50
docker exec -it <compose_prometheus_container> ls -la /etc/prometheus
```

5. Restarted the Compose stack after confirming the correct config/rules were present:

```
docker compose down
docker compose up -d
```

---

## Verification

- Only one Prometheus container remained running
- Prometheus logs confirmed the expected config file path was being loaded
- Rule files appeared in the Prometheus UI and/or logs after restart
- Alerts fired as expected when targets were intentionally made unavailable

---

## Prevention

- Define a single “source of truth” for running Prometheus (Compose only)

- Add a quick pre-check before changes:

    - `docker ps` to confirm there is only one Prometheus instance
    - Validate mounts: `docker inspect <container> | grep -A2 Mounts`

- Use consistent container naming conventions and avoid manual `docker run` for services managed by Compose

- Document expected config/rules paths in the Week 3 runbook

---

## Lessons Learned

Service orchestration failures can look like application failures. When behavior is inconsistent, first verify there is a single running instance and that the active instance is reading from the intended configuration and rule files.
