#!/bin/bash

# Script ini digunakan untuk menyisipkan baris konfigurasi ke setiap CT, 
# supaya dapat mengakses TUN yang dibutuhkan ketika menginstal VPN
# jalankan di Shell PVE

CONFIG_DIR="/etc/pve/lxc/"
CONFIG_FILES=$(find "$CONFIG_DIR" -type f -name "*.conf")

# Baris yang akan ditambahkan
LINE1="lxc.cgroup.devices.allow: c 10:200 rwm"
LINE2="lxc.mount.entry: /dev/net dev/net none bind,create=dir"

ADDED_IDS=()

for FILE in $CONFIG_FILES; do
    CONTAINER_ID=$(basename "$FILE" .conf)
    MODIFIED=false
    
    # Cek dan tambahkan LINE1 jika belum ada
    if ! grep -qF "$LINE1" "$FILE"; then
        echo "$LINE1" >> "$FILE"
        echo "Menambahkan ke $FILE: $LINE1"
        MODIFIED=true
    fi
    
    # Cek dan tambahkan LINE2 jika belum ada
    if ! grep -qF "$LINE2" "$FILE"; then
        echo "$LINE2" >> "$FILE"
        echo "Menambahkan ke $FILE: $LINE2"
        MODIFIED=true
    fi
    
    if [ "$MODIFIED" = true ]; then
        ADDED_IDS+=("$CONTAINER_ID")
    fi
done

if [ ${#ADDED_IDS[@]} -gt 0 ]; then
    echo "Penyisipan selesai untuk container: ${ADDED_IDS[*]}"
else
    echo "Tidak ada perubahan yang dilakukan."
fi
