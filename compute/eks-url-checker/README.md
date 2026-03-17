# Kubernetes Deployment on Amazon EKS

## Overview

Deploys the URL checker application to Amazon EKS using both imperative (`kubectl run`) and declarative (YAML manifests) patterns. Demonstrates Kubernetes fundamentals — pods, deployments, services, and scaling.

## AWS Services Used

- **Amazon EKS** - Managed Kubernetes control plane
- **Amazon EC2** - Worker nodes (managed node group)
- **Amazon ECR** - Container image source
- **Elastic Load Balancing** - Kubernetes Service type LoadBalancer

## Architecture

```
┌──────────┐     HTTP     ┌─────────┐           ┌─────────────────────────┐
│  Client  │ ──────────> │   ELB   │ ────────> │  EKS Cluster            │
│          │             │         │           │                         │
└──────────┘             └─────────┘           │  ┌─────┐ ┌─────┐       │
                                               │  │Pod 1│ │Pod 2│       │
                                               │  └─────┘ └─────┘       │
                                               │  Deployment (replicas=2)│
                                               │  Managed Node Group     │
                                               └─────────────────────────┘
```

## Technical Highlights

- Imperative deployment: `kubectl run` and `kubectl expose`
- Declarative deployment: YAML manifests for Deployment and Service
- Replica scaling with `kubectl scale` and manifest updates
- Rolling update strategy for zero-downtime deployments
- `kubeconfig` setup with `aws eks update-kubeconfig`
- Comparison of imperative vs declarative Kubernetes management
