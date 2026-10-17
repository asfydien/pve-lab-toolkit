#!/usr/bin/env bash
set -e

if [ "$(id -u)" -ne 0 ]; then
    echo "Jalankan skrip ini dari host Proxmox (sebagai root)."
    exit 1
fi

echo "=========================================================="
echo " Pembuat OS Template LXC Otomatis "
echo "=========================================================="
read -p "Masukkan ID CT Master (contoh: 100) : " CTID
read -p "Nama Template Baru (tanpa spasi)    : " TPL_NAME

if [[ -z "$TPL_NAME" ]]; then
    echo "Nama template tidak boleh kosong."
    exit 1
fi

echo ""
echo "Pilih Tingkat Kompresi:"
echo "1) Normal / Cepat (Bawaan - Eksekusi dalam hitungan detik)"
echo "2) Maksimal / Lambat (Ukuran terkecil, memakan waktu lama)"
read -p "Pilihan Anda [1/2, tekan Enter untuk 1]: " COMP_CHOICE

TPL_FILENAME="${TPL_NAME}.tar.zst"
TEMPLATE_DIR="/var/lib/vz/template/cache"

if ! pct status "$CTID" >/dev/null 2>&1; then
    echo "Error: Kontainer $CTID tidak ditemukan!"
    exit 1
fi

CT_STATUS=$(pct status "$CTID" | awk '{print $2}')
if [ "$CT_STATUS" == "stopped" ]; then
    echo "Menyalakan CT $CTID untuk pembersihan..."
    pct start "$CTID"
    sleep 5
fi

echo "[1/4] Deep Clean: Membersihkan apt, log, dan identitas..."
pct exec "$CTID" -- bash -c '
    export DEBIAN_FRONTEND=noninteractive
    apt-get autoremove --purge -y
    apt-get clean
    rm -rf /var/lib/apt/lists/*
    rm -rf /var/cache/apt/archives/*
    truncate -s 0 /etc/machine-id
    rm -f /var/lib/dbus/machine-id
    rm -f /etc/ssh/ssh_host_*
    rm -rf /tmp/* /var/tmp/* /var/cache/* /root/.cache/*
    find /var/log -type f -exec truncate -s 0 {} +
    history -c
    rm -f ~/.bash_history /root/.bash_history
'

echo "[2/4] Mematikan CT $CTID dengan aman..."
pct stop "$CTID"

echo "[3/4] Memaketkan Rootfs dengan Vzdump..."

# Mengatur level kompresi berdasarkan input
if [ "$COMP_CHOICE" == "2" ]; then
    echo ">> Menggunakan kompresi MAKSIMAL (Level 19)..."
    export ZSTD_CLEVEL=19
else
    echo ">> Menggunakan kompresi NORMAL (Bawaan)..."
    # Menghapus setelan variabel agar kembali ke standar bawaan vzdump (Level 3)
    unset ZSTD_CLEVEL
fi

# Memanfaatkan semua thread CPU yang tersedia agar lebih cepat
export ZSTD_NBTHREADS=0

# Hapus sisa backup sebelumnya jika ada
rm -f ${TEMPLATE_DIR}/vzdump-lxc-${CTID}-*.tar.zst

# Buat template
vzdump "$CTID" --mode stop --compress zstd --dumpdir "$TEMPLATE_DIR"

echo "[4/4] Mengubah nama template..."
DUMP_FILE=$(ls -t ${TEMPLATE_DIR}/vzdump-lxc-${CTID}-*.tar.zst 2>/dev/null | head -n 1)

if [ -n "$DUMP_FILE" ]; then
    mv "$DUMP_FILE" "${TEMPLATE_DIR}/${TPL_FILENAME}"
    echo "=========================================================="
    echo " BERHASIL! Template aman untuk Unprivileged CT."
    echo " Lokasi   : ${TEMPLATE_DIR}/${TPL_FILENAME}"
    echo " File Size: $(du -sh "${TEMPLATE_DIR}/${TPL_FILENAME}" | awk '{print $1}')"
    echo "=========================================================="
else
    echo "Error: Gagal menemukan file hasil ekspor."
fi
