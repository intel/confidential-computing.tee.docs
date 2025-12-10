---
description: PCCS Admin Tool usage guide for managing the Intel SGX/TDX Provisioning Certificate Caching Service (PCCS).
keywords: PCCS, DCAP, administration, admin tool, PCCS Admin Tool, caching service, Confidential Computing, SGX, TDX
---
<!---
Copyright (C) 2025 Intel Corporation
SPDX-License-Identifier: CC-BY-4.0
-->

# PCCS Admin Tool

The PCCS Admin Tool is a Python\* script that contains a set of commands to allow an administrator to manage the data cached inside PCCS.
The tool's primary function is to help administer a PCCS setup in an environment without a direct connection to the Internet (i.e., PCCS configured in `OFFLINE` cache fill mode).
The tool can also be used to trigger PCCS to refresh the collateral before they expire as well as refresh the data for a TCB Recovery.

!!! Note
    The PCCS Admin Tool input/output file formats are compatible with the [PCS Client Tool](../09/pcs_client_tool.md) so that both tools can be used together in order to complete an end-to-end platform registration flow in an air-gapped environment.
    Refer to [Platform Registration](../08/cache_management_flows.md#platform-registration) for a flow description.


## Supported Operations

The following operations are supported by the tool:


### `get`

Retrieves queued platform registration from the PCCS using the [Get Platform IDs](../03/api_specification_for_pccs.md#get-platform-ids) API.


### `put`

Imports the quote generation collateral (i.e. PCK Certificates) and quote verification collateral into the PCCS using the [Put Platform Collateral to Cache](../03/api_specification_for_pccs.md#put-platform-collateral-to-cache) API.


### `refresh`

Request PCCS to refresh certificates and collateral in cache database using the [Refresh through HTTP Request](../03/api_specification_for_pccs.md#refresh-through-http-request) API of the PCCS.
This operation only supported in `LAZY` or `REQ` cache fill mode – not in `OFFLINE` cache fill mode.


## Download information

The PCCS Admin Tool can be found in the [PCCS repository](https://github.com/intel/confidential-computing.tee.dcap.pccs/tree/main/PccsAdminTool) on GitHub\*.
The tool's command-line syntax and latest usage information are available in the [README](https://github.com/intel/confidential-computing.tee.dcap.pccs/tree/main/PccsAdminTool/README.txt) located in the same directory.
