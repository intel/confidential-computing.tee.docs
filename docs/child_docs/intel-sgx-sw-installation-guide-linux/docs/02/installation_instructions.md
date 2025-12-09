---
description: Step-by-step instructions for installing Intel SGX software components on various Linux distributions, including SDK, PSW, and DCAP.
keywords: Intel SGX, installation guide, Linux, SDK, PSW, DCAP, Ubuntu, Red Hat, CentOS, Debian, SUSE, software installation
---
<!---
Copyright (C) 2025 Intel Corporation
SPDX-License-Identifier: CC-BY-4.0
-->

# Installation Instructions

This section is designed to provide quick setup instructions to help with configuring a platform to support Intel® SGX for a variety of usages -- running an Intel SGX application, building and running an Intel SGX application, or building the Intel SGX software stack.
For details about software packages used for Intel® SGX and Intel® TDX, see the [Software Packages](../03/software-packages.md) chapter.


## Driver Installation

The Linux\* kernel contains the necessary driver since the mainline kernel release 5.11.
Accordingly, a driver installation is no longer necessary in Linux OSes with a newer kernel.
The resulting device node is located at `/dev/{sgx_enclave, sgx_provision}`.
Note that the platform needs to support Flexible Launch Control and it must be configured.

??? info "What is Flexible Launch Control?"

    All platforms since the 3rd Gen Intel® Xeon® Scalable Processor support Flexible Launch Control, officially known as SGX Launch Control.
    On such platforms, the Intel SGX driver dynamically reconfigures the launch control MSRs for each enclave loaded, so that the enclave does not need a valid Launch Token to run.
    See section "Intel® SGX Launch Control Configuration" in the Intel® 64 and IA-32 Architectures Software Developer Manuals](https://software.intel.com/en-us/articles/intel-sdm) for more information.


## Software Installation based on Use Case

The procedure for configuring a platform with the necessary Intel® SGX software components depends on the intended use of the platform.
In the following sections, we describe the installation steps for different use cases:

- Start an application that uses an Intel® SGX enclave: Section [Intel® SGX Application User](#intel-sgx-application-user).
- Build or develop an application that uses an Intel® SGX enclave: Section [Intel® SGX Application Developer](#intel-sgx-application-developer).
- Build or develop the Intel SGX software stack, i.e., the Intel SGX SDK, the Intel SGX PSW, or Intel SGX/TDX DCAP: Section [Intel® SGX Software Stack Developer or Builder](#building-the-intel-sgx-software-stack).


### Intel® SGX Application User

To start an application that uses an Intel® SGX enclave, install the necessary packages from the Intel® SGX Platform Software (Intel® SGX PSW) and Intel® SGX/TDX DCAP.

#### Install Packages

=== "Debian"

    Follow the steps below to install the primary Intel® SGX packages: `libsgx-quote-ex` and `libsgx-dcap-ql`.

    ??? info "Dependent packages automatically installed"
        Installing the primary Intel® SGX packages (`libsgx-quote-ex` and `libsgx-dcap-ql`) will also automatically install the following dependent packages required for SGX functionality:

        - `libsgx-ae-le`
        - `libsgx-ae-pce`
        - `libsgx-ae-qe3`
        - `libsgx-ae-qve`
        - `libsgx-aesm-ecdsa-plugin`
        - `libsgx-aesm-quote-ex-plugin`
        - `libsgx-dcap_quote-verify`
        - `libsgx-enclave-common`
        - `libsgx-pce-logic`
        - `libsgx-qe3-logic`
        - `libsgx-urts`
        - `sgx-aesm-service`

    - Download the correct repository archive:

        === "Debian 12"
            ```bash
            curl -fsSLO \
                https://download.01.org/intel-sgx/latest/linux-latest/distro/Debian12/sgx_debian_local_repo.tgz
            ```

        === "Debian 10"
            ```bash
            curl -fsSLO \
                https://download.01.org/intel-sgx/latest/linux-latest/distro/Debian10/sgx_debian_local_repo.tgz
            ```

    - Verify that the repository archive has the expected, publicly-available checksum:

        === "Debian 12"
            ```bash
            local_sum=$(sha256sum sgx_debian_local_repo.tgz | awk '{print $1}')
            remote_sum=$(curl -s https://download.01.org/intel-sgx/latest/dcap-latest/linux/SHA256SUM_dcap_1.24.cfg | grep 'distro/Debian12/sgx_debian_local_repo.tgz' | awk '{print $1}')
            if [[ "$local_sum" == "$remote_sum" ]]; then echo "Checksum matches"; else echo "Checksum mismatch!"; fi
            ```

        === "Debian 10"
            ```bash
            local_sum=$(sha256sum sgx_debian_local_repo.tgz | awk '{print $1}')
            remote_sum=$(curl -s https://download.01.org/intel-sgx/latest/dcap-latest/linux/SHA256SUM_dcap_1.24.cfg | grep 'distro/Debian10/sgx_debian_local_repo.tgz' | awk '{print $1}')
            if [[ "$local_sum" == "$remote_sum" ]]; then echo "Checksum matches"; else echo "Checksum mismatch!"; fi
            ```

    - Extract the repository archive to an appropriate folder, e.g., `/opt/intel`:

        === "Debian 12"
            ```bash
            sudo mkdir -p /opt/intel
            sudo tar xzf sgx_debian_local_repo.tgz -C /opt/intel
            ```

        === "Debian 10"
            ```bash
            sudo mkdir -p /opt/intel
            sudo tar xzf sgx_debian_local_repo.tgz -C /opt/intel
            ```

    - Add local repository to your system's list of package sources:

        === "Debian 12"
            ```bash
            echo 'deb [signed-by=/etc/apt/keyrings/intel-sgx-keyring.asc arch=amd64] file:///opt/intel/sgx_debian_local_repo bookworm main' \
                | sudo tee /etc/apt/sources.list.d/sgx_debian_local_repo.list
            ```

        === "Debian 10"
            ```bash
            echo 'deb [signed-by=/usr/share/keyrings/intel-sgx-keyring.asc arch=amd64] file:///opt/intel/sgx_debian_local_repo buster main' \
                | sudo tee /etc/apt/sources.list.d/sgx_debian_local_repo.list
            ```

    - Add the public key of the package repository to the list of trusted keys that are used by `apt` to authenticate packages:

        === "Debian 12"
            ```bash
            sudo cp /opt/intel/sgx_debian_local_repo/keys/intel-sgx.key /etc/apt/keyrings/intel-sgx-keyring.asc
            ```

        === "Debian 10"
            ```bash
            sudo cp /opt/intel/sgx_debian_local_repo/keys/intel-sgx.key /usr/share/keyrings/intel-sgx-keyring.asc
            ```

    - Update the package index and install the required packages:

        === "Debian 12"
            ```bash
            sudo apt-get update
            sudo apt-get install libsgx-quote-ex libsgx-dcap-ql
            ```

        === "Debian 10"
            ```bash
            sudo apt-get update
            sudo apt-get install libsgx-quote-ex libsgx-dcap-ql
            ```

    - **(Optional)** To debug with `sgx-gdb`, install the debug symbol packages:

        === "Debian 12"
            ```bash
            sudo apt-get install \
                libsgx-aesm-ecdsa-plugin-dbgsym \
                libsgx-aesm-launch-plugin-dbgsym \
                libsgx-aesm-pce-plugin-dbgsym \
                libsgx-aesm-quote-ex-plugin-dbgsym \
                libsgx-dcap-default-qpl-dbgsym \
                libsgx-dcap-ql-dbgsym \
                libsgx-dcap-quote-verify-dbgsym \
                libsgx-enclave-common-dbgsym \
                libsgx-launch-dbgsym \
                libsgx-pce-logic-dbgsym \
                libsgx-qe3-logic-dbgsym \
                libsgx-quote-ex-dbgsym \
                libsgx-ra-network-dbgsym \
                libsgx-ra-uefi-dbgsym \
                libsgx-tdx-logic-dbgsym \
                libsgx-uae-service-dbgsym \
                libsgx-urts-dbgsym \
                libtdx-attest-dbgsym \
                sgx-aesm-service-dbgsym \
                sgx-pck-id-retrieval-tool-dbgsym \
                sgx-ra-service-dbgsym \
                tdx-qgs-dbgsym \
                tee-appraisal-tool-dbgsym
            ```

        === "Debian 10"
            ```bash
            sudo apt-get install \
                libsgx-aesm-ecdsa-plugin-dbgsym \
                libsgx-aesm-launch-plugin-dbgsym \
                libsgx-aesm-pce-plugin-dbgsym \
                libsgx-aesm-quote-ex-plugin-dbgsym \
                libsgx-dcap-default-qpl-dbgsym \
                libsgx-dcap-ql-dbgsym \
                libsgx-dcap-quote-verify-dbgsym \
                libsgx-enclave-common-dbgsym \
                libsgx-launch-dbgsym \
                libsgx-pce-logic-dbgsym \
                libsgx-qe3-logic-dbgsym \
                libsgx-quote-ex-dbgsym \
                libsgx-ra-network-dbgsym \
                libsgx-ra-uefi-dbgsym \
                libsgx-tdx-logic-dbgsym \
                libsgx-uae-service-dbgsym \
                libsgx-urts-dbgsym \
                libtdx-attest-dbgsym \
                sgx-aesm-service-dbgsym \
                sgx-pck-id-retrieval-tool-dbgsym \
                sgx-ra-service-dbgsym \
                tdx-qgs-dbgsym \
                tee-appraisal-tool-dbgsym
            ```

    - **(Optional)** If you intend to run an application that uses an Intel® SGX enclave requiring the Provision Key Access, your user needs to be added to the group `sgx_prv`.
        Note that any enclave obtaining an SGX Quote using the DCAP Quote Generation Library requires this access.
        A user `<username>` can be added to the group with the following command:

        === "Debian 12"
            ```bash
            sudo usermod -aG sgx_prv <username>
            ```

        === "Debian 10"
            ```bash
            sudo usermod -aG sgx_prv <username>
            ```

=== "Red Hat and CentOS"

    Follow the steps below to install the primary Intel® SGX packages: `libsgx-urts`, `libsgx-quote-ex`, and `libsgx-dcap-ql`.

    ??? info "Dependent packages automatically installed"
        Installing the primary Intel® SGX packages (`libsgx-urts`, `libsgx-quote-ex`, and `libsgx-dcap-ql`) will also automatically install the following dependent packages required for SGX functionality:

        - `libsgx-ae-le`
        - `libsgx-ae-pce`
        - `libsgx-ae-qe3`
        - `libsgx-ae-qve`
        - `libsgx-aesm-ecdsa-plugin`
        - `libsgx-aesm-quote-ex-plugin`
        - `libsgx-dcap_quote-verify`
        - `libsgx-enclave-common`
        - `libsgx-pce-logic`
        - `libsgx-qe3-logic`
        - `sgx-aesm-service`

    - Download the correct repository archive:

        === "CentOS Stream 9"
            ```bash
            curl -fsSLO \
                https://download.01.org/intel-sgx/latest/linux-latest/distro/centos-stream9/sgx_rpm_local_repo.tgz
            ```

        === "Red Hat Enterprise Linux 9.4"
            ```bash
            curl -fsSLO \
                https://download.01.org/intel-sgx/latest/linux-latest/distro/rhel9.4-server/sgx_rpm_local_repo.tgz
            ```

    - Verify the downloaded repo file with the SHA value in this file:

        === "CentOS Stream 9"
            ```bash
            local_sum=$(sha256sum sgx_rpm_local_repo.tgz | awk '{print $1}')
            remote_sum=$(curl -s https://download.01.org/intel-sgx/latest/dcap-latest/linux/SHA256SUM_dcap_1.24.cfg | grep 'distro/centos-stream9/sgx_rpm_local_repo.tgz' | awk '{print $1}')
            if [[ "$local_sum" == "$remote_sum" ]]; then echo "Checksum matches"; else echo "Checksum mismatch!"; fi
            ```

        === "Red Hat Enterprise Linux 9.4"
            ```bash
            local_sum=$(sha256sum sgx_rpm_local_repo.tgz | awk '{print $1}')
            remote_sum=$(curl -s https://download.01.org/intel-sgx/latest/dcap-latest/linux/SHA256SUM_dcap_1.24.cfg | grep 'distro/rhel9.4-server/sgx_rpm_local_repo.tgz' | awk '{print $1}')
            if [[ "$local_sum" == "$remote_sum" ]]; then echo "Checksum matches"; else echo "Checksum mismatch!"; fi
            ```

    - Extract the repository archive to an appropriate folder, e.g., `/opt/intel`:

        === "CentOS Stream 9"
            ```bash
            sudo mkdir -p /opt/intel
            sudo tar xzf sgx_rpm_local_repo.tgz -C /opt/intel
            ```

        === "Red Hat Enterprise Linux 9.4"
            ```bash
            sudo mkdir -p /opt/intel
            sudo tar xzf sgx_rpm_local_repo.tgz -C /opt/intel
            ```

    - Add local repository to your system's list of package sources:

        === "CentOS Stream 9"
            ```bash
            sudo dnf config-manager --add-repo file:///opt/intel/sgx_rpm_local_repo
            ```

        === "Red Hat Enterprise Linux 9.4"
            ```bash
            sudo dnf config-manager --add-repo file:///opt/intel/sgx_rpm_local_repo
            ```

    - Add the public key of the package repository to the list of trusted keys that are used by `dnf` to authenticate packages:

        === "CentOS Stream 9"
            ```bash
            sudo rpm --import /opt/intel/sgx_rpm_local_repo/keys/intel-sgx.key
            sudo dnf config-manager --save --setopt=*sgx_rpm_local_repo.gpgkey=file:///opt/intel/sgx_rpm_local_repo/keys/intel-sgx.key
            ```

        === "Red Hat Enterprise Linux 9.4"
            ```bash
            sudo rpm --import /opt/intel/sgx_rpm_local_repo/keys/intel-sgx.key
            sudo dnf config-manager --save --setopt=*sgx_rpm_local_repo.gpgkey=file:///opt/intel/sgx_rpm_local_repo/keys/intel-sgx.key
            ```

    - Install the required packages with:

        === "CentOS Stream 9"
            ```bash
            sudo dnf install <package names>
            ```

        === "Red Hat Enterprise Linux 9.4"
            ```bash
            sudo dnf install <package names>
            ```

        For example, use:

        === "CentOS Stream 9"
            ```bash
            sudo dnf install libsgx-urts libsgx-quote-ex libsgx-dcap-ql
            ```

        === "Red Hat Enterprise Linux 9.4"
            ```bash
            sudo dnf install libsgx-urts libsgx-quote-ex libsgx-dcap-ql
            ```

    - **(Optional)** To debug with `sgx-gdb`, install the debug symbol packages.
        For example:

        === "CentOS Stream 9"
            ```bash
            sudo dnf install \
                libsgx-aesm-ecdsa-plugin-debuginfo \
                libsgx-aesm-launch-plugin-debuginfo \
                libsgx-aesm-pce-plugin-debuginfo \
                libsgx-aesm-quote-ex-plugin-debuginfo \
                libsgx-dcap-default-qpl-debuginfo \
                libsgx-dcap-ql-debuginfo \
                libsgx-dcap-quote-verify-debuginfo \
                libsgx-enclave-common-debuginfo \
                libsgx-launch-debuginfo \
                libsgx-pce-logic-debuginfo \
                libsgx-qe3-logic-debuginfo \
                libsgx-quote-ex-debuginfo \
                libsgx-ra-network-debuginfo \
                libsgx-ra-uefi-debuginfo \
                libsgx-tdx-logic-debuginfo \
                libsgx-uae-service-debuginfo \
                libsgx-urts-debuginfo \
                libtdx-attest-debuginfo \
                sgx-aesm-service-debuginfo \
                sgx-pck-id-retrieval-tool-debuginfo \
                sgx-ra-service-debuginfo \
                tdx-qgs-debuginfo
            ```

        === "Red Hat Enterprise Linux 9.4"
            ```bash
            sudo dnf install \
                libsgx-aesm-ecdsa-plugin-debuginfo \
                libsgx-aesm-launch-plugin-debuginfo \
                libsgx-aesm-pce-plugin-debuginfo \
                libsgx-aesm-quote-ex-plugin-debuginfo \
                libsgx-dcap-default-qpl-debuginfo \
                libsgx-dcap-ql-debuginfo \
                libsgx-dcap-quote-verify-debuginfo \
                libsgx-enclave-common-debuginfo \
                libsgx-launch-debuginfo \
                libsgx-pce-logic-debuginfo \
                libsgx-qe3-logic-debuginfo \
                libsgx-quote-ex-debuginfo \
                libsgx-ra-network-debuginfo \
                libsgx-ra-uefi-debuginfo \
                libsgx-tdx-logic-debuginfo \
                libsgx-uae-service-debuginfo \
                libsgx-urts-debuginfo \
                libtdx-attest-debuginfo \
                sgx-aesm-service-debuginfo \
                sgx-pck-id-retrieval-tool-debuginfo \
                sgx-ra-service-debuginfo \
                tdx-qgs-debuginfo
            ```

    - **(Optional)** If you intend to run an application that uses an Intel® SGX enclave requiring the Provision Key Access, your user needs to be added to the group `sgx_prv`.
        Note that any enclave obtaining an SGX Quote using the DCAP Quote Generation Library requires this access.
        A user `<username>` can be added to the group with the following command:

        === "CentOS Stream 9"
            ```bash
            sudo usermod -aG sgx_prv <username>
            ```

        === "Red Hat Enterprise Linux 9.4"
            ```bash
            sudo usermod -aG sgx_prv <username>
            ```

=== "SUSE Linux Enterprise Server"

    Follow the steps below to install the primary Intel® SGX packages: `libsgx-urts`, `libsgx-quote-ex`, and `libsgx-dcap-ql`.

    ??? info "Dependent packages automatically installed"
        Installing the primary Intel® SGX packages (`libsgx-urts`, `libsgx-quote-ex`, and `libsgx-dcap-ql`) will also automatically install the following dependent packages required for SGX functionality:

        - `libsgx-ae-le`
        - `libsgx-ae-pce`
        - `libsgx-ae-qe3`
        - `libsgx-ae-qve`
        - `libsgx-aesm-ecdsa-plugin`
        - `libsgx-aesm-quote-ex-plugin`
        - `libsgx-dcap_quote-verify`
        - `libsgx-enclave-common`
        - `libsgx-pce-logic`
        - `libsgx-qe3-logic`
        - `sgx-aesm-service`

    - Download the correct repository archive:

        === "SUSE Linux Enterprise Server 15 SP6"
            ```bash
            curl -fsSLO \
                https://download.01.org/intel-sgx/latest/linux-latest/distro/suse15.6-server/sgx_rpm_local_repo.tgz
            ```

    - Verify the downloaded repo file with the SHA value in this file:

        === "SUSE Linux Enterprise Server 15 SP6"
            ```bash
            local_sum=$(sha256sum sgx_rpm_local_repo.tgz | awk '{print $1}')
            remote_sum=$(curl -s https://download.01.org/intel-sgx/latest/dcap-latest/linux/SHA256SUM_dcap_1.24.cfg | grep 'distro/suse15.6-server/sgx_rpm_local_repo.tgz' | awk '{print $1}')
            if [[ "$local_sum" == "$remote_sum" ]]; then echo "Checksum matches"; else echo "Checksum mismatch!"; fi
            ```

    - Extract the repository archive to an appropriate folder, e.g., `/opt/intel`:

        === "SUSE Linux Enterprise Server 15 SP6"
            ```bash
            sudo mkdir -p /opt/intel
            sudo tar xzf sgx_rpm_local_repo.tgz -C /opt/intel
            ```

    - Add local repository to your system's list of package sources:

        === "SUSE Linux Enterprise Server 15 SP6"
            ```bash
            sudo zypper addrepo --gpgcheck /opt/intel/sgx_rpm_local_repo sgx_rpm_local_repo
            ```

    - Add the public key of the package repository to the list of trusted keys that are used by `zypper` to authenticate packages:

        === "SUSE Linux Enterprise Server 15 SP6"
            ```bash
            sudo rpm --import /opt/intel/sgx_rpm_local_repo/keys/intel-sgx.key
            ```

    - Install the required packages with:

        === "SUSE Linux Enterprise Server 15 SP6"
            ```bash
            sudo zypper install <package names>
            ```

        For example, use:

        === "SUSE Linux Enterprise Server 15 SP6"
            ```bash
            sudo zypper install libsgx-urts libsgx-quote-ex libsgx-dcap-ql
            ```

    - **(Optional)** To debug with `sgx-gdb`, install the debug symbol packages.
        For example:

        === "SUSE Linux Enterprise Server 15 SP6"
            ```bash
            sudo zypper install \
                libsgx-aesm-ecdsa-plugin-debuginfo \
                libsgx-aesm-launch-plugin-debuginfo \
                libsgx-aesm-pce-plugin-debuginfo \
                libsgx-aesm-quote-ex-plugin-debuginfo \
                libsgx-dcap-default-qpl-debuginfo \
                libsgx-dcap-ql-debuginfo \
                libsgx-dcap-quote-verify-debuginfo \
                libsgx-enclave-common-debuginfo \
                libsgx-launch-debuginfo \
                libsgx-pce-logic-debuginfo \
                libsgx-qe3-logic-debuginfo \
                libsgx-quote-ex-debuginfo \
                libsgx-ra-network-debuginfo \
                libsgx-ra-uefi-debuginfo \
                libsgx-uae-service-debuginfo \
                libsgx-urts-debuginfo \
                sgx-aesm-service-debuginfo \
                sgx-pck-id-retrieval-tool-debuginfo \
                sgx-ra-service-debuginfo
            ```

    - **(Optional)** If you intend to run an application that uses an Intel® SGX enclave requiring the Provision Key Access, your user needs to be added to the group `sgx_prv`.
        Note that any enclave obtaining an SGX Quote using the DCAP Quote Generation Library requires this access.
        A user `<username>` can be added to the group with the following command:

        === "SUSE Linux Enterprise Server 15 SP6"
            ```bash
            sudo usermod -aG sgx_prv <username>
            ```

=== "Ubuntu"

    Follow the steps below to install the primary Intel® SGX packages: `libsgx-quote-ex` and `libsgx-dcap-ql`.

    ??? info "Dependent packages automatically installed"
        Installing the primary Intel® SGX packages (`libsgx-quote-ex` and `libsgx-dcap-ql`) will also automatically install the following dependent packages required for SGX functionality:

        - `libsgx-ae-le`
        - `libsgx-ae-pce`
        - `libsgx-ae-qe3`
        - `libsgx-ae-qve`
        - `libsgx-aesm-ecdsa-plugin`
        - `libsgx-aesm-quote-ex-plugin`
        - `libsgx-dcap_quote-verify`
        - `libsgx-enclave-common`
        - `libsgx-pce-logic`
        - `libsgx-qe3-logic`
        - `libsgx-urts`
        - `sgx-aesm-service`

    - Setup the necessary package repository, which requires an active Internet connection:

        === "Ubuntu 24.04"
            ```bash
            sudo tee /etc/apt/sources.list.d/intel-sgx.list > /dev/null <<EOF
            deb [signed-by=/etc/apt/keyrings/intel-sgx-keyring.asc arch=amd64] https://download.01.org/intel-sgx/sgx_repo/ubuntu noble main
            EOF
            ```

        === "Ubuntu 22.04"
            ```bash
            sudo tee /etc/apt/sources.list.d/intel-sgx.list > /dev/null <<EOF
            deb [signed-by=/etc/apt/keyrings/intel-sgx-keyring.asc arch=amd64] https://download.01.org/intel-sgx/sgx_repo/ubuntu jammy main
            EOF
            ```


    - Download the public key of the package repository and add it to the list of trusted keys that are used by `apt` to authenticate packages:

        === "Ubuntu 24.04"
            ```bash
            curl -fsSLO https://download.01.org/intel-sgx/sgx_repo/ubuntu/intel-sgx-deb.key
            sudo mv intel-sgx-deb.key /etc/apt/keyrings/intel-sgx-keyring.asc
            ```

        === "Ubuntu 22.04"
            ```bash
            curl -fsSLO https://download.01.org/intel-sgx/sgx_repo/ubuntu/intel-sgx-deb.key
            sudo mv intel-sgx-deb.key /etc/apt/keyrings/intel-sgx-keyring.asc
            ```

    - Update the package index and install the required packages:

        === "Ubuntu 24.04"
            ```bash
            sudo apt-get update
            sudo apt-get install libsgx-quote-ex libsgx-dcap-ql
            ```

        === "Ubuntu 22.04"
            ```bash
            sudo apt-get update
            sudo apt-get install libsgx-quote-ex libsgx-dcap-ql
            ```

    - **(Optional)** To debug with `sgx-gdb`, install the debug symbol packages:

        === "Ubuntu 24.04"
            ```bash
            sudo apt-get install \
                libsgx-aesm-ecdsa-plugin-dbgsym \
                libsgx-aesm-launch-plugin-dbgsym \
                libsgx-aesm-pce-plugin-dbgsym \
                libsgx-aesm-quote-ex-plugin-dbgsym \
                libsgx-dcap-default-qpl-dbgsym \
                libsgx-dcap-ql-dbgsym \
                libsgx-dcap-quote-verify-dbgsym \
                libsgx-enclave-common-dbgsym \
                libsgx-launch-dbgsym \
                libsgx-pce-logic-dbgsym \
                libsgx-qe3-logic-dbgsym \
                libsgx-quote-ex-dbgsym \
                libsgx-ra-network-dbgsym \
                libsgx-ra-uefi-dbgsym \
                libsgx-tdx-logic-dbgsym \
                libsgx-uae-service-dbgsym \
                libsgx-urts-dbgsym \
                libtdx-attest-dbgsym \
                sgx-aesm-service-dbgsym \
                sgx-pck-id-retrieval-tool-dbgsym \
                sgx-ra-service-dbgsym \
                tdx-qgs-dbgsym \
                tee-appraisal-tool-dbgsym
            ```

        === "Ubuntu 22.04"
            ```bash
            sudo apt-get install \
                libsgx-aesm-ecdsa-plugin-dbgsym \
                libsgx-aesm-launch-plugin-dbgsym \
                libsgx-aesm-pce-plugin-dbgsym \
                libsgx-aesm-quote-ex-plugin-dbgsym \
                libsgx-dcap-default-qpl-dbgsym \
                libsgx-dcap-ql-dbgsym \
                libsgx-dcap-quote-verify-dbgsym \
                libsgx-enclave-common-dbgsym \
                libsgx-launch-dbgsym \
                libsgx-pce-logic-dbgsym \
                libsgx-qe3-logic-dbgsym \
                libsgx-quote-ex-dbgsym \
                libsgx-ra-network-dbgsym \
                libsgx-ra-uefi-dbgsym \
                libsgx-tdx-logic-dbgsym \
                libsgx-uae-service-dbgsym \
                libsgx-urts-dbgsym \
                libtdx-attest-dbgsym \
                sgx-aesm-service-dbgsym \
                sgx-pck-id-retrieval-tool-dbgsym \
                sgx-ra-service-dbgsym \
                tdx-qgs-dbgsym \
                tee-appraisal-tool-dbgsym
            ```

    - **(Optional)** If you intend to run an application that uses an Intel® SGX enclave requiring the Provision Key Access, your user needs to be added to the group `sgx_prv`.
        Note that any enclave obtaining an SGX Quote using the DCAP Quote Generation Library requires this access.
        A user `<username>` can be added to the group with the following command:

        === "Ubuntu 24.04"
            ```bash
            sudo usermod -aG sgx_prv <username>
            ```

        === "Ubuntu 22.04"
            ```bash
            sudo usermod -aG sgx_prv <username>
            ```

    ??? info "Alternate installation method using local repository"

        - Download the correct repository archive:

            === "Ubuntu 24.04"
                ```bash
                curl -fsSLO \
                    https://download.01.org/intel-sgx/latest/linux-latest/distro/ubuntu24.04-server/sgx_debian_local_repo.tgz
                ```

            === "Ubuntu 22.04"
                ```bash
                curl -fsSLO \
                    https://download.01.org/intel-sgx/latest/linux-latest/distro/ubuntu22.04-server/sgx_debian_local_repo.tgz
                ```

        - Verify that the repository archive has the expected, publicly-available checksum:

            === "Ubuntu 24.04"
                ```bash
                local_sum=$(sha256sum sgx_debian_local_repo.tgz | awk '{print $1}')
                remote_sum=$(curl -s https://download.01.org/intel-sgx/latest/dcap-latest/linux/SHA256SUM_dcap_1.24.cfg | grep 'distro/ubuntu24.04-server/sgx_debian_local_repo.tgz' | awk '{print $1}')
                if [[ "$local_sum" == "$remote_sum" ]]; then echo "Checksum matches"; else echo "Checksum mismatch!"; fi
                ```

            === "Ubuntu 22.04"
                ```bash
                local_sum=$(sha256sum sgx_debian_local_repo.tgz | awk '{print $1}')
                remote_sum=$(curl -s https://download.01.org/intel-sgx/latest/dcap-latest/linux/SHA256SUM_dcap_1.24.cfg | grep 'distro/ubuntu22.04-server/sgx_debian_local_repo.tgz' | awk '{print $1}')
                if [[ "$local_sum" == "$remote_sum" ]]; then echo "Checksum matches"; else echo "Checksum mismatch!"; fi
                ```

        - Extract the repository archive to an appropriate folder, e.g., `/opt/intel`:

            === "Ubuntu 24.04"
                ```bash
                sudo mkdir -p /opt/intel
                sudo tar xzf sgx_debian_local_repo.tgz -C /opt/intel
                ```

            === "Ubuntu 22.04"
                ```bash
                sudo mkdir -p /opt/intel
                sudo tar xzf sgx_debian_local_repo.tgz -C /opt/intel
                ```

        - Add local repository to your system's list of package sources

            === "Ubuntu 24.04"
                ```bash
                echo 'deb [signed-by=/etc/apt/keyrings/intel-sgx-keyring.asc arch=amd64] file:///opt/intel/sgx_debian_local_repo noble main' | \
                    sudo tee /etc/apt/sources.list.d/sgx-repo.list
                ```

            === "Ubuntu 22.04"
                ```bash
                echo 'deb [signed-by=/etc/apt/keyrings/intel-sgx-keyring.asc arch=amd64] file:///opt/intel/sgx_debian_local_repo jammy main' | \
                    sudo tee /etc/apt/sources.list.d/sgx-repo.list
                ```

        - Add the public key of the package repository to the list of trusted keys that are used by `apt` to authenticate packages:

            === "Ubuntu 24.04"
                ```bash
                sudo cp /opt/intel/sgx_debian_local_repo/keys/intel-sgx.key /etc/apt/keyrings/intel-sgx-keyring.asc
                ```

            === "Ubuntu 22.04"
                ```bash
                sudo cp /opt/intel/sgx_debian_local_repo/keys/intel-sgx.key /etc/apt/keyrings/intel-sgx-keyring.asc
                ```

        - Update the package index and install the required packages:

            === "Ubuntu 24.04"
                ```bash
                sudo apt-get update
                sudo apt-get install libsgx-quote-ex libsgx-dcap-ql
                ```

            === "Ubuntu 22.04"
                ```bash
                sudo apt-get update
                sudo apt-get install libsgx-quote-ex libsgx-dcap-ql
                ```

#### Install Intel® SGX/TDX DCAP

=== "Red Hat and CentOS"
    Set up the Intel® SGX/TDX Data Center Attestation Primitives (Intel® SGX/TDX DCAP), Provisioning Certificate Caching Service (PCCS), and Quote Provider Library (QPL).
    The PCCS and QPL work together to first cache DCAP attestation collateral and then make the collateral available to the DCAP Quote Generation Library (`libsgx-dcap-ql`).
    These packages are provided as reference designs that users may deploy as follows.

    !!! Note
        If you are using an external infrastructure provider (e.g., a CSP), check with the infrastructure provider to see if a specific collateral caching service is provided, which might also require a specific QPL.
        For example, Azure provides the [Trusted Hardware Identity Management](https://learn.microsoft.com/en-us/azure/security/fundamentals/trusted-hardware-identity-management).
        Here, we assume that the Intel-provided packages are used.

    1. **[Optional]** Setup the Provisioning Certificate Caching Service (PCCS) as explained in the [Provisioning Certificate Caching Service (PCCS)](../../../intel-tdx-enabling-guide/02/infrastructure_setup/#provisioning-certificate-caching-service-pccs) section of the Intel TDX Enabling Guide.
        Note that Intel TDX and Intel SGX use the same PCCS.

    2. Install the DCAP QPL package:

        ```bash
        sudo yum install libsgx-dcap-default-qpl
        ```

=== "SUSE Linux Enterprise Server"
    Set up the Intel® SGX/TDX Data Center Attestation Primitives (Intel® SGX/TDX DCAP), Provisioning Certificate Caching Service (PCCS), and Quote Provider Library (QPL).
    The PCCS and QPL work together to first cache DCAP attestation collateral and then make the collateral available to the DCAP Quote Generation Library (`libsgx-dcap-ql`).
    These packages are provided as reference designs that users may deploy as follows.

    !!! Note
        If you are using an external infrastructure provider (e.g., a CSP), check with the infrastructure provider to see if a specific collateral caching service is provided, which might also require a specific QPL.
        For example, Azure provides the [Trusted Hardware Identity Management](https://learn.microsoft.com/en-us/azure/security/fundamentals/trusted-hardware-identity-management).
        Here, we assume that the Intel-provided packages are used.

    1. **[Optional]** Setup the Provisioning Certificate Caching Service (PCCS) as explained in the [Provisioning Certificate Caching Service (PCCS)](../../../intel-tdx-enabling-guide/02/infrastructure_setup/#provisioning-certificate-caching-service-pccs) section of the Intel TDX Enabling Guide.
        Note that Intel TDX and Intel SGX use the same PCCS.

    2. Install the DCAP QPL package:

        ```bash
        sudo zypper install libsgx-dcap-default-qpl
        ```

=== "Ubuntu and Debian"
    Set up the Intel® SGX/TDX Data Center Attestation Primitives (Intel® SGX/TDX DCAP), Provisioning Certificate Caching Service (PCCS), and Quote Provider Library (QPL).
    The PCCS and QPL work together to first cache DCAP attestation collateral and then make the collateral available to the DCAP Quote Generation Library (`libsgx-dcap-ql`).
    These packages are provided as reference designs that users may deploy as follows.

    !!! Note
        If you are using an external infrastructure provider (e.g., a CSP), check with the infrastructure provider to see if a specific collateral caching service is provided, which might also require a specific QPL.
        For example, Azure provides the [Trusted Hardware Identity Management](https://learn.microsoft.com/en-us/azure/security/fundamentals/trusted-hardware-identity-management).
        Here, we assume that the Intel-provided packages are used.

    1. **[Optional]** Setup the Provisioning Certificate Caching Service (PCCS) as explained in the [Provisioning Certificate Caching Service (PCCS)](../../../intel-tdx-enabling-guide/02/infrastructure_setup/#provisioning-certificate-caching-service-pccs) section of the Intel TDX Enabling Guide.
        Note that Intel TDX and Intel SGX use the same PCCS.

    2. Install the DCAP QPL package:

        ```bash
        sudo apt-get install libsgx-dcap-default-qpl
        ```


### Intel® SGX Application Developer

To build or develop an application that uses an Intel® SGX enclave, you have to install everything mentioned in the section [Intel® SGX Application User](#intel-sgx-application-user).
Additionally, you have to install the Intel® SGX Software Development Kit (Intel® SGX SDK) and the developer packages, which we describe in this section.

#### Install Intel® SGX SDK

=== "Red Hat and CentOS"

    1. Install dependencies:

        === "CentOS Stream 9"
            ```bash
            sudo yum groupinstall 'Development Tools'
            sudo yum install python3
            ```

        === "Red Hat Enterprise Linux 9.4"
            ```bash
            sudo yum groupinstall 'Development Tools'
            sudo yum install python3
            ```

        For more information about dependencies, see the "Prerequisites" section in the corresponding [README](https://github.com/intel/confidential-computing.sgx/blob/main/README.md#build-the-intelr-sgx-sdk-and-intelr-sgx-psw-package).

    2. Download the Intel® SGX SDK binary:

        === "CentOS Stream 9"
            ```bash
            curl -fsSLo sgx_linux_x64_sdk.bin \
                https://download.01.org/intel-sgx/latest/linux-latest/distro/centos-stream9/sgx_linux_x64_sdk_2.27.100.1.bin
            ```

        === "Red Hat Enterprise Linux 9.4"
            ```bash
            curl -fsSLo sgx_linux_x64_sdk.bin \
                https://download.01.org/intel-sgx/latest/linux-latest/distro/rhel9.4-server/sgx_linux_x64_sdk_2.27.100.1.bin
            ```

    3. Adjust the permissions of the Intel® SGX SDK binary:

        === "CentOS Stream 9"
            ```bash
            chmod +x sgx_linux_x64_sdk.bin
            ```

        === "Red Hat Enterprise Linux 9.4"
            ```bash
            chmod +x sgx_linux_x64_sdk.bin
            ```

    4. Start interactive setup of the Intel® SGX SDK (with `sudo` privileges if necessary):

        === "CentOS Stream 9"
            ```bash
            ./sgx_linux_x64_sdk.bin
            ```

        === "Red Hat Enterprise Linux 9.4"
            ```bash
            ./sgx_linux_x64_sdk.bin
            ```

        When the question `Do you want to install in current directory? [yes/no]` appears, choose one of the following:

        - If you want to install the components in the current directory, type **yes** and press **Enter.**
        - If you want to provide another path for the installation, type **no** and press **Enter**.

            Now the Intel® SGX SDK package is installed into the directory `<Your Input Location>/sgxsdk`.
            In this location, you can also find an uninstallation script `uninstall.sh`, which you can use to uninstall the Intel® SGX SDK.

        !!! Note
            A non-interactive installation (with `sudo` privileges if necessary) can be started with:

            === "CentOS Stream 9"
                ```bash
                ./sgx_linux_x64_sdk.bin --prefix {SDK_INSTALL_PATH_PREFIX}
                ```

            === "Red Hat Enterprise Linux 9.4"
                ```bash
                ./sgx_linux_x64_sdk.bin --prefix {SDK_INSTALL_PATH_PREFIX}
                ```

    5. Run the following command to set all environment variables of the Intel® SGX SDK:

        === "CentOS Stream 9"
            ```bash
            source <Intel SGX SDK Installation Path>/sgxsdk/environment
            ```

        === "Red Hat Enterprise Linux 9.4"
            ```bash
            source <Intel SGX SDK Installation Path>/sgxsdk/environment
            ```

=== "SUSE Linux Enterprise Server"

    1. Install dependencies:

        === "SUSE Linux Enterprise Server 15 SP6"
            ```bash
            sudo zypper install --type pattern devel_basis
            sudo zypper install ocaml ocaml-ocamlbuild automake autoconf libtool \
                curl python3 libopenssl-devel rpm-build git cmake perl
            sudo update-alternatives --install /usr/bin/python python \
                /usr/bin/python3 1
            ```

        For more information about dependencies, see the "Prerequisites" section in the corresponding [README](https://github.com/intel/confidential-computing.sgx/blob/main/README.md#build-the-intelr-sgx-sdk-and-intelr-sgx-psw-package).

    2. Download the Intel® SGX SDK binary:

        === "SUSE Linux Enterprise Server 15 SP6"
            ```bash
            curl -fsSLo sgx_linux_x64_sdk.bin \
                https://download.01.org/intel-sgx/latest/linux-latest/distro/suse15.6-server/sgx_linux_x64_sdk_2.27.100.1.bin
            ```

    3. Adjust the permissions of the Intel® SGX SDK binary:

        === "SUSE Linux Enterprise Server 15 SP6"
            ```bash
            chmod +x sgx_linux_x64_sdk.bin
            ```

    4. Start interactive setup of the Intel® SGX SDK (with `sudo` privileges if necessary):

        === "SUSE Linux Enterprise Server 15 SP6"
            ```bash
            ./sgx_linux_x64_sdk.bin
            ```

        When the question `Do you want to install in current directory? [yes/no]` appears, choose one of the following:

        - If you want to install the components in the current directory, type **yes** and press **Enter.**
        - If you want to provide another path for the installation, type **no** and press **Enter**.

            Now the Intel® SGX SDK package is installed into the directory `<Your Input Location>/sgxsdk`.
            In this location, you can also find an uninstallation script `uninstall.sh`, which you can use to uninstall the Intel® SGX SDK.

        !!! Note
            A non-interactive installation (with `sudo` privileges if necessary) can be started with:

            === "SUSE Linux Enterprise Server 15 SP6"
                ```bash
                ./sgx_linux_x64_sdk.bin --prefix {SDK_INSTALL_PATH_PREFIX}
                ```

    5. Run the following command to set all environment variables of the Intel® SGX SDK:
        === "SUSE Linux Enterprise Server 15 SP6"
            ```bash
            source <Intel SGX SDK Installation Path>/sgxsdk/environment
            ```

=== "Ubuntu and Debian"

    1. Install dependencies:

        === "Debian 12"
            ```bash
            sudo apt-get install build-essential python3
            sudo update-alternatives --install /usr/bin/python python /usr/bin/python3 1
            ```

        === "Debian 10"
            ```bash
            sudo apt-get install build-essential python3
            sudo update-alternatives --install /usr/bin/python python /usr/bin/python3 1
            ```

        === "Ubuntu 24.04"
            ```bash
            sudo apt-get install build-essential python-is-python3
            ```

        === "Ubuntu 22.04"
            ```bash
            sudo apt-get install build-essential python-is-python3
            ```

        For more information about dependencies, see the "Prerequisites" section in the corresponding [README](https://github.com/intel/confidential-computing.sgx/blob/main/README.md#build-the-intelr-sgx-sdk-and-intelr-sgx-psw-package).


    2. Download the Intel® SGX SDK binary:

        === "Debian 12"
            ```bash
            curl -fsSLo sgx_linux_x64_sdk.bin \
                https://download.01.org/intel-sgx/latest/linux-latest/distro/Debian12/sgx_linux_x64_sdk_2.27.100.1.bin
            ```

        === "Debian 10"
            ```bash
            curl -fsSLo sgx_linux_x64_sdk.bin \
                https://download.01.org/intel-sgx/latest/linux-latest/distro/Debian10/sgx_linux_x64_sdk_2.27.100.1.bin
            ```

        === "Ubuntu 24.04"
            ```bash
            curl -fsSLo sgx_linux_x64_sdk.bin \
                https://download.01.org/intel-sgx/latest/linux-latest/distro/ubuntu24.04-server/sgx_linux_x64_sdk_2.27.100.1.bin
            ```

        === "Ubuntu 22.04"
            ```bash
            curl -fsSLo sgx_linux_x64_sdk.bin \
                https://download.01.org/intel-sgx/latest/linux-latest/distro/ubuntu22.04-server/sgx_linux_x64_sdk_2.27.100.1.bin
            ```

    3. Adjust the permissions of the Intel® SGX SDK binary:

        === "Debian 12"
            ```bash
            chmod +x sgx_linux_x64_sdk.bin
            ```

        === "Debian 10"
            ```bash
            chmod +x sgx_linux_x64_sdk.bin
            ```

        === "Ubuntu 24.04"
            ```bash
            chmod +x sgx_linux_x64_sdk.bin
            ```

        === "Ubuntu 22.04"
            ```bash
            chmod +x sgx_linux_x64_sdk.bin
            ```

    4. Start interactive setup of the Intel® SGX SDK (with `sudo` privileges if necessary):

        === "Debian 12"
            ```bash
            ./sgx_linux_x64_sdk.bin
            ```

        === "Debian 10"
            ```bash
            ./sgx_linux_x64_sdk.bin
            ```

        === "Ubuntu 24.04"
            ```bash
            ./sgx_linux_x64_sdk.bin
            ```

        === "Ubuntu 22.04"
            ```bash
            ./sgx_linux_x64_sdk.bin
            ```

        When the question `Do you want to install in current directory? [yes/no]` appears, choose one of the following:

        - If you want to install the components in the current directory, type **yes** and press **Enter.**
        - If you want to provide another path for the installation, type **no** and press **Enter**.

            Now the Intel® SGX SDK package is installed into the directory `<Your Input Location>/sgxsdk`.
            In this location, you can also find an uninstallation script `uninstall.sh`, which you can use to uninstall the Intel® SGX SDK.

        !!! Note
            A non-interactive installation (with `sudo` privileges if necessary) can be started with:

            === "Debian 12"
                ```bash
                ./sgx_linux_x64_sdk.bin --prefix {SDK_INSTALL_PATH_PREFIX}
                ```

            === "Debian 10"
                ```bash
                ./sgx_linux_x64_sdk.bin --prefix {SDK_INSTALL_PATH_PREFIX}
                ```

            === "Ubuntu 24.04"
                ```bash
                ./sgx_linux_x64_sdk.bin --prefix {SDK_INSTALL_PATH_PREFIX}
                ```

            === "Ubuntu 22.04"
                ```bash
                ./sgx_linux_x64_sdk.bin --prefix {SDK_INSTALL_PATH_PREFIX}
                ```

    5. Run the following command to set all environment variables of the Intel® SGX SDK:

        === "Debian 12"
            ```bash
            source <Intel SGX SDK Installation Path>/sgxsdk/environment
            ```

        === "Debian 10"
            ```bash
            source <Intel SGX SDK Installation Path>/sgxsdk/environment
            ```

        === "Ubuntu 24.04"
            ```bash
            source <Intel SGX SDK Installation Path>/sgxsdk/environment
            ```

        === "Ubuntu 22.04"
            ```bash
            source <Intel SGX SDK Installation Path>/sgxsdk/environment
            ```


#### Install Developer Packages

=== "Red Hat and CentOS"

    Install the appropriate developer packages using  the following commands:

    ```bash
    sudo yum install libsgx-enclave-common-devel \
        libsgx-dcap-ql-devel \
        libsgx-dcap-default-qpl-devel \
        libsgx-quote-ex-devel \
        libsgx-dcap-ql-devel \
        libsgx-dcap-quote-verify-devel \
        tee-appraisal-tool
    ```

    !!! Note
        This command assumes that you have setup the package repository as explained in the section [Intel® SGX Application User](#intel-sgx-application-user).

=== "SUSE Linux Enterprise Server"

    Install the appropriate developer packages using  the following commands:

    ```bash
    sudo zypper install libsgx-enclave-common-devel \
        libsgx-dcap-ql-devel \
        libsgx-dcap-default-qpl-devel \
        libsgx-quote-ex-devel \
        libsgx-dcap-ql-devel \
        libsgx-dcap-quote-verify-devel \
        tee-appraisal-tool
    ```

    !!! Note
        This command assumes that you have setup the package repository as explained in the section [Intel® SGX Application User](#intel-sgx-application-user).

=== "Ubuntu and Debian"

    Install the appropriate developer packages using  the following commands:

    ```bash
    sudo apt-get install libsgx-enclave-common-dev \
        libsgx-dcap-ql-dev \
        libsgx-dcap-default-qpl-dev \
        tee-appraisal-tool
    ```

    !!! Note
        This command assumes that you have setup the package repository as explained in the section [Intel® SGX Application User](#intel-sgx-application-user).


### Building the Intel® SGX Software Stack

Follow the instructions in this section to build or develop the Intel SGX software stack, i.e., the Intel SGX SDK, the Intel SGX PSW, or Intel SGX/TDX DCAP.
In particular, this is necessary when you want to build/develop a version for a distribution not mentioned in the sections above.


#### Intel® SGX PSW and Intel® SGX SDK

The source code for the Intel® SGX PSW and the Intel® SGX SDK is located in GitHub* repository [https://github.com/intel/confidential-computing.sgx](https://github.com/intel/confidential-computing.sgx).
To build and deploy the packages, follow the instructions in <https://github.com/intel/confidential-computing.sgx/blob/main/README.md>.

##### Prebuilt Binaries

For Intel® SGX EPID-based attestation, you must use the Architectural Enclaves (AEs), which are pre-built and signed by Intel.
You can download these pre-built enclaves for the Intel® SGX Linux* release from <https://download.01.org/intel-sgx/latest/linux-latest/>.
The prebuilt enclaves are in a .tar file in the form `prebuilt_ae_<version>.tar.gz`

In addition, the Intel® SGX SDK provides prebuilt optimized libraries in the binary form.
These libraries are provided in a .tar file in the form of `optimized_libs_<version>.tar.gz`.

Check the SHA256 hash of downloaded libraries using `SHA256SUM_prebuilt_<version>.cfg`.


#### Intel® SGX/TDX DCAP

The source code for Intel® SGX/TDX DCAP is located in GitHub* repository <https://github.com/intel/confidential-computing.tee.dcap>.
To build and deploy the packages, follow the instructions in <https://github.com/intel/confidential-computing.tee.dcap/blob/main/README.md>.
For release notes and other details, see <https://download.01.org/intel-sgx/latest/dcap-latest/linux/docs/>

##### Prebuilt Binaries

For Intel® SGX DCAP-based attestation, you must also use certain enclaves that are pre-built and signed by Intel.
This includes enclaves used by the Intel® SGX DCAP Quote Generation Library, which are located here: <https://download.01.org/intel-sgx/latest/dcap-latest/linux/> in file `prebuilt_dcap_<version>.tar.gz`.
