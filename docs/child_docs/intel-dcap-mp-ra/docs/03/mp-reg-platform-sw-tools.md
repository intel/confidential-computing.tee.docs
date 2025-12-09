---
description: Tools and utilities for SGX multi-package registration platform software.
keywords: Intel SGX, DCAP, multi-package, registration, tools, MPA
---
<!---
Copyright (C) 2025 Intel Corporation
SPDX-License-Identifier: CC-BY-4.0
-->

# Multi-Package Registration Platform Software Tools

The Intel® SGX Data Center Attestation Primitives (DCAP) release has added new tools and extended existing tools to support multi-package platform registration.
These tools use the [Multi-Package Registration Libraries][mp-reg-lib] described in a later section.
These tools were created to quickly support multi-package platform registration in their datacenter or cloud service provider environments.
Customers can modify or design their own tools using the multi-package libraries.
These DCAP tools and libraries are released in binary format for Linux\* [https://download.01.org/intel-sgx/latest/dcap-latest/linux/distro/&lt;distro&gt;][linuxtools] and for Windows\* [https://download.01.org/intel-sgx/latest/dcap-latest/windows/tools/][windowstools].
For the open source for these tools, see [https://github.com/intel/confidential-computing.tee.dcap/tree/main/tools/SGXPlatformRegistration][githubtools] .


## Multi-Package Registration Agent (MPA)

The Multi-Package Registration Agent (MPA) is an executable that launches as a daemon/service automatically after boot.
Upon OS boot, it examines the state of the [BIOS Multi-Package UEFI Variables][uefivar] to determine if there is any registration action to take.
This tool requires Internet access.
It also requires access to the UEFI SGX variable interface, which is only available to bare-metal platforms or to the Host VM.
So, this tool may not be suitable for data centers or Cloud Service Providers (CSP’s) that have a separate provisioning environment and customer workload environment where customer workloads run in guest VMs and platform provisioning happens without an Internet connection.
This tool may be most useful for validation purposes or workstations with Internet connection ([Single Stage Registration][singlereg]).
This tool is available as open source, and you can use it as a reference for communicating to both the [SGX MP UEFI][uefivar] variables and the Intel® SGX Registration Service ([SGX MP Network][mp-net-lib]).

BIOS resets the `SgxRegistrationStatus.Status.SgxRegistrationComplete` to `0` when a registration request is available for processing.
BIOS clears this bit when there is a successful IPE boot flow, TCB Recovery boot flow, and the Add Package boot flow.
When this flag is 0, the BIOS puts data in the SgxRegistrationServerRequest UEFI variable that needs processing.
For the IPE boot flow and the TCB Recovery boot flow, the SgxRegistrationServerRequest UEFI variable contains the platform manifest structure.
For the Add Package boot flow, the SgxRegistrationServerRequest UEFI variable contains the add package structure.
The MPA treats the platform manifest and add package structure as blobs and only parses the header to determine which of the data structures BIOS provided.

The MPA first checks if BIOS has reported any errors by scanning the `SgxRegistrationStatus.Errorcode`.
Then it checks the `SgxRegistrationStatus.Status.SgxRegistrationComplete` flag to see if it has been reset to `0`.
If both the `SgxRegistrationStatus.Errorcode` is `success` and the `SgxRegistrationStatus.Status.SgxRegistrationComplete` flag is `0`, the MPA reads the [`SgxRegistrationServerRequest`][request] UEFI variable and parses the data structure header to determine what type of data structure needs processing (currently, only platform manifest and add package structures are supported).
The MPA sends the data structure to the Intel® SGX Registration Service.
When the MPA successfully communicates to the Registration Service or it encounters a non-recoverable error, it sets the `SgxRegistrationStatus.Status.SgxRegistrationComplete` to `1` to indicate that BIOS does not need to provide the data structure again on a subsequent boot.
If the MPA receives an error that can be recoverable, it does not set the `SgxRegistrationStatus.Status.SgxRegistrationComplete` to `1` to indicate that BIOS should provide the same structure on a subsequent boot so the MPA can retry processing the structure again.

The MPA sends the requests to the URL provided by the [`SgxRegistrationConfiguration`][configuration] UEFI variable using the API defined by the Intel® SGX Registration Service.
Once complete, the MPA stops its service/daemon.


### Platform Manifest Handling

BIOS provides platform manifests on IPE boot flows and TR boot flows.
It also provides them in Normal boot flow when the SgxRegistrationComplete flag is 0 (indicating a retry).
When receiving a platform manifest, the Registration Service returns a hex-encoded representation of the PPID.
The MPA treats some server response codes as terminal when no amount of retries fixes the problem.
In this case, the MPA sets the SgxRegistrationComplete flag to 1 so that BIOS does not provide the same platform manifest on a subsequent boot.

The list of response codes from the Intel® SGX Registration Service response codes that terminate the registration process:

- `201` - Created (The platform instance is created or updated in the Registration Service database)
- `400` - Invalid Platform Manifest (Client should not repeat the request without modifications)
    - ErrorCode = InvalidRequestSyntax
    - ErrorCode = InvalidRegistrationServer
    - ErrorCode = InvalidOrRevokedPackage
    - ErrorCode = PackageNotFound
    - ErrorCode = IncompatiblePackage
    - ErrorCode = InvalidPlatformManifest
    - ErrorCode = CachedKeyPolicyViolation

The list of response codes from the Intel® SGX Registration Service response codes that do not terminate the registration process:

- `401` - Failed to authenticate or authorize the request
- `415` - MIME type specified in the request is not supported by the server.
- `500` - Internal server error occurred
- `503` - Server is currently unable to process the request.

There are also internal MPA errors that are considered terminal.
See section [MPA Error Codes][errorcodes] for a list of these errors.


### Add Package Handling

Handling an Add Package flow is more complicated than platform manifests.
The MPA expects a response from the Registration Service.
This response contains the platform membership certificate(s) for the new CPU package(s).
If the response does not contain the platform membership certificate, the MPA reports a failure.
This flow requires internet connection to directly interact with the Registration Service.
The Intel® SGX Registration Service requires that the user subscribes for an API key to use the add package API.
BIOS provides an add package structure in the Add Package boot flow.
It also provides them in a Normal boot flow when the SgxRegistrationComplete flag is 0 indicating a retry.
The MPA treats some server response codes as terminal, and retries do not fixe the problem.
In this case, the MPA sets the SgxRegistrationComplete flag to 1 so that BIOS does not provide the same add package structure on a subsequent boot.

The list of Intel® SGX Registration Service response codes that terminates the add package process:

- `200` - OK
- `400` - Invalid Platform Manifest (Client should not repeat the request without modifications)
    - ErrorCode = InvalidRequestSyntax
    - ErrorCode = PlatformNotFound
    - ErrorCode = InvalidOrRevokedPackage
    - ErrorCode = PackageNotFound
    - ErrorCode = InvalidAddRequest

The list of Intel® SGX Registration Service response codes that does not terminate the add package process:

- `401` - Failed to authenticate or authorize the request
- `415` - MIME type specified in the request is not supported by the server.
- `500` - Internal server error occurred
- `503` - Server is currently unable to process the request.

There are also internal MPA errors that are considered terminal.
See section [MPA Error Codes][errorcodes] for a list of these errors.


### Configuration

The MPA can be configured with the following settings.
Linux configurations are provided in a configuration file.
Windows configurations are provided by registry keys.

- Subscription Key – Only required for Add Package flows.
Provided by the Intel® SGX Registration Service upon subscribing.
    - Config Location:
        - Linux: `/etc/mpa_registration.conf`
        - Windows:
            - `KEY_LOCAL_MACHINE\SOFTWARE\Intel\SGX_RA\RASubscriptionKey`
            - Add the following String key name `token`
            - <64byte-hex-value>
            - e.g:  `7a963d696ff94b7d82df4cbe924b1574`

- Proxy Setting – Modify the proxy settings used by the MPA
    - Values:

        <!-- markdownlint-disable MD033 -->

        | Proxy Type                                     | Linux Value                          | Windows Value |
        | ---------------------------------------------- | ------------------------------------ | -------------- |
        | Use the configuration in your operating system | default                              | 0 |
        | Direct access to the internet                  | direct                               | 1 |
        | Set the proxy URL directly:<br />&emsp;- Supports authenticated proxy.<br />&emsp;- Proxy URL uses standard format:  `user:password@proxy:port`| manual                               | 2 |
        <!-- markdownlint-enable MD033 -->

    - Config Location:
        - Linux: `/etc/mpa_registration.conf`
        - Windows:
            - `HKEY_LOCAL_MACHINE\SOFTWARE\Intel\SGX_RA\RAProxy`
            - Add the following DWORD key name `type` and set it to one of the Windows Values from the table above.
            - If you set it to `2` (manual), then also add the String key `url` and set the URL in the standard format described in the table above.

- Log Level
    - Values:

        | Logging Level              | Linux Value        | Windows Value |
        | ---------------------------| -------------------| ----------------------- |
        | None                       | none               | 0 |
        | Functional                 | func               | 1 |
        | Error (default value)  | error              | 2 |
        | Verbose                    | info               | 3 |

    - Config Location:
        - Linux: `/etc/mpa_registration.conf`
        - Windows:
            - `HKEY_LOCAL_MACHINE\SOFTWARE\Intel\SGX_RA\RALog`
            - Add the the DWORD key `level` and set it to one of the Windows Values from the table above.

    - Logging output:
        - Linux: `/var/log/mpa_registration.log`
        - Windows:
            - `C:\Windows\System32\Winevt\Logs\Application.evtx`
            - Open `Application.evtx` (from another platform with Windows GUI)
            - Look for `IntelMPAService` records in the `source` column

- UEFI path
    - Values:
        - `/sys/firmware/efi/efivars` (Default)
    - Config Location:
        - Linux: `/etc/mpa_registration.conf`
        - Windows: Not available for Windows

#### BIOS Registration Authority Service Configuration

The BIOS uses a default URL for the Intel® Registration Service in the SgxRegistrationServerConfiguration UEFI variable.
The platform owner can modify the registration service configuration using the SgxRegistrationServerConfiguration UEFI variable but only when SGX is disabled.

The BIOS also has a BIOS User Interface (UI) (`SGX Auto MP Registration`) setting that allows the platform owner to enable/disable the MPA from running automatically at OS boot.
By default, the MPA does not automatically run at boot.


### Error Codes

The MPA writes an error code to the ErrorCode field of the SgxRegistrationServerStatus UEFI variable when it completes.
These are the possible ErrorCode values produced by the MPA (the MPA error codes always have the most significant bit of the ErrorCode field):

| Error Name                                | Error Code | Description |
| ------------------------------------------|--------|-------------|
| `MPA_SUCCESS`                             | (0x00) | Completed without any errors |
| `MPA_AG_UNEXPECTED_ERROR`                 | (0x80) | Unexpected internal error |
| `MPA_AG_OUT_OF_MEMORY`                    | (0x81) | Out-of-memory error |
| `MPA_AG_NETWORK_ERROR`                    | (0x82) | Proxy detection or network communication error |
| `MPA_AG_INVALID_PARAMETER`                | (0x83) | Invalid parameter in input |
| `MPA_AG_INTERNAL_SERVER_ERROR`            | (0x84) | Internal server error occurred |
| `MPA_AG_SERVER_TIMEOUT`                   | (0x85) | Server communication timeout |
| `MPA_AG_BIOS_PROTOCOL_ERROR`              | (0x86) | BIOS UEFI protocol error |
| `MPA_AG_UNAUTHORIZED_ERROR`               | (0x87) | The client is unauthorized to access the registration server |
| `MPA_RS_INVALID_REQUEST_SYNTAX`           | (0xA0) | Server could not understand request due to malformed syntax |
| `MPA_RS_PM_INVALID_REGISTRATION_SERVER`   | (0xA1) | Server rejected request because it is intended for different registration server (Registration Server Authentication Key (RSAK) mismatch) |
| `MPA_RS_INVALID_OR_REVOKED_PACKAGE`       | (0xA2) | Server rejected request due to invalid or revoked CPU package |
| `MPA_RS_PACKAGE_NOT_FOUND`                | (0xA3) | Server could not recognize at least one of the CPU packages |
| `MPA_RS_PM_INCOMPATIBLE_PACKAGE`          | (0xA4) | Server detected at least one of the CPU packages is incompatible  rest of the CPU packages on the platform |
| `MPA_RS_PM_INVALID_PLATFORM_MANIFEST`     | (0xA5) | Server could not process the platform manifest structure |
| `MPA_RS_AD_PLATFORM_NOT_FOUND`            | (0xA6) | Server rejected add package request because the platform has not been registered |
| `MPA_RS_AD_INVALID_ADD_REQUEST`           | (0xA7) | Server could not process the add package structure |
| `MPA_RS_UNKOWN_ERROR`                     | (0xA8) | Server rejected request for unknown reason (Probably means MPA to be updated with newly defined server response errors) |

<!-- // cspell:ignore UNKOWN -->


## PCK Cert ID Retrieval Tool

The PCK Cert ID Retrieval Tool is an executable that collects the platform information that is necessary for retrieving PCK Certs from the Intel® SGX Provisioning Certificate Service (PCS).
The DCAP releases for single-package platforms already include the PCK Cert ID Retrieval Tool, but it has been expanded to include support for multi-package platforms.

The main expansion to the tool is its ability to retrieve the platform manifest from the [`SgxRegistrationServerRequest`][request] UEFI variable. By retrieving the platform manifest, this tool supports [Indirection Registration][indirectreg] better by allowing to store the platform manifest and use it later for retrieving PCK Certificates. The registration authority service does not need to persistently store the platform keys when the platform owner maintains a copy of the platform manifest for retrieving PCK Certificates.

Unlike the PCK Cert ID Retrieval Tool support for single package platforms, the tool needs to run in the host VM or on bare metal to get access to the UEFI variables.
The SGX UEFI variables are not exposed to guest VMs.
This tool is expected to run in the platform deployment environment when a platform is assembled or when a TCB Recovery event occurs requiring a new microcode patch applied at reset.
It is not expected to run in a guest VM.
For more information, see [Dual Stage Registration][dualreg].

By default, this tool loads enclaves to retrieve the platform identification data.
This is required for single package platforms.
For multi-package platforms, it can be configured to get limited platform identification information without loading any enclaves.
For more information, see [Platform ID Without Enclave Loading][pidwel].

Unlike the MPA, the PCK Cert ID Retrieval Tool does not require internet connection.
The PCK Cert ID Retrieval Tool can output the platform ID information to a file, or it can be configured to send the data to the DCAP's reference Caching Service (See [PCK Certification Caching Service (PCCS)](https://download.01.org/intel-sgx/latest/dcap-latest/linux/docs/SGX_DCAP_Caching_Service_Design_Guide.pdf) for more information).

The tool links with the [SGX Multi-Package UEFI Variables Access Library][uefivaralib].


### Platform Manifest Handling

BIOS provides platform manifests on IPE boot flows and TR boot flows.
It also provides them in Normal boot flow when the SgxRegistrationComplete flag is 0 indicating a retry.
This tool always checks the [`SgxRegistrationServerRequest`][request] UEFI variable directly and ignores the value of the SgxRegistrationComplete flag.
If it finds the platform manifest, it adds it to its platform ID output.

Although this tool does not check the `SgxRegistrationComplete` flag to be 0 before reading the SgxRegistrationServer Request, it writes 1 to the `SgxRegistrationComplete` flag if it successfully processes the [`SgxRegistrationServerRequest`][request] UEFI variable.


### Add Package Handling

The PCK Cert ID Retrieval Tool does not support Add Package flows.
If it encounters an add package structure in the [`SgxRegistrationServerRequest`][request] UEFI variable, it generates an error.
You should use other means to support Add Package flows.


### Configuration

The PCK Cert ID Retrieval Tool has two major operating modes:

1. Output platform ID information to a comma-separated values (CSV) file
2. Send platform ID information to the reference design PCCS on  local network
    1. Network configuration can be specified by an XML file.
    2. Network configuration can be specified on the command line.

Valid Command line Parameters:

<!-- markdownlint-disable MD033 MD056 -->
| Command Line Parameter        | Description |
| ----------------------------- | ----------- |
| `-f <filename>`                   | Output the platform ID information to the `filename`. The output is a comma-separated value (CSV) file with base-16 encoding. |
| `-url <cache_server_address>`     | Reference PCCS's URL.<br />Only needed when using the network to communicate to the PCCS. |
| `-user_token <token_string>`      | User token to access the PCCS.<br />Only needed when using the network to communicate to the PCCS. |
| `-proxy_type <proxy_type>`        | Proxy setting when accessing the PCCS.<br />Only needed when using the network to communicate to the PCCS.<br />Available options: `direct`, `default`, and `manual` |
| `-proxy_url <proxy_server_address>`| Proxy server address.<br /> Only needed when using the network to communicate to the PCCS. |
| `-use_secure_cert <[true | false]>` | Accept secure/insecure https cert.<br /> Only needed when using the network to communicate to the PCCS.<br /> Default value is true |
| `-tcb_update_type <standard, early, all>` | Update type for tcb material.<br /> Only needed when using the network to communicate to the PCCS, and the PCCS was configured in REQ mode.<br /> Default value is standard. |
| `-platform_id <platform_id>`      | When provided, no enclaves are loaded. You need to provide a unique platform id that can be used to identify the platform at run-time. |
| `-?`                                | Show command help                |
| `-h`                                | Show command help                |
| `-help`                             | Show command help                |
<!-- markdownlint-enable MD033 -->

#### Outputting to a CSV File

The PCK Cert ID Retrieval tool can output the platform identification information using the `-f` command line parameter.

!!! note
    All integer fields are in little-endian format.

``` {.text}
<EncryptedPPID (384 byte array)>,
<PCE_ID (16 bit integer)>,
<CPUSVN (16 byte array)>,
<PCE ISVSVN (16 bit integer)>,
<PLATFORM_ID (16 byte array)>,
<PLATFORM_MANIFEST (variable byte array)>
```

This output is the same as it was for the single-package platforms with the addition of the platform manifest.
The platform manifest is an optional output to the CSV file, and it is not present on single-package platforms or on multi-package platform boot flows that do not provide a platform manifest.

Because the EncryptedPPID cannot be used as a platform identifier due the randomness entropy of the encryption algorithm, the PLATFORM_ID is used as platform identifier for the platform.
If the -platform_id parameter is not provided, the DCAP Quoting Enclave (QE) generates a QE_ID as the platform_id.
If the PLATFORM_ID is used as input, the Quote Provider Library must use the same PLATFORM_ID when retrieving the PCK Certificates from the PCCS.

#### Outputting to the Reference Provisioning Certification Caching Service (PCCS)

The PCK Cert ID Retrieval Tool can be configured to send the platform ID information to the Intel reference PCCS.
The PCCS exposes a REST API for accepting the platform ID information.
See [PCK Certification Caching Service (PCCS)](https://download.01.org/intel-sgx/latest/dcap-latest/linux/docs/SGX_DCAP_Caching_Service_Design_Guide.pdf) for more information.
The network configuration can be provided on the command line or by entering the information into an xml configuration file (network_configuration.conf).
The command line configurations take precedence.
This is convenient if the multi-package platform can reach the local network in the provisioning environment.

#### Platform Identity Without Enclave Loading

The PCK Cert ID Retrieval Tool may run in a constrained environment during platform provisioning.
It may not have OS support for loading enclaves or all of the DCAP software packages installed, or you may have a specific need to choose/supply their own platform ID.
To support these environments better, the PCK Cert ID Retrieval Tool supports a mode that only retrieves the platform manifest and does not retrieve the platform ID information that requires loading any enclaves.
The output of the CSV file or the data sent to the PCCS only contains the PCEID, the platform manifest and a user-supplied run-time platform identifier.
The run-time platform identifier replaces the QE_ID in the platform ID information.
This platform identifier can be used during run-time for requesting PCK Certificates because the platform manifest is not available to guest VMs.
Providing the `-platform_id` command line parameter selects this mode of operation


## Multi-Package Management Tool

The DCAP release for multi-package platforms also includes a management tool to provide status and configuration to the platform from the OS software.
Like the PCK Cert ID Retrieval Tool, it links with the [SGX Multi-Package UEFI Variables Access Library][uefivaralib].

<!-- markdownlint-disable MD033 -->
| Command Line Parameter         | Description |
|------------------------------------|---------------------------------- |
| `-get_platform_manifest <file_name>` | Reads the [`SgxRegistrationServerRequest`][request] UEFI variable to get the platform manifest when present. It outputs the platform manifest in binary form to the file specified in `<file_name>`.<br /> *Note: if UEFI variable is in read-only mode, this command could NOT change the [`SgxRegistrationStatus`][status]' status.* |
| `-get_key_blobs <file_name>`       | Reads [`SgxRegistrationPackageInfo`][packageinfo] UEFI variable to get the key blobs when present. It outputs the key blobs in binary form to the file specified in `<file_name>`.<br /> *Note: if UEFI variable is in read-only mode, this command could NOT change the [`SgxRegistrationStatus`][status]' status.* |
| `-set_server_info <file_name> <hex_flags> <URL>` | Used to change the registration authority service. <br />`<file_name>` contains the self-signed [`SgxRegistrationServerID`][serverid] from the registration authority service. <br /> `<hex_flags>` indicates the value of `Flags` in [`SgxRegistrationConfiguration`][configuration] UEFI variable. <br />`<URL>` the URL of the registration authority service.<br /> *Note: if UEFI variable is in read-only mode, this command could NOT work.* |
| `-get_registration_status`           | Reports whether it is completed or in progress. This is the reporting the value of the `SgxRegistrationComplete` flag in the [`SgxRegistrationStatus`][status] UEFI variable.<br /> *Note: if UEFI variable is in read-only mode, maybe this command could NOT give one correct registration status.* |
| `-get_last_registration_error_code`  | Reports the registration error code. It is the value of the `Status.ErrorCode` field in the [`SgxRegistrationStatus`][status] UEFI variable. The error code can be from the BIOS or from the MPA.<br /> *Note: if UEFI variable is in read-only mode, maybe this command could NOT give one correct registration status.* |
| `-get_sgx_status`                    | Reports the [status of SGX](#sgx-status). |
| `-v`                                 | Produce verbose output.         |
| `-h`                                 | Show command help.              |
<!-- markdownlint-enable MD033 -->

### Changing the Registration Authority Service

BIOS provides a default registration authority service configuration.
For the Intel reference BIOS, the default registration authority service is the Intel® SGX Registration Service.
The SGX multi-package platforms support modifying the registration authority service with the [`SgxRegistrationConfiguration`][configuration] UEFI variable.
This variable becomes writable only when the platform owner disables SGX via the BIOS configuration settings.
The registration authority service does not need to generate a self-signed [`SgxRegistrationServerID`][serverid] structure.
This combined with the registration authority service URL is the [SgxRegistrationServerInfo][serverinfo] structure.
The platform owner then writes the [SgxRegistrationServerInfo][serverinfo] to the [`SgxRegistrationConfiguration`][configuration] UEFI variable.

On the next SGX enabled boot, key blobs generated for a different registration authority service are deleted and BIOS forces an Initial Platform Establishment boot flow.
This results in new key blobs and a new platform manifest.


### Handling Key Blobs

Each CPU package on the platform has a key blob when SGX is enabled on a multi-package platform.
BIOS provides a mechanism for retrieving the key blobs.
Platform owners may want to maintain a copy of the key blobs in case they need to be restored after they are deleted from BIOS persistent store (e.g. the FLASH was erased or SGX was reset).
The [SgrRegistrationPackageInfo][packageinfo] UEFI variable provides the key blobs.
By default, BIOS does not present the key blobs to the software.
The platform owner needs to 'opt-in' using the BIOS configuration setting (`SGX Package Info In-band Access`)
before BIOS provides the key blobs.


### Registration Error Codes

The error codes written to the `Status.ErrorCode` field in the [`SgxRegistrationStatus`][status] UEFI variable can come from one of two sources.
BIOS writes to this field when an error occurs during a boot flow.
The most significant bit of the ErrorCode is 0 when generated by BIOS.
The software can also use this field to report any errors in processing the data from BIOS.
The most significant bit of the ErrorCode is 1 when generated by software.
Software should not overwrite the ErrorCode if BIOS writes a non-zero value.

The software error codes generated by the MPA are defined in [MPA Error Codes][errorcodes].
The BIOS error codes are defined as follows:

| Error Name                                    | Error Code |
|-----------------------------------------------|------|
| `RS_PREMEM_OTHER`                             | 0x10 |
| `RS_PREMEM_NOMEM`                             | 0x11 |
| `RS_PREMEM_SYS_NOT_CAPABLE`                   | 0x12 |
| `RS_PREMEM_NO_VALID_PRMRR`                    | 0x13 |
| `RS_PREMEM_HW_NOT_CAPABLE`                    | 0x14 |
| `RS_PREMEM_TME_DISABLED`                      | 0x15 |
| `RS_PREMEM_SGX_DISABLED`                      | 0x16 |
| `RS_PREMEM_INVALID_PRRMR_SIZE`                | 0x17 |
| `RS_PREMEM_PRMRR_NOT_SECURED`                 | 0x18 |
| `RS_PREMEM_MEM_TOPOLOGY_ERR`                  | 0x19 |
| `RS_POSTMEM_OTHER`                            | 0x20 |
| `RS_POSTMEM_NOMEM`                            | 0x21 |
| `RS_POSTMEM_SYSHOST_NOTFOUND`                 | 0x22 |
| `RS_POSTMEM_MMAP_HOST_NOTFOUND`               | 0x23 |
| `RS_POSTMEM_VSPPI_NOTFOUND`                   | 0x24 |
| `RS_POSTMEM_MRCHCSPPI_NOTFOUND`               | 0x25 |
| `RS_POSTMEM_SVN_ERR`                          | 0x26 |
| `RS_POSTMEM_REGVARS_ERR`                      | 0x27 |
| `RS_POSTMEM_KEYBLOBS_RES_ERR`                 | 0x28 |
| `RS_POSTMEM_PRID_UNLOCK_ERR`                  | 0x29 |
| `RS_POSTMEM_DETERMINE_BOOT_ERR`               | 0x2A |
| `RS_POSTMEM_FIRSTBOOT_ERR`                    | 0x2B |
| `RS_POSTMEM_WARMRESET_ERR`                    | 0x2C |
| `RS_LATEINIT_OTHER`                           | 0x30 |
| `RS_LATEINIT_TRIGCALLBACK_ERR`                | 0x31 |
| `RS_LATEINIT_HOBLIST_NOTFOUND`                | 0x32 |
| `RS_LATEINIT_MPSVC_ERR`                       | 0x33 |
| `RS_LATEINIT_INITDATAHOB_RES`                 | 0x34 |
| `RS_LATEINIT_UPDTCAPAB_ERR`                   | 0x35 |
| `RS_LATEINIT_UPDTPRMRR_ERR`                   | 0x36 |
| `RS_LATEINIT_CRDIMM_ERR`                      | 0x37 |
| `RS_LATEINIT_UPDTLEWR_ERR`                    | 0x38 |
| `RS_LATEINIT_SYS_NOT_CAPABLE`                 | 0x39 |
| `RS_LATEINIT_SGX_DISABLED`                    | 0x3A |
| `RS_LATEINIT_FACTORY_RESET_ERR`               | 0x3B |
| `RS_LATEINIT_NVSAREA_ERR`                     | 0x3C |
| `RS_LATEINIT_GET_NVVAR_ERR`                   | 0x3D |
| `RS_LATEINIT_EXPOSE_PROTO_ERR`                | 0x3E |
| `RS_LATEINIT_LOCKVARS_ERR`                    | 0x3F |
| `RS_LATEINIT_VAR_ROTO_ERR`                    | 0x40 |
| `RS_LATEINIT_CALLBACK_OTHER`                  | 0x50 |
| `RS_LATEINIT_CALLBACK_NOMEM`                  | 0x51 |
| `RS_LATEINIT_CALLBACK_BIOSPARAM_ERR`          | 0x52 |
| `RS_LATEINIT_CALLBACK_MICROCODE_LAUNCH_ERR`   | 0x53 |
| `RS_LATEINIT_CALLBACK_UPDT_TIMESTMP_ERR`      | 0x54 |
| `RS_LATEINIT_CALLBACK_UPDT_PKG_INFO_ERR`      | 0x55 |
| `RS_LATEINIT_CALLBACK_LAUNCHCTRL_ERR`         | 0x56 |
| `RS_LATEINIT_CALLBACK_UPDT_KEYBLOBS_ERR`      | 0x57 |
| `RS_LATEINIT_CALLBACK_TCBRECOVERY_ERR`        | 0x58 |
| `RS_LATEINIT_CALLBACK_STORPLATMANIF_ERR`      | 0x59 |
| `RS_LATEINIT_CALLBACK_LEGACYVARS_ERR`         | 0x5A |
| `RS_LATEINIT_CALLBACK_REGSTATE_VAR_ERR`       | 0x5B |


### SGX Status

The possible values reported for SGX on multi-package platforms are:

- SGX is enabled.
- A reboot is required to finish enabling SGX.
- SGX is disabled and a Software Control Interface is not available to enable it.
- SGX is not enabled on this platform. More details are unavailable.
- SGX is disabled, but a Software Control Interface is available to enable it.
- SGX is disabled, but can be enabled manually in the BIOS setup.
- Detected an unsupported version of Windows* 10 with Hyper-V enabled.
- SGX is not supported by this CPU.

[errorcodes]:  #error-codes
[pidwel]:   #platform-identity-without-enclave-loading

[indirectreg]:  ../02/overview.md#indirect-registration
[singlereg]:  ../02/overview.md#single-stage-registration
[dualreg]:  ../02/overview.md#dual-stage-registration

[uefivaralib]:  ../04/mp-reg-lib.md#sgx-multi-package-uefi-variables-access-library

[request]:  ../06/sgx_registration_server_request.md#sgx-registration-server-request
[packageinfo]:  ../06/sgx_registration_package_info.md#sgx-registration-package-info
[status]:  ../06/sgx_registration_status.md#sgx-registration-status
[serverinfo]:  ../06/sgx_registration_configuration.md#sgx-registration-server-info
[configuration]:  ../06/sgx_registration_configuration.md
[serverid]:  ../06/sgx_registration_configuration.md#sgx-registration-server-id

[linuxtools]:  https://download.01.org/intel-sgx/latest/dcap-latest/linux/distro/
[windowstools]:  https://download.01.org/intel-sgx/latest/dcap-latest/windows/tools/
[githubtools]:  https://github.com/intel/confidential-computing.tee.dcap/tree/main/tools/SGXPlatformRegistration
[mp-reg-lib]:  ../04/mp-reg-lib.md
[uefivar]:  ../06/index.md#bios-multi-package-uefi-variables
[mp-net-lib]:  ../04/mp_network_library.md
