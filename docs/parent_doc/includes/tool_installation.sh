# --8<-- [start:pcs_client_tool-package-cent_os_stream_9]
sudo dnf install -y intel-tee-pcs-client-tool
# --8<-- [end:pcs_client_tool-package-cent_os_stream_9]

# --8<-- [start:pcs_client_tool-package-ubuntu_24_04]
sudo apt install -y intel-tee-pcs-client-tool
# --8<-- [end:pcs_client_tool-package-ubuntu_24_04]

# --8<-- [start:pcs_client_tool-source-cent_os_stream_9]
sudo dnf install git python3
git clone https://github.com/intel/SGXDataCenterAttestationPrimitives.git
cd SGXDataCenterAttestationPrimitives/tools/PcsClientTool
python3 -m venv venv
source ./venv/bin/activate
pip install -r requirements.txt
# --8<-- [end:pcs_client_tool-source-cent_os_stream_9]

# --8<-- [start:pcs_client_tool-source-ubuntu_24_04]
sudo apt install -y python3 python3-venv
git clone https://github.com/intel/SGXDataCenterAttestationPrimitives.git
cd SGXDataCenterAttestationPrimitives/tools/PcsClientTool
python3 -m venv venv
source ./venv/bin/activate
pip install -r requirements.txt
# --8<-- [end:pcs_client_tool-source-ubuntu_24_04]

# --8<-- [start:pccs_admin_tool-package-cent_os_stream_9]
sudo dnf install -y intel-tee-pccs-admin-tool
# --8<-- [end:pccs_admin_tool-package-cent_os_stream_9]

# --8<-- [start:pccs_admin_tool-package-ubuntu_24_04]
sudo apt install -y intel-tee-pccs-admin-tool
# --8<-- [end:pccs_admin_tool-package-ubuntu_24_04]

# --8<-- [start:pccs_admin_tool-source-cent_os_stream_9]
sudo dnf install git python3
git clone https://github.com/intel/confidential-computing.tee.dcap.pccs.git
cd confidential-computing.tee.dcap.pccs/PccsAdminTool
python3 -m venv venv
source ./venv/bin/activate
pip install -r requirements.txt
# --8<-- [end:pccs_admin_tool-source-cent_os_stream_9]

# --8<-- [start:pccs_admin_tool-source-ubuntu_24_04]
sudo apt install -y python3 python3-venv
git clone https://github.com/intel/confidential-computing.tee.dcap.pccs.git
cd confidential-computing.tee.dcap.pccs/PccsAdminTool
python3 -m venv venv
source ./venv/bin/activate
pip install -r requirements.txt
# --8<-- [end:pccs_admin_tool-source-ubuntu_24_04]
