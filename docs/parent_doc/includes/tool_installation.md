<!-- markdownlint-disable MD041 -->
--8<-- [start:pcs-client-tool-install]
=== "*Option 1:* Tool from package"

    - If not done during another component installation, set up the appropriate Intel SGX package repository for your distribution of choice:

        --8<-- "includes/package_repo_setup.md:sgx-repo_cent-os-stream-9"
        --8<-- "includes/package_repo_setup.md:sgx-repo_ubuntu_24_04"

    - Install PCS Client Tool:

        === "CentOS Stream 9"

            ``` { .bash }
            --8<-- "includes/tool_installation.sh:pcs_client_tool-package-cent_os_stream_9"
            ```

        === "Ubuntu 24.04"

            ``` { .bash }
            --8<-- "includes/tool_installation.sh:pcs_client_tool-package-ubuntu_24_04"
            ```

=== "*Option 2:* Tool from source"

    === "CentOS Stream 9"

        ``` { .bash }
        --8<-- "includes/tool_installation.sh:pcs_client_tool-source-cent_os_stream_9"
        ```

    === "Ubuntu 24.04"

        ``` { .bash }
        --8<-- "includes/tool_installation.sh:pcs_client_tool-source-ubuntu_24_04"
        ```

    !!! Note
        When no longer needed, the virtual Python environment can be deactivated by executing `deactivate`.

--8<-- [end:pcs-client-tool-install]


--8<-- [start:pccs-admin-tool-install]
=== "*Option 1:* Tool from package"

    - If not done during another component installation, set up the appropriate Intel SGX package repository for your distribution of choice:

        --8<-- "includes/package_repo_setup.md:sgx-repo_cent-os-stream-9"
        --8<-- "includes/package_repo_setup.md:sgx-repo_ubuntu_24_04"

    - Install PCCS Admin Tool:

        === "CentOS Stream 9"

            ``` { .bash }
            --8<-- "includes/tool_installation.sh:pccs_admin_tool-package-cent_os_stream_9"
            ```

        === "Ubuntu 24.04"

            ``` { .bash }
            --8<-- "includes/tool_installation.sh:pccs_admin_tool-package-ubuntu_24_04"
            ```

        !!! Note
            If the PCCS package (`sgx-dcap-pccs`) has been installed via a package manager, `intel-tee-pccs-admin-tool` might be installed and available already due to it being **recommended** by the PCCS package.

=== "*Option 2:* Tool from source"

    === "CentOS Stream 9"

        ``` { .bash }
        --8<-- "includes/tool_installation.sh:pccs_admin_tool-source-cent_os_stream_9"
        ```

    === "Ubuntu 24.04"

        ``` { .bash }
        --8<-- "includes/tool_installation.sh:pccs_admin_tool-source-ubuntu_24_04"
        ```

    !!! Note
        When no longer needed, the virtual Python environment can be deactivated by executing `deactivate`.

--8<-- [end:pccs-admin-tool-install]
