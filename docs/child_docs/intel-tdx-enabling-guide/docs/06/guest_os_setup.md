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

To start an Intel TDX protected VM (i.e., a TD), you must create an Intel TDX-enabled guest OS image.
Use the following instructions for your distribution of choice:

1. Install the packages required to create and launch an Intel TDX-enabled cloud image:

    === "CentOS Stream 10"

        <!-- cspell:disable -->
        ``` { .bash }
        sudo dnf install -y guestfs-tools qemu-kvm libvirt
        ```
        <!-- cspell:enable -->

    === "openSUSE 16"

        <!-- cspell:disable -->
        ``` { .bash }
        sudo zypper install -y qemu qemu-tools guestfs-tools
        ```
        <!-- cspell:enable -->

    === "RHEL 10.2"

        <!-- cspell:disable -->
        ``` { .bash }
        sudo dnf install -y guestfs-tools qemu-kvm libvirt
        ```
        <!-- cspell:enable -->

    === "SLES 16.0 QU0"

        <!-- cspell:disable -->
        ``` { .bash }
        sudo zypper install -y qemu qemu-tools guestfs-tools
        ```
        <!-- cspell:enable -->

    === "Ubuntu 26.04"

        <!-- cspell:disable -->
        ``` { .bash }
        sudo apt install -y qemu-system-x86 cloud-image-utils libguestfs-tools \
            qemu-utils libvirt-daemon-system libvirt-clients ovmf ovmf-inteltdx
        ```
        <!-- cspell:enable -->


2. Add the current user to the appropriate groups:

    === "CentOS Stream 10"
        ``` { .bash }
        sudo usermod -aG qgsd $USER
        ```

        The `qgsd` group grants access to the QGS's Unix socket for TD Quote generation.
        Add only trusted users to this group.

    === "openSUSE 16"
        ``` { .bash }
        sudo usermod -aG kvm,qgsd $USER
        ```

        The `kvm` group grants access to `/dev/kvm` for QEMU hardware virtualization acceleration.
        The `qgsd` group grants access to the QGS's Unix socket for TD Quote generation.

    === "RHEL 10.2"
        ``` { .bash }
        sudo usermod -aG kvm,qgsd $USER
        ```

        The `kvm` group grants access to `/dev/kvm` for QEMU hardware virtualization acceleration.
        The `qgsd` group grants access to the QGS's Unix socket for TD Quote generation.
        Add only trusted users to these groups.

    === "SLES 16.0 QU0"
        ``` { .bash }
        sudo usermod -aG kvm,qgsd $USER
        ```

        The `kvm` group grants access to `/dev/kvm` for QEMU hardware virtualization acceleration.
        The `qgsd` group grants access to the QGS's Unix socket for TD Quote generation.

    === "Ubuntu 26.04"
        ``` { .bash }
        sudo usermod -aG kvm,libvirt,qgsd $USER
        ```

        The `kvm` group grants access to `/dev/kvm` for QEMU hardware virtualization acceleration.
        The `qgsd` group grants access to the QGS's Unix socket for TD Quote generation.
        The `libvirt` group grants access to manage the system libvirt daemon, which can configure VMs with host resources and should be treated as root-equivalent.
        Add only trusted users to these groups.

    For the above new group additions to take effect, log out and back in again.

3. Create an SSH key pair to allow SSH access to the TD after it is launched:

    === "CentOS Stream 10"
        ``` { .bash }
        ssh-keygen -t ed25519 -f ./guest_TD_root_id -N "" -q
        ```

    === "openSUSE 16"
        ``` { .bash }
        ssh-keygen -t ed25519 -f ./guest_TD_root_id -N "" -q
        ```

    === "RHEL 10.2"
        ``` { .bash }
        ssh-keygen -t ed25519 -f ./guest_TD_root_id -N "" -q
        ```

    === "SLES 16.0 QU0"
        ``` { .bash }
        ssh-keygen -t ed25519 -f ./guest_TD_root_id -N "" -q
        ```

    === "Ubuntu 26.04"
        ``` { .bash }
        ssh-keygen -t ed25519 -f ./guest_TD_root_id -N "" -q
        ```


