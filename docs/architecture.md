# Thatch - An Architectural Overview

### Platform Setup

Ansible installs and deploys Thatch's dependencies - that being the k3s cluster and the ArgoCD resources, so you can write and deploy your applications without worrying about a missing config.

### CI/CD

Thatch uses GitHub Actions for CI and ArgoCD to deploy its applications onto the k3s cluster - this is to avoid missing manual errors or discrepencies between WHAT is deployed in the cluster and WHAT actually exists on Git. 

### Security Tooling

Thatch subscribes to a security-first mindset, making sure vulnerable apps are detected and patched posthaste. 

**Kyverno** is used as a Policy-As-Code engine, acting as a valuable guardrail between a misconfigured application that was allowed to run as Root, and an attacker looking to exploit exactly that. 

**Falco** WIP
**Trivy** WIP

### Monitoring & Logging

**Grafana** WIP
**Prometheus** WIP
**Opensearch** WIP

### Secret Management

**TBD**