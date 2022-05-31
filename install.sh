#!/bin/bash

red() {
    echo -e "\033[31m\033[01m$1\033[0m"
}

green() {
    echo -e "\033[32m\033[01m$1\033[0m"
}

yellow() {
    echo -e "\033[33m\033[01m$1\033[0m"
}

REGEX=("debian" "ubuntu" "centos|red hat|kernel|oracle linux|alma|rocky" "'amazon linux'")
RELEASE=("Debian" "Ubuntu" "CentOS" "CentOS")
PACKAGE_UPDATE=("apt -y update" "apt -y update" "yum -y update" "yum -y update")
PACKAGE_INSTALL=("apt -y install" "apt -y install" "yum -y install" "yum -y install")
PACKAGE_UNINSTALL=("apt -y autoremove" "apt -y autoremove" "yum -y autoremove" "yum -y autoremove")

[[ $EUID -ne 0 ]] && red "Silakan jalankan skrip di bawah pengguna root" && exit 1

CMD=("$(grep -i pretty_name /etc/os-release 2>/dev/null | cut -d \" -f2)" "$(hostnamectl 2>/dev/null | grep -i system | cut -d : -f2)" "$(lsb_release -sd 2>/dev/null)" "$(grep -i description /etc/lsb-release 2>/dev/null | cut -d \" -f2)" "$(grep . /etc/redhat-release 2>/dev/null)" "$(grep . /etc/issue 2>/dev/null | cut -d \\ -f1 | sed '/^[ ]*$/d')")

for i in "${CMD[@]}"; do
    SYS="$i" && [[ -n $SYS ]] && break
done

