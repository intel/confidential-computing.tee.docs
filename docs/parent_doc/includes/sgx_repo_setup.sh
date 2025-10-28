# --8<-- [start:cent-os-stream-9]
sudo dnf install -y wget yum-utils
sudo mkdir /opt/intel
cd /opt/intel
sudo wget https://download.01.org/intel-sgx/latest/dcap-latest/linux/distro/centos-stream9/sgx_rpm_local_repo.tgz
sudo tar xvf sgx_rpm_local_repo.tgz
sudo yum-config-manager --add-repo file:///opt/intel/sgx_rpm_local_repo
sudo wget https://download.01.org/intel-sgx/sgx_repo/ubuntu/intel-sgx-deb.key -O /opt/intel/intel-sgx.key
sudo yum-config-manager --save --setopt=*sgx_rpm_local_repo.gpgkey=file:///opt/intel/intel-sgx.key
# --8<-- [end:cent-os-stream-9]

# --8<-- [start:rhel_9_4_kvm]
sudo dnf install -y yum-utils wget
sudo mkdir /opt/intel
cd /opt/intel
sudo wget https://download.01.org/intel-sgx/latest/dcap-latest/linux/distro/rhel9.2-server/sgx_rpm_local_repo.tgz
sudo tar xvf sgx_rpm_local_repo.tgz
sudo yum-config-manager --add-repo file:///opt/intel/sgx_rpm_local_repo
sudo wget https://download.01.org/intel-sgx/sgx_repo/ubuntu/intel-sgx-deb.key -O /opt/intel/intel-sgx.key
sudo yum-config-manager --save --setopt=*sgx_rpm_local_repo.gpgkey=file:///opt/intel/intel-sgx.key
# --8<-- [end:rhel_9_4_kvm]

# --8<-- [start:ubuntu_24_04]
echo 'deb [signed-by=/etc/apt/keyrings/intel-sgx-keyring.asc arch=amd64] https://download.01.org/intel-sgx/sgx_repo/ubuntu noble main' | sudo tee /etc/apt/sources.list.d/intel-sgx.list
wget https://download.01.org/intel-sgx/sgx_repo/ubuntu/intel-sgx-deb.key
sudo mkdir -p /etc/apt/keyrings
cat intel-sgx-deb.key | sudo tee /etc/apt/keyrings/intel-sgx-keyring.asc > /dev/null
sudo apt-get update
# --8<-- [end:ubuntu_24_04]

# --8<-- [start:ubuntu_24_04_OFFLINE]
sudo mkdir -p /opt/intel /etc/apt/keyrings
cd /opt/intel
wget https://download.01.org/intel-sgx/sgx_repo/ubuntu/intel-sgx-deb.key
cat intel-sgx-deb.key | sudo tee /etc/apt/keyrings/intel-sgx-keyring.asc > /dev/null
sudo wget https://download.01.org/intel-sgx/latest/dcap-latest/linux/distro/ubuntu24.04-server/sgx_debian_local_repo.tgz
sudo tar xvf sgx_debian_local_repo.tgz
echo 'deb [signed-by=/etc/apt/keyrings/intel-sgx-keyring.asc arch=amd64] file:///opt/intel/sgx_debian_local_repo noble main' | sudo tee /etc/apt/sources.list.d/intel-sgx-local.list
sudo apt-get update
# --8<-- [end:ubuntu_24_04_OFFLINE]

# --8<-- [start:opensuse_leap_15_6]
sudo mkdir /opt/intel
cd /opt/intel
sudo rpm --import https://download.01.org/intel-sgx/sgx_repo/ubuntu/intel-sgx-deb.key
sudo wget https://download.01.org/intel-sgx/latest/dcap-latest/linux/distro/suse15.6-server/sgx_rpm_local_repo.tgz
sudo tar xvf sgx_rpm_local_repo.tgz
sudo zypper addrepo /opt/intel/sgx_rpm_local_repo sgx_rpm_local_repo
# --8<-- [end:opensuse_leap_15_6]
