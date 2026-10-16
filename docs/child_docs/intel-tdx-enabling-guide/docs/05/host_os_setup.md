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

Currently, the following host OS distributions ship with the necessary versions of kernel/kvm, QEMU, and libvirt to be able to run TDs.

- CentOS Stream 10
- openSUSE Leap 16
- Red Hat Enterprise Linux (RHEL) 10.2
- SUSE Linux Enterprise Server (SLES) 16.0 QU0
- Ubuntu 26.04


### Configure Kernel Command Line Parameters

The required kernel command line parameters to enable Intel TDX are not included by default and must be added manually.
Follow these steps for your distribution:

1. Add the required kernel command line parameters for your distribution:

    === "CentOS Stream 10"
        ``` { .bash }
        sudo grubby --update-kernel=ALL --args="nohibernate kvm_intel.tdx=1"
        ```

    === "openSUSE 16"
        <!-- cspell:disable -->

        ``` { .bash }
        sudo bash -c 'changed=0
            for arg in "kvm_intel.tdx=1" "nohibernate"; do
                key=${arg%%=*}
                already_set="^GRUB_CMDLINE_LINUX=.*[ \"]${arg//./\\.}[ \"]"
                grep -qE "$already_set" /etc/default/grub && continue

                drop_old_key="s/(^|[ \"])${key//./\\.}(=[^ \"]*)?/\1/g"
                append_arg="s/(GRUB_CMDLINE_LINUX=\"[^\"]*)\"/\1 ${arg}\"/"
                sed -i -E "/^GRUB_CMDLINE_LINUX=/{ $drop_old_key; $append_arg }" /etc/default/grub
                changed=1
            done
            [ $changed = 1 ] && grub2-mkconfig -o /boot/grub2/grub.cfg'
        ```
        <!-- cspell:enable -->

    === "RHEL 10.2"
        ``` { .bash }
        sudo grubby --update-kernel=ALL --args="nohibernate kvm_intel.tdx=1"
        ```

    === "SLES 16.0 QU0"
        <!-- cspell:disable -->

        ``` { .bash }
        sudo bash -c 'changed=0
            for arg in "kvm_intel.tdx=1" "nohibernate"; do
                key=${arg%%=*}
                already_set="^GRUB_CMDLINE_LINUX=.*[ \"]${arg//./\\.}[ \"]"
                grep -qE "$already_set" /etc/default/grub && continue

                drop_old_key="s/(^|[ \"])${key//./\\.}(=[^ \"]*)?/\1/g"
                append_arg="s/(GRUB_CMDLINE_LINUX=\"[^\"]*)\"/\1 ${arg}\"/"
                sed -i -E "/^GRUB_CMDLINE_LINUX=/{ $drop_old_key; $append_arg }" /etc/default/grub
                changed=1
            done
            [ $changed = 1 ] && grub2-mkconfig -o /boot/grub2/grub.cfg'
        ```
        <!-- cspell:enable -->

    === "Ubuntu 26.04"
        <!-- cspell:disable -->
        ``` { .bash }
        sudo bash -c 'changed=0
            for arg in "kvm_intel.tdx=1" "nohibernate"; do
                key=${arg%%=*}
                already_set="^GRUB_CMDLINE_LINUX=.*[ \"]${arg//./\\.}[ \"]"
                grep -qE "$already_set" /etc/default/grub && continue

                drop_old_key="s/(^|[ \"])${key//./\\.}(=[^ \"]*)?/\1/g"
                append_arg="s/(GRUB_CMDLINE_LINUX=\"[^\"]*)\"/\1 ${arg}\"/"
                sed -i -E "/^GRUB_CMDLINE_LINUX=/{ $drop_old_key; $append_arg }" /etc/default/grub
                changed=1
            done
            [ $changed = 1 ] && update-grub'
        ```
        <!-- cspell:enable -->


2. Reboot the system for the kernel command line changes to take effect:

    === "CentOS Stream 10"
        ``` { .bash }
        sudo reboot
        ```

    === "openSUSE 16"
        ``` { .bash }
        sudo reboot
        ```

    === "RHEL 10.2"
        ``` { .bash }
        sudo reboot
        ```

    === "SLES 16.0 QU0"
        ``` { .bash }
        sudo reboot
        ```

    === "Ubuntu 26.04"
        ``` { .bash }
        sudo reboot
        ```

