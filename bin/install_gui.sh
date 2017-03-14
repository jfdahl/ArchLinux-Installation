#!/usr/bin/env bash

desktop_environment="lxde"   #Options: xfce4, lxde
display_manager="slim"     #Options: lightdm, slim

[[ $(lspci | grep VirtualBox) ]] && VBOX=true || VBOX=false

pci_wifi_count=$(lspci | egrep -ic 'wifi|wlan|wireless')
usb_wifi_count=$(lsusb | egrep -ic 'wifi|wlan|wireless')
wifi_count=$(( $pci_wifi_count + $usb_wifi_count ))
[ ${wifi_count} -gt 0 ] && WIFI=true || WIFI=false

# Install packages
packages="xorg-server xorg-utils xdg-utils mesa gvfs alsa-utils"
$VBOX && \
    packages="${packages} virtualbox-guest-utils dkms linux-headers" || \
    packages="${packages} xf86-input-all xf86-video-vesa"
$WIFI && packages="$packages wicd"

if [ "${display_manager}" == "slim" ]; then
    packages="${packages} slim"
    dm_service="slim.service"
elif [ "${display_manager}" == "lightdm" ]; then
    packages="${packages} lightdm lightdm-gtk-greeter"
    dm_service="lightdm.service"
fi

if [ "${desktop_environment}" == "xfce4" ]; then
    packages="${packages} xfce4 xfce4-whiskermenu-plugin mousepad"
    init_exec="startxfce4"
elif [ "${desktop_environment}" == "lxde" ]; then
        packages="${packages} lxde-common lxsession openbox"
        init_exec="startlxde"
fi
pacman -S --noconfirm $packages

# Configure packages
$VBOX && \
    systemctl enable vboxservice && \
    systemctl start vboxservice
echo "exec ${init_exec}" >> /etc/skel/.xinitrc && \
    cp /etc/skel/.xinitrc /home/user/

systemctl enable ${dm_service}
amixer sset Master unmute
