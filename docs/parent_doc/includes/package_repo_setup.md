<!-- markdownlint-disable MD041 -->
--8<-- [start:sgx-repo_cent-os-stream-9]

=== "CentOS Stream 9"

    ``` { .bash }
    --8<-- "includes/sgx_repo_setup.sh:cent-os-stream-9"
    ```

--8<-- [end:sgx-repo_cent-os-stream-9]

<!-- --- -->

--8<-- [start:sgx-repo_rhel_9_4_kvm]

=== "Red Hat Enterprise Linux 9.4 KVM"

    ``` { .bash }
    --8<-- "includes/sgx_repo_setup.sh:rhel_9_4_kvm"
    ```

--8<-- [end:sgx-repo_rhel_9_4_kvm]

<!-- --- -->

--8<-- [start:sgx-repo_ubuntu_24_04-online_only]

=== "Ubuntu 24.04"

    ``` { .bash }
    --8<-- "includes/sgx_repo_setup.sh:ubuntu_24_04"
    ```

--8<-- [end:sgx-repo_ubuntu_24_04-online_only]

<!-- --- -->

--8<-- [start:sgx-repo_ubuntu_24_04]

=== "Ubuntu 24.04"

    === "*Option 1:* Online repository"

        ``` { .bash }
        --8<-- "includes/sgx_repo_setup.sh:ubuntu_24_04"
        ```

    === "*Option 2:* Local (offline) repository"

        ``` { .bash }
        --8<-- "includes/sgx_repo_setup.sh:ubuntu_24_04_OFFLINE"
        ```

--8<-- [end:sgx-repo_ubuntu_24_04]

<!-- --- -->

--8<-- [start:sgx-repo_opensuse_leap_15_6]

=== "openSUSE Leap 15.6 or SUSE Linux Enterprise Server 15-SP6"

    ``` { .text }
    --8<-- "includes/sgx_repo_setup.sh:opensuse_leap_15_6"
    ```

--8<-- [end:sgx-repo_opensuse_leap_15_6]
