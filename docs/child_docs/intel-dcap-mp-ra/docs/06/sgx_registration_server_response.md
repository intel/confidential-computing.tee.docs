---
description: Explains the SGX Registration Server Response UEFI variable for registration flows.
keywords: Intel SGX, DCAP, registration, server response, UEFI variable
---
<!---
Copyright (C) 2025 Intel Corporation
SPDX-License-Identifier: CC-BY-4.0
-->

# SGX Registration Server Response

This variable is created by software when it successfully receives response data from the registration authority service.
Once successfully completed, the software sets the `SgxRegistrationStatus.SgxRegistrationComplete` bit to 1 to indicate to BIOS that the software does not require the same SGX Registration Server Request data on the subsequent boot flow.
Currently, the only response data from the registration authority service platform membership certificates in response to a successful add request.

You should clear the data in this variable once it is consumed by BIOS to protect privacy sensitive data on the next boot.

<!-- markdownlint-disable MD033 -->
|               |    |
|---------------|----|
| `GUID`        | `89589c7b-b2d9-4fc9-bcda-463b983b2fb7` |
| `Size`        | `4 + 8*sizeof(PLATFORM_MEMBERSHIP_CERT)` |
| `Attributes`  | Read-Write |
| `Description` | This variable is created by OS/SW using data it received from the registration authority server. <br />Contains response data from the registration server. |
| `Fields` | See table SgxRegistrationServerResponse Fields |

/// table-caption
SgxRegistrationServerResponse
///
<!-- markdownlint-enable MD033 -->

<!-- markdownlint-disable MD033 -->
| Name | Size - | Type | Description |
| --- | --- | --- | --- |
| `Version` | 2 | LE Integer | `1` |
| `Size` | 2 | LE Integer | Size in bytes of data below |
| `Platform Membership Certs[8]` | `8 * sizeof(PLATFORM_MEMBERSHIP_CERT)` | Mix | Array of platform membership certs returned by the registration server. <br />Empty array elements are all `0x00`s. <br />BIOS clears the data once it has read it |

/// table-caption
SgxRegistrationServerResponse Fields
///
<!-- markdownlint-enable MD033 -->
