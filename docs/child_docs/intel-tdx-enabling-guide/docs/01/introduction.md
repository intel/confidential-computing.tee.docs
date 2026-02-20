---
description: The Intel TDX Enabling Guide offers comprehensive instructions for the entire Intel TDX enablement workflow from infrastructure setup, hardware selection, hardware setup, host OS setup, guest OS setup to runtime topics.
keywords: enabling guide, Intel TDX, Trust Domain Extension, Confidential Computing, introduction, overview
---
<!---
Copyright (C) 2024 Intel Corporation
SPDX-License-Identifier: CC-BY-4.0
-->

# Introduction

This Intel® TDX enabling guide provides a distilled set of instructions for integrating, deploying, and using Intel® Trust Domain Extensions (Intel TDX).
Among other things, it covers essential prerequisites, integration steps, testing procedures, performance measurement, and maintenance steps.
In the following, we provide a brief introduction to Intel TDX.
More specific details and explanations are covered in [dedicated specification documents and other documentation](https://www.intel.com/content/www/us/en/developer/tools/trust-domain-extensions/documentation.html).


## What is Intel TDX?

Intel TDX is Intel's newest Confidential Computing technology.
The Trusted Execution Environment (TEE) provided by Intel TDX provides hardware isolation of individual Virtual Machines (VMs) designed to protect sensitive data and applications from unauthorized access.
VMs protected by Intel TDX are called Trust Domains (TDs).

A CPU-measured Intel TDX Module enables Intel TDX.
This software module runs in a new CPU Secure Arbitration Mode (SEAM) as a peer to the Virtual Machine Manager (VMM), and it supports TD entries and exits using the existing virtualization infrastructure.
The module is hosted in a reserved memory space identified by the SEAM Range Register (SEAMRR).

Intel TDX uses hardware extensions for managing and encrypting memory and it protects both the confidentiality and integrity of the TD CPU state from all software in non-SEAM mode.
Intel TDX also uses architectural elements such as SEAM, a shared bit in Guest Physical Address (GPA), secure Extended Page Table (EPT), physical-address-metadata table, Intel® Total Memory Encryption – Multi-Key (Intel® TME-MK), and remote attestation.

Intel TDX is designed to ensure data integrity, confidentiality, and authenticity, which empowers engineers and tech professionals to create and maintain more secure systems, enhancing trust in virtualized environments.


## Intended Audience

This guide is for engineers and technical staff from Cloud Service Providers (CSPs), System Integrators (SIs), on-premises enterprises involved in cloud feature integration, as well as cloud guest users (i.e., end users).
Throughout this document, we use CSPs as examples for brevity.


## Scope

In its current version, this guide is for Intel TDX on 5th Gen Intel® Xeon® Scalable processors and Intel® Xeon® 6 processors.
The following Intel TDX features are currently supported in this guide:

- Launching a TD
- Shutting down a TD
- Attesting a TD

Additional features may be added to this guide in the future, as the features become available in the ecosystem.
Examples include:

- TD Preserving Updates
- TD Live Migration
- TD Partitioning
- Intel® TDX Connect


## Reading Guideline

This guide encompasses the entire workflow of an Intel TDX deployment as illustrated in the following figure, and the guide is structured accordingly with every step in the workflow having a dedicated page.

``` mermaid
graph LR
    %%{init:{'themeVariables':{'fontSize':'20px'},'flowchart':{'diagramPadding':0,'padding':0}}}%%
    A("<p style='width:120px'>Infrastructure<br/>Setup</p>")
    B("<p style='width:120px'>Hardware<br/>Selection</p>")
    C("<p style='width:120px'>Hardware<br/>Setup</p>")
    D("<p style='width:120px'>Host OS<br/>Setup</p>")
    E("<p style='width:120px'>Guest OS<br/>Setup</p>")
    F("<p style='width:120px'>Trust Domain<br/>at Runtime</p>")
    A:::boxes --> B
    B:::boxes --> C
    C:::boxes --> D
    D:::boxes --> E
    E:::boxes --> F:::boxes
    classDef boxes fill:#85b4ff,stroke-width:0px
```

Depending on the target offering, the different steps are covered by employees of the provider of the offering or by the end user.
In the following, we show cases that might happen in a concrete Intel TDX implementation project.
Note these examples are just for illustrative purposes and the situation might be different in your case.

- Bare metal offering:

    ``` mermaid
    graph LR
        %%{init:{'themeVariables':{'fontSize':'20px'},'flowchart':{'diagramPadding':0,'padding':0}}}%%
        A("<p style='width:120px'>Infrastructure<br/>Setup</p>")
        B("<p style='width:120px'>Hardware<br/>Selection</p>")
        C("<p style='width:120px'>Hardware<br/>Setup</p>")
        D("<p style='width:120px'>Host OS<br/>Setup</p>")
        E("<p style='width:120px'>Guest OS<br/>Setup</p>")
        F("<p style='width:120px'>Trust Domain<br/>at Runtime</p>")
        A:::boxProv --> B
        B:::boxProv --> C
        C:::boxProv --> D
        D:::boxProv --> E
        E:::boxUser --> F:::boxUser
        classDef boxProv fill:#ffc000,stroke-width:0px
        classDef boxUser fill:#92d050,stroke-width:0px
    ```

    ``` mermaid
    graph LR
        %%{init:{'flowchart':{'diagramPadding':0,'padding':6}}}%%
        A(" "):::boxProv --- |Provider| B
        B(" "):::boxUser --- |User| C(" "):::hidden

        classDef boxProv fill:#ffc000,stroke-width:0px
        classDef boxUser fill:#92d050,stroke-width:0px
        classDef hidden fill:#FFFFFF,stroke-width:0px,visibility:hidden

        linkStyle 0,1 stroke-width:0px,background-color:black;
    ```

- Virtual machine offering:

    ``` mermaid
    graph LR
        %%{init:{'themeVariables':{'fontSize':'20px'},'flowchart':{'diagramPadding':0,'padding':0}}}%%
        A("<p style='width:120px'>Infrastructure<br/>Setup</p>")
        B("<p style='width:120px'>Hardware<br/>Selection</p>")
        C("<p style='width:120px'>Hardware<br/>Setup</p>")
        D("<p style='width:120px'>Host OS<br/>Setup</p>")
        E("<p style='width:120px'>Guest OS<br/>Setup</p>")
        F("<p style='width:120px'>Trust Domain<br/>at Runtime</p>")
        A:::boxProv --> B
        B:::boxProv --> C
        C:::boxProv --> D
        D:::boxProv --> E
        E:::boxProv --> F:::boxUser
        classDef boxProv fill:#ffc000,stroke-width:0px
        classDef boxUser fill:#92d050,stroke-width:0px
    ```

    ``` mermaid
    graph LR
        %%{init:{'flowchart':{'diagramPadding':0,'padding':6}}}%%
        A(" "):::boxProv --- |Provider| B
        B(" "):::boxUser --- |User| C(" "):::hidden

        classDef boxProv fill:#ffc000,stroke-width:0px
        classDef boxUser fill:#92d050,stroke-width:0px
        classDef hidden fill:#FFFFFF,stroke-width:0px,visibility:hidden

        linkStyle 0,1 stroke-width:0px,background-color:black;
    ```

- Platform service offering:

    ``` mermaid
    graph LR
        %%{init:{'themeVariables':{'fontSize':'20px'},'flowchart':{'diagramPadding':0,'padding':0}}}%%
        A("<p style='width:120px'>Infrastructure<br/>Setup</p>")
        B("<p style='width:120px'>Hardware<br/>Selection</p>")
        C("<p style='width:120px'>Hardware<br/>Setup</p>")
        D("<p style='width:120px'>Host OS<br/>Setup</p>")
        E("<p style='width:120px'>Guest OS<br/>Setup</p>")
        F("<p style='width:120px'>Trust Domain<br/>at Runtime</p>")
        A:::boxProv --> B
        B:::boxProv --> C
        C:::boxProv --> D
        D:::boxProv --> E
        E:::boxProv --> F:::boxProv
        classDef boxProv fill:#ffc000,stroke-width:0px
        classDef boxUser fill:#92d050,stroke-width:0px
    ```

    ``` mermaid
    graph LR
        %%{init:{'flowchart':{'diagramPadding':0,'padding':6}}}%%
        A(" "):::boxProv --- |Provider| B
        B(" "):::boxUser --- |User| C(" "):::hidden

        classDef boxProv fill:#ffc000,stroke-width:0px
        classDef boxUser fill:#92d050,stroke-width:0px
        classDef hidden fill:#FFFFFF,stroke-width:0px,visibility:hidden

        linkStyle 0,1 stroke-width:0px,background-color:black;
    ```

Please read the pages that are most suitable for your target offering and your persona.
