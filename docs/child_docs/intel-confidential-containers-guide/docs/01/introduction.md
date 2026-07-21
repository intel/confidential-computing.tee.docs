---
description: The Intel Confidential Containers Guide provides step-by-step instructions on how to use the Confidential Containers project to start an Intel TDX-protected application within a Kubernetes environment.
keywords: enabling guide, Intel TDX, Trust Domain Extension, Confidential Computing, Confidential Containers, introduction, overview
---
<!---
Copyright (C) 2024 Intel Corporation
SPDX-License-Identifier: CC-BY-4.0
-->

# Introduction

Kubernetes is a popular open-source platform for automating deployment, scaling, and managing containerized applications (pods).
The Confidential Containers (CoCo) open-source project aims to establish a standardized approach to Confidential Computing within Kubernetes pods. It utilizes the power of TEE, like Intel® TDX, to deploy secure containerized applications without requiring in-depth understanding of the Confidential Computing technology.


## Intended audience

This guide is intended for engineers and technical staff from Cloud Service Providers (CSPs), System Integrators (SIs), on-premises enterprises involved in cloud feature integration, as well as cloud guest users (i.e., end users).


## About this guide

This guide provides step-by-step instructions on configuring Confidential Containers on an Ubuntu 24.04 system within a Kubernetes environment.
Our intention is to give you a quick start guide to deploy Intel TDX-protected applications in a Kubernetes cluster, so that you can work on implementing this technology in your environment.

We assume that you have basic knowledge about [Kubernetes concepts](https://kubernetes.io/docs/concepts/) and that a Kubernetes cluster is already set up and running.
Refer to the [Kubernetes documentation](https://kubernetes.io/docs/setup/) for more information on setting up a Kubernetes cluster.
We tested the guide on a single-node Kubernetes cluster.
There might be some differences in the steps if you are using a multi-node cluster.

This guide also assumes that you have already [enabled and configured Intel® TDX](/intel-tdx-enabling-guide/01/introduction/) on each platform you wish to use as a worker node for your Kubernetes cluster.
The master node (aka control plane) does not need to have Intel® TDX enabled.
All provided steps should be executed on the master node if not specified otherwise.

This guide is divided into the following sections:

- [Infrastructure Setup](../02/infrastructure_setup.md): This section provides instructions on setting up the infrastructure in an existing Kubernetes cluster to be able to run Intel TDX-protected applications.
- [Demo Workload Deployment](../03/demo_workload_deployment.md): This section provides instructions on deploying a sample Intel TDX-protected application in the configured Kubernetes cluster.
- [Troubleshooting](../04/troubleshooting.md): This section provides instructions on troubleshooting common issues that may arise following the steps in this guide.


## Scope

This guide covers the following operating system:

- Ubuntu 24.04

The guide was tested on the following hardware:

- 4th Gen Intel® Xeon® Scalable processors
- 5th Gen Intel® Xeon® Scalable processors
- 6th Gen Intel® Xeon® Scalable processors

## Further reading

For more information on the projects mentioned in this guide, refer to the following resources:

- [Confidential Containers project](https://confidentialcontainers.org/)
- [Kata Containers project](https://katacontainers.io/)
- [Introducing Confidential Containers Trustee: Attestation Services Solution Overview and Use Cases](https://www.redhat.com/en/blog/introducing-confidential-containers-trustee-attestation-services-solution-overview-and-use-cases)
- [Nydus Snapshotter](https://github.com/containerd/nydus-snapshotter)