4. Download an Intel TDX-enabled cloud image and prepare it for use as a TD:

    === "CentOS Stream 10"
        ``` { .bash }
        wget https://cloud.centos.org/centos/10-stream/x86_64/images/CentOS-Stream-GenericCloud-x86_64-10-latest.x86_64.qcow2 \
           -O centos.qcow2
        virt-customize -a \
            centos.qcow2 \
            --root-password password:root \
            --uninstall cloud-init \
            --ssh-inject "root:file:./guest_TD_root_id.pub"
        qemu-img amend -o compat=v3 centos.qcow2
        ```

    === "openSUSE 16"

        <!-- cspell:disable -->
        ``` { .bash }
        wget https://download.opensuse.org/distribution/leap/16.0/appliances/Leap-16.0-Minimal-VM.x86_64-kvm-and-xen.qcow2 -O opensuse16.qcow2
        virt-customize -a \
            opensuse16.qcow2 \
            --root-password password:root \
            --uninstall jeos-firstboot \
            --ssh-inject "root:file:./guest_TD_root_id.pub"
        ```
        <!-- cspell:enable -->

    === "RHEL 10.2"
        To create a RHEL guest image, manually create a cloud ISO image.
        This guide uses a CentOS Stream 10 prebuilt cloud image:
        ``` { .bash }
        wget https://cloud.centos.org/centos/10-stream/x86_64/images/CentOS-Stream-GenericCloud-x86_64-10-latest.x86_64.qcow2 \
           -O centos.qcow2
        virt-customize -a \
            centos.qcow2 \
            --root-password password:root \
            --uninstall cloud-init \
            --ssh-inject "root:file:./guest_TD_root_id.pub"
        qemu-img amend -o compat=v3 centos.qcow2
        ```

    === "SLES 16.0 QU0"

        To use a SLES guest image, go to the SUSE website and download a cloud image.
        This guide uses an openSUSE 16 cloud image:

        <!-- cspell:disable -->
        ``` { .bash }
        wget https://download.opensuse.org/distribution/leap/16.0/appliances/Leap-16.0-Minimal-VM.x86_64-kvm-and-xen.qcow2 -O sles16.qcow2
        virt-customize -a \
            sles16.qcow2 \
            --root-password password:root \
            --uninstall jeos-firstboot \
            --ssh-inject "root:file:./guest_TD_root_id.pub"
        ```
        <!-- cspell:enable -->

    === "Ubuntu 26.04"

        <!-- cspell:disable -->
        ``` { .bash }
        wget https://cloud-images.ubuntu.com/releases/resolute/release/ubuntu-26.04-server-cloudimg-amd64.img -O ubuntu.img
        sudo qemu-img resize ubuntu.img +2G
        sudo virt-customize -a ubuntu.img \
            --ssh-inject "root:file:./guest_TD_root_id.pub" \
            --run-command 'growpart /dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_hd0 1' \
            --run-command 'resize2fs /dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_hd0-part1' \
            --run-command 'systemctl mask pollinate.service' \
            --run-command 'cloud-init clean'

        # Create user-data and cloud-init image.
        cat > user-data.yaml << 'EOF'
        #cloud-config
        disable_root: false
        network:
          version: 2
          ethernets:
            all-en:
              match:
                name: "en*"
              dhcp4: true
              dhcp-identifier: mac
        write_files:
          - path: /etc/ssh/sshd_config.d/99-td-enablement.conf
            content: |
              PermitRootLogin yes
        EOF

        # Use a unique instance-id so cloud-init always runs on first boot
        cat > meta-data.yaml << EOF
        instance-id: iid-$(uuidgen)
        local-hostname: td-guest
        EOF
        cloud-localds user-data.img user-data.yaml meta-data.yaml
        ```
        <!-- cspell:enable -->


## Launch a Trust Domain

To launch a TD, use the following instructions for your distribution of choice:

=== "CentOS Stream 10"

    <!-- cspell:disable -->
    ``` { .bash }
    (
    # Check that the user is part of the `qgsd` group.
    if ! groups | grep -qw "qgsd"; then
        echo "User '$USER' is NOT in the 'qgsd' group.  Attestation will fail to work in the TD."
        exit 1
    fi

    # Find an unused IPv4 TCP port for SSH into the TD.
    while :; do
        SSH_PORT=$(shuf -i 49152-65535 -n 1)

        # List listening IPv4 TCP sockets using the selected port.
        # If no socket is listed, the port is available for QEMU to use.
        ss -H -4 -ltn "sport = :$SSH_PORT" | grep -q . || break
    done

    /usr/libexec/qemu-kvm \
        -accel kvm \
        -smp 32 \
        -m 16G \
        -cpu host,-kvm-asyncpf-int \
        -object '{"qom-type":"tdx-guest","id":"tdx","quote-generation-socket":{"type": "unix", "path":"/var/run/tdx-qgs/qgs.socket"}}' \
        -object memory-backend-ram,id=mem0,size=16G \
        -machine q35,kernel_irqchip=split,confidential-guest-support=tdx,memory-backend=mem0 \
        -bios /usr/share/edk2/ovmf/OVMF.inteltdx.fd \
        -nographic \
        -nodefaults \
        -vga none \
        -drive file=${HOME}/centos.qcow2,if=none,id=virtio-disk0 \
        -device virtio-blk-pci,drive=virtio-disk0 \
        -device virtio-net-pci,netdev=nic0_td \
        -netdev user,id=nic0_td,hostfwd=tcp::$SSH_PORT-:22 \
        -monitor unix:/tmp/td-monitor.sock,server,nowait \
        -daemonize && \
        echo "Connect to TD via SSH: ssh -i ./guest_TD_root_id -p $SSH_PORT root@localhost"
    )
    ```
    <!-- cspell:enable -->

