---
description: Explanation of cache fill modes in the Intel SGX/TDX Provisioning Certificate Caching Service (PCCS) and their operational impact.
keywords: PCCS, DCAP, cache fill mode, caching service, Confidential Computing, SGX, TDX
---
<!---
Copyright (C) 2025 Intel Corporation
SPDX-License-Identifier: CC-BY-4.0
-->

# Cache Fill Modes

When Intel SGX-based attestation should be used on any server, Intel® SGX attestation collateral is required for quote generation and quote verification.
The attestation collateral can be retrieved from PCS and it should be cached in a collateral caching service, e.g., PCCS.

Currently, the PCCS supports the three cache fill modes described in the next sub-sections.


## `LAZY` Cache Fill Mode

In this cache fill mode, when the PCCS gets a collateral retrieval request at runtime (for, e.g., [PCK Certificate](../03/api_specification_for_pccs.md#get-pck-certificate) or [TCB Info](../03/api_specification_for_pccs.md#get-tcb-info)), it looks for the collateral in its database to see if it is already in the cache.

If the collateral is present in the cache and it is still valid it will be returned.
If the collateral is not present in the cache or it is invalid, PCCS contacts the PCS to retrieve the collateral.

!!! note

    This mode expects continuos Internet connection to request attestation collateral from PCS whenever required.


## `REQ` Cache Fill Mode

In this cache fill mode, the PCCS creates a platform database entry when the PCCS receives a platform registration requests during platform deployment/provisioning using the [Post Platforms IDs](../03/api_specification_for_pccs.md#post-platforms-ids) API.
The [PCK Cert ID Retrieval Tool](https://github.com/intel/SGXDataCenterAttestationPrimitives/tree/main/tools/PCKRetrievalTool) can be used to send platform registration information to the PCCS.

Even if the collateral is present in the cache, nothing will be returned to the caller.
If the collateral is not present in the cache, PCCS retrieves the collateral from PCS.
PCCS saves the retrieved collateral in cache database for use during runtime.

!!! note

    - During deployment/provisioning, this mode requires the PCCS to have an Internet connection.
    - During runtime, the PCCS uses cache data only and does not contact PCS.


## `OFFLINE` Cache Fill Mode

In this cache fill mode, the PCCS does not have access to the PCS on the Internet.
Instead, the PCCS has to be filled manually.

At first, platform registration information must be retrieved from the target platforms and must be sent to PCCS using the [Post Platforms IDs](../03/api_specification_for_pccs.md#post-platforms-ids) API.
The [PCK Cert ID Retrieval Tool](https://github.com/intel/SGXDataCenterAttestationPrimitives/tree/main/tools/PCKRetrievalTool) can be used for these tasks.

Later, the registration information can be collected from the PCCS using the [Get Platforms IDs](../03/api_specification_for_pccs.md#get-platform-ids).
The [`get` operation](../07/pccs_admin_tool.md#get) of the [PCCS Admin Tool](../07/pccs_admin_tool.md) can be used for this request.
The tool saves the result to a JSON file.

If the platform that created the JSON file does not have Internet, the JSON file must be transferred out-of-band to a platform with Internet access.
On a platform with Internet access, the Web API of PCS must used to retrieve the collateral.
The [PCS Client Tool](../09/pcs_client_tool.md) can be used for the request and it expects the JSON file from the PCCS Admin Tool as input.

The collateral has to be transferred out-of-band to a platform with PCCS access.
On this machine, the collateral has to be pushed to the PCCS using the [Put Platform Collateral to Cache](../03/api_specification_for_pccs.md#put-platform-collateral-to-cache) API.
The [`put` operation](../07/pccs_admin_tool.md#put) of the PCCS Admin Tool can be used for this operation.

!!! note

    This mode is especially suitable in an *air-gap* environment because it does not require any Internet connectivity from the PCCS.