3. If not done before, reboot the system into the BIOS setup menu and configure the [necessary BIOS settings](../04/hardware_setup.md#enable-intel-tdx-in-bios) for Intel TDX-enabling.
    You can use the checks described in the [next section](#check-intel-tdx-enablement) to determine if your BIOS is already configured appropriately.


### Check OS kernel version

In process of time, kernel becomes outdated. With new version comes new features and fixes. To check and manage installed version, can be manually executed the following commands:

Check kernel version

    ``` { .bash }
    uname -r
    ```

Select kernel version to be installed

=== "Ubuntu 24.04"

    ``` { .bash }
    export KERNEL_VERSION=6.17.0-35-generic
    sudo sh -c 'apt update && apt install --allow-downgrades linux-image-$KERNEL_VERSION linux-headers-$KERNEL_VERSION'
    ```

Check currently saved boot entry in GRUB

    ``` { .bash }
    grub-editenv list | sed -e "s/.*gnulinux-//g" -e "s/-generic.*//g" -e "s/-intel.*//g"
    ```

If freshly installed kernel differs from saved boot entry in GRUB

    ``` { .bash }
    read -r -p "Should be changed saved entry? <y/N>: " answer
    case $answer in
    	[Yy]* ) SUBMENU=`sudo grep submenu /boot/grub/grub.cfg  | sed -e "s/.*menuentry_id_option '//g" -e "s/' {//"` 
                MENUENTRY=`sudo grep menuentry /boot/grub/grub.cfg  | grep ${KERNEL_VERSION} | grep advanced | sed -e "s/.*menuentry_id_option '//g" -e "s/' {//g"`
			    echo "Boot Id from /boot/grub/grub.cfg"
			    echo "saved_entry=${SUBMENU}>${MENUENTRY}"
                sudo grub-editenv - set saved_entry="${SUBMENU}>${MENUENTRY}"
			    echo "Double check - boot Id from grub-editenv list"
			    sudo grub-editenv list ;;
	    [Nn]* ) ;;
    esac
    ```


### Check Intel TDX enablement

To check the status of your Intel TDX configuration, you can manually execute the following commands:

- Check whether Intel TDX Module is initialized.
  The expected output contains `tdx: TDX module initialized`.

    ``` { .bash }
    sudo dmesg | grep -i tdx
    ```

- As a prerequisite for the following commands, install the MSR Tools package and load the MSR module.

    === "CentOS Stream 10"

        ``` { .bash }
        sudo dnf config-manager --set-enabled crb
        sudo dnf install -y epel-release
        sudo dnf install  -y msr-tools
        sudo modprobe msr
        ```

    === "openSUSE 16"
        ``` { .bash }
        sudo zypper addrepo https://download.opensuse.org/repositories/openSUSE:Backports:SLE-15-SP6/standard/openSUSE:Backports:SLE-15-SP6.repo
        sudo zypper refresh
        sudo modprobe msr
        sudo zypper install -y msr-tools
        sudo zypper mr -d openSUSE_Backports_SLE-15-SP6
        ```

    === "RHEL 10.2"

        ``` { .bash }
        sudo dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-10.noarch.rpm
        sudo dnf install -y msr-tools
        sudo modprobe msr
        ```

    === "SLES 16.0 QU0"
        ``` { .bash }
        sudo zypper addrepo https://download.opensuse.org/repositories/openSUSE:Backports:SLE-15-SP6/standard/openSUSE:Backports:SLE-15-SP6.repo
        sudo zypper refresh
        sudo modprobe msr
        sudo zypper install -y msr-tools
        sudo zypper mr -d openSUSE_Backports_SLE-15-SP6
        ```

    === "Ubuntu 26.04"

        ``` { .bash }
        sudo apt install -y msr-tools
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


## Set Up Quote Generation Service (QGS)

The main artifact used in a remote attestation flow is the TD Quote, which is generated on the Intel TDX hardware and then transferred to any other party/machine for verification.
To generate a TD Quote, a TD first uses the hardware to generate a TD Report.
This TD Report is then forwarded to an Intel SGX Architectural Enclave, called the TD Quoting Enclave (TDQE).
This enclave takes the incoming TD Report, verifies that the TD Report was generated by a TD on the same platform, and then signs the TD Report with a signature key for which the trust is rooted in an Intel CA.
More details can be found in the [Intel® Trust Domain Extensions Data Center Attestation Primitives (Intel® TDX DCAP): Quote Generation Library and Quote Verification Library](https://download.01.org/intel-sgx/latest/dcap-latest/linux/docs/Intel_TDX_DCAP_Quoting_Library_API.pdf) documentation.

The Quote Generation Service (QGS) is a service that runs in the host OS (or inside a dedicated VM) to host the TDQE.
Note that the QGS cannot run on another machine, because the verification of the TD Report requires that the corresponding TD and the TDQE run on the same machine.

In the following, we describe how to [install the QGS](#install-qgs) and how to [configure it](#configure-qgs) for your environment.
Afterwards, we show how to [restart the QGS](#restart-qgs) so that the configuration changes take effect and how to [check the QGS log](#check-qgs-log) to verify that the service is running as expected.


### Install QGS

1. If not done during another component installation, set up the appropriate Intel SGX package repository for your distribution of choice:
    --8<-- "includes/package_repo_setup.md:sgx-repo_cent-os-stream-10"
    --8<-- "includes/package_repo_setup.md:sgx-repo_opensuse_16"
    --8<-- "includes/package_repo_setup.md:sgx-repo_rhel_10_2"
    --8<-- "includes/package_repo_setup.md:sgx-repo_sles_16"
    --8<-- "includes/package_repo_setup.md:sgx-repo_ubuntu_26_04"

2. Install the QGS with the following command, which will also install the necessary prerequisites:

    === "CentOS Stream 10"

        ``` { .bash }
        sudo dnf install -y tdx-qgs
        ```

    === "openSUSE 16"

        ``` { .bash }
        sudo zypper install -y tdx-qgs
        ```

    === "RHEL 10.2"

        ``` { .bash }
        sudo dnf install -y tdx-qgs
        ```

    === "SLES 16.0 QU0"

        ``` { .bash }
        sudo zypper install -y tdx-qgs
        ```

    === "Ubuntu 26.04"

        ``` { .bash }
        sudo apt install -y tdx-qgs
        ```


### Configure QGS

The QGS is not configured through a single file.
Depending on what you want to change, you have to adjust one of the following two configurations:

1. [QGS Daemon Configuration](#qgs-daemon-configuration): behavior of the QGS daemon, e.g., the transport protocol that TDs use to reach the QGS, the number of worker threads, or the log level.
2. [PCK Certificate Retrieval Configuration](#pck-certificate-retrieval-configuration): behavior of PCK Certificates retrieval, e.g., the address of the collateral caching service (e.g., PCCS) or Intel PCS, the lifetime of the local certificate cache, or the number of retries after a failed request.

The following two subsections explain these configurations in detail.


#### QGS Daemon Configuration

The QGS daemon can be configured in two ways: via a configuration file or via command line arguments.
Both ways are described in the following subsections.

!!! note "Configuration Sources Precedence"
    For every setting that is configured via configuration file **and** via command line argument, the command line argument takes precedence.

##### Configuration File Based Configuration

On start, the QGS reads its configuration file.
The following options can be set in this file:

::spantable:: class="st-w100p"

| Option @class="w020p" | Description |
| ------ | ----------- |
| `port = <port>` | The vsock port that the QGS listens on. Valid values are `0` to `65535`. This setting is commented out by default, with `4050` as the suggested value. As long as it stays commented out, the QGS listens on the Unix domain socket `/var/run/tdx-qgs/qgs.socket` instead. |
| `number_threads = <count>` | The number of worker threads of the QGS. Valid values are `1` to `255`. |

::end-spantable::

To change the configuration file of the QGS, follow these steps:

1. Open the configuration file of the QGS (`/etc/qgs.conf`) in an editor of your choice.
    For example:

    ``` { .bash }
    sudo vim /etc/qgs.conf
    ```

2. Add or adjust settings using the configuration file options presented above.
    A setting only takes effect if its line is not commented out.

3. For the change to take effect, [restart the QGS](#restart-qgs).

##### Command Line Based Configuration

On start, the QGS evaluates its command line arguments, which take precedence over settings in its configuration file.
The following options can be set as command line arguments:

::spantable:: class="st-w100p"

| Option @class="w020p" | Description |
| ------ | ----------- |
| `-p=<port>` | The vsock port that the QGS listens on. Valid values are `0` to `65535`. As long as this argument is not used, the QGS listens on the Unix domain socket `/var/run/tdx-qgs/qgs.socket` instead. |
| `-n=<count>` | The number of worker threads of the QGS. Valid values are `1` to `255`. |
| `-l=<level>` | Log level, exactly one of `error`, `warn`, `info`, or `debug`. Each level includes all messages of the levels above it in the list, so `error` is the most restrictive value and `debug` logs everything. |
| `--no-daemon` | Run in the foreground and write log messages to standard output/standard error instead of the system log. Without this option the QGS runs as a background daemon and logs through `syslog(3)` under the `user` facility with the identifier `qgsd`. On a systemd host, view the log messages with `journalctl -t qgsd`. Otherwise, view the messages in the syslog file for the `user` facility (typically `syslog` or `/var/log/messages`). |

::end-spantable::

To change the command line of the QGS, follow these steps:

1. Open the override file of the service:

    ``` { .bash }
    sudo systemctl edit qgsd
    ```

2. Change the `ExecStart=` entry of the service to add or adjust the command line options presented above.
    An empty `ExecStart=` is required to reset the original command before a new one is set.
    For example, the log level can be set to `debug` with:

    ```text
    [Service]
    ExecStart=
    ExecStart=/opt/intel/tdx-qgs/qgs -l=debug
    ```

3. For the change to take effect, [restart the QGS](#restart-qgs).

??? note "How to find out the path of the QGS binary?"
    The path `/opt/intel/tdx-qgs/qgs` is the one used by the Intel packages installed above.
    If you use a different installation, look up the `ExecStart` line of the shipped unit file before you override it:

    ``` { .bash }
    grep '^ExecStart=' "$(systemctl show --property=FragmentPath --value qgsd)"
    ```

    The `FragmentPath` property always refers to the shipped unit file, so the output of this command is not affected by an override that you or the installation might have created before.

??? note "How to undo an override of the `qgsd` service?"
    All overrides that you create with `systemctl edit qgsd` are stored in the drop-in file `/etc/systemd/system/qgsd.service.d/override.conf`.
    Steps to remove the override:

    1. Delete the override file and make systemd reload its unit configuration:

        ``` { .bash }
        sudo rm -f /etc/systemd/system/qgsd.service.d/override.conf
        sudo systemctl daemon-reload
        ```

        !!! warning
            Do not use `systemctl revert qgsd` instead.
            That command removes the whole `qgsd.service.d/` directory with all the files it contains, including the `socket.conf` that the installation of the QGS created to configure the runtime directory and the permissions of the Unix domain socket.

    2. For the change to take effect, [restart the QGS](#restart-qgs).


#### PCK Certificate Retrieval Configuration

To generate a TD Quote, the QGS needs the PCK Certificate of the platform at the platform's current TCB level.
In short, the QGS fetches the PCK Certificate using QCNL, which is why the settings below configure the QCNL.
For additional details, see the "Additional Background" box below.
On successful TD Quote generation, the QGS embeds the PCK Certificate in the TD Quote, enabling verifiers to validate the attestation chain back to Intel.

??? note "Additional Background"
    Retrieving the PCK Certificate involves several components that QGS loads in-process at runtime, each shipping in its own package:

    - TDQE:
        - Derives an asymmetric *attestation key* on demand, either when the QGS explicitly requests an initialization or lazily on the first TD Quote request.
        The attestation key is cached and re-used as long as CPUSVN, TDQE ISVSVN, and PCE ISVSVN stay the same since the key was last generated; otherwise, the key is re-generated.<br>
            - For more details about the key derivation, see Section 3.5.2 of the [Intel SGX ECDSA QuoteLib Reference (DCAP API)](https://download.01.org/intel-sgx/latest/dcap-latest/linux/docs/Intel_SGX_ECDSA_QuoteLibReference_DCAP_API.pdf).
            - The attestation key is cached and re-used as long as CPUSVN, TDQE ISVSVN, and PCE ISVSVN stay the same since the key was last generated; otherwise, the key is re-generated.
        - Submits a QE Report, which carries a hash of the attestation key's public part as report data, to the PCE for certification.
        - Signs TD Quotes using the private part of the attestation key.
    - PCE:
        - Derives the private part of the platform's *PCK* and signs the TDQE's QE Report with it, certifying the attestation key against the platform's CPUSVN and PCE ISVSVN.
        The PCE is the only enclave allowed to derive a PCK.
     - QPL:
        - Receives a PCK Certificate request from the QGS for a certain CPUSVN and PCE ISVSVN.
        - Delegates the request to the QCNL.
    - QCNL:
        - Receives a PCK Certificate request from the QPL for a certain CPUSVN and PCE ISVSVN.
        - Fetches the PCK Certificate, which contains the PCK public key for the given CPUSVN and PCE ISVSVN, from a collateral caching service (e.g., PCCS) or Intel PCS, and handles the local caching described below.

The QCNL does not have to contact a collateral caching service (e.g., PCCS) or Intel PCS for every TD Quote request.
Instead, it can keep a local cache on the host storing each PCK Certificate that it has retrieved, and only send a request if this cache holds no valid PCK Certificate.

The settings described in this section configure the QCNL, and thus determine where the QGS gets PCK Certificates from, whether the PCK Certificates are cached, and how the PCK Certificates are cached.
The settings are stored in a configuration file in JSON format.
As the QGS is only responsible for quote generation, and not for quote verification, we only describe the corresponding QCNL settings in the following.
To see all settings and the default values, refer to the [default configuration file](https://github.com/intel/confidential-computing.tee.dcap/blob/main/QuoteGeneration/qcnl/linux/sgx_default_qcnl.conf).

::spantable:: class="st-w100p"

<!-- markdownlint-disable MD033 -->
| Setting @class="w025p" | Description |
| ------- | ----------- |
| `pccs_url` | Address of the service that the PCK Certificate is retrieved from, which in most cases is a collateral caching service (e.g., PCCS). Alternatively, the setting can be used to point to Intel PCS directly using `https://api.trustedservices.intel.com/sgx/certification/v4/`.<br /><br />**Note:** Directly using Intel PCS is only allowed for low-frequency testing purposes (e.g., Proof of Concepts, testing, CI/CD pipelines). For more info about using Intel PCS directly including restrictions, please see the notes in the [Intel TDX Quote Generation and Quote Verification Collateral](../02/infrastructure_setup.md#intel-tdx-quote-generation-and-quote-verification-collateral) section. |
| `use_secure_cert` | Defines whether the HTTPS certificate of the collateral retrieval endpoint is verified. Set it to `false` to accept an insecure certificate, for example a self-signed one.<br /><br />**Note:** You must not use insecure HTTPS certificates in a production environment. |
| `retry_times` | Number of retries after a failed request. A request is retried if the connection could not be established, if it timed out, or if the service answered with the HTTP status code `503`. The defined number of retries applies per endpoint: if `local_pck_url` is configured, it is retried independently from `pccs_url`, so failed PCK Certificate requests can result in up to twice the number of total attempts. A value of `0` disables retrying. |
| `retry_delay` | Delay in seconds before each retry. A value of `0` makes the QCNL wait one second before the first retry and then double the waiting time for every further retry. |
| `local_pck_url` | Address of an additional service for PCK Certificate retrieval. The lookup order is: `local_pck_url` → local cache → `pccs_url`. Responses from this additional service are never written to the local cache. |
| `pck_cache_expire_hours` | Lifetime in hours of the local cache for PCK Certificates that were retrieved from `pccs_url`. A value of `0` disables the client-side cache TTL, and values above `2160` (90 days) are reduced to `2160`. Note that the `Cache-Control: max-age` header in the service's HTTP response takes precedence over this setting; if the service returns a non-zero `max-age`, responses are cached for that duration regardless of this setting. |
| `local_cache_only` | If set to `true`, the QCNL exclusively uses PCK Certificates from local cache files and does not send requests to any PCK Certificate service provider. In this case, an administrator has to pre-populate the cache folders, for example with cache files generated by the [PCS Client Tool](../../../intel-sgx-tdx-pccs/09/pcs_client_tool/). |
<!-- markdownlint-enable MD033 -->

::end-spantable::

??? note "Location of the local cache files"
    The local cache files live in a folder named `.dcap-qcnl` and its location is chosen from the ordered list `$AZDCAP_CACHE`, `$XDG_CACHE_HOME`, `$HOME`, `$TMPDIR`, and `/tmp/`.
     To determine the location of `.dcap-qcnl/`, QCNL first traverses the list of locations in order and checks whether `.dcap-qcnl/` exists.
    If `.dcap-qcnl/` does exist, QCNL uses the found folder.
    If `.dcap-qcnl/` doesn't exist in any of the locations, QCNL again traverses the list of locations in order and tries to create the folder.
    A location defined by an environment variable is skipped if that variable is unset or empty; `/tmp/` is a fixed fallback and is never skipped for this reason.
    Additionally, a location is skipped if its directory cannot be created (e.g., no write permission or the parent directory doesn't exist).
    Note that the environment variables are evaluated for the user that runs the process loading the QPL, which is the `qgsd` user in the case of the QGS.


To change the configuration of the QCNL, follow these steps:

1. Open the configuration file of the QCNL (default: `/etc/sgx_default_qcnl.conf`) in an editor of your choice.
    For example:

    ``` { .bash }
    sudo vim /etc/sgx_default_qcnl.conf
    ```

    ??? note "How to use a QCNL configuration file at a different path?"
        If you prefer, you can rename the `sgx_default_qcnl.conf` file and/or move it to another location.
        On start of the `qgsd` service, the QCNL is loaded and `qgsd` evaluates the environment variable `QCNL_CONF_PATH`, which can override the default path of the configuration file.
        To change the path of the QCNL configuration file, follow these steps:

        1. Open the override file of the `qgsd` service:

            ``` { .bash }
            sudo systemctl edit qgsd
            ```

        2. Add the environment variable to the `[Service]` section, pointing to the new name and/or location of the configuration file:

            ```text
            [Service]
            Environment=QCNL_CONF_PATH=/etc/sgx_qcnl_local_pccs.conf
            ```

        3. For the change to take effect, [restart the QGS](#restart-qgs).

2. Add or adjust the settings presented above.
    For example, the URL of your collateral caching service can be adjusted by changing the following line appropriately:

    ```text
    "pccs_url": "https://<PCCS URL:port>/sgx/certification/v4/"
    ```

3. For the change to take effect, [restart the QGS](#restart-qgs).


### Restart QGS

To restart the QGS, execute the following command:

=== "CentOS Stream 10"

    ``` { .bash }
    sudo systemctl restart qgsd.service
    ```

=== "openSUSE 16"

    ``` { .bash }
    sudo systemctl restart qgsd.service
    ```

=== "RHEL 10.2"

    ``` { .bash }
    sudo systemctl restart qgsd.service
    ```

=== "SLES 16.0 QU0"

    ``` { .bash }
    sudo systemctl restart qgsd.service
    ```

=== "Ubuntu 26.04"

    ``` { .bash }
    sudo systemctl restart qgsd.service
    ```


### Check QGS Log

To check the service log of the QGS, execute the following command:

=== "CentOS Stream 10"

    ``` { .bash }
    # Note: remove `-f` for non-interactive log
    sudo journalctl -u qgsd -f
    ```

=== "openSUSE 16"

    ``` { .bash }
    # Note: remove `-f` for non-interactive log
    sudo journalctl -u qgsd -f
    ```

=== "RHEL 10.0"

    ``` { .bash }
    # Note: remove `-f` for non-interactive log
    sudo journalctl -u qgsd -f
    ```

=== "SLES 16.0 QU0"

    ``` { .bash }
    # Note: remove `-f` for non-interactive log
    sudo journalctl -u qgsd -f
    ```

=== "Ubuntu 26.04"

    ``` { .bash }
    # Note: remove `-f` for non-interactive log
    sudo journalctl -u qgsd -f
    ```