=== "openSUSE 16"

    <!-- cspell:disable -->
    ``` { .bash }
    (
    # Check that the user is part of the `qgsd` group.
    if ! groups | grep -qw "qgsd"; then
        echo "User '$USER' is NOT in the 'qgsd' group.  Attestation will fail to work in the TD."
        exit 1
    fi

    # Find an unused IPv4 TCP port for SSH into the TD.
    while :; do
        SSH_PORT=$(shuf -i 49152-65535 -n 1)

        # List listening IPv4 TCP sockets using the selected port.
        # If no socket is listed, the port is available for QEMU to use.
        ss -H -4 -ltn "sport = :$SSH_PORT" | grep -q . || break
    done

    qemu-kvm \
        -accel kvm \
        -smp 32 \
        -m 16G \
        -cpu host \
        -object '{"qom-type":"tdx-guest","id":"tdx","quote-generation-socket":{"type": "unix", "path":"/var/run/tdx-qgs/qgs.socket"}}' \
        -object memory-backend-ram,id=mem0,size=16G \
        -machine q35,kernel_irqchip=split,confidential-guest-support=tdx,memory-backend=mem0 \
        -bios /usr/share/qemu/ovmf-x86_64-tdx.bin \
        -nographic \
        -nodefaults \
        -vga none \
        -drive file=${HOME}/opensuse16.qcow2,if=none,id=virtio-disk0 \
        -device virtio-blk-pci,drive=virtio-disk0 \
        -device virtio-net-pci,netdev=nic0_td \
        -netdev user,id=nic0_td,hostfwd=tcp::$SSH_PORT-:22 \
        -monitor unix:/tmp/td-monitor.sock,server,nowait \
        -daemonize

    echo "Connect to TD via SSH: ssh -i ./guest_TD_root_id -p $SSH_PORT root@localhost"
    )
    ```
    <!-- cspell:enable -->

=== "RHEL 10.2"

    <!-- cspell:disable -->
    ``` { .bash }
    (
    # Check that the user is part of the `qgsd` group.
    if ! groups | grep -qw "qgsd"; then
        echo "User '$USER' is NOT in the 'qgsd' group.  Attestation will fail to work in the TD."
        exit 1
    fi

    # Find an unused IPv4 TCP port for SSH into the TD.
    while :; do
        SSH_PORT=$(shuf -i 49152-65535 -n 1)

        # List listening IPv4 TCP sockets using the selected port.
        # If no socket is listed, the port is available for QEMU to use.
        ss -H -4 -ltn "sport = :$SSH_PORT" | grep -q . || break
    done

    /usr/libexec/qemu-kvm \
        -accel kvm \
        -smp 32 \
        -m 16G \
        -cpu host,-kvm-asyncpf-int \
        -object '{"qom-type":"tdx-guest","id":"tdx","quote-generation-socket":{"type": "unix", "path":"/var/run/tdx-qgs/qgs.socket"}}' \
        -object memory-backend-ram,id=mem0,size=16G \
        -machine q35,kernel_irqchip=split,confidential-guest-support=tdx,memory-backend=mem0 \
        -bios /usr/share/edk2/ovmf/OVMF.inteltdx.fd \
        -nographic \
        -nodefaults \
        -vga none \
        -drive file=${HOME}/centos.qcow2,if=none,id=virtio-disk0 \
        -device virtio-blk-pci,drive=virtio-disk0 \
        -device virtio-net-pci,netdev=nic0_td \
        -netdev user,id=nic0_td,hostfwd=tcp::$SSH_PORT-:22 \
        -monitor unix:/tmp/td-monitor.sock,server,nowait \
        -daemonize && \
        echo "Connect to TD via SSH: ssh -i ./guest_TD_root_id -p $SSH_PORT root@localhost"
    )
    ```
    <!-- cspell:enable -->

