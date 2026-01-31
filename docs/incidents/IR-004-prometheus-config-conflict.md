# IR-004 — Duplicate Prometheus and Alertmanager deployments caused configuration conflicts

## Summary
Monitoring and alerting behavior became inconsistent due to Prometheus and Alertmanager being deployed simultaneously via systemd and Docker Compose. Configuration changes were applied to one deployment while traffic was being served by another, leading to unclear ownership of active services.

---

## Impact

- Alert rules and Alertmanager configuration were inconsistently applied
- Port conflicts occurred on monitoring endpoints
- Alerts did not reliably fire
- Troubleshooting time increased due to ambiguous service state
- Delayed validation of monitoring and remediation workflows

---

## Detection

After deploying Prometheus and Grafana with Docker Compose, Alertmanager was installed natively using systemd. This created multiple active monitoring services.  

Alertmanager was installed and enabled as a host-level service:  

```
alertmanager.service - Prometheus Alertmanager
    Loaded: loaded (/etc/systemd/system/alertmanager.service; enabled; vendor preset: disabled)
    Active: active (running) since Tue 2026-01-27 14:18:42 EST; 3min ago
```

Later, Prometheus and Grafana were launched via Docker Compose:  

`docker compose up -d`

Process and container checks revealed overlapping services:  

```
[+] up 10/12 ✔ Image p... Pulled 1.5s 
✔ Network... Created 0.2s 
✘ Contain... Error response from daemon: Conflict. The container name "/prometheus" is already in use by container "119a51c71cc10dd40cfee8e00e3f9479e4f64cc6f358cbe352aaf22a58f4c84a". You have to remove (or rename) that container to be able to reuse that name. 0.0s 
⠋ Contain... Creating 0.0s 
⠋ Contain... Creating 0.0s 
Error response from daemon: Conflict. The container name "/prometheus" is already in use by container "119a51c71cc10dd40cfee8e00e3f9479e4f64cc6f358cbe352aaf22a58f4c84a". You have to remove (or rename) that container to be able to reuse that name.
```

Port inspection showed conflicting listeners:  

```
[+] up 2/2 ✔ Container grafana Created 0.0s 
✔ Container prometheus Created 0.1s 
Error response from daemon: driver failed programming external connectivity on endpoint alertmanager (07d2d8ab847a5a08712c235d433e320ada5881f6b2678dd42b38e11f0930a04f): Error starting userland proxy: listen tcp4 0.0.0.0:9093: bind: address already in use
```

Key detection commands:

```
docker ps
ps aux | grep -E "prometheus|alertmanager"
pgrep -a prometheus
ss -ltnp | grep :9093
```

---

## Root Cause

Two parallel deployment models were active:

### 1. Systemd-managed Alertmanager

Alertmanager was installed manually and registered as a system service using:

- Binary in `/usr/local/bin`

- Config in `/etc/alertmanager/alertmanager.yml`

- Service unit in `/etc/systemd/system/alertmanager.service`

This service was enabled and running:

```
alertmanager.service - Prometheus Alertmanager
    Loaded: loaded (/etc/systemd/system/alertmanager.service; enabled; vendor preset: disabled)
    Active: active (running) since Tue 2026-01-27 14:18:42 EST; 3min ago
```

### 2. Docker Compose Monitoring Stack

Prometheus, Grafana, and later Alertmanager were deployed using Docker Compose with mounted configuration files:

| NAMES         | IMAGE                   | PORTS                |
| ------------- |:-----------------------:|:--------------------:|
| prometheus    | prom/prometheus:latest  |0.0.0.0:9090->9090/tcp|
| grafana       | grafana/grafana:latest  |0.0.0.0:3000->3000/tcp|
| alert manager | prom/alertmanager:latest|0.0.0.0:9093->9093/tcp|

This resulted in:
- Host-level Alertmanager running alongside container Alertmanager
- Possible host-level Prometheus alongside container Prometheus
- Different configuration paths and rule directories
- Multiple services binding to the same ports

