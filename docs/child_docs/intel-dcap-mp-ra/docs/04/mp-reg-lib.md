---
description: SGX Multi-Package UEFI Variables Access Library API documentation.
keywords: Intel SGX, DCAP, UEFI, library, API, multi-package
---
<!---
Copyright (C) 2025 Intel Corporation
SPDX-License-Identifier: CC-BY-4.0
-->

# SGX Multi-Package UEFI Variables Access Library

This library provides a set of C-like APIs that allow applications to interface with the [multi-package SGX UEFI variables][uefivar] used to communicate with BIOS.
The [Multi-Package Registration Agent][agentmpa], the [PCK Cert ID Retrieval Tool][pckidret] and the [Multi-Package Management Tool][mngtool] all link to this library.
You can develop your own tools using this library to suit your SGX attestation infrastructure.


## Initialize the Multi-Package UEFI Library (MP UEFI Library)


### Description

Provides the UEFI variable directory path and the logging level that the UEFI library uses in the other functions.
Only the Linux version of the library uses the `path` input, and it is ignored in the Windows version of the library.
You must call this function before using the other APIs provided by this library.


### Syntax

```c++
MpResult mp_uefi_init(
    const char* path,
    const LogLevel logLevel);
```


### Parameters

<!-- markdownlint-disable MD033 -->
| Parameter | Description |
| --- | --- |
| `path [In]` | Linux absolute path to the UEFI variables directory. For Linux, if the value is `NULL`, the default UEFI path of /sys/firmware/efi/efivars/ is used. For Windows, this parameter is ignored. |
| `logLevel [In]` | Set the logging level. Logging messages default to stdout. You can create an auxiliary logging function and link with the MP UEFI Library to change the output location.<br /><ul><li>Linux: `void log_message_aux(LogLevel level, const char *format, va_list argptr)`</li><li>Windows: `void uefi_log_message_aux(LogLevel glog_level, LogLevel level, const char* format, ...)`</li></ul> |
<!-- markdownlint-enable MD033 -->

### Return Values

| Parameter | Description |
| --- | --- |
| `MP_SUCCESS` | The MP UEFI library successfully initialized. |
| `MP_REDUNDANT_OPERATION` | The MP UEFI library was already initialized. |
| `MP_MEM_ERROR` | Failed to initialize the MP UEFI library. |


## Retrieve the Registration Request Type


### Description

Returns the type of data structure in the [`SgxRegistrationServerRequest`][request] UEFI variable.
Currently, the library only supports platform manifest and add package structures.


### Syntax

```c++
MpResult mp_uefi_get_request_type(
    MpRequestType *type);
```


### Parameters

| Parameter | Description |
| --- | --- |
| `type [Out]` | Holds the pending request type or `MP_REQ_NONE`. |


### Return Values

| Parameter | Description |
| --- | --- |
| `MP_SUCCESS` | The API either found the [`SgxRegistrationServerRequest`][request] UEFI variable and `type` contains the request type or the API could not find the [`SgxRegistrationServerRequest`][request] UEFI variable and `type` contains `MP_REQ_NONE`. |
| `MP_INVALID_PARAMETER` | The parameter type is `NULL`. |
| `MP_UEFI_INTERNAL_ERROR` | The request structure header in the [`SgxRegistrationServerRequest`][request] UEFI variable has an invalid version, invalid size, or unrecognized GUID. |
| `MP_NOT_INITIALIZED` | The MP UEFI library was not initialized. |


##  Retrieve the BIOS Registration Server Request


### Description

Returns the contents of the [`SgxRegistrationServerRequest`][request] UEFI variable.
It also returns the required size of the `request` structure in the parameter `request_size` if you pass in `NULL` for the `request` parameter.


### Syntax

```c++
MpResult mp_uefi_get_request(
    uint8_t *request,
    uint16_t *request_size);
```


### Parameters

<!-- markdownlint-disable MD033 -->
| Parameter | Description |
| --- | --- |
| `request [Out]` | Holds the request buffer to be populated. When this value is `NULL` but `request_size` is not `NULL`, the API will return the size of the request in the [`SgxRegistrationServerRequest`][request] UEFI variable in `request_size`. |
| `request_size [In/Out]` | <ul><li> If `request` is not `NULL`, it contains the size in bytes of buffer pointed to by `request`. Upon a successful execution, the API sets it to the number of bytes written to `request`.</li><li>If `request` is `NULL` or the inputted `request_size` is too small to contain the request (return value is `MP_USER_INSUFFICIENT_MEM`), the API sets it to the number of bytes required to contain the `request` data.</li><li>Must not be `NULL`.</li></ul> |
<!-- markdownlint-enable MD033 -->

