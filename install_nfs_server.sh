#!/bin/bash

SHARED_DIR="/mnt/xgrid_pods_info"

apt-get update

apt-get install nfs-kernel-server -y

mkdir -p "${SHARED_DIR}"

chown nobody:nogroup "${SHARED_DIR}"

chmod 777 "${SHARED_DIR}"

echo "${SHARED_DIR}	192.168.0.0/26(rw,sync,no_subtree_check)" >>  /etc/exports

exportfs -a

systemctl restart nfs-kernel-server

ufw allow from 192.168.0.0/26 to any port nfs


