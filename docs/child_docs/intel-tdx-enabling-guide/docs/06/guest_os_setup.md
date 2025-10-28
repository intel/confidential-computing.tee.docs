---
description: To use Intel® TDX, the guest operating system (OS) must be enabled. Multiple distributions are ready for Intel TDX as a guest OS.
keywords: enabling guide, Intel TDX, Trust Domain Extension, Confidential Computing, guest OS, operating system
---
<!---
Copyright (C) 2024 Intel Corporation
SPDX-License-Identifier: CC-BY-4.0
-->

# Guest OS Setup

On this page, we will introduce [how an Intel TDX-enabled guest image can be generated](#prepare-an-intel-tdx-enabled-guest-image) and [how a TD using this image can be started](#launch-a-trust-domain).
We assume that the [host OS setup](../05/host_os_setup.md) was done before.


## Prepare an Intel TDX-enabled Guest Image

To start an Intel TDX protected VM (i.e., a TD), it is necessary to prepare an Intel TDX-enabled guest image.
The *TDX Early Preview* distributions are the preferred way to prepare such an image.
The TDX Early Preview distributions are special distributions provided by partners for a convenient Intel TDX enablement experience.
Currently, the following Intel TDX-enabled guest OSes are supported by TDX Early Preview distributions:

- CentOS Stream 9
- Ubuntu 24.04
- openSUSE Leap 15.6 or SUSE Linux Enterprise Server 15-SP6

To prepare a guest image for these OSes, refer to the instructions provided by the individual TDX Early Preview distributions:

=== "CentOS Stream 9"

    Follow instruction from the ["Create VM Disk Image" section](https://sig.centos.org/virt/tdx/guest/#create-vm-disk-image) on the "Run a TD guest (VM)" page in the Cent OS guide.

=== "Ubuntu 24.04"

    Follow instruction from the ["Create TD Image" section](https://github.com/canonical/tdx/blob/3.3/README.md#5-create-td-image) in the Canonical guide.

    !!! warning
        Our guide assumes that the remote attestation packages provided by Canonical are not installed on the guest OS.
        To make sure to not install these packages:

        - Keep the default setting of `TDX_SETUP_ATTESTATION=0` during the execution of `create-td-image.sh`.
        - Do not manually execute `setup-attestation-guest.sh`, which is described in Section 9.3 of the Canonical guide.

=== "openSUSE Leap 15.6 or SUSE Linux Enterprise Server 15-SP6"

    Follow instruction from the ["Preparing the Guest Image" section](https://github.com/SUSE/tdx-demo/blob/1da7994045d7d1cf1192f5316e1a22c262376611/INSTALL-SLES-15-SP5.md#preparing-the-guest-image) in the SUSE guide.


## Launch a Trust Domain

To launch a TD, refer to the instructions provided by the individual TDX Early Preview distributions:

=== "CentOS Stream 9"

    Follow instruction from the ["Configure and boot VM" section](https://sig.centos.org/virt/tdx/guest/#configure-and-boot-vm) on the "Run a TD guest (VM)" page in the CentOS guide.

=== "Ubuntu 24.04"

    Follow instruction from the ["Boot TD" section](https://github.com/canonical/tdx/blob/3.3/README.md#6-boot-td) in the Canonical guide.

=== "openSUSE Leap 15.6 or SUSE Linux Enterprise Server 15-SP6"

    Follow instruction from the ["Launching a TDX guest" section](https://github.com/SUSE/tdx-demo/blob/1da7994045d7d1cf1192f5316e1a22c262376611/INSTALL-SLES-15-SP5.md#launching-a-tdx-guest) in the SUSE guide.
