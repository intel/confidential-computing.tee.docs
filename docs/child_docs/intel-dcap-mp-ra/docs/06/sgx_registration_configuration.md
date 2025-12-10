---
description: Describes the SgxRegistrationConfiguration UEFI variable for configuring the SGX registration authority service.
keywords: Intel SGX, DCAP, SgxRegistrationConfiguration, registration authority, UEFI variable
---
<!---
Copyright (C) 2025 Intel Corporation
SPDX-License-Identifier: CC-BY-4.0
-->

# SgxRegistrationConfiguration

BIOS creates this variable to communicate the registration authority service URL to software.
Software reads this variable when there is data in SgxRegistrationServerRequest and `SgxRegistrationStatus.SgxRegistrationComplete` bit is `0`.
The platform owner must disable SGX to allow software to write to this variable.
When this variable is writeable by software, the software can modify which registration authority service the platform to use.
When the registration authority service changes, any current platform registration is invalid.
On writes to this variable, the BIOS clears all platform registration data (`KEY_BLOBS` and `PLATFORM_MANIFESTS`).
Any attempts to write to this variable when it is read-only are ignored.

BIOS provides this variable to software on all boot flows.

The `Flags` field contains a flag indicating when the platform owner allows the registration authority service to store the platform keys.
Software uses this flag to determine if direct or indirect registration is enabled for the platform.
The flag can be modified using the BIOS UI's 'SGX Auto MP Registration' knob.

<!-- markdownlint-disable MD033 -->
|    |    |
|----|----|
| `GUID` | `18b3bc81-e210-42b9-9ec8-2c5a7d4d89b6` |
| `Size` | 1514 |
| `Attributes` | <ul><li>`Read-only` when SGX is enabled.</li><li>`Read-Write` when SGX is disabled.</li></ul> |
| `Description` | BIOS creates this variable during all boot flows. Software can use it to modify the registration authority service. |
| `Fields` | See table SgxRegistrationConfiguration Fields |

/// table-caption
SgxRegistrationConfiguration
///
<!-- markdownlint-enable MD033 -->

<!-- markdownlint-disable MD033 -->
| Name                  | Size  | Type          | Description   |
|-----------------------|-------|---------------|---------------|
| `Version`             | 2     | LE Integer    | 1             |
| `Size`                | 2     | LE Integer    | Size in bytes of data below|
| `Flags`               | 2     | LE Integer    | `BIT 0`:&nbsp;&nbsp;&nbsp;&nbsp;RS Encrypted Keys<br />&nbsp;&nbsp;&nbsp;&nbsp;`0`: Registration Server saves platform keys<br />&nbsp;&nbsp;&nbsp;&nbsp;`1`: Registration Server does not save platform keys<br />`Bits 1:15`:&nbsp;&nbsp;&nbsp;&nbsp;Reserved MBZ |
| `SgxRegServerInfo`    | 1514  | Mix           | As defined in MP SGX_REGISTRATION_SERVER_INFO |

/// table-caption
SgxRegistrationConfiguration Fields
///
<!-- markdownlint-enable MD033 -->

!!! note
    The above data can be part of BIOS setup configuration variable.


## Header

The Header is the first field of multi-package data structures that is shared between components.

| Name        | Size | Type        | Description        |
|-------------|----- |-------------|--------------------|
| `GUID`        | 16   |  Byte Array | GUID uniquely identifying the data structure. |
| `SIZE`        | 2    | LE Integer  | Data structure size excluding the size of this header. |
| `VERSION`     | 2    | LE Integer  | Structure version. |
| `RESERVED`    | 12   | N/A         | Reserved: This field is `0`. |


## PubKey

This structure represents an RSA3072 public key.
It does not contain a HEADER since it is never used as an "upper-layer" structure.

| Name        | Size | Type        | Description        |
|-------------|----- |-------------|--------------------|
| `MODULUS`     | 384  | LE Integer  | RSA key pair modulus (N) |
| `PUBEXP`      | 4    | LE Integer  | RSA public exponent (E) |


## SGX Registration Server ID

This structure represents the identity of the registration authority service.
BIOS provides it to microcode so it can properly generate platform manifests and key blobs.
The self-signed `REGISTRATION_SERVER_ID` structure contains all the keys the registration authority service uses for authorizing and decrypting the platform keys.
The structure includes two 3072-bit RSA keys.
The Registration Server Authorization Key (RSAK) is used to sign `PLATFORM_MEMBERSHIP_CERTS` and this structure.
The Registration Service Encryption Key (RSEK) is used by microcode for encrypting the platform keys in the platform manifest.

| Name        | Size | Type        | Description        |
|-------------|----- |-------------|--------------------|
| `Header`    | 32  | Mix | GUID: `31A12AFE-0720-4EBC-B64E-C4B3C7F8BC0F` Version: 1 |
| `RSNAME`    | 32    | Byte Array | Registration Server self-selected public ID. Frequently the hash of the server’s domain name or something to this effect |
| `RSAK`      | PubKey (388)    | Mix | Registration Server’s RSA Authorization Key. |
| `RSEK`      | PubKey (388)    | Mix | Registration Server’s RSA public key used to encrypt platform keys. |
| `Signature` | 384    | LE Integer  | This entire structure is self-signed using the Registration Server’s RSAK. |


## SGX Registration Server Info

This structure links the registration authority service URL with the signed `REGISTRATION_SERVER_ID` structure.

| Name                      | Size  | Type          | Description        |
|---------------------------|-------|---------------|--------------------|
| `Header`                  | 32    | Mix           | GUID: `212FE183-6B1A-42A1-A7A9-DA3AB6B7BD02` Version: 1 |
| `URL_SIZE`                | 2     | LE Integer    | Number of bytes in the URL. |
| `URL`                     | 256   | Byte Array    | ASCII representation of the URL name. Does not contain `\0` ``NULL`` terminator. |
| `SgxRegistrationServerID` | `sizeof (SgxRegistrationServerID)` | Mix | Registration authority services’s RSA public keys and RSNAME |
