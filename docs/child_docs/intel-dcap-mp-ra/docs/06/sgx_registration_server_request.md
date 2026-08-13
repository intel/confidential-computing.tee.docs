---
description: Explains the SGX Registration Server Request UEFI variable for registration flows.
keywords: Intel SGX, DCAP, registration, server request, UEFI variable
---
<!---
Copyright (C) 2025 Intel Corporation
SPDX-License-Identifier: CC-BY-4.0
-->

# SGX Registration Server Request

BIOS exposes this variable when data needs to be sent to the registration authority service.
Its contents depend on the registration boot flow.
For Initial Platform Establishment and TCB Recovery boot flows, it contains the platform manifests.
For the Add Package flow, it contains add package structure.
BIOS only generates this variable when there is data to send.
The platform manifest and add package structures contain privacy sensitive information and should only be exposed to software until registration completes.
Software indicates that registration is complete by setting the `SgxRegistrationStatus.SgxRegistrationComplete` bit to 1.
BIOS clears the `SgxRegistrationStatus.SgxRegistrationComplete` bit to 0 when there is data to process, and software expects this variable to be available.
Software processes its contents and sets the `SgxRegistrationStatus.SgxRegistrationComplete` bit to 1 to indicate whether the registration flow completes successfully.
Software also sets the `SgxRegistrationStatus.SgxRegistrationComplete` to 1 on terminal errors received from the server as an indication that no retries resolve the error.
If the registration does not complete and the software does not set the `SgxRegistrationStatus.SgxRegistrationComplete` bit to 1, BIOS provides the same data in this variable on the next boot for software to retry processing the data.
Otherwise, BIOS does not present this same data on a subsequent boot.

Any errors encountered by software are reported with an error code in `SgxRegistrationStatus.ErrorCode`.

<!-- markdownlint-disable MD033 -->
| | |
| --- | --- |
| `GUID` | `304e0796-d515-4698-ac6e-e76cb1a71c28` |
| `Size` | N/A |
| `Attributes` | Read-only |
| `Description` | This variable is created by BIOS when `SgxRegistrationStatus.SgxRegistrationComplete` is 0.<br />Contains several self-signed data structures based on boot scenario. |
| `Fields` | See table SgxRegistrationServerRequest Fields |

/// table-caption
SgxRegistrationServerRequest
///
<!-- markdownlint-enable MD033 -->

<!-- markdownlint-disable MD033 -->
| Boot Scenario | Contents | Size | Type | Description |
| --- | --- | --- | --- | --- |
| | `Version` | 2 | LE Integer | `2` – When content is `PLATFORM_MANIFEST`<br /> `1` or `2` – When content is `ADD_REQUEST` |
| | `Size` | 2 | LE Integer | Size in bytes of data below (after trimming) |
| Initial Platform Establishment/TCB Recovery | `PLATFORM_MANIFEST` | Variable (PM Header size will always be untrimmed size) | Mix | Contains 2 `PLATFORM_MANIFESTS`. <br />The first `PLATFORM_MANIFEST` is from the IPE flow and the second is for TCB Recovery (for the IPE boot flow, the TCB Recovery `PLATFORM_MANIFEST` will be all zeros and will be trimmed the same as the IPE `PLATFORM_MANIFEST`). <br />**Data Header:** <br />GUID: `178E874B-49E4-4AA5-99BB-3057170925B4` <br />Version: 1 |
| Add package | `ADD_REQUEST` | 211 | Mix | Contains the `ADD_REQUEST` structure. <br />**Data Header:** <br />GUID: `696519ca-73c1-4785-a0f6-4d289d37e995` <br />Version: 1 |

/// table-caption
SgxRegistrationServerRequest Fields
///
<!-- markdownlint-enable MD033 -->

!!! note
    Data structures based on boot scenario.
