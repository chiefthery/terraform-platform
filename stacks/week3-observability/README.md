# Week 3 — Observability Stack (Prometheus + Grafana + Alerting)

## What this builds
- Monitoring EC2 host
- Prometheus (Docker)
- Grafana (Docker)
- Alertmanager (Docker)
- Node Exporter on target hosts
- Alert rules and webhook integration

---

## Components

- Prometheus: metrics scraping and rule evaluation
- Grafana: dashboards
- Alertmanager: alert routing
- Node Exporter: host metrics
- Webhook receiver: alert sink

---

## Prerequisites

- Week 2 VPC stack deployed
- SSH access via bastion
- Docker + Compose available on monitoring host
- Target hosts running node_exporter

---

## How to run

### SSH to monitoring host

`ssh week3-monitoring`

### Install Docker (AL2023)

```
sudo dnf -y install docker docker-compose-plugin
sudo systemctl enable --now docker
sudo usermod -aG docker ec2-user
newgrp docker
```

### Start monitoring stack

```
cd /opt/monitoring
docker compose up -d
docker ps
```

---

## Validation

### Prometheus

`curl http://localhost:9090/-/ready`

Open:

`http://<monitoring-ip>:9090/targets`

All targets should be UP.

### Grafana

Open:

`http://<monitoring-ip>:3000`

Add Prometheus datasource and import dashboard.

### Node Exporter (on targets)

```
sudo ss -ltnp | grep :9100
curl http://localhost:9100/metrics | head
```

### Alertmanager

`sudo ss -ltnp | grep :9093`

---

## Teardown

`docker compose down`

(Optional)

`terraform destroy`

---

## Cost note

Monitoring host, NAT, and data transfer incur AWS charges. Destroy when idle.
