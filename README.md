# Inception Of Things

**Inception Of Things** is a reproducible local Kubernetes lab and GitOps demo platform designed to showcase end-to-end infrastructure provisioning, application deployment, and GitOps-driven CI/CD workflows. The project uses a `Vagrantfile` for repeatable VM provisioning, lightweight Kubernetes distributions (`k3d` / `k3s`) for cluster creation, and GitLab + Argo CD to demonstrate continuous delivery and GitOps patterns for on-prem testing.

---

## Key highlights
- Reproducible local lab environment using `Vagrant` for VM lifecycle management.  
- Lightweight Kubernetes clusters with `k3d` / `k3s` for fast iteration and testing.  
- GitLab CI/CD pipelines that build and push container images and manifest changes.  
- Argo CD for GitOps-driven application delivery and automated sync between Git and cluster.  
- Example apps and manifests to demonstrate service deployment, configuration, and rollbacks.

---

## Architecture (high level)
1. **Vagrant VMs** — provide a controlled host environment that mimics nodes/edge servers.  
2. **k3d / k3s clusters** — lightweight clusters running inside the VMs (or locally) for development/testing.  
3. **GitLab** — stores source code, container images and triggers CI/CD pipelines.  
4. **Argo CD** — watches Git repositories and enforces the desired state on the cluster (GitOps).  
5. **Example workloads** — simple services and manifests that illustrate build → deploy → observe flows.

---

## Prerequisites
Install the following on your machine:
- `vagrant` and a provider (VirtualBox / libvirt)  
- `docker`  
- `kubectl`  
- `k3d` (or `k3s` if you prefer native)  
- `helm` (optional, for charts)  
- `git`  
- A GitLab instance (local or hosted) and Argo CD access to deploy apps

---

## Quickstart (recommended flow)
> The repo includes helper scripts — adjust names to match the ones in the `scripts/` folder if needed.

1. **Clone the repo**
```bash
git clone https://github.com/peler1nl1kelt0s/inception-of-things.git
cd inception-of-things
