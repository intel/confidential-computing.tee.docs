---
description: API specification for the Intel SGX/TDX Provisioning Certificate Caching Service (PCCS).
keywords: PCCS, DCAP, API, specification, caching service, Confidential Computing, SGX, TDX
---
<!---
Copyright (C) 2025 Intel Corporation
SPDX-License-Identifier: CC-BY-4.0
-->

# API Specification for PCCS


## Get PCK Certificate

Retrieve the X.509 SGX Provisioning Certification Key (PCK) certificate for an SGX-enabled platform at a specified TCB level.


### Endpoint(s)

- `GET https://pccs-server-url:8081/sgx/certification/v3/pckcert`
- `GET https://pccs-server-url:8081/sgx/certification/v4/pckcert`


### Request

::spantable:: class="st-w100p"

<!-- markdownlint-disable MD033 -->
| **Name** @class="w012p" | **Type** @class="w009p" | **Request**<br/>**Type** @class="w011p" | **Required** @class="w012p" | **Pattern** @class="w022p" | **Description** @class="w034p" |
| --- | --- | --- | --- | --- | --- |
| `encrypted_ppid` | String | Query | False | `^[0-9a-fA-F]{512}$` | Base16-encoded Encrypted\_PPID |
| `cpusvn` | String | Query | True | `^[0-9a-fA-F]{32}$` | Base16-encoded CPUSVN value |
| `pcesvn` | String | Query | True | `^[0-9a-fA-F]{4}$` | Base16-encoded PCESVN value |
| `pceid` | String | Query | True | `^[0-9a-fA-F]{4}$` | Base16-encoded PCEID value |
| `qeid` | String | Query | True | `^[0-9a-fA-F]{32}$` | Base16-encoded QEID value |
<!-- markdownlint-enable MD033 -->

::end-spantable::

/// table-caption
    attrs: {id: tab_table2}

///


### Response

`PckCert` (x-pem-file) - PEM-encoded representation of Intel® SGX PCK Certificate in case of success (200 HTTP status code)


#### Status codes

::spantable:: class="st-w100p"

<!-- markdownlint-disable MD033 -->
| **Code** @class="w009p" | **Model** @class="w015p" | **Headers** @class="w044p" | **Description** @class="w034p" |
| --- | --- | --- | --- |
| 200 | `PckCert` | <ul><li>`SGX-PCK-Certificate-Issuer-Chain` (String): URL-encoded Issuer Certificate chain for SGX PCK Certificate in PEM format. It consists of SGX Intermediate CA Certificate (Processor CA) followed by SGX Root CA Certificate</li><li>`SGX-TCBm` (String): Hex-encoded string representation of concatenation of CPUSVN (16 bytes) and PCESVN (2 bytes) as returned in corresponding SGX PCK Certificate</li></ul> | Successfully completed |
| 400 | - | - | Invalid request parameters |
| 404 | - | - | No cache data for this platform |
| 461 | - | - | The platform was not found in the cache. |
| 462 | - | - | Certificates are not available for certain TCBs. |
| 500 | - | - | Internal server error occurred |
| 502 | - | - | Unable to retrieve the collateral from the PCS. |
<!-- markdownlint-enable MD033 -->

::end-spantable::

/// table-caption
    attrs: {id: tab_table3}

///


### Process

