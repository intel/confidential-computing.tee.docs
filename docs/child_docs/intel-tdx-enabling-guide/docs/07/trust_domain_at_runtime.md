---
description: A virtual machine (VM) protected by Intel® TDX is called a Trust Domain (TD). Several aspects are important for a TD at runtime.
keywords: enabling guide, Intel TDX, Trust Domain Extension, Confidential Computing, Trust Domain, runtime
---
<!---
Copyright (C) 2024 Intel Corporation
SPDX-License-Identifier: CC-BY-4.0
-->

# Trust Domain at Runtime

On this page, we provide instructions on topics concerning a Trust Domain (TD) at runtime.


## Perform Remote Attestation

As explained in the [TDX remote attestation section](../02/infrastructure_setup.md#intel-tdx-remote-attestation) of the [Infrastructure Setup page](../02/infrastructure_setup.md), remote attestation is one of the main features of Intel TDX.

In this section, we assume that your infrastructure provider has done the necessary setup steps.
This includes the setup of a [collateral caching service](../02/infrastructure_setup.md#collateral-caching-service) in the infrastructure; a [Quote Generation Service (QGS)](../05/host_os_setup.md#install-qgs) is running on the same host as the TD; and a communication channel between the QGS and the TD was [configured on TD start](../05/host_os_setup.md#setup-communication-path-between-qgs-and-td).

Based on this assumption, we explain how to configure the communication channel between the TD and the QGS from inside the TD.
Then, we show how TD Quotes can be generated, which always has to happen inside a TD.

We also describe how generated TD Quotes can be verified to close the loop.
TD Quote Verification can be done by any party at any place.
Examples:

- Inside the TD by the TD owner.
- In the host OS by the host OS owner.
- On any remote platform by the owner of the remote platform.

Note that there are [multiple TD Quote Verification alternatives](../02/infrastructure_setup.md#td-quote-verification).


### Configure TD to QGS Communication Channel

Inside the TD, create the file `/etc/tdx-attest.conf` file as root defining the vsock port that is for the communication between TD and QGS.
The following command can be used to create and fill the file:

``` { .text }
sudo tee -a /etc/tdx-attest.conf > /dev/null <<EOT
port=4050
EOT
```


### TD Quote Generation

TD Quote Generation must always happen inside the TD.
There are multiple ways to generate a TD Quote.
In the following, we explore how TD Quote Generation can be tested using the *TDX Quote Generation Sample*.

Steps:

1. Setup the appropriate Intel SGX package repository for your distribution of choice (if not done during another component installation):

    === "Red Hat Enterprise Linux 9.4 KVM"

        ```
        --8<-- "docs/code/sgx_repo_setup.sh:rhel_9_4_kvm"
        ```

    === "Ubuntu 24.04"

        ```
        --8<-- "docs/code/sgx_repo_setup.sh:ubuntu_24_04"
        ```

    === "openSUSE Leap 15.5 or SUSE Linux Enterprise Server 15-SP5"

        ```
        --8<-- "docs/code/sgx_repo_setup.sh:opensuse_leap_15_5"
        ```

2. Execute the following commands to install and run the sample application generating a TD Quote:

    === "Red Hat Enterprise Linux 9.4 KVM"

        ``` { .bash }
        sudo dnf install -y gcc make
        sudo dnf --nogpgcheck install -y libtdx-attest libtdx-attest-devel
        cd /opt/intel/tdx-quote-generation-sample/
        make
        ./test_tdx_attest
        ```

    === "Ubuntu 24.04"

        ``` { .bash }
        sudo apt install -y libtdx-attest libtdx-attest-dev
        cd /opt/intel/tdx-quote-generation-sample/
        make
        ./test_tdx_attest
        ```

    === "openSUSE Leap 15.5 or SUSE Linux Enterprise Server 15-SP5"

        ``` { .bash }
        sudo zypper --no-gpg-checks install -y libtdx-attest libtdx-attest-devel
        cd /opt/intel/tdx-quote-generation-sample/
        make
        ./test_tdx_attest
        ```

    If successful, a TD Quote will be written to disk in a `quote.dat` file.
    This `quote.dat` file can now be verified as described in the next section.


### TD Quote Verification

TD Quote Verification can be done by any party at an arbitrary place.
There are [multiple TD Quote Verification alternatives](../02/infrastructure_setup.md#td-quote-verification).
In the following, we explore how TD Quote Verification can be tested using the *Quote Verification Sample* application deployed in the host OS.

Steps:

1. Copy the TD Quote file (e.g., `quote.dat`) to the host OS.
    Use a tool of your choice for this operation.
    Possible commands using `scp` or ``virt-copy-out``:

    === "scp"

        !!! note
            SSH access to your TD is necessary for this approach.
            If the VM is started with sudo privileges, ensure you execute the following command with sudo.

        Adjust the following command to your environment and use it to copy the file:
        ``` { .bash }
        scp -p <TD SSH port> <TD user>@<TD IP>:<guest-path-to>/quote.dat <host_directory>/.
        ```

        Example command:
        ``` { .bash }
        scp -P 10022 root@localhost:/opt/intel/tdx-quote-generation-sample/quote.dat ~/quote.dat
        ```

    === "virt-copy-out"

        !!! note
            Host OS access is necessary for this approach.

        Terminate TD.
        Then, adjust the following command to your environment and use it to copy the file:
        ``` { .bash }
        virt-copy-out -a <image_path> <guest-path-to>/quote.dat <host_directory>
        ```

        Example command:
        ``` { .bash }
        virt-copy-out -a ~/tdx/guest-tools/image/tdx-guest-ubuntu-24.04.qcow2 /opt/intel/tdx-quote-generation-sample/quote.dat ~
        ```

2. Setup the appropriate Intel SGX package repository for your distribution of choice (if not done during another component installation):

    === "CentOS Stream 9"

        ```
        --8<-- "docs/code/sgx_repo_setup.sh:cent-os-stream-9"
        ```

    === "Ubuntu 24.04"

        ```
        --8<-- "docs/code/sgx_repo_setup.sh:ubuntu_24_04"
        ```

    === "openSUSE Leap 15.5 or SUSE Linux Enterprise Server 15-SP5"

        ```
        --8<-- "docs/code/sgx_repo_setup.sh:opensuse_leap_15_5"
        ```

3. Execute the following command to install the dependencies for the [Quote Verification Sample](https://github.com/intel/SGXDataCenterAttestationPrimitives/tree/main/SampleCode/QuoteVerificationSample) application, retrieve the application, build the application, and use the application to verify the TD Quote (i.e., `quote.dat`):

    === "CentOS Stream 9"

        ``` { .bash }
        sudo dnf install -y gcc make
        sudo dnf --nogpgcheck install -y libsgx-enclave-common-devel libsgx-dcap-quote-verify-devel libsgx-dcap-default-qpl-devel
        cd ~
        git clone https://github.com/intel/SGXDataCenterAttestationPrimitives.git
        cd SGXDataCenterAttestationPrimitives/SampleCode/QuoteVerificationSample
        make QVL_ONLY=1
        ./app -quote ~/quote.dat
        ```

    === "Ubuntu 24.04"

        ``` { .bash }
        sudo apt install -y libsgx-enclave-common-dev libsgx-dcap-quote-verify-dev libsgx-dcap-default-qpl-dev
        git clone https://github.com/intel/SGXDataCenterAttestationPrimitives.git
        cd SGXDataCenterAttestationPrimitives/SampleCode/QuoteVerificationSample
        make QVL_ONLY=1
        ./app -quote ~/quote.dat
        ```

    === "openSUSE Leap 15.5 or SUSE Linux Enterprise Server 15-SP5"

        ``` { .bash }
        sudo zypper --no-gpg-checks install -y libsgx-enclave-common-devel libsgx-dcap-quote-verify-devel libsgx-dcap-default-qpl-devel
        cd ~
        git clone https://github.com/intel/SGXDataCenterAttestationPrimitives.git
        cd SGXDataCenterAttestationPrimitives/SampleCode/QuoteVerificationSample
        make QVL_ONLY=1
        ./app -quote ~/quote.dat
        ```

    If TD Quote Verification is successful, the output contains `Verification completed successfully`.
