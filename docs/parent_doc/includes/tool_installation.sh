# --8<-- [start:pcs_client_tool-package-cent_os_stream_9]
sudo dnf install -y intel-tee-pcs-client-tool
# --8<-- [end:pcs_client_tool-package-cent_os_stream_9]

# --8<-- [start:pcs_client_tool-package-cent-os-stream-10]
sudo dnf install -y intel-tee-pcs-client-tool
# --8<-- [end:pcs_client_tool-package-cent-os-stream-10]

# --8<-- [start:pcs_client_tool-package-rhel_10_2]
sudo dnf install -y intel-tee-pcs-client-tool
# --8<-- [end:pcs_client_tool-package-rhel_10_2]

# --8<-- [start:pcs_client_tool-package-ubuntu_26_04]
sudo apt install -y intel-tee-pcs-client-tool
# --8<-- [end:pcs_client_tool-package-ubuntu_26_04]

# --8<-- [start:pcs_client_tool-package-opensuse_16]
sudo zypper install -y intel-tee-pcs-client-tool
# --8<-- [end:pcs_client_tool-package-opensuse_16]

# --8<-- [start:pcs_client_tool-package-sles_16]
sudo zypper install -y intel-tee-pcs-client-tool
# --8<-- [end:pcs_client_tool-package-sles_16]

# --8<-- [start:pcs_client_tool-source-cent-os-stream-10]
sudo dnf install -y git python3
git clone https://github.com/intel/confidential-computing.tee.dcap.git
cd confidential-computing.tee.dcap/tools/PcsClientTool
python3 -m venv venv
source ./venv/bin/activate
pip install -r requirements.txt
# --8<-- [end:pcs_client_tool-source-cent-os-stream-10]

# --8<-- [start:pcs_client_tool-source-cent_os_stream_9]
sudo dnf install -y git python3
git clone https://github.com/intel/confidential-computing.tee.dcap.git
cd confidential-computing.tee.dcap/tools/PcsClientTool
python3 -m venv venv
source ./venv/bin/activate
pip install -r requirements.txt
# --8<-- [end:pcs_client_tool-source-cent_os_stream_9]

# --8<-- [start:pcs_client_tool-source-rhel_10_2]
sudo dnf install -y git python3
git clone https://github.com/intel/confidential-computing.tee.dcap.git
cd confidential-computing.tee.dcap/tools/PcsClientTool
python3 -m venv venv
source ./venv/bin/activate
pip install -r requirements.txt
# --8<-- [end:pcs_client_tool-source-rhel_10_2]

# --8<-- [start:pcs_client_tool-source-ubuntu_26_04]
sudo apt install -y python3 python3-venv
git clone https://github.com/intel/confidential-computing.tee.dcap.git
cd confidential-computing.tee.dcap/tools/PcsClientTool
python3 -m venv venv
source ./venv/bin/activate
pip install -r requirements.txt
# --8<-- [end:pcs_client_tool-source-ubuntu_26_04]

# --8<-- [start:pcs_client_tool-source-opensuse_16]
sudo zypper install -y git python3 python3-pip
git clone https://github.com/intel/confidential-computing.tee.dcap.git
cd confidential-computing.tee.dcap/tools/PcsClientTool
python3 -m venv venv
source ./venv/bin/activate
pip install -r requirements.txt
# --8<-- [end:pcs_client_tool-source-opensuse_16]

# --8<-- [start:pcs_client_tool-source-sles_16]
sudo zypper install -y git python3 python3-pip
git clone https://github.com/intel/confidential-computing.tee.dcap.git
cd confidential-computing.tee.dcap/tools/PcsClientTool
python3 -m venv venv
source ./venv/bin/activate
pip install -r requirements.txt
# --8<-- [end:pcs_client_tool-source-sles_16]

# --8<-- [start:pccs_admin_tool-package-cent-os-stream-10]
sudo dnf install -y intel-tee-pccs-admin-tool
# --8<-- [end:pccs_admin_tool-package-cent-os-stream-10]

# --8<-- [start:pccs_admin_tool-package-cent_os_stream_9]
sudo dnf install -y intel-tee-pccs-admin-tool
# --8<-- [end:pccs_admin_tool-package-cent_os_stream_9]

# --8<-- [start:pccs_admin_tool-package-rhel_10_2]
sudo dnf install -y intel-tee-pccs-admin-tool
# --8<-- [end:pccs_admin_tool-package-rhel_10_2]

# --8<-- [start:pccs_admin_tool-package-ubuntu_26_04]
sudo apt install -y intel-tee-pccs-admin-tool
# --8<-- [end:pccs_admin_tool-package-ubuntu_26_04]

# --8<-- [start:pccs_admin_tool-package-opensuse_16]
sudo zypper install -y intel-tee-pccs-admin-tool
# --8<-- [end:pccs_admin_tool-package-opensuse_16]

# --8<-- [start:pccs_admin_tool-package-sles_16]
sudo zypper install -y intel-tee-pccs-admin-tool
# --8<-- [end:pccs_admin_tool-package-sles_16]

# --8<-- [start:pccs_admin_tool-source-cent-os-stream-10]
sudo dnf install -y git python3
git clone https://github.com/intel/confidential-computing.tee.dcap.pccs.git
cd confidential-computing.tee.dcap.pccs/PccsAdminTool
python3 -m venv venv
source ./venv/bin/activate
pip install -r requirements.txt
# --8<-- [end:pccs_admin_tool-source-cent-os-stream-10]

# --8<-- [start:pccs_admin_tool-source-cent_os_stream_9]
sudo dnf install -y git python3
git clone https://github.com/intel/confidential-computing.tee.dcap.pccs.git
cd confidential-computing.tee.dcap.pccs/PccsAdminTool
python3 -m venv venv
source ./venv/bin/activate
pip install -r requirements.txt
# --8<-- [end:pccs_admin_tool-source-cent_os_stream_9]

# --8<-- [start:pccs_admin_tool-source-rhel_10_2]
sudo dnf install -y git python3
git clone https://github.com/intel/confidential-computing.tee.dcap.pccs.git
cd confidential-computing.tee.dcap.pccs/PccsAdminTool
python3 -m venv venv
source ./venv/bin/activate
pip install -r requirements.txt
# --8<-- [end:pccs_admin_tool-source-rhel_10_2]

# --8<-- [start:pccs_admin_tool-source-ubuntu_26_04]
sudo apt install -y python3 python3-venv
git clone https://github.com/intel/confidential-computing.tee.dcap.pccs.git
cd confidential-computing.tee.dcap.pccs/PccsAdminTool
python3 -m venv venv
source ./venv/bin/activate
pip install -r requirements.txt
# --8<-- [end:pccs_admin_tool-source-ubuntu_26_04]

# --8<-- [start:pccs_admin_tool-source-opensuse_16]
sudo zypper install -y git python3 python3-pip
git clone https://github.com/intel/confidential-computing.tee.dcap.pccs.git
cd confidential-computing.tee.dcap.pccs/PccsAdminTool
python3 -m venv venv
source ./venv/bin/activate
pip install -r requirements.txt
# --8<-- [end:pccs_admin_tool-source-opensuse_16]

# --8<-- [start:pccs_admin_tool-source-sles_16]
sudo zypper install -y git python3 python3-pip
git clone https://github.com/intel/confidential-computing.tee.dcap.pccs.git
cd confidential-computing.tee.dcap.pccs/PccsAdminTool
python3 -m venv venv
source ./venv/bin/activate
pip install -r requirements.txt
# --8<-- [end:pccs_admin_tool-source-sles_16]