1. Checks request parameters upon client request and returns the 400 error if any parameter is invalid.
2. Gets the platform object from `platforms` table with the input `{qeid, pceid}` as key (see [platformsDao.getPlatform](../04/database.md#platformsdao)).
3. If the platform was found, which means the platform was already cached:
    1. Queries PCK Certificate for this platform and PCK Certificate issuer chain from cache db with the input `{qeid, cpusvn, pcesvn, pceid}` as key (see [pckcertDao.getCert](../04/database.md#pckcertdao)).
    2. Goes to step 4.
4. If collateral was not retrieved in step 3:
    1. If platform is not cached
        1. If cache fill mode is `LAZY`:
            1. Gets all PCK Certificates for this platform from [PCS v4 API](https://api.portal.trustedservices.intel.com/content/documentation.html#pcs-certificates-v4) with `{encrypted_ppid, pceid}` for single-package platform, or `{platform_manifest, pceid}` for multi-package platform.
            2. Parses the first cert (X.509) in the array to get FMSPC and ca type (`processor` or `platform`).
            3. Contacts PCS again to get SGX TCB Info as well as TDX TCB Info (if available) with the above FMSPC value.
            4. Gets the best cert with PCKCertSelectionTool using `{cpusvn, pcesvn, pceid, SGX TCB Info, PCK Certificates}`.
            5. Updates the cache tables:
                - `platforms` table: calls [platformsDao.upsertPlatform](../04/database.md#platformsdao) to update the platforms table;
                - `pck_cert` table: first calls [pckcertDao.deleteCerts](../04/database.md#pckcertdao) to delete old records associated with the `{qeid, pceid}`, then for each certificate fetched in i., calls [pckcertDao.upsertPckCert](../04/database.md#pckcertdao) to insert the certificate;
                - `platform_tcbs` table: for the new raw TCB in the request and all old cached raw TCBs, inserts/updates the new TCB mapping by calling [platformTcbsDao.upsertPlatformTcbs](../04/database.md#platformtcbsdao);
                - `fmspc_tcbs` table: calls [fmspcTcbDao.upsertFmspcTcb](../04/database.md#fmspctcbdao) to update `fmspc_tcbs` table for both SGX TCB Info and TDX TCB Info (if available);
                - `pck_certchain` table: calls [pckCertchainDao.upsertPckCertchain](../04/database.md#pckcertchaindao) to update `pck_certchain` table with the ca type in step ii.;
                - `pcs_certificates` table: calls [pcsCertificatesDao.upsertPckCertificateIssuerChain](../04/database.md#pcscertificatesdao) to update PCK Certificate issuer chain with the ca type in step ii.
            6. Returns the PCK Certificate in the response body and PCK Certificate issuer chain in the response header.
            7. Responds with the 200 status code.
            8. Else return 461 (not found) error
        2. Else
            1. Gets PCK Certificates from cache DB with `{qeid, pceid}` (see [pckcertDao.getCerts](../04/database.md#pckcertdao)).
            2. Gets TCB Info from cache DB with the FMSPC of the platform (see [fmspcTcbDao.getTcbInfo](../04/database.md#fmspctcbdao)).
            3. Runs PCK Certificate selection tool with the raw TCB, PCK Certificates, and SGX TCB Info.
            4. Gets PCK Certificate issuer chain from cache DB (see [pckCertchainDao.getPckCertChain](../04/database.md#pckcertchaindao)).
            5. If success, returns the "best" certificate and certificate chain, else returns the 404 error.
            6. Updates `platform_tcbs` table for this raw TCB (see [platformTcbsDao.upsertPlatformTcbs](../04/database.md#platformtcbsdao)).
    2. Else
        1. Returns the PCK Certificate in the response body and PCK Certificate issuer chain in the response header.


## Get PCK Certificate CRL

Retrieve the X.509 Certificate Revocation List with the revoked Intel® SGX PCK Certificates.
The CRL is issued either by Intel® SGX Platform CA or by Intel® SGX Processor CA.


### Endpoint(s)

- `GET https://pccs-server-url:8081/sgx/certification/v3/pckcrl`
- `GET https://pccs-server-url:8081/sgx/certification/v4/pckcrl`


### Request

::spantable:: class="st-w100p"

<!-- markdownlint-disable MD033 -->
| **Name** @class="w012p" | **Type** @class="w009p" | **Request**<br/>**Type** @class="w011p" | **Required** @class="w012p" | **Pattern** @class="w016p" | **Description** @class="w040p" |
| --- | --- | --- | --- | --- | --- |
| `ca` | String | Query | True | Enum: `processor`, `platform` | Identifier of the CA that issued the requested CRL |
| `encoding` | String | Query | True | Enum: `der` | Optional identifier of the encoding for the requested CRL. If the parameter is not provided, HEX-encoded DER is assumed. If `der` is provided, raw DER format CRL will be returned. |
<!-- markdownlint-enable MD033 -->

::end-spantable::

/// table-caption
    attrs: {id: tab_table4}

///


### Response

`PckCrl` (PKIX-CRL) – DER or HEX-encoded DER representation of SGX Platform CA CRL or SGX Processor CA CRL in case of success.


#### Status codes

::spantable:: class="st-w100p"

| **Code** @class="w009p" | **Model** @class="w015p" | **Headers** @class="w044p" | **Description** @class="w034p" |
| --- | --- | --- | --- |
| 200 | `PckCrl` | `SGX-PCK-CRL-Issuer-Chain`: Issuer Certificate chain for SGX PCK CRL. It consists of SGX Intermediate CA Certificate (Processor CA) followed by SGX Root CA Certificate | Successfully completed |
| 400 | - | - | Invalid request parameters |
| 404 | - | - | PCK CRL cannot be found |
| 500 | - | - | Internal server error occurred |
| 502 | - | - | Unable to retrieve the collateral from the PCS. |

::end-spantable::

/// table-caption
    attrs: {id: tab_table5}

///


### Process

1. Checks request parameters and returns the 400 error if any input parameter is invalid
2. Queries PCK CRL along with CRL issuer chain with the key `{ca}` ([see pckcrlDao.GetPckCrl](../04/database.md#pckcrldao)).
    1. If record exists:
        1. Returns `pck_crl` in the response body and the PCK CRL certificate chain in the response header.
        2. Responds with the 200 status code.
    2. Else:
        1. If cache fill mode is not `LAZY`, returns the 404 (No cache data) error to client.
        2. If cache fill mode is `LAZY`
            1. Gets PCK CRL and PCK CRL certificate chain from [PCS v4 API](https://api.portal.trustedservices.intel.com/content/documentation.html#pcs-revocation-v4) with `{ca}`.
              If failed, returns the 404 error.
            2. Updates `pck_crl` and `pcs_certificates` table:
                1. Calls [pckcrlDao.upsertPckCrl(ca, crl)](../04/database.md#pckcrldao), crl is a response body.
                2. Calls [pcsCertificatesDao.upsertPckCrlCertchain](../04/database.md#pcscertificatesdao) with `{ca}` and retrieved PCK CRL certificate chain.
            3. Returns PCK CRL in the response body and PCK CRL certificate chain in the response header.
            4. Responds with the 200 status code.


## Get TCB Info

Retrieve Intel® SGX or TDX TCB Information for the given FMSPC


### Endpoint(s)

- `GET https://pccs-server-url:8081/sgx/certification/v3/tcb`
- `GET https://pccs-server-url:8081/sgx/certification/v4/tcb`
- `GET https://pccs-server-url:8081/tdx/certification/v4/tcb`


### Request

::spantable:: class="st-w100p"

<!-- markdownlint-disable MD033 -->
| **Name** @class="w012p" | **Type** @class="w009p" | **Request**<br/>**Type** @class="w011p" | **Required** @class="w012p" | **Pattern** @class="w016p" | **Description** @class="w040p" |
| --- | --- | --- | --- | --- | --- |
| `fmspc` | String | Query | True | `^[0-9a-fA-F]{12}` | Base16-encoded FMSPC value |
| `update` | String | Query | False | Enum: `early`, `standard` | Type of update to TCB Info. <br/>If not provided `standard` is assumed.<br/>`early` indicates an early access to updated TCB Info provided as part of a TCB recovery event (commonly the day of public disclosure of the items in scope)<br/>`standard` indicates standard access to updated TCB Info provided as part of a TCB recovery event (commonly approximately 6 weeks after public disclosure of the items in scope) |
<!-- markdownlint-enable MD033 -->

::end-spantable::

/// table-caption
    attrs: {id: tab_table6}

///


### Response

`TcbInfo` (JSON) - Intel® SGX TCB Info encoded as JSON string in case of success


#### Status codes

::spantable:: class="st-w100p"

<!-- markdownlint-disable MD033 -->
| **Code** @class="w009p" | **Model** @class="w015p" | **Headers** @class="w044p" | **Description** @class="w034p" |
| --- | --- | --- | --- |
| 200 | `TcbInfo` | `SGX-TCB-Info-Issuer-Chain` (v3) or `TCB-Info-Issuer-Chain` (v4): Issuer Certificate chain for Intel® SGX TCB Info. It consists of Intel® TCB Signing Certificate followed by Root CA Certificate | Successfully completed |
| 400 | - | - | Invalid request parameters |
| 404 | - | - | TCB Information for provided `{fmspc}` cannot be found |
| 500 | - | - | Internal server error occurred |
| 502 | - | - | Unable to retrieve the collateral from the PCS |
<!-- markdownlint-enable MD033 -->

::end-spantable::

/// table-caption
    attrs: {id: tab_table7}

///


### Process

1. Checks request parameters and returns the 400 error if any parameter is invalid.
2. Queries TCB Info along with Intel® TCB Info issuer chain with key `{type, fmspc, version, update_type}` ([see fmspcTcbDao.
  getTcbInfo](../04/database.md#fmspctcbdao)).
  Type can be 0:SGX or 1:TDX.
    1. If record exists:
        1. Returns `tcb_info` in the response body and the issuer chain in the response header.
        2. Responds with the 200 status code.
    2. Else:
        1. If cache fill mode is not `LAZY`, returns the 404 (No cache data) error to client.
        2. If cache fill mode is `LAZY`
            1. Gets TCB Info from PCS with `{type, fmspc, version}`.
                If failed, return the 404 error.

                If type is 0:SGX, send request to /sgx/ url, else if type is 1:TDX, send request to /tdx/ url.
                Version will be translated to either /v3/ or /v4/.
            2. Updates `fmspc_tcbs` and `pcs_certificates`:
                - `fmspc_tcbs` table: calls [fmspcTcbDao.upsertFmspcTcb](../04/database.md#fmspctcbdao);
                - `pcs_certificates` table: calls [pcsCertificatesDao.upsertTcbInfoIssuerChain](../04/database.md#pcscertificatesdao).
            3. Returns TCB Info in the response body and TCB Info certificate chain in the response header.
            4. Responds with the 200 status code.


## Get Intel's QE Identity

Retrieve the Quote Identity information for the Quoting Enclave issued by Intel.


### Endpoint(s)

- `GET https://pccs-server-url:8081/sgx/certification/v3/qe/identity`
- `GET https://pccs-server-url:8081/sgx/certification/v4/qe/identity`


### Request

::spantable:: class="st-w100p"

<!-- markdownlint-disable MD033 -->
| **Name** @class="w012p" | **Type** @class="w009p" | **Request**<br/>**Type** @class="w011p" | **Required** @class="w012p" | **Pattern** @class="w016p" | **Description** @class="w040p" |
| --- | --- | --- | --- | --- | --- |
| `update` | String | Query | False | Enum: `early`, `standard` | Type of update to QE Identity.<br/>If not provided `standard` is assumed.<br/>`early` indicates an early access to updated QE Identity provided as part of a TCB recovery event (commonly the day of public disclosure of the items in scope)<br/>`standard` indicates standard access to updated QE Identity provided as part of a TCB recovery event (commonly approximately 6 weeks after public disclosure of the items in scope) |
<!-- markdownlint-enable MD033 -->

::end-spantable::

/// table-caption
    attrs: {id: tab_table8}

///


### Response

`QEIdentity` (JSON) - QE Identity data structure encoded as JSON string in case of success


#### Status codes

::spantable:: class="st-w100p"

| **Code** @class="w009p" | **Model** @class="w015p" | **Headers** @class="w044p" | **Description** @class="w034p" |
| --- | --- | --- | --- |
| 200 | `QEIdentity` | `SGX-Enclave-Identity-Issuer-Chain`: Issuer Certificate chain for Intel® SGX QE Identity. It consists of Intel® SGX TCB Signing Certificate followed by Intel® SGX Root CA Certificate | Successfully completed |
| 404 | - | - | QE identity information cannot be found |
| 500 | - | - | Internal server error occurred |
| 502 | - | - | Unable to retrieve the collateral from the PCS |

::end-spantable::

/// table-caption
    attrs: {id: tab_table9}

///


### Process

1. Queries QE identity along with SGX Enclave identity issuer chain ([see identityDao.
  getIdentity](../04/database.md#identitydao)).
    1. If record exists:
        1. Returns `qe_identity` in the response body and the QE certificate chain in the response header.
        2. Returns the 200 status code.
    2. Else:
        1. If cache fill mode is not `LAZY`, returns the 404 (No cache data) error to client.
        2. If cache fill mode is `LAZY`:
            1. Gets QE identity from the corresponding API version of [PCS](https://api.portal.trustedservices.intel.com/content/documentation.html#pcs-enclave-identity-v4).
              If failed, returns the 404 error.
            2. Updates `identities` and `pcs_certificates` table:
                - `identities` table: calls [identityDao.upsertIdentity](../04/database.md#identitydao).
                - `pcs_certificates` table: calls [pcsCertificatesDao.upsertIdentityIssuerChain](../04/database.md#pcscertificatesdao).
            3. Returns `qe_identity` in the response body and the QE certificate chain in the response header.
            4. Returns the 200 status code.


## Get Intel's QvE Identity

Retrieve Identity information for Quote Verification Enclave issued by Intel.


### Endpoint(s)

- `GET https://pccs-server-url:8081/sgx/certification/v3/qve/identity`
- `GET https://pccs-server-url:8081/sgx/certification/v4/qve/identity`


### Request

::spantable:: class="st-w100p"

<!-- markdownlint-disable MD033 -->
| **Name** @class="w012p" | **Type** @class="w009p" | **Request**<br/>**Type** @class="w011p" | **Required** @class="w012p" | **Pattern** @class="w016p" | **Description** @class="w040p" |
| --- | --- | --- | --- | --- | --- |
| `update` | String | Query | False | Enum: `early`, `standard` | Type of update to QVE Identity.<br/>If not provided `standard` is assumed.<br/>`early` indicates an early access to updated QVE Identity provided as part of a TCB recovery event (commonly the day of public disclosure of the items in scope)<br/>`standard` indicates standard access to updated QVE Identity provided as part of a TCB recovery event (commonly approximately 6 weeks after public disclosure of the items in scope) |
<!-- markdownlint-enable MD033 -->

::end-spantable::

/// table-caption
    attrs: {id: tab_table10}

///


### Response

`QvEIdentity` (JSON) - QvE Identity data structure encoded as JSON string in case of success


#### Status codes

::spantable:: class="st-w100p"

| **Code** @class="w009p" | **Model** @class="w015p" | **Headers** @class="w044p" | **Description** @class="w034p" |
| --- | --- | --- | --- |
| 200 | `QvEIdentity` | `SGX-Enclave-Identity-Issuer-Chain`: Issuer Certificate chain for Intel® SGX QvE Identity. It consists of Intel® SGX TCB Signing Certificate followed by Intel® SGX Root CA Certificate | Successfully completed |
| 404 | - | - | QvE identity information cannot be found |
| 500 | - | - | Internal server error occurred |
| 502 | - | - | Unable to retrieve the collateral from the PCS |

::end-spantable::

/// table-caption
    attrs: {id: tab_table11}

///


### Process

1. Queries QvE identity along with Intel® SGX Enclave identity issuer chain ([see identityDao.getEnclaveIdentity](../04/database.md#identitydao)).
    1. If record exists:
        1. Returns `qve_identity` in the response body and QVE certificate chain in the response header.
        2. Returns the 200 status code.
    2. Else:
        1. If cache fill mode is not `LAZY`, returns the 404 (No cache data) error to client.
        2. If cache fill mode is `LAZY`:
            1. Gets QvE identity from the corresponding API version of [PCS](https://api.portal.trustedservices.intel.com/content/documentation.html#pcs-enclave-identity-v4) .
              If failed, returns the 404 error.
            2. Updates `identities` and `pcs_certificates` table:
                - `identities` table: calls [identityDao.upsertIdentity](../04/database.md#identitydao);
                - `pcs_certificates` table: calls [pcsCertificatesDao.upsertIdentityIssuerChain](../04/database.md#pcscertificatesdao).
            3. Returns `qve_identity` in the response body and QVE certificate chain in the response header.
            4. Returns the 200 status code.


## Get Intel's TD QE Identity

Retrieve Identity information for TD Quote Enclave issued by Intel.


### Endpoint(s)

- `GET https://pccs-server-url:8081/tdx/certification/v4/qe/identity`


### Request

::spantable:: class="st-w100p"

<!-- markdownlint-disable MD033 -->
| **Name** @class="w012p" | **Type** @class="w009p" | **Request**<br/>**Type** @class="w011p" | **Required** @class="w012p" | **Pattern** @class="w016p" | **Description** @class="w040p" |
| --- | --- | --- | --- | --- | --- |
| `update` | String | Query | False | Enum: `early`, `standard` | Type of update to QE Identity.<br/>If not provided `standard` is assumed.<br/>`early` indicates an early access to updated QE Identity provided as part of a TCB recovery event (commonly the day of public disclosure of the items in scope)<br/>`standard` indicates standard access to updated QE Identity provided as part of a TCB recovery event (commonly approximately 6 weeks after public disclosure of the items in scope) |
<!-- markdownlint-enable MD033 -->

::end-spantable::

/// table-caption
    attrs: {id: tab_table8}

///


### Response

`TDQEIdentity` (JSON) - TDQE Identity data structure encoded as JSON string in case of success


#### Status codes

::spantable:: class="st-w100p"

| **Code** @class="w009p" | **Model** @class="w015p" | **Headers** @class="w044p" | **Description** @class="w034p" |
| --- | --- | --- | --- |
| 200 | `TDQEIdentity` | `SGX-Enclave-Identity-Issuer-Chain`: Issuer Certificate chain for Intel® SGX TDQE Identity. It consists of Intel® SGX TCB Signing Certificate followed by Intel® SGX Root CA Certificate | Successfully completed |
| 404 | - | - | TDQE identity information cannot be found |
| 500 | - | - | Internal server error occurred |
| 502 | - | - | Unable to retrieve the collateral from the PCS |

::end-spantable::

/// table-caption
    attrs: {id: tab_table13}

///


### Process

1. Queries TDQE identity along with Intel® SGX Enclave identity issuer chain ([see identityDao.getIdentity](../04/database.md#identitydao)).
    1. If record exists:
        1. Returns `tdqe_identity` in the response body and TDQE certificate chain in the response header.
        2. Returns the 200 status code.
    2. Else:
        1. If cache fill mode is not `LAZY`, returns the 404 (No cache data) error to client.
        2. If cache fill mode is `LAZY`:
            1. Gets TDQE identity from [PCS v4 API](https://api.portal.trustedservices.intel.com/content/documentation.html#pcs-enclave-identity-v4).
              If failed, returns the 404 error.
            2. Updates `identities` and `pcs_certificates` table:
                - `identities` table: calls [identityDao.upsertEnclaveIdentity](../04/database.md#identitydao);
                - `pcs_certificates` table: calls [pcsCertificatesDao.upsertIdentityIssuerChain](../04/database.md#pcscertificatesdao).
            3. Returns `tdqe_identity` in the response body and TDQE certificate chain in the response header.
            4. Returns the 200 status code.


## Get Root CA CRL

Retrieve Root CA CRL.


### Endpoint(s)

- `GET https://pccs-server-url:8081/sgx/certification/v3/rootcacrl`
- `GET https://pccs-server-url:8081/sgx/certification/v4/rootcacrl`


### Request

No parameters


### Response

`RootCACRL` – The HEX-encoded DER representation of Root CA CRL in case of success


#### Status codes

::spantable:: class="st-w100p"

| **Code** @class="w009p" | **Model** @class="w015p" | **Headers** @class="w044p" | **Description** @class="w034p" |
| --- | --- | --- | --- |
| 200 | `RootCACRL` | - | Successfully completed |
| 404 | - | - | Root CA CRL cannot be found |
| 500 | - | - | Internal server error occurred |
| 502 | - | - | Unable to retrieve the collateral from the PCS |

::end-spantable::

/// table-caption
    attrs: {id: tab_table17}

///


### Process

1. Queries root CA record(id=1) from `pcs_certificates` table ([see pcsCertificatesDao.getCertificateById](../04/database.md#pcscertificatesdao))
    1. If the root CA record exists and the CRL field is not empty:
        1. Returns the CRL in the response body.
        2. Returns the 200 status code.
    2. Else:
        1. If cache fill mode is not `LAZY`, return the 404 error to client
        2. If cache fill mode is `LAZY`:
            1. Calls PCS v4 API to get QE identity and extracts the root CA from the certificate chain in response header.
              If failed, returns empty body.
            2. Parses the root CA to get cdp uri
            3. Contacts the cdp uri to get root CA CRL.
              If failed, returns the 500 error.
            4. Updates `pcs_certificates` table with root CA and CRL([see pcsCertificatesDao.upsertPcsCertificates](../04/database.md#pcscertificatesdao))
            5. Returns the root CA CRL in the response body (hex-encoded)
            6. Returns the 200 status code.


## Post Platforms IDs

This API stores platform identity information provided in the request.
This API is restricted to users with the access to the user-token.


### Endpoint(s)

- `POST https://pccs-server-url:8081/sgx/certification/v3/platforms`
- `POST https://pccs-server-url:8081/sgx/certification/v4/platforms`


### Request

#### Parameters

::spantable:: class="st-w100p"

<!-- markdownlint-disable MD033 -->
| **Name** @class="w012p" | **Type** @class="w009p" | **Request**<br/>**Type** @class="w011p" | **Required** @class="w012p" | **Pattern** @class="w016p" | **Description** @class="w040p" |
| --- | --- | --- | --- | --- | --- |
| `user-token` | String | Header | True | String | PCCS user token which provides access to this API. |
<!-- markdownlint-enable MD033 -->

::end-spantable::

/// table-caption
    attrs: {id: tab_table18}

///


#### Body

``` {.json}
{
    "qe_id": "Base16-encoded QE-ID value",
    "pce_id": "Base16-encoded PCE-ID value",
    "cpu_svn": "Base16-encoded CPUSVN value",
    "pce_svn": "Base16-encoded PCESVN value",
    "enc_ppid": "Base16-encoded PPID encrypted with PPIDEK",
    "platform_manifest": "Base16-encoded platform manifest value"
}
```


### Response


#### Status codes

::spantable:: class="st-w100p"

| **Code** @class="w009p" | **Model** @class="w015p" | **Headers** @class="w015p" | **Description** @class="w061p" |
| --- | --- | --- | --- |
| 200 | - | - | Successfully completed (entry updated) |
| 201 | - | - | Successfully completed (entry created) |
| 400 | - | - | Invalid request parameters |
| 401 | - | - | Authentication failed |
| 500 | - | - | Internal server error occurred |
| 502 | - | - | Unable to retrieve the collateral from the PCS |

::end-spantable::

/// table-caption
    attrs: {id: tab_table19}

///


### Process

1. Validates the user token(calculate sha-512 hash of the token and compare the hash value with UserTokenHash in the configuration file).
  If validation fails, returns the 401 error.
2. Validates the request body with pre-defined JSON schema.
  If the validation fails, returns the 400 error to client.
3. Checks cache status for this platform.
    1. Gets the platform object from `platforms` table based on the provided `{qeid, pceid}` ([see platformsDao.getPlatform](../04/database.md#platformsdao)) .
    2. If the `platform_manifest` in the request does not match the one in the cache (**Note:** Treat the absence of the `platform_manifest` in the request while there is a `PLATFORM_MANIFEST` in the cache as a match):
        1. Updates `platforms` table of the cache with the new manifest.
        2. Sets cache status to FALSE.
    3. Else if `platform_manifest` matches:
        1. Queries PCK Certificate from cache db with `{qeid, cpusvn, pcesvn, pceid}` to check whether PCK Certificate for this platform is cached ([see pckcertDao.getCert](../04/database.md#pckcertdao)).
        2. If found, sets cache status to TRUE.
        3. Else: sets cache status to FALSE.
4. If cache fill mode is `OFFLINE`:
    1. If cache status is FALSE:
        1. Adds the platform registration data to `platforms_registered` table and returns SUCCESS (call [platformsRegDao.registerPlatform](../04/database.md#platformsregdao) with state=NEW).
5. Else:
    1. If cache status is FALSE:
        1. If cache fill mode is REQ, adds the platform registration data to `platforms_registered` table (calls platformsRegDao.registerPlatform with state=NEW)
        2. Uses the same logic in [section Get PCK Certificate](#get-pck-certificate) to get PCK Certificate from PCS.
        3. If cache fill mode is REQ, deletes the platform registration data from `platforms_registered` table (calls [platformsRegDao.registerPlatform](../04/database.md#platformsregdao) with state=DELETED).
    2. Checks quote verification collateral (PCK CRL, QE identity, QvE identity, Root CA CRL).
        If not cached, retrieves them from PCS and fills the cache
        - [pckcrlDao.getPckCrl](../04/database.md#pckcrldao)
        - [qeidentityDao.getQEIdentity](../04/database.md#identitydao)
        - [qveidentityDao.getQvEIdentity](../04/database.md#crlcachedao)
        - [pcsCertificatesDao.getCertificateById(root\_cert\_id=1)](../04/database.md#pcscertificatesdao)


## Get Platform IDs

Administrators use this API to retrieve the platform ID information for registered platforms or cached platforms.
This API is restricted to users with the access to the admin-token.


### Endpoint(s)

- `GET https://pccs-server-url:8081/sgx/certification/v3/platforms`
- `GET https://pccs-server-url:8081/sgx/certification/v4/platforms`


### Request

::spantable:: class="st-w100p"

<!-- markdownlint-disable MD033 -->
| **Name** @class="w012p" | **Type** @class="w009p" | **Request**<br/>**Type** @class="w011p" | **Required** @class="w012p" | **Pattern** @class="w016p" | **Description** @class="w040p" |
| --- | --- | --- | --- | --- | --- |
| `admin-token` | String | Header | True | String | The administrator token required to perform the request. |
| `fmspc` | String | Query | False | [fmspc1,fmspc2, …] | FMSPC array. |
<!-- markdownlint-enable MD033 -->

::end-spantable::

/// table-caption
    attrs: {id: tab_table20}

///


### Response

An array of data structures defined below encoded as JSON in case of success (200 HTTP status code).
When the Queue Status is 0, information for all registered platforms is retrieved.

Response format:

``` {.json}
[
    {
        "qe_id": "xxxx",
        "pce_id": "xxxx",
        "cpu_svn": "xxxx",
        "pce_svn": "xxxx",
        "enc_ppid": "xxxx",
        "platform_manifest": "xxxx"
    },
    {}
]
```

Empty body otherwise.


#### Status codes

::spantable:: class="st-w100p"

| **Code** @class="w009p" | **Model** @class="w015p" | **Headers** @class="w015p" | **Description** @class="w061p" |
| --- | --- | --- | --- |
| 200 | See "response format" above | - | Successfully completed |
| 400 | - | - | Invalid request parameters |
| 401 | - | - | Authentication failed |
| 500 | - | - | Internal server error occurred |

::end-spantable::

/// table-caption
    attrs: {id: tab_table21}

///


### Process

1. Checks if request parameters include fmspc.
    1. If fmspc is not included (will return platforms in registration queue):
        1. Gets the registration platforms list from cache db (see [platformsRegDao.findRegisteredPlatforms](../04/database.md#platformsregdao)).
    2. If fmspc is provided ():
        1. The format should be \[fmspc1, fmspc2, …\].
          If not, returns the 400 error.
        2. Gets cached platforms, whose fmspc is in the list (see [platformsDao.getCachedPlatformsByFmspc](../04/database.md#platformsdao)).
2. Returns the JSON list in response body and platforms count in response header.


## Put Platform Collateral to Cache

Administrators use this API to push the platform collateral for collected platforms from the PCS into the caching service.
This API is restricted to users with the access to the admin-token.


### Endpoint(s)

- `PUT https://pccs-server-url:8081/sgx/certification/v3/platformcollateral`
- `PUT https://pccs-server-url:8081/sgx/certification/v4/platformcollateral`


### Request


#### Parameters

::spantable:: class="st-w100p"

<!-- markdownlint-disable MD033 -->
| **Name** @class="w012p" | **Type** @class="w009p" | **Request**<br/>**Type** @class="w011p" | **Required** @class="w012p" | **Pattern** @class="w020p" | **Description** @class="w036p" |
| --- | --- | --- | --- | --- | --- |
| `Content-Type` | String | Header | True | `application/json` | MIME type of the request body. |
| `admin-token` | String | Header | True | String | The administrator token required to perform the request. |
| `platform_count` | Integer | Query | True | `^[1-9][0-9]*$` | Number of platforms in the PCK Certificate array. |
<!-- markdownlint-enable MD033 -->

::end-spantable::

/// table-caption
    attrs: {id: tab_table22}

///


#### Body

A JSON object includes all the collaterals for the registered platforms.

Body format:

``` {.json}
{
    "platforms": [
        {
            "qe_id": "xxxx",
            "pce_id": "xxxx",
            "cpu_svn": "xxxx",
            "pce_svn": "xxxx",
            "enc_ppid": "xxxx",
            "platform_manifest": "xxxx"
        },
        {}
    ],
    "collaterals": {
        "version": "4",
        "pck_certs": [
            {
                "qe_id": "string",
                "pce_id": "string",
                "enc_ppid": "string",
                "platform_manifest": "string",
                "certs": []
            },
            {}
        ],
        "tcbinfos": [
            {
                "fmspc": "string",
                "sgx_tcbinfo": {},
                "tdx_tcbinfo": {}
            },
            {}
        ],
        "pckcacrl": "string",
        "qeidentity": "string",
        "tdqeidentity": "string",
        "qveidentity": "string",
        "certificates": {
            "SGX-PCK-Certificate-Issuer-Chain": "string",
            "TCB-Info-Issuer-Chain": "string",
            "SGX-Enclave-Identity-Issuer-Chain": "string"
        },
        "rootcacrl": "string"
    }
}
```


### Response


#### Status codes

::spantable:: class="st-w100p"

| **Code** @class="w009p" | **Model** @class="w015p" | **Headers** @class="w015p" | **Description** @class="w061p" |
| --- | --- | --- | --- |
| 200 | - | - | Successfully completed |
| 400 | - | - | Invalid request parameters |
| 401 | - | - | Authentication failed |
| 500 | - | - | Internal server error occurred |

::end-spantable::

/// table-caption
    attrs: {id: tab_table21}

///


### Process

1. Validates the admin token(calculate sha-512 hash of the token and compare the hash value with AdminTokenHash in the configuration file).
  If the validation fails, returns the 401 error to client.
2. Validates the request body with pre-defined collateral schema.
  If the validation fails, returns the 400 error to client.
3. For each platform in the list:
    1. Deletes old PCK Certificates for this platform ([pckcertDao.deleteCerts](../04/database.md#pckcertdao)).
    2. Inserts all PCK Certificates for this platform to `pck_cert` table([pckcertDao.upsertPckCert](../04/database.md#pckcertdao)).
    3. Merges the raw TCBs in the request and cached `platform_tcbs` table to get a full raw tcb list.
    4. Extracts fmspc and ca value from any leaf cert (use the first cert for convenience).
    5. Finds the TCB Info for this fmspc from the TCBInfos in the request.
    6. For each raw TCB in the raw tcb list:
        1. Gets the best cert with PCKCertSelectionTool using `{cpusvn, pcesvn, pceid, TCB Info, PCK Certificates}`.
        2. Updates `platform_tcbs` tables.
    7. Updates `platforms` table.
4. For each TCB Info in the list:
    1. Updates `fmspc_tcbs` table.
5. Updates `pck_crl`, `qe_identities`, `qve_identities`, `pck_certchain` if present.
6. Updates `pcs_certificates` and root CA CRL if present.


## Cache Data Refresh


### Refresh through HTTP Request

This API is for maintenance only.
Refresh expired `{TCB Info, PCK CRLs, QE Identity, QvE Identity, Root CA CRL}` or `{PCK Certificates}` in cache DB.
This API is restricted to users with the access to the admin-token.

!!! note
    This API can be used when configured for with `REQ` or `LAZY` cache fill mode.
    It is not supported for `OFFLINE` cache fill mode.


#### Endpoint(s)

- \[Deprecated\] `GET https://pccs-server-url:8081/sgx/certification/v3/refresh`
- `POST https://pccs-server-url:8081/sgx/certification/v3/refresh`
- `POST https://pccs-server-url:8081/sgx/certification/v4/refresh`


#### Request

::spantable:: class="st-w100p"

<!-- markdownlint-disable MD033 -->
| **Name** @class="w012p" | **Type** @class="w009p" | **Request**<br/>**Type** @class="w011p" | **Required** @class="w012p" | **Pattern** @class="w016p" | **Description** @class="w040p" |
| --- | --- | --- | --- | --- | --- |
| `type` | String | Query | False | `certs` | Refresh type.<br/>If not provided, TCB Info, PCK CRLs, QE Identity, TDQE identity (v4 only) and QVE Identity will be refreshed.<br/>If `type = certs` and no fmspc is specified, all cached PCK Certificates will be refreshed. |
| `admin-token` | String | Header | True | String | The administrator token required to perform the request. |
| `fmspc` | String | Query | False | FMSPc1, FMSPC2, …, FMSPcn | Used with "type=certs". If fmspc is provided, refresh only certs for those FMSPCs. |
<!-- markdownlint-enable MD033 -->

::end-spantable::

/// table-caption
    attrs: {id: tab_table24}

///


#### Response

Based on the result, returns one of the following status codes.


##### Status codes

::spantable:: class="st-w100p"

| **Code** @class="w009p" | **Model** @class="w015p" | **Headers** @class="w015p" | **Description** @class="w061p" |
| --- | --- | --- | --- |
| 200 | - | - | Successfully completed |
| 401 | - | - | Operation failed |
| 500 | - | - | Internal server error occurred |
| 502 | - | - | Unable to retrieve the collateral from the PCS |
| 503 | - | - | Server is currently unable to process the request |

::end-spantable::

/// table-caption
    attrs: {id: tab_table25}

///


#### Process


##### Default (type is not specified)

For each record in `pck_crls` table, contacts PCS service to get the latest PCK CRL and PCK CRL certificate chain, then updates the `pck_crls` table if necessary.

For each record in `fmspc_tcbs` table, contacts PCS service to get the latest TCB Info, then updates the `fmspc_tcbs` table if necessary.

For each record in `identities` table, contacts PCS service to get the latest QE Identity, QvE Identity and TDQE identity (v4 only) then updates the `identities` table if necessary.

Refresh root CA CRL: Get the root CA from `pcs_certificates` table, and parse it to get the CRL cdp uri, then contacts PCS service to get the CRL and update the `pcs_certificates` table.

Refresh cached CRLs: Get all cached CRLs from `crl_cache` table, for each of them, download the CRL with the `cdp_url` as target url, and update the `crl_cache` table.


##### Type is `certs`

1. Gets all records for all the FMSPCs in the `platform_tcbs` table ([see platformTcbsDao.getPlatformTcbs(fmspc)](../04/database.md#platformtcbsdao)).
    If the FMSPCs are not provided, updates all platforms that are already cached.
2. Sorts the records by `{qeid, pceid}` so that the TCB mapping records of the same platform are put together.
3. For each platform:
    1. Gets all PCK Certificates for this platform from Intel SGX/TDX  with `{encrypted_ppid, pceid}` or `{PLATFORM_MANIFEST, pceid}`.
    2. Parses the first cert (X.509) in the array to get FMSPC value.
    3. Contacts PCS again to get TCB Info with the above FMSPC value.

        **Note:** This does not update the TCB Info in the cache.
        The TCB Info is only used with the PCK Cert Selection library to update the `platform_tcbs` table.

    4. Deletes old certificates and inserts new certificates for the platform.
4. For each raw TCB in the list of step 2, runs the PCK Cert Selection Tool to get the best certificate and update the cache.


### Scheduled Cache Data Refresh

The PCCS can also be configured to refresh the cache data regularly, for example, once a day or once a week, etc.
The scheduled task does not refresh PCK Certificates because the network traffic overhead is large.


**This refresh method is only supported in the `LAZY` cache fill mode.**

It supports Cron-style Scheduling:

```{ .text }
* * * * * *
┬ ┬ ┬ ┬ ┬ ┬
│ │ │ │ │ │
│ │ │ │ │ └ day of week (0 - 7) (0 or 7 is Sun)
│ │ │ │ └───── month (1 - 12)
│ │ │ └────────── day of month (1 - 31)
│ │ └─────────────── hour (0 - 23)
│ └──────────────────── minute (0 - 59)
└───────────────────────── second (0 - 59, OPTIONAL)
```


## Get CRL by endpoint

Retrieve the X.509 Certificate Revocation List by the CRL endpoint.


### Endpoint(s)

- `GET https://pccs-server-url:8081/sgx/certification/v3/crl`
- `GET https://pccs-server-url:8081/sgx/certification/v4/crl`


### Request

::spantable:: class="st-w100p"

<!-- markdownlint-disable MD033 -->
| **Name** @class="w012p" | **Type** @class="w009p" | **Request**<br/>**Type** @class="w011p" | **Required** @class="w012p" | **Pattern** @class="w016p" | **Description** @class="w040p" |
| --- | --- | --- | --- | --- | --- |
| `uri` | String | Query | True | Example:<br/><https://certificates.trustedservices.intel.com/IntelSGXRootCA.der> | URL to DER-encoded CRL (Root CA CRL, Platform/Package CA PCK CRL) |
<!-- markdownlint-enable MD033 -->

::end-spantable::

/// table-caption
    attrs: {id: tab_table26}

///


### Response

`Crl` - DER-encoded representation of specified CRL.


#### Status codes

::spantable:: class="st-w100p"

| **Code** @class="w009p" | **Model** @class="w015p" | **Headers** @class="w044p" | **Description** @class="w034p" |
| --- | --- | --- | --- |
| 200 | `Crl` | - | Successfully completed |
| 400 | - | - | Invalid request parameters |
| 500 | - | - | Internal server error occurred |
| 502 | - | - | Unable to retrieve the collateral from the PCS |
| 503 | - | - | Server is currently unable to process the request |

::end-spantable::

/// table-caption
    attrs: {id: tab_table27}

///


### Process

1. Checks request parameters and returns the 400 error if the input parameter is invalid
2. Queries CRL with the uri as the key ([see crlCacheDao.getCrl](../04/database.md#crlcachedao)).
    1. If record exists:
        1. Returns the crl buffer.
        2. Responds with the 200 status code.
    2. Else:
        1. If cache fill mode is not `LAZY`, returns the 404 (No cache data) error to client.
        2. If cache fill mode is `LAZY`
            1. Download the CRL with the uri address as target.
              If failed, returns the 404 error.
            2. Updates `crl_cache` table:
                1. Calls [crlCacheDao.upsertCrl(uri, crl)](../04/database.md#crlcachedao), crl is response body.
            3. Returns CRL in the response body.
            4. Responds with the 200 status code.


## Get default platform policy

Retrieve the default platform policy provided by the platform owner.


### Endpoint(s)

- `GET https://pccs-server-url:8081/sgx/certification/v3/appraisalpolicy`
- `GET https://pccs-server-url:8081/sgx/certification/v4/appraisalpolicy`


### Request

::spantable:: class="st-w100p"

<!-- markdownlint-disable MD033 -->
| **Name** @class="w012p" | **Type** @class="w009p" | **Request**<br/>**Type** @class="w011p" | **Required** @class="w012p" | **Pattern** @class="w016p" | **Description** @class="w040p" |
| --- | --- | --- | --- | --- | --- |
| `fmspc` | String | Query | True | `^[0-9a-fA-F]{12}` | Base16-encoded FMSPC value |
<!-- markdownlint-enable MD033 -->

::end-spantable::

/// table-caption
    attrs: {id: tab_table28}

///


### Response

The default platform policy for this fmspc in jwt format.


#### Status codes

::spantable:: class="st-w100p"

| **Code** @class="w009p" | **Model** @class="w015p" | **Headers** @class="w015p" | **Description** @class="w061p" |
| --- | --- | --- | --- |
| 200 | - | - | Successfully completed |
| 400 | - | - | Invalid request parameters |
| 404 | - | - | The default platform policy can't be found. |
| 500 | - | - | Internal server error occurred |

::end-spantable::

/// table-caption
    attrs: {id: tab_table29}

///


### Process

1. Checks request parameters and returns the 400 error if the input parameter is invalid
2. Queries the policy whose default flag is true for the specified fmspc ([see appraisalPolicyDao.
  getDefaultAppraisalPolicies](../04/database.md#appraisalpolicydao)).
    1. If record exists:
        1. Returns the policy buffer.
        2. Responds with the 200 status code.
    2. Else:
        1. Returns the 404 error.


## Put appraisal policy

Upload an appraisal policy to the PCCS.


### Endpoint(s)

- `PUT https://pccs-server-url:8081/sgx/certification/v3/appraisalpolicy`
- `PUT https://pccs-server-url:8081/sgx/certification/v4/appraisalpolicy`


### Request

#### Parameters

N/A


#### Body

``` {.json}
{
    "policy": policy string,
    "is_default": default flag,
    "fmspc": fmspc value
}
```


### Response


#### Status codes

::spantable:: class="st-w100p"

| **Code** @class="w009p" | **Model** @class="w015p" | **Headers** @class="w015p" | **Description** @class="w061p" |
| --- | --- | --- | --- |
| 200 | - | - | Successfully completed |
| 400 | - | - | Invalid request parameters |
| 401 | - | - | Authentication failed |
| 500 | - | - | Internal server error occurred |

::end-spantable::

/// table-caption
    attrs: {id: tab_table21}

///


### Process

1. Validates the admin token(calculate sha-512 hash of the token and compare the hash value with AdminTokenHash in the configuration file).
  If the validation fails, returns the 401 error to client.
2. Validates the request body with pre-defined policy schema.
  If the validation fails, returns the 400 error to client.
3. Calculate sha384 hash of the policy data, which will be used as the ID of the policy.
4. Parse the policy file to get policy type based on the class id.
  Currently only 3 types are supported: 0 – SGX; 1 – TDX 1.0; 2 – TDX 1.5;
5. Insert or update the `appraisal_policies` table (see [appraisalPolicyDao](../04/database.md#appraisalpolicydao)).
