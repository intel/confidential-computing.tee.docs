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

As explained in the [Intel TDX Remote Attestation section](../02/infrastructure_setup.md#intel-tdx-remote-attestation) of the [Infrastructure Setup page](../02/infrastructure_setup.md), remote attestation is one of the main features of Intel TDX.

In this section, we assume that your infrastructure provider has done the necessary setup steps.
This includes the setup of a [collateral caching service](../02/infrastructure_setup.md#collateral-caching-service) in the infrastructure and ensuring that a [Quote Generation Service (QGS)](../05/host_os_setup.md#install-qgs) is running on the same host as the TD.

Then, we show how TD Quotes can be generated, which always has to happen inside a TD.

We also describe how generated TD Quotes can be verified to close the loop.
TD Quote Verification can be done by any party at any place.
Examples:

- Inside the TD by the TD owner.
- In the host OS by the host OS owner.
- On any remote platform by the owner of the remote platform.

Note that there are [multiple TD Quote Verification alternatives](../02/infrastructure_setup.md#td-quote-verification).


### TD Quote Generation

TD Quote Generation must always happen inside the TD.
There are multiple ways to generate a TD Quote.
In the following, we explore two alternative for TD Quote Generation using the Linux kernel's built-in [configfs-tsm](https://www.kernel.org/doc/Documentation/ABI/testing/configfs-tsm) interface:

1. Using [manual shell commands](#manual-shell-commands)
2. Using [the Intel TDX Quote Generation Sample](#intel-tdx-quote-generation-sample)

#### Manual Shell Commands

Execute the following shell commands to generate a TD Quote on your distro of choice:
=== "CentOS Stream 10"
    ``` { .bash }
    REPORT_DIR="/sys/kernel/config/tsm/report"
    REPORT="$REPORT_DIR/report0"
    # Ensure configfs is mounted
    if ! mountpoint -q /sys/kernel/config; then
        sudo mount -t configfs none /sys/kernel/config
    fi
    # Create report directory
    sudo mkdir -p "$REPORT"
    # Provide 64 bytes of REPORTDATA (nonce)
    head -c 64 /dev/urandom | sudo tee "$REPORT/inblob" > /dev/null
    # Retrieve the Quote
    echo "[*] Retrieving TD Quote..."
    sudo cat "$REPORT/outblob" > quote.dat
    # Check if the output file is empty
    if [ ! -s quote.dat ]; then
        echo "[!] Error: TD Quote is empty. Retrieval may have failed." >&2
        sudo rmdir "$REPORT"
    else
        # Show formatted output
        echo "[*] Hexdump of the TD Quote:"
        sudo hexdump -C quote.dat
        # Cleanup
        sudo rmdir "$REPORT"
        echo "[*] Quote saved to quote.dat"
    fi
    ```
=== "openSUSE 16"
    ``` { .bash }
    REPORT_DIR="/sys/kernel/config/tsm/report"
    REPORT="$REPORT_DIR/report0"
    # Ensure configfs is mounted
    if ! mountpoint -q /sys/kernel/config; then
        mount -t configfs none /sys/kernel/config
    fi
    # Create report directory
    mkdir -p "$REPORT"
    # Provide 64 bytes of REPORTDATA (nonce)
    head -c 64 /dev/urandom | tee "$REPORT/inblob" > /dev/null
    # Retrieve the Quote
    echo "[*] Retrieving TD Quote..."
    cat "$REPORT/outblob" > quote.dat
    # Check if the output file is empty
    if [ ! -s quote.dat ]; then
        echo "[!] Error: TD Quote is empty. Retrieval may have failed." >&2
        rmdir "$REPORT"
    else
        # Show formatted output
        echo "[*] Hexdump of the TD Quote:"
        hexdump -C quote.dat
        # Cleanup
        rmdir "$REPORT"
        echo "[*] Quote saved to quote.dat"
    fi
    ```

=== "RHEL 10.2"
    ``` { .bash }
    REPORT_DIR="/sys/kernel/config/tsm/report"
    REPORT="$REPORT_DIR/report0"
    # Ensure configfs is mounted
    if ! mountpoint -q /sys/kernel/config; then
        sudo mount -t configfs none /sys/kernel/config
    fi
    # Create report directory
    sudo mkdir -p "$REPORT"
    # Provide 64 bytes of REPORTDATA (nonce)
    head -c 64 /dev/urandom | sudo tee "$REPORT/inblob" > /dev/null
    # Retrieve the Quote
    echo "[*] Retrieving TD Quote..."
    sudo cat "$REPORT/outblob" > quote.dat
    # Check if the output file is empty
    if [ ! -s quote.dat ]; then
        echo "[!] Error: TD Quote is empty. Retrieval may have failed." >&2
        sudo rmdir "$REPORT"
    else
        # Show formatted output
        echo "[*] Hexdump of the TD Quote:"
        sudo hexdump -C quote.dat
        # Cleanup
        sudo rmdir "$REPORT"
        echo "[*] Quote saved to quote.dat"
    fi
    ```

=== "SLES 16.0 QU0"
    ``` { .bash }
    REPORT_DIR="/sys/kernel/config/tsm/report"
    REPORT="$REPORT_DIR/report0"
    # Ensure configfs is mounted
    if ! mountpoint -q /sys/kernel/config; then
        mount -t configfs none /sys/kernel/config
    fi
    # Create report directory
    mkdir -p "$REPORT"
    # Provide 64 bytes of REPORTDATA (nonce)
    head -c 64 /dev/urandom | tee "$REPORT/inblob" > /dev/null
    # Retrieve the Quote
    echo "[*] Retrieving TD Quote..."
    cat "$REPORT/outblob" > quote.dat
    # Check if the output file is empty
    if [ ! -s quote.dat ]; then
        echo "[!] Error: TD Quote is empty. Retrieval may have failed." >&2
        rmdir "$REPORT"
    else
        # Show formatted output
        echo "[*] Hexdump of the TD Quote:"
        hexdump -C quote.dat
        # Cleanup
        rmdir "$REPORT"
        echo "[*] Quote saved to quote.dat"
    fi
    ```

=== "Ubuntu 26.04"
    ``` { .bash }
    REPORT_DIR="/sys/kernel/config/tsm/report"
    REPORT="$REPORT_DIR/report0"
    # Ensure configfs is mounted
    if ! mountpoint -q /sys/kernel/config; then
        sudo mount -t configfs none /sys/kernel/config
    fi
    # Create report directory
    sudo mkdir -p "$REPORT"
    # Provide 64 bytes of REPORTDATA (nonce)
    head -c 64 /dev/urandom | sudo tee "$REPORT/inblob" > /dev/null
    # Retrieve the Quote
    echo "[*] Retrieving TD Quote..."
    sudo cat "$REPORT/outblob" > quote.dat
    # Check if the output file is empty
    if [ ! -s quote.dat ]; then
        echo "[!] Error: TD Quote is empty. Retrieval may have failed." >&2
        sudo rmdir "$REPORT"
    else
        # Show formatted output
        echo "[*] Hexdump of the TD Quote:"
        sudo hexdump -C quote.dat
        # Cleanup
        sudo rmdir "$REPORT"
        echo "[*] Quote saved to quote.dat"
    fi
    ```


If successful, a TD Quote will be written to disk in a `quote.dat` file.
This `quote.dat` file can now be verified as described in the next [TD Quote Verification](#td-quote-verification) section.

#### Intel TDX Quote Generation Sample

Execute the following commands to generate a TD Quote using the Intel TDX Quote Generation Sample on your distro of choice:

1. If not done during another component installation, set up the appropriate Intel SGX package repository for your distribution of choice:
    --8<-- "includes/package_repo_setup.md:sgx-repo_cent-os-stream-10"
    --8<-- "includes/package_repo_setup.md:sgx-repo_opensuse_16_no_sudo"
    --8<-- "includes/package_repo_setup.md:sgx-repo_rhel_10_2"
    --8<-- "includes/package_repo_setup.md:sgx-repo_sles_16_no_sudo"
    --8<-- "includes/package_repo_setup.md:sgx-repo_ubuntu_26_04"

2. Install, build, and run the Intel TDX Quote Generation Sample application (`test_tdx_attest`)

    === "CentOS Stream 10"

        ``` { .bash }
        sudo dnf install -y libtdx-attest-devel make gcc
        cd /opt/intel/tdx-quote-generation-sample
        make
        ./test_tdx_attest
        mv ./quote.dat ~/quote.dat
        ```

    === "openSUSE 16"
        ``` { .bash }
        zypper install -y make gcc libtdx-attest-devel
        cd /opt/intel/tdx-quote-generation-sample
        make
        ./test_tdx_attest
        mv ./quote.dat ~/quote.dat
        ```

    === "RHEL 10.2"
        ``` { .bash }
        sudo dnf install -y libtdx-attest-devel make gcc
        cd /opt/intel/tdx-quote-generation-sample
        make
        ./test_tdx_attest
        mv ./quote.dat ~/quote.dat
        ```

    === "SLES 16.0 QU0"
        ``` { .bash }
        zypper install -y make gcc libtdx-attest-devel
        cd /opt/intel/tdx-quote-generation-sample
        make
        ./test_tdx_attest
        mv ./quote.dat ~/quote.dat
        ```

    === "Ubuntu 26.04"
        ``` { .bash }
        sudo apt install -y libtdx-attest-dev make gcc
        cd /opt/intel/tdx-quote-generation-sample
        make
        ./test_tdx_attest
        mv ./quote.dat ~/quote.dat
        ```

    If successful, a TD Quote will be written to disk in a `quote.dat` file.
    This `quote.dat` file can now be verified as described in the [TD Quote Verification](#td-quote-verification) section.


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
        scp -i ./guest_TD_root_id -p <TD SSH port> <TD user>@<TD IP>:<guest-path-to>/quote.dat <host_directory>/.
        ```

        Example command:
        ``` { .bash }
        scp -i ./guest_TD_root_id -P 10022 root@localhost:/root/quote.dat ~/quote.dat
        ```

    === "virt-copy-out"

        !!! note
            Host OS access is necessary for this approach.
            Also, you must shutdown the TD before accessing the guest image.

        Terminate TD.
        Then, adjust the following command to your environment and use it to copy the file:
        ``` { .bash }
        sudo virt-copy-out -a <image_path> <guest-path-to>/quote.dat <host_directory>
        ```

        Example command:
        ``` { .bash }
        sudo virt-copy-out -a ~/ubuntu-26.04-server-cloudimg-amd64.img /root/quote.dat ~
        ```

2. If not done during another component installation, setup the appropriate Intel SGX package repository for your distribution of choice:

    --8<-- "includes/package_repo_setup.md:sgx-repo_cent-os-stream-10"
    --8<-- "includes/package_repo_setup.md:sgx-repo_opensuse_16"
    --8<-- "includes/package_repo_setup.md:sgx-repo_rhel_10_2"
    --8<-- "includes/package_repo_setup.md:sgx-repo_sles_16"
    --8<-- "includes/package_repo_setup.md:sgx-repo_ubuntu_26_04"

3. Execute the following command to install the dependencies for the [Quote Verification Sample](https://github.com/intel/confidential-computing.tee.dcap/tree/main/SampleCode/QuoteVerificationSample) application, retrieve the application, build the application, and use the application to verify the TD Quote (i.e., `quote.dat`):

    === "CentOS Stream 10"

        ``` { .bash }
        sudo dnf install -y gcc make git g++
        sudo dnf install -y libsgx-enclave-common-devel \
            libsgx-dcap-quote-verify-devel libsgx-dcap-default-qpl-devel
        cd ~
        git clone https://github.com/intel/confidential-computing.tee.dcap.git
        cd confidential-computing.tee.dcap/SampleCode/QuoteVerificationSample
        make QVL_ONLY=1
        ./app -quote ~/quote.dat
        ```

    === "openSUSE 16"

        ``` { .bash }
        sudo zypper install -y make gcc-c++ git \
        libsgx-enclave-common-devel libsgx-dcap-quote-verify-devel libsgx-dcap-default-qpl-devel
        git clone https://github.com/intel/confidential-computing.tee.dcap.git
        cd confidential-computing.tee.dcap/SampleCode/QuoteVerificationSample
        make QVL_ONLY=1
        ./app -quote ~/quote.dat
        ```

    === "RHEL 10.2"

        ``` { .bash }
        sudo dnf install -y gcc make git g++
        sudo dnf install -y libsgx-enclave-common-devel \
            libsgx-dcap-quote-verify-devel libsgx-dcap-default-qpl-devel
        cd ~
        git clone https://github.com/intel/confidential-computing.tee.dcap.git
        cd confidential-computing.tee.dcap/SampleCode/QuoteVerificationSample
        make QVL_ONLY=1
        ./app -quote ~/quote.dat
        ```

    === "SLES 16.0 QU0"

        ``` { .bash }
        sudo zypper install -y make gcc-c++ git \
        libsgx-enclave-common-devel libsgx-dcap-quote-verify-devel libsgx-dcap-default-qpl-devel
        git clone https://github.com/intel/confidential-computing.tee.dcap.git
        cd confidential-computing.tee.dcap/SampleCode/QuoteVerificationSample
        make QVL_ONLY=1
        ./app -quote ~/quote.dat
        ```

    === "Ubuntu 26.04"

        ``` { .bash }
        sudo apt install -y make g++ libsgx-enclave-common-dev \
            libsgx-dcap-quote-verify-dev libsgx-dcap-default-qpl-dev
        git clone https://github.com/intel/confidential-computing.tee.dcap.git
        cd confidential-computing.tee.dcap/SampleCode/QuoteVerificationSample
        make QVL_ONLY=1
        ./app -quote ~/quote.dat
        ```

    If TD Quote Verification is successful, the output will contain `Verification completed`.
