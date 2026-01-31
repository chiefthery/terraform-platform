# Week 3 — Observability (Systems Thinking)

## Goal
Introduce full-stack observability to validate infrastructure health, detect failures early, and enable automated remediation. This week adds monitoring, alerting, and visualization to the platform.

---

## Architecture Overview

### Components

| Layer | Tool | Purpose |
|-------|------|---------|
| Metrics | Prometheus | Scraping + rule evaluation |
| Exporters | Node Exporter | Host telemetry |
| Visualization | Grafana | Dashboards |
| Alerting | Alertmanager | Notification routing |
| Automation | Webhook | Alert processing |

### Deployment Model

- Monitoring stack runs on dedicated EC2 host
- Services orchestrated via Docker Compose
- Target hosts expose metrics on port 9100
- Configuration mounted via volumes

---

## Data Flow

### Metrics

Node Exporter → Prometheus → Grafana

### Alerts

Prometheus Rules → Alertmanager → Webhook Receiver

### Admin Access

Admin → Bastion → Monitoring Host

---

## Network Design

| Source | Destination | Port | Purpose |
|--------|-------------|------|---------|
| Prometheus | Targets | 9100 | Scraping |
| Admin | Prometheus | 9090 | UI |
| Admin | Grafana | 3000 | Dashboards |
| Prometheus | Alertmanager | 9093 | Alerts |

All access routes through the Week 2 bastion model.

---

## Security Model

- Monitoring host isolated in private subnet
- Access only via bastion
- No public exposure of targets
- Principle of least privilege via SG chaining
- Container services isolated from host OS

---

## Key Design Decisions

### Why Prometheus

- Pull-based model
- Native alert rules
- Kubernetes/cloud compatibility
- Industry standard

### Why Docker Compose

- Reproducible deployments
- Clear service ownership
- Version-controlled configs
- Easy teardown

### Why Dedicated Monitoring Host

- Limits blast radius
- Simplifies scaling
- Separates concerns

---

## Verification Framework

### Metrics

- Targets show UP
- Scrape latency stable
- Exporter endpoints reachable

### Visualization

- Dashboards render
- Queries return expected series

### Alerting

- Rules load successfully
- Test failures trigger alerts
- Webhook receives payloads

---

## Failure Modes Encountered

| Incident | Description |
|----------|-------------|
| IR-001 | Grafana access blocked |
| IR-002 | Targets not scraped |
| IR-003 | Automation access failure |
| IR-004 | Duplicate service conflicts |

Full reports in `docs/incidents/`.

---

## Automation Integration

Monitoring enables:
- Health-based remediation
- Ansible-triggered recovery
- Capacity planning
- SLA tracking

This layer closes the loop between infrastructure and operations.

---

## How This Enables Scaling

Week 3 establishes:
- Baseline SLO measurement
- Incident detection
- Root-cause tooling
- Production readiness

Future extensions:
- Auto-scaling
- Managed Prometheus
- Centralized logging
- Multi-region monitoring

---

## Enterprise Relevance

This design mirrors:
- SRE observability stacks
- NOC monitoring systems
- Cloud operations centers
- Regulated infrastructure monitoring

It provides the foundation for resilient, self-healing platforms.
