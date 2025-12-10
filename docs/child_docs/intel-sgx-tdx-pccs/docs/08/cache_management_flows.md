---
description: Cache management flows and operational procedures for the Intel SGX/TDX Provisioning Certificate Caching Service (PCCS).
keywords: PCCS, DCAP, cache management, flows, operations, caching service, Confidential Computing, SGX, TDX
---
<!---
Copyright (C) 2025 Intel Corporation
SPDX-License-Identifier: CC-BY-4.0
-->

# Cache Management Flows


## Platform Registration

The PCCS maintains a queue of platform information called the [`platforms_registered`](../04/database.md#platforms_registered) table.
Datacenter and CSP owners add new Intel® SGX platforms to this queue using the [Post Platforms IDs](../03/api_specification_for_pccs.md#post-platforms-ids) API.
Platform registration is expected to happen before runtime workloads are executed by tenants.
The queue contains all of the platform information provided in the [Post Platforms IDs](../03/api_specification_for_pccs.md#post-platforms-ids) API.

The PCCS adds the platform ID to the queue if any of the following are true:

1. An entry for that platform is not already in the PCCS's caching database.
    1. The platform is already in the database if the `EncPPID` and the `PLATFORM_MANIFEST` in the [Post Platforms IDs](../03/api_specification_for_pccs.md#post-platforms-ids) request is the same as the platform ID already in PCCS's caching database.
2. The `PLATFORM_MANIFEST` in the registration request is different than the platform's `PLATFORM_MANIFEST` in the database.
3. Any of the collaterals (PCK Certificates + verification collateral) for that platform entry is not already in the database.


### Cache Fill Mode is [`LAZY`](../05/cache_fill_modes.md#lazy-cache-fill-mode) or [`REQ`](../05/cache_fill_modes.md#req-cache-fill-mode)

When the PCCS gets the [Post Platforms IDs](../03/api_specification_for_pccs.md#post-platforms-ids) request and adds a platform to the queue, it contacts the PCS to retrieve the platform's PCK Certificates.

- If the request contains the `PLATFORM_MANIFEST`, it uses the PCS API to retrieve multiple PCK Certificates using the `{PLATFORM_MANIFEST,PCEID}` tuple.
- If the `PLATFORM_MANIFEST` is not present, it uses the PCS API to retrieve multiple PCK Certificates using the `{EncPPID,PCEID}` tuple.

Once the PCCS retrieves the PCK Certificates, the corresponding verification collateral is also retrieved in the following way:

1. **TCB Info**:
    1. Extract the FMSPC from the PCK Leaf Cert.
    2. If the TCB Info for that FMSPC is not already in the database, the PCCS retrieves the TCB Info from the PCS.
2. **Intel PCK Certificate CA CRL**:
    1. Extract the FMSPC from the PCK Leaf Cert.
    2. If the TCB Info for that FMSPC is not already in the database, the PCCS retrieves the TCB Info from the PCS.
3. **QE Identity** – If not already in the database.
4. **QvE Identity** – If not already in the database.
5. **Intel SGX Root CA CRL**:
    1. The URL for the Intel SGX Root CA CRL needs to be extracted from the CDP field of one of the intermediate certs or the Intel SGX Root Cert.

If all the PCK Certificates and their associated collaterals are successfully retrieved (or already in the database), the PCCS creates the platform entry in the database.
Otherwise, the PCCS' [Post Platforms IDs](../03/api_specification_for_pccs.md#post-platforms-ids) API returns `"Unable to retrieve the collateral from the PCS."` in response to the request.

/// note
When the caching server is configured for the [`LAZY`](../05/cache_fill_modes.md#lazy-cache-fill-mode) cache fill mode, this registration step is not required.
When in [`LAZY`](../05/cache_fill_modes.md#lazy-cache-fill-mode) cache fill mode, the PCCS retrieves the respective platform collateral in response to the runtime request APIs:

1. [Get PCK Certificate](../03/api_specification_for_pccs.md#get-pck-certificate)
2. [Get PCK Certificate CRL](../03/api_specification_for_pccs.md#get-pck-certificate-crl)
3. [Get TCB Info](../03/api_specification_for_pccs.md#get-tcb-info)
4. [Get Intel's QE Identity](../03/api_specification_for_pccs.md#get-intels-qe-identity)
5. [Get Intel's QvE Identity](../03/api_specification_for_pccs.md#get-intels-qve-identity)
6. [Get Root CA CRL](../03/api_specification_for_pccs.md#get-intels-td-qe-identity)

This requires that the PCCS have access to the Internet during runtime workloads initiated by a tenant VM without requiring access to the PCCS admin token.
///


### Cache Fill Mode is [`OFFLINE`](../05/cache_fill_modes.md#offline-cache-fill-mode)

In this cache fill mode, the following steps make up the registration flow:

1. Registration information (i.e., the Platform Manifest and other platform-related information) must be retrieved from the target platforms and this registration information must be sent to PCCS using the [Post Platforms IDs](../03/api_specification_for_pccs.md#post-platforms-ids) API.
The [PCK Cert ID Retrieval Tool](https://github.com/intel/SGXDataCenterAttestationPrimitives/tree/main/tools/PCKRetrievalTool) can be used for these tasks.
2. The platform registration information enqueued in the PCCS must be retrieved using the [Get Platform IDs](../03/api_specification_for_pccs.md#get-platform-ids) API.
    The enqueued registration information can be collected from the PCCS using the [Get Platforms IDs](../03/api_specification_for_pccs.md#get-platform-ids).
    The [`get` operation](../07/pccs_admin_tool.md#get) of the [PCCS Admin Tool](../07/pccs_admin_tool.md) can be used for this request.
    The tool saves the result to a JSON file.

3. The retrieved registration collateral must be submitted to PCS to obtain attestation collateral.
    This step requires Internet connectivity, which might require manually transferring the JSON file from step 2 to another machine.
    The [`fetch` operation](../09/pcs_client_tool.md#fetch) of the [PCS Client Tool](../09/pcs_client_tool.md) can consume the JSON file from step 2 and retrieve the quote generation collateral (i.e., PCK Certificates).
    Additionally, the tool retrieves quote verification collateral (e.g., TCB Info, QE Identity, and QvE Identity).
    The tool saves both types of collateral to a new JSON file.
4. Finally, the resulting collateral must be imported back into the PCCS using its [Put Platform Collateral to Cache](../03/api_specification_for_pccs.md#put-platform-collateral-to-cache) API.
    This operation can be performed via the [PCCS Admin Tool](../07/pccs_admin_tool.md)'s [`put` operation](../07/pccs_admin_tool.md#put), which reads the JSON file from step 3.
    If the machine that was used to retrieve the collateral from PCS does not have access to PCCS, it is necessary to manually transfer the resulting JSON file to a machine with access.


## Handling TCB Recoveries

When a security vulnerability is found and it affects one of the components in the Intel® SGX TCB or Intel® TDX TCB, a TCB-R process starts.
As soon as a TCB-R is publicly announced, new PCK Certificates (for affected platforms) and updated verification collateral (e.g., TCB Info, QE Identity, and QVE Identity) is retrievable from PCS.
As a result, the PCCS must be updated with new PCK Certificates - for all platforms affected by the TCB-R - and with all verification collaterals - regardless of affected platforms.


### Cache Fill Mode is [`LAZY`](../05/cache_fill_modes.md#lazy-cache-fill-mode) or [`REQ`](../05/cache_fill_modes.md#req-cache-fill-mode)

In these cache fill modes, the PCCS has an Internet connection.
An administrator can request an update in two ways:

1. List of affected FMSPC's **is not** known:
    1. Re-register all platforms in the CSP or database using the [Post Platforms IDs](../03/api_specification_for_pccs.md#post-platforms-ids) request.
    This ensures all platforms that can generate a new PLATFORM_MANIFEST on TCB Recoveries get the PCK Certificates associated with this TCB Recovery.

        ??? info "(Re-)registration: Tool information"

            [PCK Cert ID Retrieval Tool](https://github.com/intel/SGXDataCenterAttestationPrimitives/tree/master/tools/PCKRetrievalTool) tool may be used for registration data collateral retrieval and direct upload into the PCCS using the [Post Platforms IDs](../03/api_specification_for_pccs.md#post-platforms-ids) API.<br/>
            By default, the PCKCIDRT attempts automated upload of collected registration data to the PCCS set in its configuration file, but PCCS invocation can also be triggered explicitly by providing the URL in the CLI, for example via:

            - `sudo PCKIDRetrievalTool -defaulturl`
            - `sudo PCKIDRetrievalTool -url https://YOUR_PCCS_URL:YOUR_PCCS_PORT -user_token YOUR_USER_TOKEN -proxy_type YOUR_PROXY_TYPE -use_secure_cert true`

            ??? note "Alternative: PCCS not directly reachable by PCKCIDRT tool"

                In a rare scenario when the PCKCIDRT on the target platform does **not** have direct connectivity to the PCCS[^no-pccs-from-host], the updated registration data may be stored in a CSV file instead.

                [^no-pccs-from-host]: This is a niche scenario. In most deployments, the PCCS is directly reachable from the target systems, including at the time of (re-)registration.

                For example, by using the following command:

                - `sudo PCKIDRetrievalTool -f host_$(hostnamectl --static).csv`

                Subsequently, the registration data may be directly submitted to the PCS service, using the [PCS Client Tool](../09/pcs_client_tool.md)'s [`collect` operation](../09/pcs_client_tool.md#collect), followed by a [`fetch` operation](../09/pcs_client_tool.md#fetch).
                The resulting quote generation collateral can then be uploaded to the PCCS, using [PCCS Admin Tool](../07/pccs_admin_tool.md)'s [`put` operation](../07/pccs_admin_tool.md#put).

                For example:[^pccsadmin-packaging-variants]

                === "*Option 1*: Packaged tools"
                    ``` { .bash }
                    pcs-client-tool collect -d DIRECTORY_CONTAINING_CSV_FILES -o platform_list.json

                    # Note Internet connectivity is required for next command
                    pcs-client-tool fetch -i platform_list.json -o platform_collaterals.json

                    # Note PCCS connectivity is required for next command
                    pccs-admin-tool put -i platform_collaterals.json
                    ```

                === "*Option 2*: Tools installed from source"

                    ``` { .bash }
                    ./pcsclient.py collect -d DIRECTORY_CONTAINING_CSV_FILES -o platform_list.json

                    # Note Internet connectivity is required for next command
                    ./pcsclient.py fetch -i platform_list.json -o platform_collaterals.json

                    # Note PCCS connectivity is required for next command
                    ./pccsadmin.py put -i platform_collaterals.json
                    ```

        [^pccsadmin-packaging-variants]: The name of the tool depends on the installation method. While `pccsadmin.py` is the script name, the `intel-tee-pccs-admin-tool` package additionally provides a convenience wrapper around its invocation in *Python virtualenv*, invocable system-wide, via `pccs-admin-tool`.

        [^pcsclient-packaging-variants]: The name of the tool depends on the installation method. While `pcsclient.py` is the script name, the `intel-tee-pcs-client-tool` package additionally provides a convenience wrapper around its invocation in *Python virtualenv*, invocable system-wide, via `pcs-client-tool`.


    2. Send the [Refresh through HTTP Request](../03/api_specification_for_pccs.md#refresh-through-http-request) with the optional `type` field `certs` option and without the optional `fmspc` field.
        This will refresh all the **PCK Certificates** in the cache for all registered platforms.

        - The [PCCS Admin Tool](../07/pccs_admin_tool.md)'s [`refresh` operation](../07/pccs_admin_tool.md#refresh) can be used to trigger the [aforementioned API](../03/api_specification_for_pccs.md#refresh-through-http-request) via the CLI.[^pccsadmin-packaging-variants]

            === "*Option 1*: Packaged tools"
                ``` { .bash }
                pccs-admin-tool refresh -f all
                ```

            === "*Option 2*: Tools installed from source"

                ``` { .bash }
                python pccsadmin.py refresh -f all
                ```

    3. Send the [Refresh through HTTP Request](../03/api_specification_for_pccs.md#refresh-through-http-request) without the optional `type` field option and without the optional `fmspc` field.
    This will refresh all the **verification collateral** in the cache.
        - The [PCCS Admin Tool](../07/pccs_admin_tool.md)'s [`refresh` operation](../07/pccs_admin_tool.md#refresh) can be used for this [API request](../03/api_specification_for_pccs.md#refresh-through-http-request)[^pccsadmin-packaging-variants]

            === "*Option 1*: Packaged tools"
                ``` { .bash }
                pccs-admin-tool refresh
                ```

            === "*Option 2*: Tools installed from source"
                ``` { .bash }
                python pccsadmin.py refresh
                ```

2. List of affected FMSPC's **is** known:
    1. Send the [Refresh through HTTP Request](../03/api_specification_for_pccs.md#refresh-through-http-request) with the optional `type` field `certs` option and the optional `fmspc` to the list of FMSPCs affected by the TCB Recovery.
        This will refresh all the **PCK Certificates** in the cache for all registered platforms.
        - The [PCCS Admin Tool](../07/pccs_admin_tool.md)'s [`refresh` operation](../07/pccs_admin_tool.md#refresh) can be used for this [API request](../03/api_specification_for_pccs.md#refresh-through-http-request)[^pccsadmin-packaging-variants]

            === "*Option 1*: Packaged tools"
                ``` { .bash }
                pccs-admin-tool refresh -f [FMSPC1, FMSPC2, ...]
                ```

            === "*Option 2*: Tools installed from source"

                ``` { .bash }
                python pccsadmin.py refresh -f [FMSPC1, FMSPC2, ...]
                ```

    2. Send the [Refresh through HTTP Request](../03/api_specification_for_pccs.md#refresh-through-http-request) without the optional `type` field option and without the optional `fmspc` field.
        This will refresh all the **verification collateral** in the cache.
        - The [PCCS Admin Tool](../07/pccs_admin_tool.md)'s [`refresh` operation](../07/pccs_admin_tool.md#refresh) can be used for this [API request](../03/api_specification_for_pccs.md#refresh-through-http-request)[^pccsadmin-packaging-variants]

            === "*Option 1*: Packaged tools"
                ``` { .bash }
                pccs-admin-tool refresh
                ```

            === "*Option 2*: Tools installed from source"

                ``` { .bash }
                python pccsadmin.py refresh
                ```


### Cache Fill Mode is [`OFFLINE`](../05/cache_fill_modes.md#offline-cache-fill-mode)

In this cache fill mode, the PCCS will not request any data from PCS by itself.
Instead, all collateral must be pushed to the PCCS manually, which can be done using the [PCCS Admin Tool](../07/pccs_admin_tool.md).

1. Re-register all platforms in the CSP or database using the [Post Platforms IDs](../03/api_specification_for_pccs.md#post-platforms-ids) request.
    This ensures all platforms that can generate a new `PLATFORM_MANIFEST` on TCB Recoveries get the PCK Certificates associated with this TCB Recovery.
2. On a machine that has a PCCS connection, use the [PCCS Admin Tool](../07/pccs_admin_tool.md) to retrieve the registered platform IDs from the cache[^pccsadmin-packaging-variants]:

    === "*Option 1*: Packaged tools"
        ``` { .bash }
        pccs-admin-tool get -s [FMSPC1,FMSPC2, …] -t YOUR_PCCS_ADMIN_TOKEN
        ```

    === "*Option 2*: Tools installed from source"
        ``` { .bash }
        python pccsadmin.py get -s [FMSPC1,FMSPC2, …] -t YOUR_PCCS_ADMIN_TOKEN
        ```

    !!! note
        Use empty brackets `[]` to get the platform IDs for all FMSPCs.

3. Use the [PCS Client Tool](../09/pcs_client_tool.md) to fetch collateral from the PCS.[^pcsclient-packaging-variants]
    The tool must run on a machine that has an Internet connection.

    === "*Option 1*: Packaged tools"
        ``` { .bash }
        pcs-client-tool fetch -k YOUR_INTEL_PCS_API_KEY
        ```

    === "*Option 2*: Tools installed from source"

        ``` { .bash }
        python pcsclient.py fetch -k YOUR_INTEL_PCS_API_KEY
        ```

4. Use the [PCCS Admin Tool](../07/pccs_admin_tool.md) to put the collateral into the cache.[^pccsadmin-packaging-variants]

    === "*Option 1*: Packaged tools"
        ``` { .bash }
        pccs-admin-tool put -t YOUR_PCCS_ADMIN_TOKEN
        ```

    === "*Option 2*: Tools installed from source"

        ``` { .bash }
        python pccsadmin.py put -t YOUR_PCCS_ADMIN_TOKEN
        ```


### Special handling of Multi-Package TCB Recovery

There may be cases where a TCB Recovery requires a microcode patch.
There is no guarantee that a given platform will be patched with the new microcode patch before Intel announces the TCB Recovery.
In this case, the PCS will not be able to generate all PCK Certificates required for this TCB Recovery.
When this happens, the `Get PCK Certificates` API of the PCS will return a `Not available` string instead of the PEM encoded PCK Certificate for the affected TCB Levels.
Until the missing PCK Certificates exist in the PCCS database, the PCCS will return the PCK Certificate with the highest TCB for the requesting platform.

The PCCS and the [PCCS Admin Tool](../07/pccs_admin_tool.md) will provide information to the PCCS administrator when this occurs.
This allows the administrator to retry the TCB Recovery related collateral refresh for the affected platforms.
The method of indication depends on the cache fill mode.


#### Cache Fill Mode is [`LAZY`](../05/cache_fill_modes.md#lazy-cache-fill-mode)

The PCCS will automatically handle this case.
The PCCS will continue to request PCK Certificates from the PCS for each affected platform when requested by that platform until it receives a complete set of PCK Certificates.

PCCS should provide the requester with the 'best' PCK Certificate it can use by running the PCK Cert Selection Library with the available PCK Certificates for the platform.
It should only fail to provide a PCK Certificate to the requester if the PCK Cert Selection logic fails.

#### Cache Fill Mode is [`REQ`](../05/cache_fill_modes.md#req-cache-fill-mode)

The PCCS will store the affected Platform IDs in the database's cached platform table.
The administrator retrieves the PCK Certificates from the database using the [PCCS Admin Tool](../07/pccs_admin_tool.md)'s [`get` operation](../07/pccs_admin_tool.md#get) with the `source` parameter set to `-reg_na`.

The administrator can then request the PCK Certificates for these platforms from the PCS, using the [PCS Client Tool](../09/pcs_client_tool.md)'s [`fetch` operation](../09/pcs_client_tool.md#fetch) and import them to the PCCS using [PCCS Admin Tool](../07/pccs_admin_tool.md)'s [`put` operation](../07/pccs_admin_tool.md#put).


#### Cache Fill Mode is [`OFFLINE`](../05/cache_fill_modes.md#offline-cache-fill-mode)

The [PCS Client Tool](../09/pcs_client_tool.md)'s [`fetch` operation](../09/pcs_client_tool.md#fetch) will output a warning that some platform's PCK Certificates were not available from the PCS.
It will prompt the administrator to store the platform IDs in a file.
The administrator can then retry the [`fetch` operation](../09/pcs_client_tool.md#fetch) for these files once the platforms have been patched.


## Refreshing Expiring Collateral

Some of the cached verification collateral have short lifetimes whereas PCK Certificates are long-lived.
The CSP or infrastructure owner needs to set up a policy for refreshing this collateral.
It is possible to retrieve all the collaterals including PCK Certificates (similar to the process described in [Handling TCB Recoveries](#handling-tcb-recoveries)), but every platform has a unique set of PCK Certificates, and refreshing PCK Certificates can incur a lot of overhead.
To refresh expiring verification collateral without refreshing PCK Certificates, the following flows can be used.


### Cache Fill Mode is [`LAZY`](../05/cache_fill_modes.md#lazy-cache-fill-mode)

In this mode, the PCCS can directly retrieve collateral from PCS.
An administrator can request an update of only the verification collateral in two ways:

1. Set up a timed refresh using the method described in [Scheduled Cache Data Refresh](../03/api_specification_for_pccs.md#scheduled-cache-data-refresh).
2. Use the method described in the next sub-section for the `REQ` cache fill mode.


### Cache Fill Mode is [`REQ`](../05/cache_fill_modes.md#req-cache-fill-mode)

In this mode, the PCCS can directly retrieve collateral from PCS.
An administrator can request an update of only the verification collateral as follows:

- Send the [Refresh through HTTP Request](../03/api_specification_for_pccs.md#refresh-through-http-request) without the optional `type` filed option and without the optional `fmspc` field.
- The [PCCS Admin Tool](../07/pccs_admin_tool.md)'s [`refresh` operation](../07/pccs_admin_tool.md#refresh) can be used to trigger the [aforementioned API](../03/api_specification_for_pccs.md#refresh-through-http-request).[^pccsadmin-packaging-variants]

    === "*Option 1*: Packaged tools"
        ``` { .bash }
        pccs-admin-tool refresh
        ```

    === "*Option 2*: Tools installed from source"

        ``` { .bash }
        python pccsadmin.py refresh
        ```


### Cache Fill Mode is [`OFFLINE`](../05/cache_fill_modes.md#offline-cache-fill-mode)

In this mode, the PCCS cannot retrieve collateral from PCS by itself.
An administrator can request an update of collateral as follows:

1. Create a `platform_list.json` file simply put a pair of brackets in it, i.e., `[]`.
2. Use [PCS Client Tool](../09/pcs_client_tool.md) to fetch collateral from the PCS.[^pcsclient-packaging-variants]

    === "*Option 1*: Packaged tools"
        ``` { .bash }
        pcs-client-tool fetch -k YOUR_INTEL_PCS_API_KEY
        ```

    === "*Option 2*: Tools installed from source"

        ``` { .bash }
        python pcsclient.py fetch -k YOUR_INTEL_PCS_API_KEY
        ```

3. Use [PCCS Admin Tool](../07/pccs_admin_tool.md) to put the collateral into the cache.

    === "*Option 1*: Packaged tools"
        ``` { .bash }
        pccs-admin-tool put -t YOUR_PCCS_ADMIN_TOKEN
        ```

    === "*Option 2*: Tools installed from source"

        ``` { .bash }
        python pccsadmin.py put -t YOUR_PCCS_ADMIN_TOKEN
        ```


## Database migration


### Migrating from v2 caching database (DCAP v1.8 and before) to v3 caching database (DCAP v1.9 and after)

Versions of PCCS from v1.8 and earlier do not support automatic database migration.
The following steps describe how to import platform data from a v2 PCCS to a v3 PCCS.


An administrator may want to import platform data from a v2 PCCS after he/she has set up a v3 PCCS.
To ensure the certificate and collateral data is up to date, we suggest the administrator first retrieves the cached platforms list from v2 PCCS using the [PCCS Admin Tool](../07/pccs_admin_tool.md).
Then, the administrator should use the [`fetch` operation](../09/pcs_client_tool.md#fetch) of the [PCS Client Tool](../09/pcs_client_tool.md) to retrieve platform collateral from PCS service.
 and finally use [`put` operation](../07/pccs_admin_tool.md#put) to upload the data to V3 PCCS service.

1. Use the [PCCS Admin Tool](../07/pccs_admin_tool.md) to retrieve the cached platform IDs from the **v2** PCCS.[^pccsadmin-packaging-variants]

    === "*Option 1*: Packaged tools"
        ``` { .bash }
        pccs-admin-tool get \
            -s [] -u V2_PCCS_SERVICE_URL -t YOUR_PCCS_ADMIN_TOKEN
        ```

    === "*Option 2*: Tools installed from source"

        ``` { .bash }
        python pccsadmin.py get \
            -s [] -u V2_PCCS_SERVICE_URL -t YOUR_PCCS_ADMIN_TOKEN
        ```

2. Use the [PCS Client Tool](../09/pcs_client_tool.md) to fetch collateral from the **v3** PCS.[^pcsclient-packaging-variants]

    === "*Option 1*: Packaged tools"
        ``` { .bash }
        pcs-client-tool fetch \
            -k YOUR_INTEL_PCS_API_KEY
        ```

    === "*Option 2*: Tools installed from source"

        ``` { .bash }
        python pcsclient.py fetch \
            -k YOUR_INTEL_PCS_API_KEY
        ```

3. Use the [PCCS Admin Tool](../07/pccs_admin_tool.md) to put the collateral into  **v3** PCCS.[^pccsadmin-packaging-variants]

    === "*Option 1*: Packaged tools"
        ``` { .bash }
        pccs-admin-tool put \
            -u V3_PCCS_SERVICE_URL -t YOUR_PCCS_ADMIN_TOKEN
        ```

    === "*Option 2*: Tools installed from source"

        ``` { .bash }
        python pccsadmin.py put \
            -u **V3**_PCCS_SERVICE_URL -t YOUR_PCCS_ADMIN_TOKEN
        ```


### Migrating database from DCAP v1.9 to newer versions of DCAP

The PCCS installation supports automatic database migration starting from DCAP v1.9.
Database backup is recommended before performing the upgrade and the installer will provide a warning before automatic migration occurs.
