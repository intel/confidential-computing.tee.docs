---
description: Describes the SGX Registration Status UEFI variable and its fields.
keywords: Intel SGX, DCAP, registration, status, UEFI variable
---
<!---
Copyright (C) 2025 Intel Corporation
SPDX-License-Identifier: CC-BY-4.0
-->

# SGX Registration Status

This variable is created by BIOS and is always available to software for reading on all boot flows (including when SGX is disabled).
When BIOS needs to communicate to the software that some action needs to take place, BIOS resets one of the defined Status bits to 0.
When software completes the action, it can set the relevant status bit to 1 to prevent BIOS from requesting the same action on a subsequent boot and to limit exposure of privacy sensitive data.
When all valid status bits are set to 1, BIOS makes this variable read-only.
Software can also use this variable to query the status of an action on future boot flows, so the status bits need to be preserved by BIOS across boots (until a new action is required).
If one of the status bits remains 0 on a subsequent boot, BIOS provides the data necessary to allow the software to retry that action.

BIOS communicates to software any errors that occurred during a boot flow by setting the Error Code to a non-zero value (with the most significant bit reset to 0).
If BIOS reports an error, there is no action for software to take.
Software can also write to the Error Code when it encounters an error (with the most significant bit set to 1).
To allow a software Error Code to persist across boot flows, BIOS should not overwrite a non-zero software ErrorCode on a subsequent successful normal boot flow.

| | |
| --- | --- |
| `GUID` | `f236c5dc-a491-4bbe-bcdd-88885770df45` |
| `Size` | 2 |
| `Attributes` | `Read-Write` then `Read-only`. |
| `Description` | BIOS creates this variable whenever communication to the registration authority service is required or whenever a key blob backup is required. |
| `Fields` | See table SgxRegistrationStatus Fields |

/// table-caption
SgxRegistrationStatus
///

<!-- markdownlint-disable MD033 -->
| Name | Size | Type | Description |
| --- | --- | --- | --- |
| `Version` | 2 | LE Integer | 1 |
| `Size` | 2 | LE Integer | Size in bytes of data below |
| `Status` | 2 | Little Endian | `BIT[0]`: `SgxRegistrationComplete` <br />&nbsp;&nbsp;&nbsp;&nbsp;`0`: SGX Registration is in progress. <br />&nbsp;&nbsp;&nbsp;&nbsp;`SgxRegistrationServerRequest` is accessible. <br /><br />&nbsp;&nbsp;&nbsp;&nbsp;`1`: SGX Registration is complete. <br />&nbsp;&nbsp;&nbsp;&nbsp;`SGXRegistrationResponse` is available when `ErrorCode` is `0`. <br />&nbsp;&nbsp;&nbsp;&nbsp;`SgxPlatformServerRequest` is not accessible on next boot. <br /><br />`BIT[1]`: `SgxRegistrationPackageInfo` read complete <br />&nbsp;&nbsp;&nbsp;&nbsp;`0`: `RegistrationPackageInfo` backup in process.<br />&nbsp;&nbsp;&nbsp;&nbsp;`SgxRegistrationPackageInfo` accessible.<br /><br />&nbsp;&nbsp;&nbsp;&nbsp;`1`: `RegistrationPackageInfo` backup is complete.<br />&nbsp;&nbsp;&nbsp;&nbsp;`SgxRegistrationPackageInfo` is not accessible on next boot. <br /><br />`BIT[15:2]`: Reserved |
| `Error Code` | 1 | N/A | Registration Error Code. <ul><li>BIOS errors have most significant bit reset.</li><li>SW errors have most significant bit set.</li></ul> |

/// table-caption
SgxRegistrationStatus Fields
///
<!-- markdownlint-enable MD033 -->
