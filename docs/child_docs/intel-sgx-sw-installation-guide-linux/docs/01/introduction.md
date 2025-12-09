---
description: Introduces the Intel SGX software stack and provides an overview of installation sources and supported Linux distributions.
keywords: Intel SGX, installation guide, Linux, SDK, PSW, DCAP, open source, attestation, software stack, introduction
---
<!---
Copyright (C) 2025 Intel Corporation
SPDX-License-Identifier: CC-BY-4.0
-->

# Introduction

This guide outlines the installation process of the Intel® Software Guard Extensions (Intel® SGX) software components, specifically:

- Intel® SGX Software Development Kit (Intel SGX SDK): Assists developers in creating applications that utilize Intel SGX.
- Intel® SGX Platform Software (Intel SGX PSW) for Linux\* OS: Provides software modules to run Intel® SGX applications on Linux\* OS.
- Intel® SGX/TDX Data Center Attestation Primitives (Intel SGX/TDX DCAP) for Linux\* OS: Provides software modules to perform application attestation.

This document focuses on the installation process for the following Linux distributions:

- CentOS\* Server
- Debian
- Red Hat\* Enterprise Linux\*
- SUSE Linux Enterprise Server
- Ubuntu\* Server

The source code for Intel® SGX software components is available on GitHub\* at at the following locations:

- Intel SGX SDK and Intel SGX PSW:
<https://github.com/intel/confidential-computing.sgx>
- Intel SGX/TDX DCAP:
<https://github.com/intel/confidential-computing.tee.dcap>

An overview of the all releases can be found at <https://download.01.org/intel-sgx/Releases/>.
Additionally, installation repositories for Intel SGX PSW and Intel SGX/TDX DCAP are provided for multiple OSes:

=== "Red Hat, CentOS, Anolis, and SUSE"
    Provided via tar file located at [https://download.01.org/intel-sgx/latest/linux-latest/distro/<distro\>/](https://download.01.org/intel-sgx/latest/linux-latest/distro/).

=== "Ubuntu and Debian"
    Provided as remote repository at <https://download.01.org/intel-sgx/sgx_repo/ubuntu/> and via tar file located at [https://download.01.org/intel-sgx/latest/linux-latest/distro/<distro\>/](https://download.01.org/intel-sgx/latest/linux-latest/distro/).