### Return Values

| Parameter | Description |
| --- | --- |
| `MP_SUCCESS` | Successfully read the contents of the [`SgxRegistrationServerRequest`][request] UEFI variable if `request` is not `NULL` or `request_size` contains the required buffer size when `request` is `NULL`. |
| `MP_INVALID_PARAMETER` | The parameter `request_size` is `NULL` |
| `MP_NO_PENDING_DATA` | The API could not find the [`SgxRegistrationServerRequest`][request] UEFI variable. |
| `MP_USER_INSUFFICIENT_MEM` | The size of the request exceeds the size of the inputted `request`. |
| `MP_UEFI_INTERNAL_ERROR` | The request structure header in the [`SgxRegistrationServerRequest`][request] UEFI variable has an invalid version or invalid size. |
| `MP_NOT_INITIALIZED` | The MP UEFI library was not initialized. |


## Provide to BIOS the Registration Server Response


### Description

The Registration Service may generate responses to the data provided in the [`SgxRegistrationServerRequest`][request] UEFI variable.
This API allows software to provide those server responses to BIOS via the [SgxRegistrationServerResponse][serverresponse] UEFI variable.
Currently, only the [Add Package (Replace Package)][addpackage] boot flow generates a response data from the Registration Service.

If the [SgxRegistrationServerResponse][serverresponse] UEFI variable is not already available, this API creates it.


### Syntax

```c++
MpResult mp_uefi_set_server_response(
    const uint8_t *response,
    uint16_t *response_size);
```


### Parameters

| Parameter | Description |
| --- | --- |
| `response [In]` | Contains the response from the registration authority service. |
| `response_size [In]` | Size of response buffer in bytes. |


### Return Values

| Parameter | Description |
| --- | --- |
| `MP_SUCCESS` | Successfully wrote the inputted data to  [SgxRegistrationServerResponse][serverresponse] UEFI variable. |
| `MP_INVALID_PARAMETER` | Either `response` or `response_size` is `NULL`. |
| `MP_UEFI_INTERNAL_ERROR` | Error encountered when writing to the UEFI variable. |
| `MP_NOT_INITIALIZED` | The MP UEFI library was not initialized. |


## Retrieve Platform Information from BIOS


### Description

This API reads data from the [`SgxRegistrationPackageInfo`][packageinfo] UEFI variable.
Currently, BIOS uses this variable to provide software with the key blobs generated for each CPU package.
The platform owner needs to enable a BIOS configuration (`SGX Package Info In-band Access`) before it provides this information.
This data is not provided to the software by default.


### Syntax

```c++
MpResult mp_uefi_get_key_blobs(
    uint8_t *blobs,
    uint16_t blobs_size);
```


### Parameters

<!-- markdownlint-disable MD033 -->
| Parameter | Description |
| --- | --- |
| `blobs [Out]` | Holds the package info buffer to be populated. When this value is `NULL` but `blobs_size` is not `NULL`, the API returns the size of the data in the [`SgxRegistrationPackageInfo`][packageinfo] UEFI variable in `blobs_size`. |
| `blobs_size [In/Out]` | <ul><li>If `blobs` is not `NULL`, it contains the size in bytes of the buffer pointed to by `blobs`. Upon a successful execution, the API sets it to the number of bytes written to the `blobs` buffer. </li><li>If `blobs` is `NULL` or the inputted `blobs_size` is too small to contain the package info data (return value is `MP_USER_INSUFFICIENT_MEM`), the API sets it to the number of bytes required to contain the package info data. </li><li>Must not be `NULL`.</li></ul> |
<!-- markdownlint-enable MD033 -->

### Return Values