for ((int = 0; int < ${#REGEX[@]}; int++)); do
    [[ $(echo "$SYS" | tr '[:upper:]' '[:lower:]') =~ ${REGEX[int]} ]] && SYSTEM="${RELEASE[int]}" && [[ -n $SYSTEM ]] && break
done

[[ -z $SYSTEM ]] && red "Sistem VPS saat ini tidak didukung, silakan gunakan sistem operasi utama" && exit 1

arch=$(arch)
os_version=$(grep -i version_id /etc/os-release | cut -d \" -f2 | cut -d . -f1)

if [[ $arch == "x86_64" || $arch == "x64" || $arch == "amd64" ]]; then
    arch="amd64"
elif [[ $arch == "aarch64" || $arch == "arm64" ]]; then
    arch="arm64"
elif [[ $arch == "s390x" ]]; then
    arch="s390x"
else
    echo -e "Arsitektur CPU tidak didukung! Script akan otomatis keluar！"
    rm -f install.sh
    exit 1
fi

if [ $(getconf WORD_BIT) != '32' ] && [ $(getconf LONG_BIT) != '64' ]; then
    echo "Panel X-ui tidak mendukung sistem 32-bit (x86), silakan gunakan sistem 64-bit (x86_64), jika deteksi salah, silakan hubungi penulis"
    rm -f install.sh
    exit -1
fi

if [[ $SYSTEM == "CentOS" ]]; then
    if [[ ${os_version} -le 6 ]]; then
        echo -e "Silakan gunakan CentOS 7 atau lebih tinggi！\n" && exit 1
    fi
elif [[ $SYSTEM == "Ubuntu" ]]; then
    if [[ ${os_version} -lt 16 ]]; then
        echo -e "Silakan gunakan Ubuntu 16 atau yang lebih baru！\n" && exit 1
    fi
elif [[ $SYSTEM == "Debian" ]]; then
    if [[ ${os_version} -lt 8 ]]; then
        echo -e "Silakan gunakan Debian 8 atau lebih tinggi！\n" && exit 1
    fi
fi

${PACKAGE_UPDATE[int]}
[[ -z $(type -P curl) ]] && ${PACKAGE_INSTALL[int]} curl
[[ -z $(type -P tar) ]] && ${PACKAGE_INSTALL[int]} tar

checkCentOS8(){
    if [[ -n $(cat /etc/os-release | grep "CentOS Linux 8") ]]; then
        yellow "Terdeteksi bahwa sistem VPS saat ini adalah CentOS 8. Apakah Anda ingin mengupgrade ke CentOS Stream 8 untuk memastikan bahwa paket-paket diinstal secara normal?"
        read -p "Silakan masukkan opsi [y/n]：" comfirmCentOSStream
        if [[ $comfirmCentOSStream == "y" ]]; then yellow "Meningkatkan ke CentOS Stream 8 untuk Anda, ini akan memakan waktu sekitar 10-30 menit"

            sleep 1
            sed -i -e "s|releasever|releasever-stream|g" /etc/yum.repos.d/CentOS-*
            yum clean all && yum makecache
            dnf swap centos-linux-repos centos-stream-repos distro-sync -y
        else
            red "Proses peningkatan dibatalkan, skrip akan segera keluar！"
            exit 1
        fi
    fi
}

config_after_install() {
    yellow "Untuk alasan keamanan, perlu untuk secara paksa mengubah port dan kata sandi akun setelah instalasi/pembaruan selesai."
    read -p "Konfirmasi apakah akan melanjutkan?[y/n]": config_confirm
    if [[ x"${config_confirm}" == x"y" || x"${config_confirm}" == x"Y" ]]; then
        read -p "Silakan atur nama akun Anda:" config_account
        read -p "Silakan setel kata sandi akun Anda:" config_password
        read -p "Silakan atur port akses panel:" config_port
        yellow "Silakan periksa informasi login panel sudah benar："
        green "Nama akun Anda akan disetel ke:${config_account}"
        green "Kata sandi akun Anda akan disetel ke:${config_password}"
        green "Port akses panel Anda akan disetel ke:${config_port}"
        read -p "Konfirmasi pengaturan selesai？[y/n]": config_confirm
        if [[ x"${config_confirm}" == x"y" || x"${config_confirm}" == x"Y" ]]; then
            yellow "Konfirmasi pengaturan, pengaturan sedang berlangsung"
            /usr/local/x-ui/x-ui setting -username ${config_account} -password ${config_password}
            /usr/local/x-ui/x-ui setting -port ${config_port}
        else
            red "Dibatalkan, semua item pengaturan adalah pengaturan default, harap ubah tepat waktu"
        fi
    else
        red "Dibatalkan, semua item pengaturan adalah pengaturan default, harap ubah tepat waktu"
    fi
}

install_x-ui() {
    systemctl stop x-ui
    if [ $# == 0 ]; then
        last_version=$(curl -Ls "https://api.github.com/repos/Misaka-blog/x-ui/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
        if [[ ! -n "$last_version" ]]; then
            red "Gagal mendeteksi versi x-ui, mungkin batas API Github terlampaui, silakan coba lagi nanti, atau tentukan versi x-ui yang akan diinstal secara manual"
            rm -f install.sh
            exit 1
        fi
        yellow "x-ui versi terbaru terdeteksi：${last_version}，mulai instalasi"
        wget -N --no-check-certificate -O /usr/local/x-ui-linux-${arch}.tar.gz https://github.com/Misaka-blog/x-ui/releases/download/${last_version}/x-ui-linux-${arch}.tar.gz
        if [[ $? -ne 0 ]]; then
            red "Gagal mengunduh x-ui, pastikan server Anda dapat terhubung dan mengunduh file Github"
            rm -f install.sh
            exit 1
        fi
    else
        last_version=$1
        url="https://github.com/Misaka-blog/x-ui/releases/download/${last_version}/x-ui-linux-${arch}.tar.gz"
        yellow "mulai menginstal x-ui v$1"
        wget -N --no-check-certificate -O /usr/local/x-ui-linux-${arch}.tar.gz ${url}
        if [[ $? -ne 0 ]]; then
            red "unduh x-ui v$1 gagal, pastikan versi ini ada"
            rm -f install.sh
            exit 1
        fi
    fi
    if [[ -e /usr/local/x-ui/ ]]; then
        rm -rf /usr/local/x-ui/
    fi
    cd /usr/local/
    tar zxvf x-ui-linux-${arch}.tar.gz
    rm x-ui-linux-${arch}.tar.gz -f
    cd x-ui
    chmod +x x-ui bin/xray-linux-${arch}
    cp -f x-ui.service /etc/systemd/system/
    wget --no-check-certificate -O /usr/bin/x-ui https://raw.githubusercontents.com/ZheHacK/x-ui/main/x-ui.sh
    chmod +x /usr/local/x-ui/x-ui.sh
    chmod +x /usr/bin/x-ui
    config_after_install
    systemctl daemon-reload
    systemctl enable x-ui
    systemctl start x-ui
    cd /root
    rm -f install.sh
    green "x-ui v${last_version} Instalasi selesai, panel diluncurkan"
    echo -e ""
    echo -e "Cara menggunakan skrip manajemen x-ui: "
    echo -e "----------------------------------------------"
    echo -e "x-ui              - Menampilkan menu manajemen (dengan lebih banyak fungsi)"
    echo -e "x-ui start        - Mulai panel x-ui"
    echo -e "x-ui stop         - hentikan panel x-ui"
    echo -e "x-ui restart      - mulai ulang panel x-ui"
    echo -e "x-ui status       - Lihat status x-ui"
    echo -e "x-ui enable       - Atur x-ui untuk memulai secara otomatis saat boot"
    echo -e "x-ui disable      - Batalkan mulai otomatis boot x-ui"
    echo -e "x-ui log          - Lihat log x-ui"
    echo -e "x-ui v2-ui        - Migrasikan data akun v2-ui mesin ini ke x-ui"
    echo -e "x-ui update       - Perbarui panel x-ui"
    echo -e "x-ui install      - instal panel x-ui"
    echo -e "x-ui uninstall    - hapus instalan panel x-ui"
    echo -e "----------------------------------------------"
}

checkCentOS8
install_x-ui $1