Because each deployment referenced different config locations, updates were made to container files while systemd services were still active, causing configuration drift.

---

## Resolution

1. Enumerated all running monitoring processes:

```
docker ps
ps aux | grep prometheus
pgrep -a prometheus
```

2. Terminated stray host Prometheus processes:

`sudo pkill -x prometheus`

Verified termination:

`36819 /bin/prometheus --config.file=/etc/prometheus/prometheus.yml --storage.tsdb.path=/var/lib/prometheus`

3. Traced remaining processes using process tree inspection:

```
systemd─┬─alertmanager───7*[{alertmanager}]
        └─prometheus───6*[{prometheus}]
```

4. Stopped and disabled systemd Alertmanager:

```
sudo systemctl stop alertmanager
sudo systemctl disable alertmanager
```

5. Removed duplicate containers:

```
docker stop alertmanager || true
docker rm alertmanager || true
```

6. Standardized on Docker Compose as the canonical deployment:

```
docker compose down
docker compose up -d
```

7. Verified container mounts and rule paths:

```
docker inspect prometheus --format '{{range .Mounts}}{{println .Source "->" .Destination}}{{end}}'
docker exec -it prometheus ls -la /etc/prometheus
docker exec -it prometheus ls -la /etc/prometheus/rules
```

---

## Verification

### After consolidation:
- Only one Prometheus and one Alertmanager container were running
- Port 9093 was bound exclusively to container Alertmanager
- Prometheus logs confirmed correct rule loading
- Alert files were visible inside the container
- Alerts fired correctly during controlled failure tests

### Verification evidence:

####Containers

| CONTAINER ID  | IMAGE                    | COMMAND                 | STATUS       |   PORTS                |
| ------------- |:------------------------:|:-----------------------:|:------------:|:----------------------:|
| b3a91f72aa21  | prom/prometheus:latest   | "/bin/prometheus ..."   | Up 5 minutes | 0.0.0.0:9090->9090/tcp |
| a12c92bc91fd  | prom/alertmanager:latest | "/bin/alertmanager ..." | Up 5 minutes | 0.0.0.0:9093->9093/tcp |
| c92a21de7734  | grafana/grafana:latest   | "/run.sh"               | Up 5 minutes | 0.0.0.0:3000->3000/tcp |

#### Port Ownership

`LISTEN 0      4096    0.0.0.0:9093    0.0.0.0:*    users:(("docker-proxy",pid=42112,fd=4))`

#### Prometheus logs

```
level=info ts=2026-01-27T19:43:12Z caller=rule_manager.go:520 msg="Loading rules" file=/etc/prometheus/rules/node-alerts.yml
level=info ts=2026-01-27T19:43:12Z caller=rule_manager.go:530 msg="Completed loading of rules"
level=info ts=2026-01-27T19:43:13Z caller=main.go:1010 msg="Server is ready to receive web requests."
```

#### Rules Visible in Container

```
total 16
drwxr-xr-x 2 root root 4096 Jan 27 19:42 .
drwxr-xr-x 4 root root 4096 Jan 27 19:40 ..
-rw-r--r-- 1 root root 1782 Jan 27 19:41 node-alerts.yml
-rw-r--r-- 1 root root 2013 Jan 27 19:41 node-extra-alerts.yml
```

#### Alert Test

`"InstanceDown"`

---

## Prevention

- Use a single orchestration method per service (Docker Compose only)

- Avoid mixing systemd-managed and container-managed monitoring services

- Document canonical configuration paths in runbooks

- Require `docker ps` and `ss -ltnp` validation before production changes

- Add deployment ownership notes to architecture docs

---

## Lessons Learned

Mixing deployment models introduces hidden operational complexity. Reliable observability depends on clearly defined service ownership, lifecycle management, and configuration authority. Before debugging application behavior, active processes and ports must be verified.
