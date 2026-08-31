# --8<-- [start:cent-os-stream-9]
sudo dnf install -y wget yum-utils
sudo mkdir -p /opt/intel
wget https://download.01.org/intel-sgx/latest/dcap-latest/linux/distro/centos-stream9/sgx_rpm_local_repo.tgz
sudo tar -xvzf sgx_rpm_local_repo.tgz -C /opt/intel
sudo yum-config-manager --add-repo file:///opt/intel/sgx_rpm_local_repo
sudo wget https://download.01.org/intel-sgx/sgx_repo/ubuntu/intel-sgx-deb.key -O /opt/intel/intel-sgx.key
sudo yum-config-manager --save --setopt=*sgx_rpm_local_repo.gpgkey=file:///opt/intel/intel-sgx.key
# Set the priority of the local repo to 1 (highest) to avoid conflicts with other repos
sudo yum-config-manager --save --setopt=*sgx_rpm_local_repo.priority=1
# --8<-- [end:cent-os-stream-9]

# --8<-- [start:cent-os-stream-10]
sudo dnf install -y yum-utils wget tar
sudo mkdir -p /opt/intel
wget https://download.01.org/intel-sgx/latest/dcap-latest/linux/distro/centos-stream10/sgx_rpm_local_repo.tgz
sudo tar -xvzf sgx_rpm_local_repo.tgz -C /opt/intel
sudo yum-config-manager --add-repo file:///opt/intel/sgx_rpm_local_repo
sudo wget https://download.01.org/intel-sgx/sgx_repo/ubuntu/intel-sgx-deb.key -O /opt/intel/intel-sgx.key
sudo yum-config-manager --save --setopt=*sgx_rpm_local_repo.gpgkey=file:///opt/intel/intel-sgx.key
# Set the priority of the local repo to 1 (highest) to avoid conflicts with other repos
sudo yum-config-manager --save --setopt=*sgx_rpm_local_repo.priority=1
# --8<-- [end:cent-os-stream-10]

# --8<-- [start:rhel_9_4_kvm]
sudo dnf install -y yum-utils wget
sudo mkdir -p /opt/intel
wget https://download.01.org/intel-sgx/latest/dcap-latest/linux/distro/rhel9.2-server/sgx_rpm_local_repo.tgz
sudo tar -xvzf sgx_rpm_local_repo.tgz -C /opt/intel
sudo yum-config-manager --add-repo file:///opt/intel/sgx_rpm_local_repo
sudo wget https://download.01.org/intel-sgx/sgx_repo/ubuntu/intel-sgx-deb.key -O /opt/intel/intel-sgx.key
sudo yum-config-manager --save --setopt=*sgx_rpm_local_repo.gpgkey=file:///opt/intel/intel-sgx.key
# Set the priority of the local repo to 1 (highest) to avoid conflicts with other repos
sudo yum-config-manager --save --setopt=*sgx_rpm_local_repo.priority=1
# --8<-- [end:rhel_9_4_kvm]

# --8<-- [start:rhel_10_2]
sudo dnf install -y yum-utils wget tar
sudo mkdir -p /opt/intel
wget https://download.01.org/intel-sgx/latest/dcap-latest/linux/distro/rhel10.2-server/sgx_rpm_local_repo.tgz
sudo tar -xvzf sgx_rpm_local_repo.tgz -C /opt/intel
sudo yum-config-manager --add-repo file:///opt/intel/sgx_rpm_local_repo
sudo wget https://download.01.org/intel-sgx/sgx_repo/ubuntu/intel-sgx-deb.key -O /opt/intel/intel-sgx.key
sudo yum-config-manager --save --setopt=*sgx_rpm_local_repo.gpgkey=file:///opt/intel/intel-sgx.key
# Set the priority of the local repo to 1 (highest) to avoid conflicts with other repos
sudo yum-config-manager --save --setopt=*sgx_rpm_local_repo.priority=1
# --8<-- [end:rhel_10_2]

