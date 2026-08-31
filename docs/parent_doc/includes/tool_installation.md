<!-- markdownlint-disable MD041 -->
--8<-- [start:pcs-client-tool-install]
=== "*Option 1:* Tool from package"

    - If not done during another component installation, set up the appropriate Intel SGX package repository for your distribution of choice:

        --8<-- "includes/package_repo_setup.md:sgx-repo_cent-os-stream-10"
        --8<-- "includes/package_repo_setup.md:sgx-repo_opensuse_16"
        --8<-- "includes/package_repo_setup.md:sgx-repo_rhel_10_2"
        --8<-- "includes/package_repo_setup.md:sgx-repo_sles_16"
        --8<-- "includes/package_repo_setup.md:sgx-repo_ubuntu_26_04"

    - Install PCS Client Tool:

        === "CentOS Stream 10"

            ``` { .bash }
            --8<-- "includes/tool_installation.sh:pcs_client_tool-package-cent-os-stream-10"
            ```

        === "openSUSE 16"

            ``` { .bash }
            --8<-- "includes/tool_installation.sh:pcs_client_tool-package-opensuse_16"
            ```

        === "RHEL 10.2"

            ``` { .bash }
            --8<-- "includes/tool_installation.sh:pcs_client_tool-package-rhel_10_2"
            ```

        === "SLES 16.0 QU0"

            ``` { .bash }
            --8<-- "includes/tool_installation.sh:pcs_client_tool-package-sles_16"
            ```

        === "Ubuntu 26.04"

            ``` { .bash }
            --8<-- "includes/tool_installation.sh:pcs_client_tool-package-ubuntu_26_04"
            ```

=== "*Option 2:* Tool from source"

    === "CentOS Stream 10"

        ``` { .bash }
        --8<-- "includes/tool_installation.sh:pcs_client_tool-source-cent-os-stream-10"
        ```

    === "openSUSE 16"

        ``` { .bash }
        --8<-- "includes/tool_installation.sh:pcs_client_tool-source-opensuse_16"
        ```

    === "RHEL 10.2"

        ``` { .bash }
        --8<-- "includes/tool_installation.sh:pcs_client_tool-source-rhel_10_2"
        ```

    === "SLES 16.0 QU0"

        ``` { .bash }
        --8<-- "includes/tool_installation.sh:pcs_client_tool-source-sles_16"
        ```

    === "Ubuntu 26.04"

        ``` { .bash }
        --8<-- "includes/tool_installation.sh:pcs_client_tool-source-ubuntu_26_04"
        ```

    !!! Note
        When no longer needed, the virtual Python environment can be deactivated by executing `deactivate`.

--8<-- [end:pcs-client-tool-install]


--8<-- [start:pccs-admin-tool-install]
=== "*Option 1:* Tool from package"

    - If not done during another component installation, set up the appropriate Intel SGX package repository for your distribution of choice:

        --8<-- "includes/package_repo_setup.md:sgx-repo_cent-os-stream-10"
        --8<-- "includes/package_repo_setup.md:sgx-repo_opensuse_16"
        --8<-- "includes/package_repo_setup.md:sgx-repo_rhel_10_2"
        --8<-- "includes/package_repo_setup.md:sgx-repo_sles_16"
        --8<-- "includes/package_repo_setup.md:sgx-repo_ubuntu_26_04"

    - Install PCCS Admin Tool:

        === "CentOS Stream 10"

            ``` { .bash }
            --8<-- "includes/tool_installation.sh:pccs_admin_tool-package-cent-os-stream-10"
            ```

        === "openSUSE 16"

            ``` { .bash }
            --8<-- "includes/tool_installation.sh:pccs_admin_tool-package-opensuse_16"
            ```

        === "RHEL 10.2"

            ``` { .bash }
            --8<-- "includes/tool_installation.sh:pccs_admin_tool-package-rhel_10_2"
            ```

        === "SLES 16.0 QU0"

            ``` { .bash }
            --8<-- "includes/tool_installation.sh:pccs_admin_tool-package-sles_16"
            ```

        === "Ubuntu 26.04"

            ``` { .bash }
            --8<-- "includes/tool_installation.sh:pccs_admin_tool-package-ubuntu_26_04"
            ```

        !!! Note
            If the PCCS package (`sgx-dcap-pccs`) has been installed via a package manager, `intel-tee-pccs-admin-tool` might be installed and available already due to it being **recommended** by the PCCS package.

=== "*Option 2:* Tool from source"

    === "CentOS Stream 10"

        ``` { .bash }
        --8<-- "includes/tool_installation.sh:pccs_admin_tool-source-cent-os-stream-10"
        ```

    === "openSUSE 16"

        ``` { .bash }
        --8<-- "includes/tool_installation.sh:pccs_admin_tool-source-opensuse_16"
        ```

    === "RHEL 10.2"

        ``` { .bash }
        --8<-- "includes/tool_installation.sh:pccs_admin_tool-source-rhel_10_2"
        ```

    === "SLES 16.0 QU0"

        ``` { .bash }
        --8<-- "includes/tool_installation.sh:pccs_admin_tool-source-sles_16"
        ```

    === "Ubuntu 26.04"

        ``` { .bash }
        --8<-- "includes/tool_installation.sh:pccs_admin_tool-source-ubuntu_26_04"
        ```

    !!! Note
        When no longer needed, the virtual Python environment can be deactivated by executing `deactivate`.

--8<-- [end:pccs-admin-tool-install]