=== "SLES 16.0 QU0"

    <!-- cspell:disable -->
    ``` { .bash }
    (
    # Check that the user is part of the `qgsd` group.
    if ! groups | grep -qw "qgsd"; then
        echo "User '$USER' is NOT in the 'qgsd' group.  Attestation will fail to work in the TD."
        exit 1
    fi

    # Find an unused IPv4 TCP port for SSH into the TD.
    while :; do
        SSH_PORT=$(shuf -i 49152-65535 -n 1)

        # List listening IPv4 TCP sockets using the selected port.
        # If no socket is listed, the port is available for QEMU to use.
        ss -H -4 -ltn "sport = :$SSH_PORT" | grep -q . || break
    done

    qemu-kvm \
        -accel kvm \
        -smp 32 \
        -m 16G \
        -cpu host \
        -object '{"qom-type":"tdx-guest","id":"tdx","quote-generation-socket":{"type": "unix", "path":"/var/run/tdx-qgs/qgs.socket"}}' \
        -object memory-backend-ram,id=mem0,size=16G \
        -machine q35,kernel_irqchip=split,confidential-guest-support=tdx,memory-backend=mem0 \
        -bios /usr/share/qemu/ovmf-x86_64-tdx.bin \
        -nographic \
        -nodefaults \
        -vga none \
        -drive file=${HOME}/sles16.qcow2,if=none,id=virtio-disk0 \
        -device virtio-blk-pci,drive=virtio-disk0 \
        -device virtio-net-pci,netdev=nic0_td \
        -netdev user,id=nic0_td,hostfwd=tcp::$SSH_PORT-:22 \
        -monitor unix:/tmp/td-monitor.sock,server,nowait \
        -daemonize

    echo "Connect to TD via SSH: ssh -i ./guest_TD_root_id -p $SSH_PORT root@localhost"
    )
    ```
    <!-- cspell:enable -->

=== "Ubuntu 26.04"

    <!-- cspell:disable -->
    ``` { .bash }
    (
    # Check that the user is part of the `qgsd` group.
    if ! groups | grep -qw "qgsd"; then
        echo "User '$USER' is NOT in the 'qgsd' group.  Attestation will fail to work in the TD."
        exit 1
    fi

    # Find an unused IPv4 TCP port for SSH into the TD.
    while :; do
        SSH_PORT=$(shuf -i 49152-65535 -n 1)

        # List listening IPv4 TCP sockets using the selected port.
        # If no socket is listed, the port is available for QEMU to use.
        ss -H -4 -ltn "sport = :$SSH_PORT" | grep -q . || break
    done

    qemu-system-x86_64 \
        -accel kvm \
        -smp 32 \
        -m 16G \
        -cpu host \
        -object '{"qom-type":"tdx-guest","id":"tdx","quote-generation-socket":{"type": "unix", "path":"/var/run/tdx-qgs/qgs.socket"}}' \
        -object memory-backend-ram,id=mem0,size=16G \
        -machine q35,kernel_irqchip=split,confidential-guest-support=tdx,memory-backend=mem0 \
        -bios /usr/share/ovmf/OVMF.inteltdx.ms.fd \
        -nographic \
        -nodefaults \
        -vga none \
        -drive file=ubuntu.img,if=none,id=virtio-disk0 \
        -device virtio-blk-pci,drive=virtio-disk0 \
        -drive file=user-data.img,if=none,id=cloud-init,format=raw \
        -device virtio-blk-pci,drive=cloud-init \
        -device virtio-net-pci,netdev=nic0_td \
        -netdev user,id=nic0_td,hostfwd=tcp::$SSH_PORT-:22 \
        -daemonize && \
        echo "Connect to TD via SSH: ssh -i ./guest_TD_root_id -p $SSH_PORT root@localhost"
    )
    ```
    <!-- cspell:enable -->

    Once the TD has started, you can ssh into the TD and check that TDX is detected:
    ``` { .bash }
    dmesg | grep -i tdx
    ```

    The output should look similar to the following:
    <!-- cspell:disable -->
    ``` { .bash }
    [    0.000000] tdx: Guest detected
    [    0.000000] tdx: Attributes: SEPT_VE_DISABLE
    [    0.000000] tdx: TD_CTLS: PENDING_VE_DISABLE ENUM_TOPOLOGY VIRT_CPUID2 REDUCE_VE
    [    7.934806] process: using TDX aware idle routine
    [    7.934806] Memory Encryption Features active: Intel TDX
    [    7.934806] smpboot: CPU0: Intel TDX (family: 0x6, model: 0xad, stepping: 0x1)
    [   10.874294] systemd[1]: Detected confidential virtualization tdx.
    [   14.004275] systemd[1]: Detected confidential virtualization tdx.
    ```
    <!-- cspell:enable -->
