---
description: To use Intel® TDX, the host operating system (OS) must be enabled. Multiple distributions are ready for Intel TDX as a host OS.
keywords: enabling guide, Intel TDX, Trust Domain Extension, Confidential Computing, host OS, operating system
---
<!---
Copyright (C) 2024 Intel Corporation
SPDX-License-Identifier: CC-BY-4.0
-->

# Host OS Setup

On this page, we will introduce how an Intel TDX-enabled host OS can be configured.
We assume that proper [hardware was selected](../03/hardware_selection.md) and the [hardware setup](../04/hardware_setup.md) was done.


## Enable Intel TDX in the Host OS

The preferred way to enable Intel TDX in the host OS is to use the *TDX Early Preview* distributions.
These distributions are provided by partners for a convenient Intel TDX enablement experience.
Currently, the following Intel TDX-enabled host OSes are supported by TDX Early Preview distributions:

- CentOS Stream 9
- Ubuntu 24.04
- openSUSE Leap 15.6 or SUSE Linux Enterprise Server 15-SP6

To install the Intel TDX host OS kernel with KVM support, as well as the QEMU and libvirt packages required to create and manage the launch of TDs, refer to the instructions provided by the individual TDX Early Preview distributions:

=== "CentOS Stream 9"

    Follow instruction from the ["Configure a host" page](https://sig.centos.org/virt/tdx/host/) in the CentOS guide.
    Note that we cover the "UEFI (BIOS) settings" section from the CentOS guide on our [Hardware Setup page](../04/hardware_setup.md#enable-intel-tdx-in-bios).
    In the [next section of this page](#check-intel-tdx-enablement), we cover verification commands that go beyond the "Verification" section in the CentOS guide.

=== "Ubuntu 24.04"

    Follow instruction from the ["Setup Host OS" section](https://github.com/canonical/tdx/blob/3.3/README.md#4-setup-host-os) in the Canonical guide.
    Note that we cover step "4.3 Enable Intel TDX in the Host's BIOS" on our [Hardware Setup page](../04/hardware_setup.md#enable-intel-tdx-in-bios) and a more detailed version of "4.4 Verify Intel TDX is Enabled on Host OS" is covered in [the next section of this page](#check-intel-tdx-enablement).

    !!! warning
        Our guide assumes that the remote attestation packages provided by Canonical are not installed on the host OS.
        To make sure to not install these packages:

        - Keep the default setting of `TDX_SETUP_ATTESTATION=0` during the execution of `setup-tdx-host.sh`.
        - Do not manually execute `setup-attestation-host.sh`, which is described in Section 9.2 of the Canonical guide.

=== "openSUSE Leap 15.6 or SUSE Linux Enterprise Server 15-SP6"

    Follow instruction from the "Quickstart Scripts" or and "Manual instructions" sections in the [SUSE guide](https://github.com/SUSE/tdx-demo/blob/1da7994045d7d1cf1192f5316e1a22c262376611/INSTALL-SLES-15-SP5.md).


If not done before, reboot the system into the BIOS setup menu and perform the [necessary Intel TDX enablement steps](../04/hardware_setup.md#enable-intel-tdx-in-bios).


### Check Intel TDX enablement

To check the status of your Intel TDX configuration, you can manually execute the following commands:

- Check whether Intel TDX Module is initialized.
  The expected output contains `tdx: TDX module initialized`.

    ``` { .bash }
    sudo dmesg | grep -i tdx
    ```

- As a prerequisite for the following commands, install the MSR Tools package and load the MSR module.

    === "CentOS Stream 9"

        ``` { .bash }
        sudo dnf config-manager --set-enabled crb
        sudo dnf install epel-release epel-next-release
        sudo dnf install msr-tools
        sudo modprobe msr
        ```

    === "Ubuntu 24.04"

        ``` { .bash }
        sudo apt install msr-tools
        sudo modprobe msr
        ```

    === "openSUSE Leap 15.6 or SUSE Linux Enterprise Server 15-SP6"

        ``` { .bash }
        sudo zypper addrepo https://download.opensuse.org/repositories/openSUSE:Backports:SLE-15-SP5/standard/openSUSE:Backports:SLE-15-SP5.repo
        sudo zypper refresh
        sudo zypper install msr-tools
        sudo modprobe msr
        ```

- Check whether Intel TME is enabled.
  The expected output is `1`.

    ``` { .text }
    sudo rdmsr -f 1:1 0x982
    ```

- Check the Intel SGX and MCHECK status.
  The expected output is `0`.

    ``` { .bash }
    sudo rdmsr 0xa0
    ```

- Check the Intel TDX status.
  The expected output is `1`.

    ``` { .text }
    sudo rdmsr -f 11:11 0x1401
    ```

- Check the maximum number of Intel TME keys available for usage.
  The expected output depends on what is [configured in the BIOS](../04/hardware_setup.md#enable-intel-tdx-in-bios).

    ``` { .text }
    sudo rdmsr -f 50:36 0x981 | awk '{print strtonum("0x"$0)}'
    ```

- Check the number of activated Intel TME keys.
  The expected output depends on what is [configured in the BIOS](../04/hardware_setup.md#enable-intel-tdx-in-bios).

    ``` { .text }
    sudo rdmsr -f 31:0 0x87 | awk '{print strtonum("0x"$0)}'
    ```

- Check the number of activated Intel TDX keys.
  The expected output depends on what is [configured in the BIOS](../04/hardware_setup.md#enable-intel-tdx-in-bios).

    ``` { .text }
    sudo rdmsr -f 63:32 0x87 | awk '{print strtonum("0x"$0)}'
    ```


## Setup Quote Generation Service (QGS)

The main artifact used in a remote attestation flow is the TD Quote, which is generated on the Intel TDX hardware and then transferred to any other party/machine for verification.
To generate a TD Quote, a TD first uses the hardware to generate a TD Report.
This TD Report is then forwarded to an Intel SGX Architectural Enclave, called the *TD Quoting Enclave*.
This enclave takes the incoming TD Report, verifies that the TD Report was generated by a TD on the same platform, and then signs the TD Report with a signature key for which the trust is rooted in an Intel CA.
More details can be found in the [Intel® Trust Domain Extensions Data Center Attestation Primitives (Intel® TDX DCAP): Quote Generation Library and
Quote Verification Library](https://download.01.org/intel-sgx/latest/dcap-latest/linux/docs/Intel_TDX_DCAP_Quoting_Library_API.pdf) documentation.

The Quote Generation Service (QGS) is a service that runs in the host OS (or inside a dedicated VM) to host the TD Quoting Enclave.
Note that the QGS cannot run on another machine, because the verification of the TD Report requires that the corresponding TD and the TD Quoting Enclave run on the same machine.


### Install QGS

1. If not done during another component installation, set up the appropriate Intel SGX package repository for your distribution of choice:
    --8<-- "includes/package_repo_setup.md:sgx-repo_cent-os-stream-9"
    --8<-- "includes/package_repo_setup.md:sgx-repo_ubuntu_24_04"
    --8<-- "includes/package_repo_setup.md:sgx-repo_opensuse_leap_15_6"

2. Install the QGS with the following command, which will also install the necessary prerequisites (the Quote Provider Library (QPL) and the Quoting Library (QL)).

    === "CentOS Stream 9"

        ``` { .bash }
        sudo dnf --nogpgcheck install -y \
            tdx-qgs \
            libsgx-dcap-default-qpl \
            libsgx-dcap-ql
        ```

    === "Ubuntu 24.04"

        ``` { .bash }
        sudo apt install -y \
            tdx-qgs \
            libsgx-dcap-default-qpl \
            libsgx-dcap-ql
        ```

    === "openSUSE Leap 15.6 or SUSE Linux Enterprise Server 15-SP6"

        ``` { .bash }
        sudo zypper --no-gpg-checks install -y \
            tdx-qgs \
            libsgx-dcap-default-qpl \
            libsgx-dcap-ql
        ```

    More detailed information about these instructions can be found in our [Intel® SGX Software Installation Guide For Linux* OS](https://download.01.org/intel-sgx/latest/dcap-latest/linux/docs/Intel_SGX_SW_Installation_Guide_for_Linux.pdf).

??? info "How to check service log of the QGS?"
    You can check the service log of the QGS with the following command:

    === "CentOS Stream 9"

        ``` { .bash }
        sudo journalctl -u qgsd -f
        ```

    === "Ubuntu 24.04"

        ``` { .bash }
        sudo journalctl -u qgsd -f
        ```

    === "openSUSE Leap 15.6 or SUSE Linux Enterprise Server 15-SP6"

        ``` { .bash }
        sudo journalctl -u qgsd -f
        ```


### Configure QCNL

On start, the QGS reads the configuration file `/etc/sgx_default_qcnl.conf`, and uses the contained settings for TD Quote Generation.
This file contains various settings that might be important in your environment.

Selected highlights regarding this configuration file:

- If the QGS should use a PCCS in your infrastructure as a [collateral caching service](../02/infrastructure_setup.md#collateral-caching-service), you have to adjust the JSON-key `pccs_url` in the configuration file accordingly.
- If the QGS should accept insecure HTTPS certificates from the PCCS, set the JSON-key `use_secure_cert` in the configuration file to `false`.

    !!! warning
        You must not use insecure HTTPS certificates in a production environment.

- See the comments of the configuration file `/etc/sgx_default_qcnl.conf` for more information on other settings.

After changing settings in the file `/etc/sgx_default_qcnl.conf`, you have to restart the QGS:

=== "CentOS Stream 9"

    ``` { .bash }
    sudo systemctl restart qgsd.service
    ```

=== "Ubuntu 24.04"

    ``` { .bash }
    sudo systemctl restart qgsd.service
    ```

=== "openSUSE Leap 15.6 or SUSE Linux Enterprise Server 15-SP6"

    ``` { .bash }
    sudo systemctl restart qgsd.service
    ```


### Setup Communication Path between QGS and TD

The current TDX Early Preview distributions use [vsock](https://man7.org/linux/man-pages/man7/vsock.7.html) as the communication path from the TD to the QGS running in the host.
A TD can be launched using QEMU or libvirt (see [Launch a Trust Domain section](../06/guest_os_setup.md#launch-a-trust-domain)).
In both cases, special options are necessary to enable the vsock interface.

=== "QEMU"

    Make sure that the following is part of your QEMU launch command:
    ``` { .bash }
    -device vhost-vsock-pci,guest-cid=3
    ```

=== "libvirt"

    Make sure that a vsock entry is present inside the `devices` element of the libvirt XML config file of the TD:

    ``` { .xml }
    ...
    <devices>
        ...
        <vsock model='virtio'>
            <cid auto='yes' address='3'/>
            <address type='pci' domain='0x0000' bus='0x05' slot='0x00' function='0x0'/>
        </vsock>
        ...
    </devices>
    ...
    ```
