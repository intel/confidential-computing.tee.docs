---
description: Configuration file details and setup instructions for the Intel SGX/TDX Provisioning Certificate Caching Service (PCCS).
keywords: PCCS, DCAP, configuration, caching service, Confidential Computing, SGX, TDX
---
<!---
Copyright (C) 2025 Intel Corporation
SPDX-License-Identifier: CC-BY-4.0
-->

# Configuration File

The PCCS can be configured using a configuration file, `default.json`, located in the `config` sub-directory under the PCCS installation directory.


## Settings in the Configuration File

`HTTPS_PORT`

:   The port you want the PCCS to listen on.
    The default listening port is `8081`.

`hosts`

:   The hosts that will be accepted for connections.
    Default is localhost only.
    To accept all connections, use `0.0.0.0`

`uri`

:   The URL of Intel Provisioning Certificate Service.
    The current URL is `https://api.trustedservices.intel.com/sgx/certification/v4/`

`ApiKey`

:   The PCCS use the API key to request collateral from Intel Provisioning Certificate Service.
    You need to subscribe first to obtain an API key.
    For how to subscribe to the Intel Provisioning Certificate Service and receive an API key, go to [PCS API Portal](https://api.portal.trustedservices.intel.com/provisioning-certification) and click 'Subscribe' (**Note:** You need an Intel® Developer Zone (IDZ) account to register).

`Proxy`

:   Specify the proxy server for Internet connection, for example, `http://192.168.1.1:80>`.
    Leave it blank for no proxy or system proxy.

`RefreshSchedule`

:   cron-style refresh schedule for the PCCS to refresh cached artifacts including CRL/TCB Info/QE Identity/QVE Identity.
    The default setting is `0 0 1 \* \* \*`, which means refresh at 1:00 am every day.

`UserTokenHash`

:   Sha512 hash of the user token for the PCCS client user to register a platform.
    For example, [PCK Cert ID Retrieval Tool](https://github.com/intel/SGXDataCenterAttestationPrimitives/tree/master/tools/PCKRetrievalTool) uses the user token to send platform information to PCCS.
    Required by the [Post Platforms IDs](../03/api_specification_for_pccs.md#post-platforms-ids).

`AdminTokenHash`

:   Sha512 hash of the administrator token for the PCCS administrator to perform a manual refresh of cached artifacts.
    It is required by these APIs: [Get registered platforms](../03/api_specification_for_pccs.md#get-platform-ids), [Put platform collateral to cache](../03/api_specification_for_pccs.md#put-platform-collateral-to-cache) and [Cache data refresh](../03/api_specification_for_pccs.md#cache-data-refresh).

    !!! note
        For Windows you need to set the UserTokenHash and the AdminTokenHash manually.
        You can calculate SHA512 hash in PowerShell using the following command:

        ``` powershell {title="Powershell"}
        [BitConverter]::ToString(
            [System.Security.Cryptography.SHA512]::Create().ComputeHash(
                [System.Text.Encoding]::UTF8.GetBytes((Read-Host 'Enter token'))
            )
        ).Replace('-', '').ToLower()
        ```

`CachingFillMode`

:   The method used to fill the cache DB.
    Can be one of the following: `REQ/LAZY/OFFLINE`.
    See page [Cache Fill Modes](../05/cache_fill_modes.md)

`LogLevel`

:   Log level.
    Use the same levels as npm: error, warn, info, http, verbose, debug, silly.
    Default is info.
    Log messages are written to `<PCCS Install Directory>/logs/pccs server.log`.

`DB_CONFIG`

:   You can choose Sqlite or Mysql and many other DBMSes.
    For Sqlite, you do not need to change anything.
    For other DBMSes, you need to set database connection options correctly.
    Normally you need to change database, username, password, host, and dialect to connect to your DBMS.


## Configuration File Example

``` {.json}
{
    "HTTPS_PORT": 8081,
    "hosts": "127.0.0.1",
    "uri": "https://api.trustedservices.intel.com/sgx/certification/v3/",
    "ApiKey": "<Your API key>",
    "proxy": "",
    "RefreshSchedule": "0 0 1 \* \* \*",
    "UserTokenHash": "",
    "AdminTokenHash": "",
    "CachingFillMode": "",
    "LogLevel": "info",
    "DB_CONFIG": "sqlite",
    "sqlite": {
        "database": "database",
        "username": "<Your sqlite username>",
        "password": "<Your sqlite password>",
        "options": {
            "host": "localhost",
            "dialect": "sqlite",
            "storage": "pckcache.db"
        }
    }
}
```
