#!/usr/bin/env bash

# =============================================================================
# Skrip Pembuatan Akun Murid Proxmox VE
# =============================================================================

# uo pipefail untuk keamanan tanpa menghentikan skrip secara paksa
set -uo pipefail

# -----------------------------------------------------------------------------
# KONFIGURASI
# -----------------------------------------------------------------------------
REALM="pve"
DEFAULT_PASSWORD="Siswa@2026!"
STORAGE="local,local-lvm,local-zfs"
BRIDGE_LIST="vmbr0 vmbr1 vmbr2"

ROLE_POOL="Administrator"
ROLE_STORAGE="PVEDatastoreUser"
ROLE_SDN="PVESDNUser"

declare -a MURID=(
"232410250|Abu Bakar Ash-Shiddiq"
"232410254|Ali bin Abi Thalib"
"232410251|Umar bin Khattab"
"232410252|Utsman bin Affan"
"232410253|Talhah bin Ubaidillah"
# tambahkan daftar murid di sisni
)

# -----------------------------------------------------------------------------
# KONFIRMASI PEMBUATAN
# -----------------------------------------------------------------------------
echo "========================================================="
echo "  PEMBUATAN AKUN MURID PROXMOX VE"
echo "  Total target proses : ${#MURID[@]} Murid"
echo "  Metode              : Paralel (Cepat)"
echo "========================================================="
echo ""
read -p "Lanjutkan proses pembuatan akun? (ya/n): " konfirm

if [[ "$konfirm" != "ya" ]]; then
    echo "Proses dibatalkan."
    exit 0
fi

echo "Memulai proses sinkronisasi..."

# -----------------------------------------------------------------------------
# FUNGSI PROSES PARALEL
# -----------------------------------------------------------------------------
process_item() {
    local nis="$1"
    local nama="$2"
    local user="${nis}@${REALM}"
    local pool="P${nis}"
    local status_msg=""

    # 1. Sinkronisasi User
    if pvesh get /access/users/${user} >/dev/null 2>&1; then
        pveum user modify "$user" --comment "$nama" >/dev/null 2>&1
        status_msg="[UPDATE]"
    else
        pveum user add "$user" --password "$DEFAULT_PASSWORD" --comment "$nama" >/dev/null 2>&1
        status_msg="[BARU]"
    fi

    # 2. Sinkronisasi Pool
    if pvesh get /pools/${pool} >/dev/null 2>&1; then
        pveum pool modify "$pool" --comment "$nama" >/dev/null 2>&1
    else
        pveum pool add "$pool" --comment "$nama" >/dev/null 2>&1
    fi

    # 3. Sinkronisasi ACL
    pveum acl modify "/pool/${pool}" --roles "${ROLE_POOL}" --users "${user}" --propagate 1 >/dev/null 2>&1
    
    for sto in ${STORAGE//,/ }; do
        pveum acl modify "/storage/${sto}" --roles "${ROLE_STORAGE}" --users "${user}" --propagate 0 >/dev/null 2>&1
    done

    for br in $BRIDGE_LIST; do
        pveum acl modify "/sdn/zones/localnetwork/${br}" --roles "${ROLE_SDN}" --users "${user}" --propagate 1 >/dev/null 2>&1
    done

    # Output log per murid
    echo "  $status_msg Selesai: $nis - $nama"
}

# -----------------------------------------------------------------------------
# Eksekusi Batch (10 murid sekaligus)
# -----------------------------------------------------------------------------
count=0
for entry in "${MURID[@]}"; do
    IFS='|' read -r nis nama <<< "$entry"
    
    # Jalankan di background
    process_item "$nis" "$nama" &
    
    count=$((count + 1))
    
    # Tunggu setiap batch 10 proses agar API tidak overload
    if (( count % 10 == 0 )); then
        wait
        echo "Batch $count murid telah disinkronkan..."
    fi
done

# Tunggu sisa proses terakhir
wait

echo ""
echo "  SELESAI! ${#MURID[@]} akun telah diproses."
