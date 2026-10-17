# Proxmox VE Lab Toolkit

Kumpulan skrip otomatisasi Bash untuk mempermudah operasional lab komputer berbasis Proxmox VE, mulai dari provisi akun siswa, pembuatan template LXC, hingga penyesuaian konfigurasi jaringan.

## Fitur Utama

- **Otomatisasi Akun Siswa**: Pembuatan dan penghapusan massal akun, user pool, serta izin ACL secara paralel per 10 antrean.
- **LXC Template Generator**: Pembersihan otomatis (apt cache, machine-id, history) dan pembuatan template kontainer Unprivileged siap pakai.
- **APT Cache Proxy Injector**: Menanamkan konfigurasi `apt-cacher-ng` ke dalam template rootfs melalui antarmuka TUI (whiptail).
- **Aktivasi LXC TUN**: Membuka akses interface TUN/TAP untuk kebutuhan lab VPN pada kontainer LXC.

## Prasyarat Sistem

- Proxmox VE 8.x / 9.x
- Hak akses `root` pada host PVE
- Paket pendukung:
  ```bash
  apt update && apt install -y whiptail zstd tar
