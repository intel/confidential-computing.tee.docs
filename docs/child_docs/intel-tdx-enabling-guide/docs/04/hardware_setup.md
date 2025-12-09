---
description: To use Intel® TDX, specific hardware configurations are needed. This includes the installation of an Intel TDX-enabled BIOs and the correct BIOS settings.
keywords: enabling guide, Intel TDX, Trust Domain Extension, Confidential Computing, hardware setup, hardware configuration
---
<!---
Copyright (C) 2024 Intel Corporation
SPDX-License-Identifier: CC-BY-4.0
-->

# Hardware Setup

On this page, we will present the settings that are necessary to setup the hardware for Intel TDX.
We assume that the [proper hardware is present](../03/hardware_selection.md).
At the moment, it is only necessary to [install an Intel TDX-enabled BIOS](#install-intel-tdx-enabled-bios), [enable Intel TDX in the BIOS](#enable-intel-tdx-in-bios), and optionally [deploy a specific Intel TDX Module version](#deploy-specific-intel-tdx-module-version).


## Install Intel TDX-enabled BIOS

To use Intel TDX, a BIOS supporting the functionality is needed.
Please reach out to your OEM/ODM or independent BIOS vendor to learn if such a BIOS is available and follow the corresponding installation instructions.


## Enable Intel TDX in BIOS

Specific BIOS settings are needed to support Intel TDX.
In the following, we present BIOS settings for specific machines and processor generations.
Afterwards, we briefly describe these BIOS settings.

!!! note

    The necessary BIOS settings or the menus might differ based on the platform that is used.
    Please reach out to your OEM/ODM or independent BIOS vendor for instructions dedicated for your BIOS.

!!! warning

    It might be necessary to [enable Intel TDX on the host OS](../05/host_os_setup.md#enable-intel-tdx-in-the-host-os), before Intel TDX is enabled in the BIOS.

!!! info "BIOS settings for a Quanta S6Q system with 5th Gen Intel® Xeon® Scalable processors"

    ``` mermaid
    %%{ init: { "flowchart": { "curve": "step", "nodeSpacing": 20, "rankSpacing": 30 } } }%%
    flowchart LR
    SC[Socket<br />Configuration];
    SC --> PC[Processor<br />Configuration];
    PC --> B1["Memory Encryption (TME)"] --> B2[Enabled];
    PC --> C1["Total Memory Encryption<br />(TME) Bypass"] --> C2[Disabled];
    PC --> D1["Total Memory Encryption<br />Multi-Tenant (TME-MT)"] --> D2[Enabled];
    PC --> E1["Memory integrity"] --> E2[Enabled or<br />Disabled];
    PC --> F1["Trust Domain Extension (TDX)"] --> F2[Enabled];
    PC --> G1["TDX Secure Arbitration<br />Mode Loader (SEAM Loader)"] --> G2[Enabled];
    PC --> H1[TME-MT/TDX key split] --> H2[Non-zero value]
    PC --> I1["SW Guard Extensions (SGX)"] --> I2[Enabled];
    PC --> J1[SGX PRM Size] --> J2[Whatever size<br />needed];
    ```

!!! info "BIOS settings for a Beechnut City system with Intel® Xeon® 6 processors"

    ``` mermaid
    %%{ init: { "flowchart": { "curve": "step", "nodeSpacing": 20, "rankSpacing": 30 } } }%%
    flowchart LR
    SC[Socket<br />Configuration];
    SC --> SeC[Security<br />Configuration];
    SeC --> A1["Memory Encryption (TME)"] --> A2[Enabled];
    SeC --> B1["Total Memory Encryption<br />Multi-Tenant (TME-MT)"] --> B2[Enabled];
    SeC --> D1["Memory integrity"] --> D2[Enabled or<br />Disabled];
    SeC --> F1["Trust Domain Extension (TDX)"] --> F2[Enabled];
    SeC --> G1["TDX Secure Arbitration<br />Mode Loader (SEAM Loader)"] --> G2[Enabled];
    SeC --> H1[TME-MT/TDX key split] --> H2[Non-zero value]
    SeC --> I1["SW Guard Extensions (SGX)"] --> I2[Enabled];
    SeC --> J1[SGX PRMRR Size] --> J2[Whatever size<br />needed];
    SC --> P1[Uncore<br />Configuration] --> P2[Uncore General<br />Configuration] --> P3[Limit CPU<br />PA to 46 bits] --> P4[Disabled]
    ```

Explanation of BIOS settings:

| BIOS setting | Notes |
| :----------- | :---- |
| Volatile Memory Mode | Defines how memory is connected to the system. |
| Memory Encryption (TME) | Activates/deactivates Intel® Total Memory Encryption, which is a prerequisite for Intel® Total Memory Encryption–Multi-Key (Intel TME-MK). |
| Total Memory Encryption (TME) Bypass | Activates/deactivates the Intel TME bypass mode. This mode allows memory outside of Intel TME-MK VMs, Intel SGX enclaves, and Intel TDX Trust Domains to be unencrypted to improve the performance of non-confidential software. |
| Total Memory Encryption Multi-Tenant (TME-MT) | Activates/deactivates Intel® Total Memory Encryption–Multi-Key (Intel TME-MK), which is used by Intel TDX for the main memory encryption. |
| Memory integrity | If disabled, only Logical Integrity (SW integrity) is used for main memory protection. If enabled, Cryptographic Integrity (HW integrity) is also used for main memory protection. NOTE: Enabling Cryptographic Integrity requires DIMMs with specific specs to be installed. |
| Trust Domain Extension (TDX) | Activates/deactivates Intel TDX. |
| TDX Secure Arbitration Mode Loader (SEAM Loader) | Defines from where the Intel TDX Module is loaded. |
| TME-MT/TDX key split | Defines how many keys are used for Intel TME-MK and how many for Intel TDX. |
| SW Guard Extensions (SGX) | Activates/deactivates Intel SGX, which is used by Intel TDX for remote attestation. |
| SGX PRM/PRMRR Size | Defines the size of the Processor Reserved Memory (PRM), which is used by Intel SGX to hold enclaves and related protected data structures. A minimum SGX PRM is required to run the Quote Generation Service (QGS) on the host OS (or inside a dedicated VM). |


## Deploy Specific Intel TDX Module Version

Once you [install a BIOS with Intel TDX support](#install-intel-tdx-enabled-bios), it will include an Intel TDX Module and a corresponding Intel TDX Loader.
To get other versions of the Intel TDX Module, you have two options:

1. Update Intel TDX Module via BIOS update.
2. Update Intel TDX Module via binary deployment.

In the following subsections, we provide more details on these two update variants.
Independent of the used variant, please consider the following details:

- Different platforms might require different Intel TDX Module binaries.
- With the both of these Intel TDX Module update variants, a system reboot is required.
    Accordingly, all running VMs or TDs have to be stopped before updating.
- Installing a specific Intel TDX Module version will make use of the Intel TDX Loader already present in the system BIOS even if updating via binary deployment.


### Update Intel TDX Module via BIOS update

Steps:

- Reach out to your OEM/ODM or Independent BIOS Vendor (IBV) to ask for a BIOS containing another version of the Intel TDX Module.
- Once available, retrieve the BIOS update.
- Flash BIOS update according the instructions of the BIOS provider.


### Update Intel TDX Module via Binary Deployment

Steps:

1. Download the Intel TDX Module binary:

    === "Latest"
        Download an archive containing the binary of the latest Intel TDX Module version and a corresponding signature structure.
        ``` { .bash }
        wget -O intel_tdx_module.tar.gz \
            https://github.com/intel/confidential-computing.tdx.tdx-module/releases/latest/download/intel_tdx_module.tar.gz
        ```

    === "Specific Version"
        To download a specific version of an Intel TDX Module and a corresponding signature structure, navigate to the [releases page of the Intel TDX Module](https://github.com/intel/confidential-computing.tdx.tdx-module/releases).
        Download the archive `intel_tdx_module.tar.gz` from the release you want to use.

2. Unpack the downloaded archive:

    ``` { .bash }
    tar -xvzf intel_tdx_module.tar.gz
    ```

3. If not done before, create an EFI directory:

    ``` { .bash }
    sudo mkdir -p /boot/efi/EFI/TDX/
    ```

4. Copy the Intel TDX Module binary and the corresponding signature structure to the EFI directly created in step 3.

    ``` { .bash }
    sudo cp TDX-Module/intel_tdx_module.so \
        /boot/efi/EFI/TDX/TDX-SEAM.so
    sudo cp TDX-Module/intel_tdx_module.so.sigstruct \
        /boot/efi/EFI/TDX/TDX-SEAM.so.sigstruct
    ```

5. Check that the copied files are present in `/boot/efi/EFI/TDX/` with a current date:

    ``` { .bash }
    sudo ls -ls /boot/efi/EFI/TDX/
    ```

6. Reboot your machine.

??? info "How to reproduce an Intel TDX Module binary?"
    Every [Intel TDX Module release](https://github.com/intel/confidential-computing.tdx.tdx-module/releases) comes with corresponding build instructions.
    Please follow these build instructions.

??? info "How to run an Intel TDX Module build from source?"
    You cannot run an Intel TDX Module build from source, because only binaries officially released and signed by Intel are allowed to run.
    Intel does not provide an environment to use Intel TDX with non-signed binaries.
