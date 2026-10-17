#!/bin/bash

# --- Konfigurasi ---
TEMPLATE_DIR="/var/lib/vz/template/cache"
WORK_DIR="/root/debian-template-tmp"
DEFAULT_PROXY_IP="10.10.2.99"

# --- Validasi Root ---
if [[ $EUID -ne 0 ]]; then
   whiptail --title "Error" --msgbox "Script ini harus dijalankan sebagai root!" 8 45
   exit 1
fi

# --- 1. SCAN TEMPLATE ---
FILES=$(ls $TEMPLATE_DIR/*.tar.zst 2>/dev/null | grep -v "proxy-ready")
if [ -z "$FILES" ]; then
    whiptail --title "Error" --msgbox "Tidak ditemukan template baru di $TEMPLATE_DIR" 8 45
    exit 1
fi

OPTIONS=()
for f in $FILES; do
    FILENAME=$(basename "$f")
    OPTIONS+=("$FILENAME" "LXC Template")
done

SELECTED_TEMPLATE=$(whiptail --title "Pilih Template" --menu \
"Pilih template yang akan di-inject konfigurasi proxy:" 15 75 6 \
"${OPTIONS[@]}" 3>&1 1>&2 2>&3)

[[ -z "$SELECTED_TEMPLATE" ]] && exit 0

# --- 2. INPUT IP PROXY ---
APT_PROXY_IP=$(whiptail --title "Konfigurasi Proxy" --inputbox \
"Masukkan IP Address server apt-cacher-ng:" 8 50 "$DEFAULT_PROXY_IP" 3>&1 1>&2 2>&3)

[[ -z "$APT_PROXY_IP" ]] && exit 0

# --- 3. FUNGSI PROSES ---
process_template() {
    # DEFINISIKAN NAMA DI SINI (Di dalam subshell fungsi)
    local NEW_NAME="${SELECTED_TEMPLATE%.tar.zst}-proxy-ready.tar.zst"
    
    echo -e "XXX\n5\nMenyiapkan direktori kerja...\nXXX"
    mkdir -p "$WORK_DIR"
    cd "$WORK_DIR" || exit
    
    echo -e "XXX\n20\nMengekstrak: $SELECTED_TEMPLATE\nXXX"
    pzstd -d -c "$TEMPLATE_DIR/$SELECTED_TEMPLATE" 2>/dev/null | tar -xf - >/dev/null 2>&1
    
    echo -e "XXX\n50\nInjeksi Proxy: $APT_PROXY_IP\nXXX"
    mkdir -p etc/apt/apt.conf.d/
    echo "Acquire::HTTP::Proxy \"http://$APT_PROXY_IP:3142\";" > etc/apt/apt.conf.d/00aptproxy
    
    echo -e "XXX\n65\nCleaning up system files...\nXXX"
    rm -rf dev/* proc/* sys/* run/* tmp/* var/log/* var/cache/apt/* >/dev/null 2>&1
    
    # Pesan ini sekarang PASTI menampilkan nama file
    echo -e "XXX\n80\nMengemas ulang ke: $NEW_NAME\nXXX"
    tar -cf - . | pzstd -19 -f -o "$TEMPLATE_DIR/$NEW_NAME" >/dev/null 2>&1
    
    echo -e "XXX\n95\nFinalisasi dan pembersihan...\nXXX"
    cd ~
    rm -rf "$WORK_DIR"
    
    echo -e "XXX\n100\nSelesai: $NEW_NAME\nXXX"
    sleep 1
}

# Jalankan dengan Gauge (Lebar 80 agar aman untuk nama file panjang)
process_template | whiptail --title "Proses Injeksi Proxy" --gauge "Memulai proses..." 8 80 0

# Simpan nama untuk notifikasi akhir
FINAL_NAME="${SELECTED_TEMPLATE%.tar.zst}-proxy-ready.tar.zst"
whiptail --title "Berhasil" --msgbox "Template baru telah dibuat!\n\nFile: $FINAL_NAME\nLokasi: $TEMPLATE_DIR" 12 80
