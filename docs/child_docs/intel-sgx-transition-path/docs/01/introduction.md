---
description: This document outlines the key migration paths from Intel SGX to Intel TDX, covering terminology, strategic drivers, and the major transition scenarios for Confidential Computing workloads.
keywords: Intel SGX, Intel TDX, migration, transition path, Confidential Computing, Trust Domain Extension, SGX to TDX
---

# Introduction

Intel® Software Guard Extensions (Intel® SGX) was the founding technology for Confidential Computing in the data center starting in 2017.
With strong isolation of cryptographically attested application code or functions, it was adopted by security-focused developers across a range of usages and industries.
The ensuing years saw the introduction of Virtual Machine (VM)-isolation Confidential Computing technologies like Intel® Trust Domain Extensions (Intel® TDX), which quickly ramped due to their superior ease-of-use, flexibility, scalability, and lower TCO.

In October 2026, Intel disclosed it will focus future Confidential Computing investments exclusively on Intel TDX, and the next-gen Intel® Xeon® platform code-named "Diamond Rapids" will be the last to support Intel SGX.
With Intel SGX support well into the 2030s, developers have plenty of time to determine their migration strategy to Intel TDX and technologies like confidential containers.

Many customers used Intel SGX for its security characteristics: a minimal Trusted Computing Base (TCB) and cryptographic attestation of the enclave's software contents.
The following migration options offer benefits and trade-offs with respect to simplicity and security characteristics.

A practical migration begins by identifying the architecture of the Intel SGX application that should be moved to Intel TDX.
The next chapter, [Main Intel SGX Application Architectures](../02/main_intel_sgx_application_architectures.md), classifies the two common architectures of Intel SGX applications.
Afterwards, chapters [Transitioning Applications Based on a Library OS](../03/libos_transition_options.md) and [Transitioning Applications Based on the Intel SGX SDK](../04/sgx_sdk_transition_options.md) describe several likely migration paths for the two common architectures.
It is not an exhaustive list of possibilities but will show the major directions an organization could take.
The final chapter, [References and Technologies to Watch](../05/references_and_technologies_watch.md), then gathers the supporting material and emerging technologies that are relevant to the selected migration path.


## Terminology

The following terms and acronyms are used in this document.

::spantable:: class="st-w100p"

<!-- markdownlint-disable MD033 -->
| **Term** @class="w021p" | **Description** @class="w079p" |
| --- | --- |
| Intel SGX | Intel Software Guard Extensions. An Intel Confidential Computing technology that provides hardware isolation and attestation at the application level. |
| Intel SGX Enclave | Hardware-enforced Trusted Execution Environment when using Intel SGX. |
| Intel TDX | Intel Trust Domain Extensions. An Intel Confidential Computing technology that provides hardware isolation and attestation at the virtual machine level. |
| Trust Domain (TD) | Hardware-enforced Trusted Execution Environment when using Intel TDX. |
| Confidential Virtual Machine (CVM) | Hardware-enforced Trusted Execution Environment when using Intel TDX. Managed like other Virtual Machines on the system. In the context of Intel TDX, it may also be called a Trust Domain (TD). |
| Trusted Computing Base (TCB) | In this paper, the Trusted Computing Base refers to all software inside an Intel SGX Enclave or an Intel TDX Trust Domain. Software in the TCB may be cryptographically attested for integrity or simply assumed to be trusted. |
| Intel SGX SDK | Software Development Kit for Intel SGX. Provides developers tools to call Intel SGX functions and APIs directly from applications. |
| Library OS (LibOS) | In the context of this article, a Library OS is a lightweight, Intel SGX-enabled operating system personality that intermediates between an application and the Intel SGX functions and APIs. A Library OS allows applications to execute in the enclave with little or no modifications. |
| Confidential Container (CoCo) | [Confidential Containers (CoCo)](https://confidentialcontainers.org/) is an open-source project under the Cloud Native Computing Foundation that enables hardware-isolated and attested containers based on Kata container technology. In an Intel TDX context, Confidential Containers run as Trust Domains.<br/><br/>**A note on formatting**: This document uses the capitalization "Confidential Containers (CoCo)" when referring to the architecture specified by the Confidential Containers open-source project. If no capitalization is used, "confidential containers" is a generic concept not specifically affiliated with the CoCo project. |

::end-spantable::

/// table-caption
    attrs: {id: tab_table1}
Terminology
///
