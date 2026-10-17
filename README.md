# Proxmox VE Lab Toolkit

Kumpulan skrip otomasi Bash untuk mempermudah administrasi, manajemen pengguna massal, dan pembuatan template kontainer (LXC) pada kluster atau server mandiri Proxmox Virtual Environment (PVE) di lingkungan laboratorium komputer sekolah/kampus.

---

## 📋 Daftar & Fungsi Skrip

## 📋 Daftar & Ringkasan Skrip

| Nama Skrip | Kategori | Fungsi Utama | Mekanisme & Fitur |
| :--- | :--- | :--- | :--- |
| **`buat-akun-murid.sh`** | Manajemen Akun | Provisi massal akun pengguna siswa | • Membuat user realm `pve`, resource pool `P<NIS>`, dan hak akses ACL (Pool, Datastore, SDN)<br>• Pemrosesan cepat/paralel per *batch* 10 akun<br>• Cek idempotensi (update komentar jika user sudah ada) |
| **`hapus-akun-murid.sh`** | Manajemen Akun | Pembersihan massal akun & hak akses siswa | • Konfirmasi keamanan interaktif (`HAPUS-CEPAT`)<br>• Pelepasan VM/CT dari pool tanpa menghapus VM fisik<br>• Penghapusan ACL, pool, dan akun secara paralel (batch 10 akun) |
| **`buat-jadi-ct-template.sh`** | Manajemen LXC | Pembuatan OS template LXC dari CT master | • Pembersihan mendalam (*deep clean*): cache APT, log, riwayat bash, `machine-id`, dan SSH host keys<br>• Pilihan kompresi Zstd (Normal atau Level 19 Maksimal)<br>• Otomatisasi multi-thread CPU (`ZSTD_NBTHREADS=0`) |
| **`inject-lxc-aptproxy.sh`** | Manajemen LXC | Injeksi konfigurasi `apt-cacher-ng` ke file template | • Antarmuka teks interaktif (TUI via `whiptail`)<br>• Dekompresi dan *re-pack* langsung template `.tar.zst` tanpa perlu menyalakan kontainer<br>• Menghasilkan berkas baru dengan akhiran `-proxy-ready.tar.zst` |
| **`aktivasi-lxc-tun.sh`** | Jaringan LXC | Aktivasi device TUN/TAP massal untuk VPN | • Memindai seluruh konfigurasi kontainer di `/etc/pve/lxc/*.conf`<br>• Menambahkan izin cgroup `c 10:200 rwm` dan bind mount `/dev/net`<br>• Pengecekan duplikasi agar baris konfigurasi tidak tertulis ganda |
---

## 🛠️ Prasyarat Sistem

1. Host Proxmox VE 7.x / 8.x dengan akses `root`.
2. Paket utilitas pendukung (khususnya untuk ekstraksi dan antarmuka TUI):
   ```bash
   apt update
   apt install -y whiptail zstd tar
---
## Batasan Tanggung Jawab (Disclaimer)

Skrip dan seluruh materi panduan di dalam repositori ini disediakan semata-mata untuk **tujuan edukasi, pembelajaran, dan pengujian di lingkungan lab/praktikum**.

- Perangkat lunak ini disediakan dengan status **"AS IS" (Apa Adanya)**, tanpa jaminan performa, stabilitas, atau kesesuaian untuk lingkungan operasional tertentu.
- Pembuat repositori **tidak bertanggung jawab** atas segala kerusakan sistem operasi, kehilangan data, eror konfigurasi, downtime layanan, maupun kerugian lain yang mungkin timbul akibat eksekusi skrip installer atau uninstaller ini.
- Pengguna bertanggung jawab penuh atas segala tindakan eksekusi hak akses root (`sudo`) dan dianjurkan untuk selalu melakukan pencadangan (*backup*) berkala atau menjalankannya di lingkungan mesin virtual (*VM / Lab Sandbox*).

---

## Lisensi

Proyek ini didistribusikan di bawah naungan **[MIT License](LICENSE)**. Anda bebas menggunakan, memodifikasi, dan mendistribusikan ulang materi ini untuk kebutuhan belajar maupun pengembangan lebih lanjut.