| Parameter | Description |
| --- | --- |
| `MP_SUCCESS` | Successfully read the contents of the [`SgxRegistrationPackageInfo`][packageinfo] UEFI variable if `blobs` is not `NULL` or `blobs_size` contains the required buffer size when `blobs` is `NULL`. |
| `MP_INVALID_PARAMETER` | The parameter `blobs_size` is `NULL`. |
| `MP_UEFI_INTERNAL_ERROR` | The request structure header in the [`SgxRegistrationPackageInfo`][packageinfo] UEFI variable has an invalid version or invalid size. |
| `MP_NO_PENDING_DATA` | [`SgxRegistrationPackageInfo`][packageinfo] UEFI variable is not provided by BIOS. |
| `MP_USER_INSUFFICIENT_MEM` | The size of the package info exceeds the size of the inputted `blobs`. |
| `MP_NOT_INITIALIZED` | The MP UEFI library was not initialized. |


## Retrieve Registration Status


### Description

This API reads the [`SgxRegistrationStatus`][status] UEFI variable and returns the registration, package info, and error code information.


### Syntax

```c++
MpResult mp_uefi_get_registration_status(
    MpRegistrationStatus *status);
```


### Parameters

| Parameter | Description |
| --- | --- |
| `status [Out]` | Holds the registration status. Must not be `NULL`. |


### Return Values


| Parameter | Description |
| --- | --- |
| `MP_SUCCESS` | Successfully read the [`SgxRegistrationStatus`][status] UEFI variable. |
| `MP_INVALID_PARAMETER` | The parameter `status` is `NULL`. |
| `MP_UEFI_INTERNAL_ERROR` | The request structure header in the [`SgxRegistrationStatus`][status] UEFI variable has an invalid version, invalid size or the variable was not found. |
| `MP_NOT_INITIALIZED` | The MP UEFI library was not initialized. |


## Set the Registration Status


### Description

This API allows to write to the [`SgxRegistrationStatus`][status] UEFI variable.
This variable can only be written under certain circumstances.
See the definition of [`SgxRegistrationStatus`][status] UEFI variable for more information.
You can use this API to modify the registration and package info complete bits.
It also allows to set an error code that any SW encountered during processing the data provided by BIOS or the registration service infrastructure.
This API overwrites the contents of the UEFI variable.


### Syntax

```c++
MpResult mp_uefi_set_registration_status(
    MpRegistrationStatus *status);
```


### Parameters

| Parameter | Description |
| --- | --- |
| `status [In]` | Holds the desired registration status. |


### Return Values

| Parameter | Description |
| --- | --- |
| `MP_SUCCESS` | Successfully wrote the inputted data to the [`SgxRegistrationStatus`][status] UEFI variable. |
| `MP_INVALID_PARAMETER` | The parameter `status` is `NULL`. |
| `MP_UEFI_INTERNAL_ERROR` | Encountered an error while writing the [`SgxRegistrationStatus`][status] UEFI variable. Check logs for more information. |
| `MP_NOT_INITIALIZED` | The MP UEFI library was not initialized. |


## Retrieve the Registration Service Configuration


### Description

This API reads the [`SgxRegistrationConfiguration`][configuration] UEFI variable.
This variable contains the information that the software uses for contacting the registration infrastructure services.


### Syntax

```c++
MpResult mp_uefi_get_registration_server_info(
    uint16_t flags,
    string *server_address,
    uint8_t *server_id,
    uint16_t *server_id_size);
```


### Parameters

<!-- markdownlint-disable MD033 -->
| Parameter | Description |
| --- | --- |
| `flags [Out]` | Holds the retrieved registration flags in the [`SgxRegistrationConfiguration`][configuration] UEFI variable. |
| `server_address [Out]` | Holds the registration server address. |
| `server_id [Out]` | Address of `server_id` buffer to be populated ([`SgxRegistrationServerID`][serverid]). |
| `server_id_size [In/Out]` | <ul><li>If both `server_id` and `server_id_size` are not `NULL`, it contains the size in bytes of the buffer pointed to by `server_id`. Upon a successful execution, the API sets it to the number of bytes written to the `server_id` buffer. If the inputted `server_id_size` not `NULL` but the number of bytes is too small to contain the server_id (return value is `MP_USER_INSUFFICIENT_MEM`), the API sets it to the number of bytes required to contain the server id data. </li><li>If `server_id` is `NULL` and `server_id_size` is not `NULL`, the API sets it to the number of bytes required to contain the server id data. </li><li> If `server_id_size` is `NULL`, no `server_id` information is returned. </li></ul> |
<!-- markdownlint-enable MD033 -->

