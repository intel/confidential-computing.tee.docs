---
description: Details the SGX Registration Package Info UEFI variable for key blob management.
keywords: Intel SGX, DCAP, registration, key blob, UEFI variable
---
<!---
Copyright (C) 2025 Intel Corporation
SPDX-License-Identifier: CC-BY-4.0
-->

# SGX Registration Package Info

Currently, this variable contains the key blob structures for each package in the platform.
BIOS only generates this variable when new or modified key blobs are available.
Microcode may generate new key blobs in any boot flow.
The software can use this variable to store the key blobs off-platform if the key blobs stored by BIOS are lost.

BIOS clears the `SgxRegistrationStatus.SgxPackageInfoComplete` bit to `0` when key blobs are available.
The key blobs contain privacy sensitive information and should only be exposed until software reads them.
Once software reads the data out for backup storage, it should set `SgxRegistrationStatus.SgxPackageInfoComplete` bit to `1` to indicate to BIOS that it should not expose this same data on a subsequent boot flow.
If the software does not set the `SgxRegistrationStatus.SgxPackageInfoComplete` bit to `1`, BIOS provides the same data in this variable on the subsequent boot (unless microcode generates new key blobs).

By default, this UEFI variable is not provided to software when microcode generates new key blobs.
Platform owners that need to store key blobs off-platform must opt-in via a BIOS configuration.
For platforms that do not opt-in for key blob storage, BIOS always sets the `SgxRegistrationStatus.SgxPackageInfoComplete` bit to `1` before booting to the OS.

To restore the key blobs, software can create/write to this UEFI variable so BIOS can use the key blobs on the next boot.
This variable is writeable only if SGX is disabled.

<!-- markdownlint-disable MD033 -->
| | |
| --- | --- |
| `GUID` | `ac406deb-ab92-42d6-aff7-0d78e0826c68` |
| `Size` | `8 * sizeof(KEY_BLOB)` |
| `Attributes` | <ul><li>`Read-only` when SGX is enabled.</li><li>`Read-Write` when SGX is disabled.</li></ul> |
| `Description` | This variable is created by BIOS using data it received from microcode. It can be created and written to by software when SGX is disabled. |
| `Fields` | See table SgxRegistrationPackageInfo Fields |

/// table-caption
SgxRegistrationPackageInfo
///
<!-- markdownlint-enable MD033 -->

<!-- markdownlint-disable MD033 -->
| Name | Size | Type | Description |
| --- | --- | --- | --- |
| `Version` | 2 | LE Integer | `1` |
| `Size` | 2 | LE Integer | Size in bytes of data below |
| `KEY_BLOB[8]` | `8 * sizeof(KEY_BLOB)` | Mix | Array of `KEY_BLOB` generated or modified by the microcode loader. <br />Empty array elements are all `0x00`s. |

/// table-caption
SgxRegistrationPackageInfo Fields
///
<!-- markdownlint-enable MD033 -->
