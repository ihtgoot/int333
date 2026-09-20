#!/bin/bash

set -e

echo "======================================"
echo " Puppet Server Bootstrap"
echo " Ubuntu 24.04 / AWS EC2"
echo "======================================"

# --------------------------------------------------
# 1. Basic system information
# --------------------------------------------------

PRIVATE_IP=$(hostname -I | awk '{print $1}')
HOSTNAME=$(hostname)

echo "[1/8] Server information"
echo "Hostname : $HOSTNAME"
echo "Private IP: $PRIVATE_IP"

# --------------------------------------------------
# 2. Update system
# --------------------------------------------------

echo "[2/8] Updating package lists"

sudo apt update

# --------------------------------------------------
# 3. Install required packages
# --------------------------------------------------

echo "[3/8] Installing Puppet Server"

sudo apt install -y puppetserver

# --------------------------------------------------
# 4. Configure hostname resolution
# --------------------------------------------------

echo "[4/8] Configuring /etc/hosts"

if ! grep -qE "^${PRIVATE_IP}[[:space:]]+puppet([[:space:]]|$)" /etc/hosts; then
    echo "${PRIVATE_IP} puppet" | sudo tee -a /etc/hosts
fi

echo
echo "Hosts entry:"
getent hosts puppet

# --------------------------------------------------
# 5. Configure Puppet Server JVM memory
# --------------------------------------------------

echo "[5/8] Configuring Puppet Server JVM"

sudo sed -i \
    's/-Xms2g -Xmx2g/-Xms512m -Xmx512m/' \
    /etc/default/puppetserver

# If JAVA_ARGS does not contain the expected values,
# explicitly configure it.
if ! grep -q -- '-Xms512m -Xmx512m' /etc/default/puppetserver; then
    sudo sed -i \
        's/^JAVA_ARGS=.*/JAVA_ARGS="-Xms512m -Xmx512m"/' \
        /etc/default/puppetserver
fi

echo
echo "JVM configuration:"
grep JAVA_ARGS /etc/default/puppetserver || true

# --------------------------------------------------
# 6. Enable Puppet Server
# --------------------------------------------------

echo "[6/8] Enabling Puppet Server"

sudo systemctl daemon-reload
sudo systemctl enable puppetserver

# --------------------------------------------------
# 7. Start Puppet Server
# --------------------------------------------------

echo "[7/8] Starting Puppet Server"

sudo systemctl start puppetserver

echo
echo "Waiting for Puppet Server..."
sleep 15

# --------------------------------------------------
# 8. Verification
# --------------------------------------------------

echo "[8/8] Verifying Puppet Server"

echo
echo "----- Puppet version -----"
puppet --version

echo
echo "----- Puppet Server version -----"
puppetserver --version

echo
echo "----- Java version -----"
java -version

echo
echo "----- Service status -----"
sudo systemctl status puppetserver --no-pager

echo
echo "----- Port 8140 -----"
sudo ss -lntp | grep 8140 || true

echo
echo "======================================"
echo " Puppet Server bootstrap complete"
echo "======================================"

echo
echo "Server hostname : $HOSTNAME"
echo "Server private IP: $PRIVATE_IP"
echo
echo "Agent should connect to:"
echo "    puppet"
echo
