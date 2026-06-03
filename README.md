<div align="center">

```
  ███████╗████████╗███████╗██╗     ██╗      █████╗ ██████╗ 
  ██╔════╝╚══██╔══╝██╔════╝██║     ██║     ██╔══██╗██╔══██╗
  ███████╗   ██║   █████╗  ██║     ██║     ███████║██████╔╝
  ╚════██║   ██║   ██╔══╝  ██║     ██║     ██╔══██║██╔══██╗
  ███████║   ██║   ███████╗███████╗███████╗██║  ██║██║  ██║
  ╚══════╝   ╚═╝   ╚══════╝╚══════╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝
```

# Stellar Theme & SubDomain Manager
### Pterodactyl Panel Addon Installer

![License](https://img.shields.io/badge/license-MIT-blue?style=flat-square)
![Pterodactyl](https://img.shields.io/badge/pterodactyl-v1.x-blueviolet?style=flat-square)
![Shell](https://img.shields.io/badge/shell-bash-green?style=flat-square)

</div>

---

## 📦 Isi Repo

```
stellar/
├── installer.sh                    ← Script installer utama
└── releases/
    ├── Stellar_v3_3_Plus_MCPack_with_Subdomain.zip
    └── subdomains-manager-updated.zip
```

> ⚠️ **Pastikan** kedua file ZIP sudah ada di folder `releases/` sebelum menjalankan installer.

---

## ⚡ Quick Install

Jalankan perintah berikut di server kamu (sebagai root):

```bash
bash <(curl -s https://raw.githubusercontent.com/NebulaCloudID/stellar/main/installer.sh)
```

Atau dengan `wget`:

```bash
wget -O installer.sh https://raw.githubusercontent.com/NebulaCloudID/stellar/main/installer.sh
chmod +x installer.sh
sudo ./installer.sh
```

---

## 🔧 Requirements

| Requirement | Keterangan |
|---|---|
| OS | Ubuntu 20.04 / 22.04 |
| Panel | Pterodactyl v1.x |
| Panel Path | `/var/www/pterodactyl` |
| User | `root` atau `sudo` |
| Tools | `wget`, `unzip`, `php`, `composer`, `node`, `yarn` |

> Script akan otomatis install dependency yang belum ada.

---

## 🚀 Fitur

### 🎨 Stellar Theme
- Tampilan modern & responsif untuk Pterodactyl Panel
- Dark mode yang nyaman di mata
- Animasi & transisi halus

### 🌐 SubDomain Manager
- Kelola subdomain langsung dari panel
- Tambah / hapus subdomain untuk setiap server
- Terintegrasi dengan admin panel Pterodactyl

---

## 📋 Menu Installer

Setelah menjalankan installer, kamu akan melihat menu:

```
  [1] 🚀 Install
  [2] ⬆️  Upgrade
  [3] 🔄 Restore Backup
  [0] ❌ Exit
```

### Pilihan Install / Upgrade:

```
  [1] Stellar Theme + SubDomain Manager (Recommended)
  [2] Stellar Theme only
  [3] SubDomain Manager only
  [0] Cancel
```

---

## 🔄 Setelah Install

Setelah instalasi selesai, jalankan:

```bash
cd /var/www/pterodactyl
php artisan queue:restart
```

Lalu reload panel di browser.

---

## 💾 Backup

Installer otomatis membuat backup sebelum install/upgrade ke:

```
/var/www/pterodactyl-backups/<timestamp>/
```

Untuk restore backup, pilih opsi **[3] Restore Backup** di menu utama.

---

## ❓ Troubleshooting

### ❌ `Failed to download` ZIP
Pastikan file ZIP sudah ada di repo:
- `releases/Stellar_v3_3_Plus_MCPack_with_Subdomain.zip`
- `releases/subdomains-manager-updated.zip`

### ❌ `php artisan: Could not open input file`
Kamu menjalankan perintah di direktori yang salah. Gunakan:
```bash
cd /var/www/pterodactyl && php artisan queue:restart
```

### ❌ `Panel not found at /var/www/pterodactyl`
Edit variabel `PANEL_PATH` di baris 8 `installer.sh` sesuai lokasi panel kamu.

---

## 📜 License

MIT License — bebas digunakan dan dimodifikasi.

---

<div align="center">
Made with ❤️ by <a href="https://github.com/NebulaCloudID">NebulaCloudID</a>
</div>
