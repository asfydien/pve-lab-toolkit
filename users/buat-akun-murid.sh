#!/usr/bin/env bash

# =============================================================================
# HAPUS TOTAL AKUN, POOL & ACL (VERSI PARALEL / CEPAT)
# =============================================================================

set -uo pipefail

REALM="pve"
STORAGE="local,local-lvm,local-zfs"

# Daftar murid (format: "NIS|Nama Lengkap")
declare -a MURID=(
"232410250|Abu Bakar Ash-Shiddiq"
"232410254|Ali bin Abi Thalib"
"232410251|Umar bin Khattab"
"232410252|Utsman bin Affan"
"232410253|Talhah bin Ubaidillah"
# tambahkan daftar murid di sisni
)

echo "======================================================================"
echo "  PERINGATAN: PENGHAPUSAN MASAL CEPAT"
echo "  Jumlah target : ${#MURID[@]} Siswa"
echo "======================================================================"
echo ""
read -p "Ketik 'HAPUS-CEPAT' untuk lanjut: " konfirm

if [[ "$konfirm" != "HAPUS-CEPAT" ]]; then
    echo "Dibatalkan."
    exit 0
fi

echo "Memulai penghapusan paralel (10 akun sekaligus)..."

# Fungsi inti penghapusan per siswa
delete_student() {
    local nis="$1"
    local nama="$2"
    local user="${nis}@${REALM}"
    local pool="P${nis}"

    # 1. Keluarkan VM/CT dari pool (Tanpa hapus VM-nya)
    vms=$(pvesh get /pools/${pool} --output-format json 2>/dev/null | grep -o '"vmid":[0-9]\+' | cut -d: -f2 || echo "")
    if [[ -n "$vms" ]]; then
        for vmid in $vms; do
            pveum pool modify "$pool" --delete 1 --vms "$vmid" >/dev/null 2>&1 || true
        done
    fi

    # 2. Hapus ACL
    pveum acl delete "/pool/${pool}" --users "${user}" >/dev/null 2>&1 || true
    pveum acl delete "/sdn/zones/localnetwork" --users "${user}" >/dev/null 2>&1 || true
    for sto in ${STORAGE//,/ }; do
        pveum acl delete "/storage/${sto}" --users "${user}" >/dev/null 2>&1 || true
    done

    # 3. Hapus Pool & User
    pveum pool delete "$pool" >/dev/null 2>&1 || true
    pveum user delete "$user" >/dev/null 2>&1 || true

    echo "  [OK] $nis ($nama) dihapus."
}

# Eksekusi Batch
count=0
for entry in "${MURID[@]}"; do
    IFS='|' read -r nis nama <<< "$entry"
    
    # Jalankan di background
    delete_student "$nis" "$nama" &
    
    count=$((count + 1))
    
    # Batch per 10 orang agar tidak membebani pveum API secara ekstrim
    if (( count % 10 == 0 )); then
        wait
        echo "Batch $count murid telah diproses..."
    fi
done

# Tunggu proses terakhir selesai
wait

echo ""
echo "========================================================="
echo "  SELESAI! ${#MURID[@]} akun telah dibersihkan."
echo "========================================================="