# --8<-- [start:ubuntu_26_04]
echo 'deb [signed-by=/etc/apt/keyrings/intel-sgx-keyring.asc arch=amd64]' \
  'https://download.01.org/intel-sgx/sgx_repo/ubuntu resolute main' \
  | sudo tee /etc/apt/sources.list.d/intel-sgx.list
curl -fsSLO https://download.01.org/intel-sgx/sgx_repo/ubuntu/intel-sgx-deb.key
sudo mkdir -p /etc/apt/keyrings
sudo mv intel-sgx-deb.key /etc/apt/keyrings/intel-sgx-keyring.asc
sudo apt-get update
# --8<-- [end:ubuntu_26_04]

# --8<-- [start:ubuntu_26_04_OFFLINE]
echo 'deb [signed-by=/etc/apt/keyrings/intel-sgx-keyring.asc arch=amd64]' \
  'file:///opt/intel/sgx_debian_local_repo resolute main' \
  | sudo tee /etc/apt/sources.list.d/intel-sgx-local.list
curl -fsSLO https://download.01.org/intel-sgx/sgx_repo/ubuntu/intel-sgx-deb.key
sudo mkdir -p /etc/apt/keyrings /opt/intel
sudo mv intel-sgx-deb.key /etc/apt/keyrings/intel-sgx-keyring.asc
curl -fsSLO https://download.01.org/intel-sgx/latest/dcap-latest/linux/distro/ubuntu26.04-server/sgx_debian_local_repo.tgz
sudo tar -xvzf sgx_debian_local_repo.tgz -C /opt/intel
sudo apt-get update
# --8<-- [end:ubuntu_26_04_OFFLINE]

# --8<-- [start:opensuse_16]
sudo zypper install -y wget tar
sudo mkdir -p /opt/intel
sudo rpm --import https://download.01.org/intel-sgx/sgx_repo/ubuntu/intel-sgx-deb.key
wget https://download.01.org/intel-sgx/sgx-dcap/1.27.1/linux/distro/suse16-server/sgx_rpm_local_repo.tgz
sudo tar -xvzf sgx_rpm_local_repo.tgz -C /opt/intel
sudo zypper addrepo /opt/intel/sgx_rpm_local_repo sgx_rpm_local_repo
# --8<-- [end:opensuse_16]

# --8<-- [start:opensuse_16_no_sudo]
zypper install -y wget tar
mkdir -p /opt/intel
rpm --import https://download.01.org/intel-sgx/sgx_repo/ubuntu/intel-sgx-deb.key
wget https://download.01.org/intel-sgx/sgx-dcap/1.27.1/linux/distro/suse16-server/sgx_rpm_local_repo.tgz
tar -xvzf sgx_rpm_local_repo.tgz -C /opt/intel
zypper addrepo /opt/intel/sgx_rpm_local_repo sgx_rpm_local_repo
# --8<-- [end:opensuse_16_no_sudo]

# --8<-- [start:sles_16]
sudo zypper install -y wget tar
sudo mkdir -p /opt/intel
sudo rpm --import https://download.01.org/intel-sgx/sgx_repo/ubuntu/intel-sgx-deb.key
wget https://download.01.org/intel-sgx/sgx-dcap/1.27.1/linux/distro/suse16-server/sgx_rpm_local_repo.tgz
sudo tar -xvzf sgx_rpm_local_repo.tgz -C /opt/intel
sudo zypper addrepo /opt/intel/sgx_rpm_local_repo sgx_rpm_local_repo
# --8<-- [end:sles_16]

# --8<-- [start:sles_16_no_sudo]
zypper install -y wget tar
mkdir -p /opt/intel
rpm --import https://download.01.org/intel-sgx/sgx_repo/ubuntu/intel-sgx-deb.key
wget https://download.01.org/intel-sgx/sgx-dcap/1.27.1/linux/distro/suse16-server/sgx_rpm_local_repo.tgz
tar -xvzf sgx_rpm_local_repo.tgz -C /opt/intel
zypper addrepo /opt/intel/sgx_rpm_local_repo sgx_rpm_local_repo
# --8<-- [end:sles_16_no_sudo]
