#!/usr/bin/env bash

ansible_user='devops'
hosts=(
    'deb-docker1'
    'deb-docker2'
    'deb-docker3'
    )
hosts_ip=(
    '10.211.0.11'
    '10.211.0.12'
    '10.211.0.13'
)

shares=(
    '/docker-exports/mongo_sharded'
)

if [ $EUID -ne 0 ]; then
   echo "This script must be run as root"
   exit 1
fi

apt-get update
apt-get -y install nfs-kernel-server

# Populate /etc/hosts
for i in "${!hosts[@]}"; do
    if ! grep -q "${hosts[i]}" /etc/hosts; then
        echo "${hosts_ip[i]}" "${hosts[i]}" >> /etc/hosts
    fi
done

for share in "${shares[@]}"; do
    [ ! -d "$share" ] && mkdir -p "$share"
    chown -R "${ansible_user}":"${ansible_user}" "$share"
    chown -R 0750 "$share"
    
    if ! grep -q "$share" /etc/exports; then
        echo -n "$share" >> /etc/exports
        
        for i in "${!hosts[@]}"; do
            echo -n " ${hosts[i]}(rw,sync,no_root_squash,crossmnt,no_subtree_check)" >> /etc/exports
        done
        echo '' >> /etc/exports
    fi
done
systemctl restart nfs-kernel-server
systemctl enable  nfs-kernel-server
exit $?