### Return Values

| Parameter | Description |
| --- | --- |
| `MP_SUCCESS` | Successfully read the contents of the [`SgxRegistrationConfiguration`][configuration] UEFI variable. |
| `MP_INVALID_PARAMETER` | Either `flags` or `response_size` is `NULL`. The version of the [SgxRegistrationServerInfo][serverinfo] in the [`SgxRegistrationConfiguration`][configuration] UEFI variable is not supported. |
| `MP_USER_INSUFFICIENT_MEM` | The size of the server id read exceeds the size of the inputted `server_id`. |
| `MP_UEFI_INTERNAL_ERROR` | The request structure header in the [`SgxRegistrationConfiguration`][configuration] UEFI variable has an invalid version or the variable was not found. |
| `MP_NOT_INITIALIZED` | The MP UEFI library was not initialized. |


## Set the Registration Service Information


### Description

This API allows software to modify the registration authority service information in the [`SgxRegistrationConfiguration`][configuration] UEFI variable.
This includes the registration authority service URL and the [SgxRegistrationServerInfo][serverinfo].
This UEFI variable is only writable when SGX is disabled.
It first reads the UEFI variable then modifies the contents and writes it back.
The URL is optional and keeps the existing value, but the server_id is not optional.


### Syntax

```c++
MpResult mp_uefi_set_registration_server_info(
    const uint16_t flags,
    const string *server_address,
    const uint8_t *server_id,
    const uint16_t server_id_size);
```


### Parameters

| Parameter | Description |
| --- | --- |
| `flags [In]` | Holds the registration flags to write to the [`SgxRegistrationConfiguration`][configuration] UEFI variable. |
| `server_address [In]` | Holds the registration server address. |
| `server_id [In]` | Address of [`SgxRegistrationServerID`][serverid] buffer to be written. |
| `server_id_size [In]` | Size in bytes of the data stored in the `server_id` buffer. |


### Return Values

| Parameter | Description |
| --- | --- |
| `MP_SUCCESS` | Successfully wrote the inputted data to the [`SgxRegistrationConfiguration`][configuration] UEFI variable. |
| `MP_INVALID_PARAMETER` | The `server_id` parameter is `NULL`, the size of the URL string is too long, or the URL is an invalid value. |
| `MP_UEFI_INTERNAL_ERROR` | The request structure header in the [`SgxRegistrationConfiguration`][configuration] UEFI variable has an invalid version, or the variable was not found. |
| `MP_UNEXPECTED_ERROR` | The API encountered an unexpected error. Check logs for more information. |
| `MP_MEM_ERROR` | Insufficient memory |
| `MP_NOT_INITIALIZED` | The MP UEFI library was not initialized. |


## Exit the Multi-Package UEFI Library


### Description

Free any resources used by the MP UEFI Library.


### Syntax

```c++
MpResult mp_uefi_terminate();
```


### Parameters

| Parameter | Description |
| --- | --- |
| N\A | N\A |


### Return Values

| Parameter | Description |
| --- | --- |
| `MP_SUCCESS` | Successfully terminated the MP UEFI library. |
| `MP_REDUNDANT_OPERATION` | The MP UEFI library was not initialized or has been terminated. |

[uefivar]:  ../06/index.md#bios-multi-package-uefi-variables
[agentmpa]:  ../03/mp-reg-platform-sw-tools.md#multi-package-registration-agent-mpa
[pckidret]:  ../03/mp-reg-platform-sw-tools.md#pck-cert-id-retrieval-tool
[mngtool]:  ../03/mp-reg-platform-sw-tools.md#multi-package-management-tool
[request]:  ../06/sgx_registration_server_request.md#sgx-registration-server-request
[serverresponse]:  ../06/sgx_registration_server_response.md#sgx-registration-server-response
[addpackage]:  ../02/overview.md#add-package-replace-package
[packageinfo]:  ../06/sgx_registration_package_info.md#sgx-registration-package-info
[status]:  ../06/sgx_registration_status.md#sgx-registration-status
[configuration]:  ../06/sgx_registration_configuration.md
[serverid]:  ../06/sgx_registration_configuration.md#sgx-registration-server-id
[serverinfo]:  ../06/sgx_registration_configuration.md#sgx-registration-server-info
