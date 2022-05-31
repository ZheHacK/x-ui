# X-ui Misaka-blog Revisi ajaib

panel xray dengan dukungan multi-protokol multi-pengguna

# Fitur

- Pemantauan Status Sistem
- Mendukung multi-pengguna multi-protokol, operasi visualisasi halaman web
- Protokol yang Didukung：vmess、vless、trojan、shadowsocks、dokodemo-door、socks、http
- Dukungan untuk mengonfigurasi lebih banyak konfigurasi transportasi
- Statistik lalu lintas, batasi lalu lintas, batasi waktu kedaluwarsa
- Templat konfigurasi xray yang dapat disesuaikan
- Mendukung panel akses https (nama domain yang disediakan sendiri + sertifikat ssl)
- VPS mendukung arsitektur amd64, arm64, s390x
- Mendukung panel pengingat Bot Telegram, informasi login SSH, penggunaan lalu lintas

# Fungsi yang diperluas
- Kueri setelan panel (diimplementasikan)
- Pengingat harian penggunaan lalu lintas (diimplementasikan)
- Pengingat masuk panel (diimplementasikan)
- Pengingat kedaluwarsa node (untuk diterapkan)
- Lebih banyak metode aplikasi sertifikat (untuk diterapkan)
- Pengaturan daftar putih login panel (akan diterapkan)

# instal atau tingkatkan perintah

```shell
wget -N --no-check-certificate https://raw.githubusercontents.com/ZheHacK/x-ui/master/install.sh && bash install.sh
```

## sistem saran

- CentOS 7+
- Ubuntu 16+
- Debian 8+

# masalah umum

## Bermigrasi dari v2-ui
Pertama-tama instal x-ui versi terbaru di server tempat v2-ui diinstal, lalu gunakan perintah berikut untuk bermigrasi, yang akan memigrasikan `semua data akun masuk` dari v2-ui lokal ke x-ui, `panel pengaturan dan nama pengguna dan kata sandi' tidak akan bermigrasi`
> Setelah migrasi berhasil, harap `close v2-ui` dan `restart x-ui`, jika tidak, inbound v2-ui akan memiliki konflik port dengan inbound x-ui`
```
x-ui v2-ui
```

# terima kasih daftar

X-ui asli：https://github.com/vaxilu/x-ui

Revisi ajaib FranzKafkaYu:：https://github.com/FranzKafkaYu/x-ui
