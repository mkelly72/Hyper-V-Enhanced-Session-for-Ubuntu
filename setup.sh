#!/bin/bash

#
# This script is to enable Enhanced Sessions over Hyper-V for Ubuntu

# Allow source downloads (sources needed to build audio driver).
#
sudo cp /etc/apt/sources.list /etc/apt/sources.list~
sudo sed -Ei 's/^# deb-src /deb-src /' /etc/apt/sources.list
###############################################################################
# Install linux-azure kernel with hv_kvp utils
sudo apt install -y linux-azure
###############################################################################
# Check if reboot is needed to continue
if [ -f /var/run/reboot-required ]; then
    echo "A reboot is required in order to proceed with the install." >&2
    echo "The install is not finished yet." >&2
    echo "Please reboot and re-run this script to finish the install." >&2
    exit 1
fi
###############################################################################
# XRDP
#

# Install the xrdp service so we have the auto start behavior
sudo apt install -y xrdp

sudo systemctl stop xrdp
sudo systemctl stop xrdp-sesman

# Configure the installed XRDP ini files.
# use vsock transport.
sudo sed -i_orig -e 's/port=3389/port=vsock:\/\/-1:3389/g' /etc/xrdp/xrdp.ini
# use rdp security.
sudo sed -i_orig -e 's/security_layer=negotiate/security_layer=rdp/g' /etc/xrdp/xrdp.ini
# remove encryption validation.
sudo sed -i_orig -e 's/crypt_level=high/crypt_level=none/g' /etc/xrdp/xrdp.ini
# disable bitmap compression since its local its much faster
sudo sed -i_orig -e 's/bitmap_compression=true/bitmap_compression=false/g' /etc/xrdp/xrdp.ini

# Add script to setup the ubuntu session properly
if [ ! -e /etc/xrdp/startubuntu.sh ]; then
sudo bash -c 'cat >> /etc/xrdp/startubuntu.sh << EOF
#!/bin/sh
export GNOME_SHELL_SESSION_MODE=ubuntu
export XDG_CURRENT_DESKTOP=ubuntu:GNOME
exec /etc/xrdp/startwm.sh
EOF'
sudo chmod a+x /etc/xrdp/startubuntu.sh
fi

# use the script to setup the ubuntu session
sudo sed -i_orig -e 's/startwm/startubuntu/g' /etc/xrdp/sesman.ini

# rename the redirected drives to 'shared-drives'
sudo sed -i -e 's/FuseMountName=thinclient_drives/FuseMountName=shared-drives/g' /etc/xrdp/sesman.ini

# Changed the allowed_users
sudo sed -i_orig -e 's/allowed_users=console/allowed_users=anybody/g' /etc/X11/Xwrapper.config

# Blacklist the vmw module
sudo bash -c 'if [ ! -e /etc/modprobe.d/blacklist-vmw_vsock_vmci_transport.conf ]; then
  echo "blacklist vmw_vsock_vmci_transport" > /etc/modprobe.d/blacklist-vmw_vsock_vmci_transport.conf
fi'

#Ensure hv_sock gets loaded
sudo bash -c 'if [ ! -e /etc/modules-load.d/hv_sock.conf ]; then
  echo "hv_sock" > /etc/modules-load.d/hv_sock.conf
fi'

# Configure the policy xrdp session
sudo bash -c 'cat > /etc/polkit-1/localauthority/50-local.d/45-allow-colord.pkla <<EOF
[Allow Colord all Users]
Identity=unix-user:*
Action=org.freedesktop.color-manager.create-device;org.freedesktop.color-manager.create-profile;org.freedesktop.color-manager.delete-device;org.freedesktop.color-manager.delete-profile;org.freedesktop.color-manager.modify-device;org.freedesktop.color-manager.modify-profile
ResultAny=no
ResultInactive=no
ResultActive=yes
EOF'

# reconfigure the service
sudo systemctl daemon-reload
sudo systemctl start xrdp

#
# End XRDP
###############################################################################
# Audio driver for xrdp
sudo apt install git libpulse-dev autoconf m4 intltool build-essential dpkg-dev libtool libsndfile-dev libspeexdsp-dev libudev-dev -y
sudo apt build-dep pulseaudio -y
cd /tmp
sudo apt source pulseaudio -y
sudo apt install pulseaudio -y

### Build and install driver
pulsever=$(ls -d /tmp/pulseaudio*/ | head -c -1)
cd $pulsever
# This configure file may not exist - seems to build without it anyway
if test -f ./configure; then
	sudo ./configure
fi
sudo meson build
sudo meson compile -C build
sudo git clone https://github.com/neutrinolabs/pulseaudio-module-xrdp.git
cd pulseaudio-module-xrdp
sudo ./bootstrap
sudo ./configure PULSE_DIR="$pulsever"
sudo make
cd src/.libs
sudo install -t "/var/lib/xrdp-pulseaudio-installer" -D -m 755 *.so

### Start and enable service
sudo killall pulseaudio
systemctl --user start pulseaudio
systemctl --user enable pulseaudio

### Add ~/pulse.sh to Startup Applications to fix initial startup issues
cd /$HOME
tee /$HOME/pulse.sh <<EOF
#!/bin/bash
systemctl --user restart pulseaudio
exit 0
EOF

chmod +x ~/pulse.sh
if [ ! -f /$HOME/.config/autostart/pulse.sh.desktop ]; then
mkdir -p /$HOME/.config/autostart
tee /$HOME/.config/autostart/pulse.sh.desktop <<EOF

[Desktop Entry]
Exec=$HOME/pulse.sh
Icon=dialog-scripts
Name=Restart Pulseaudio
Path=
Type=Application
X-KDE-AutostartScript=true
X-GNOME-Autostart-enabled=true
EOF
fi
###############################################################################
yes '' | sed 50q
echo "Install is complete."
echo "Shut down your VM."
echo "Run Linux-Enhanced-Session.ps1 in Windows."
echo "Enter your VM name when asked." 
echo "Then turn your VM back on."
echo "Re-run this script if Enhanced Sessions isn't working yet."
echo "If it still isn't working after 2 re-tries, check Hyper-V Settings to see if it is set to allow enhanced session mode"
echo "Also check that 'Enhanced session' is checked under the View menu of your Virtual Machine Connection."
echo ""
echo "ONE FINAL NOTE - PLEASE REMEMBER THIS FOR THE FUTURE:"
echo "If you are logged into a non-enhanced session (e.g. gdm3), xrdp will reject your login. So log out properly before switching."

exit 0

