#!/usr/bin/env bash

ansible_user='devops'

if [ $EUID -ne 0 ]; then
   echo "This script must be run as root"
   exit 1
fi

kernel_count="$(ls -1 /boot | wc -l)"

apt-get update
apt-get upgrade      -y --fix-missing
apt-get dist-upgrade -y --fix-missing
apt-get -y install python3 python3-venv python3-pip git wget curl vim sshpass

if ! id -u "${ansible_user}" &>/dev/null; then
    adduser "${ansible_user}"
fi

# If your user is not sudoer, add him to sudo group
sudo -l -U "${ansible_user}" | sed '1!d' | grep -q "not allowed"
[ $? -eq 0 ] && usermod -aG sudo "${ansible_user}"

check="$(ls -1 /boot | wc -l)"
if [ $kernel_count -ne $check ]; then
    echo "New kernel has been installed. Rebooting in 5sec..."
    sleep 5
    reboot
fi

exit $?
