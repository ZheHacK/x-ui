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

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
PLAIN='\033[0m'

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

os_version=$(grep -i version_id /etc/os-release | cut -d \" -f2 | cut -d . -f1)

if [[ $SYSTEM == "CentOS" ]]; then
    if [[ ${os_version} -le 6 ]]; then
        red "Silakan gunakan CentOS 7 atau lebih tinggi！\n" && exit 1
    fi
elif [[ $SYSTEM == "Ubuntu" ]]; then
    if [[ ${os_version} -lt 16 ]]; then
        red "Silakan gunakan Ubuntu 16 atau yang lebih baru！\n" && exit 1
    fi
elif [[ $SYSTEM == "Debian" ]]; then
    if [[ ${os_version} -lt 8 ]]; then
        red "Silakan gunakan Debian 8 atau lebih tinggi！\n" && exit 1
    fi
fi

confirm() {
    if [[ $# > 1 ]]; then
        echo && read -p "$1 [默认$2]: " temp
        if [[ x"${temp}" == x"" ]]; then
            temp=$2
        fi
    else
        read -p "$1 [y/n]: " temp
    fi
    if [[ x"${temp}" == x"y" || x"${temp}" == x"Y" ]]; then
        return 0
    else
        return 1
    fi
}

confirm_restart() {
    confirm "Apakah akan memulai ulang panel X-ui, memulai ulang panel juga akan memulai ulang xray" "y"
    if [[ $? == 0 ]]; then
        restart
    else
        show_menu
    fi
}

before_show_menu() {
    echo && echo -n -e "${YELLOW}Tekan Enter untuk kembali ke menu utama: ${PLAIN}" && read temp
    show_menu
}

install() {
    bash <(curl -Ls https://raw.githubusercontents.com/ZheHacK/x-ui/master/install.sh)
    if [[ $? == 0 ]]; then
        if [[ $# == 0 ]]; then
            start
        else
            start 0
        fi
    fi
}

update() {
    confirm "Fungsi ini akan memaksa menginstal ulang versi terbaru dari panel X-ui, data tidak akan hilang, apakah akan melanjutkan?" "n"
    if [[ $? != 0 ]]; then
        red "Dibatalkan"
        if [[ $# == 0 ]]; then
            before_show_menu
        fi
        return 0
    fi
    bash <(curl -Ls https://raw.githubusercontents.com/Misaka-blog/x-ui/master/install.sh)
    if [[ $? == 0 ]]; then
        green "Pembaruan selesai, panel telah dimulai ulang secara otomatis "
        exit 0
    fi
}

uninstall() {
    confirm "Apakah Anda yakin ingin mencopot pemasangan panel X-ui, xray juga akan dicopot?" "n"
    if [[ $? != 0 ]]; then
        if [[ $# == 0 ]]; then
            show_menu
        fi
        return 0
    fi
    systemctl stop x-ui
    systemctl disable x-ui
    rm /etc/systemd/system/x-ui.service -f
    systemctl daemon-reload
    systemctl reset-failed
    rm /etc/x-ui/ -rf
    rm /usr/local/x-ui/ -rf
    echo -e "Copot pemasangan panel X-ui berhasil"
    rm /usr/bin/x-ui -f

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

reset_user() {
    confirm "Apakah Anda yakin ingin mengatur ulang nama pengguna dan kata sandi panel ke admin" "n"
    if [[ $? != 0 ]]; then
        if [[ $# == 0 ]]; then
            show_menu
        fi
        return 0
    fi
    /usr/local/x-ui/x-ui setting -username admin -password admin
    echo -e "Nama pengguna dan kata sandi panel diatur ulang ke ${GREEN}admin${PLAIN}，Silakan restart panel sekarang"
    confirm_restart
}

reset_config() {
    confirm "Apakah Anda yakin ingin mengatur ulang semua pengaturan?，Data akun tidak akan hilang, username dan password tidak akan diubah" "n"
    if [[ $? != 0 ]]; then
        if [[ $# == 0 ]]; then
            show_menu
        fi
        return 0
    fi
    /usr/local/x-ui/x-ui setting -reset
    echo -e "Semua pengaturan panel telah diatur ulang ke default, silakan restart panel dan gunakan default ${GREEN}54321${PLAIN} Panel Akses Port"
    confirm_restart
}

set_port() {
    echo && echo -n -e "Masukkan nomor port[1-65535]: " && read port
    if [[ -z "${port}" ]]; then
        yellow "Dibatalkan"
        before_show_menu
    else
        /usr/local/x-ui/x-ui setting -port ${port}
        echo -e "Setelah mengatur port, silakan restart panel dan gunakan port yang baru disetel ${GREEN}${port}${PLAIN} panel akses"
        confirm_restart
    fi
}

start() {
    check_status
    if [[ $? == 0 ]]; then
        echo ""
        green "Panel X-ui sudah berjalan, tidak perlu memulai lagi, jika Anda perlu memulai ulang, silakan pilih mulai ulang"
    else
        systemctl start x-ui
        sleep 2
        check_status
        if [[ $? == 0 ]]; then
            green "Panel X-ui berhasil dimulai"
        else
            red "Panel X-ui gagal memulai, mungkin karena waktu startup melebihi dua detik, silakan periksa informasi log nanti"
        fi
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

stop() {
    check_status
    if [[ $? == 1 ]]; then
        echo ""
        green "Panel X-ui telah berhenti, tidak perlu berhenti lagi"
    else
        systemctl stop x-ui
        sleep 2
        check_status
        if [[ $? == 1 ]]; then
            green "X-ui dan xray berhasil dihentikan"
        else
            red "Panel X-ui gagal berhenti, mungkin karena waktu berhenti melebihi dua detik, silakan periksa informasi log nanti"
        fi
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

restart() {
    systemctl restart x-ui
    sleep 2
    check_status
    if [[ $? == 0 ]]; then
        green "X-ui dan xray berhasil dimulai ulang"
    else
        red "Panel X-ui gagal restart, mungkin karena waktu startup melebihi dua detik, silakan periksa informasi log nanti"
    fi
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

status() {
    systemctl status x-ui -l
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

enable_xui() {
    systemctl enable x-ui
    if [[ $? == 0 ]]; then
        green "X-ui mengatur boot untuk memulai dengan sukses"
    else
        red "X-ui gagal menyetel mulai otomatis saat boot"
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

disable_xui() {
    systemctl disable x-ui
    if [[ $? == 0 ]]; then
        green "X-ui membatalkan boot otomatis dengan sukses"
    else
        red "X-ui gagal membatalkan boot auto-start"
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

show_log() {
    journalctl -u x-ui.service -e --no-pager -f
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

migrate_v2_ui() {
    /usr/local/x-ui/x-ui v2-ui

    before_show_menu
}

install_bbr() {
    # temporary workaround for installing bbr
    bash <(curl -L -s https://raw.githubusercontents.com/teddysun/across/master/bbr.sh)
    echo ""
    before_show_menu
}

update_shell() {
    wget -O /usr/bin/x-ui -N --no-check-certificate https://github.com/Misaka-blog/x-ui/raw/master/x-ui.sh
    if [[ $? != 0 ]]; then
        echo ""
        red "Gagal mengunduh skrip, harap periksa apakah mesin dapat terhubung ke Github"
        before_show_menu
    else
        chmod +x /usr/bin/x-ui
        green "Skrip pemutakhiran berhasil, jalankan kembali skrip" && exit 0
    fi
}

# 0: running, 1: not running, 2: not installed
check_status() {
    if [[ ! -f /etc/systemd/system/x-ui.service ]]; then
        return 2
    fi
    temp=$(systemctl status x-ui | grep Active | awk '{print $3}' | cut -d "(" -f2 | cut -d ")" -f1)
    if [[ x"${temp}" == x"running" ]]; then
        return 0
    else
        return 1
    fi
}

check_enabled() {
    temp=$(systemctl is-enabled x-ui)
    if [[ x"${temp}" == x"enabled" ]]; then
        return 0
    else
        return 1
    fi
}

check_uninstall() {
    check_status
    if [[ $? != 2 ]]; then
        echo ""
        red "Panel X-ui sudah terpasang, mohon jangan dipasang lagi"
        if [[ $# == 0 ]]; then
            before_show_menu
        fi
        return 1
    else
        return 0
    fi
}

check_install() {
    check_status
    if [[ $? == 2 ]]; then
        echo ""
        red "Silakan instal panel X-ui terlebih dahulu "
        if [[ $# == 0 ]]; then
            before_show_menu
        fi
        return 1
    else
        return 0
    fi
}

show_status() {
    check_status
    case $? in
    0)
        echo -e "status panel: ${GREEN}telah dijalankan${PLAIN}"
        show_enable_status
        ;;
    1)
        echo -e "status panel: ${YELLOW}tidak berjalan${PLAIN}"
        show_enable_status
        ;;
    2)
        echo -e "status panel: ${RED}Tidak terpasang${PLAIN}"
        ;;
    esac
    show_xray_status
}

show_enable_status() {
    check_enabled
    if [[ $? == 0 ]]; then
        echo -e "Apakah akan memulai secara otomatis: ${GREEN}是${PLAIN}"
    else
        echo -e "Apakah akan memulai secara otomatis: ${RED}否${PLAIN}"
    fi
}

check_xray_status() {
    count=$(ps -ef | grep "xray-linux" | grep -v "grep" | wc -l)
    if [[ count -ne 0 ]]; then
        return 0
    else
        return 1
    fi
}

show_xray_status() {
    check_xray_status
    if [[ $? == 0 ]]; then
        echo -e "status xray: ${GREEN}berjalan${PLAIN}"
    else
        echo -e "status xray: ${RED}tidak berjalan${PLAIN}"
    fi
}

ssl_cert_issue() {
    wget -N https://raw.githubusercontents.com/Misaka-blog/acme-1key/master/acme1key.sh && bash acme1key.sh
}

open_ports(){
    systemctl stop firewalld.service
    systemctl disable firewalld.service
    setenforce 0
    ufw disable
    iptables -P INPUT ACCEPT
    iptables -P FORWARD ACCEPT
    iptables -P OUTPUT ACCEPT
    iptables -t nat -F
    iptables -t mangle -F 
    iptables -F
    iptables -X
    netfilter-persistent save
    yellow "Semua port jaringan di VPS terbuka"
}

show_usage() {
    echo "Cara menggunakan skrip manajemen x-ui: "
    echo "------------------------------------------"
    echo "x-ui              - Menampilkan menu manajemen (dengan lebih banyak fungsi)"
    echo "x-ui start        - Mulai panel x-ui"
    echo "x-ui stop         - hentikan panel x-ui"
    echo "x-ui restart      - mulai ulang panel x-ui"
    echo "x-ui status       - Lihat status x-ui"
    echo "x-ui enable       - Atur x-ui untuk memulai secara otomatis saat boot"
    echo "x-ui disable      - Batalkan mulai otomatis boot x-ui"
    echo "x-ui log          - Lihat log x-ui"
    echo "x-ui v2-ui        - Migrasikan data akun v2-ui mesin ini ke x-ui"
    echo "x-ui update       - Perbarui panel x-ui"
    echo "x-ui install      - instal panel x-ui"
    echo "x-ui uninstall    - hapus instalan panel x-ui"
    echo "------------------------------------------"
}

show_menu() {
    echo -e "
  ${GREEN}Srip Manajemen Panel X-ui${PLAIN}
  ${GREEN}0.${PLAIN} keluar skrip
————————————————
  ${GREEN}1.${PLAIN} Instal X-ui
  ${GREEN}2.${PLAIN} Perbarui X-ui
  ${GREEN}3.${PLAIN} Hapus Instalan X-ui
————————————————
  ${GREEN}4.${PLAIN} Atur Ulang Kata Sandi Nama Pengguna
  ${GREEN}5.${PLAIN} setel ulang pengaturan panel
  ${GREEN}6.${PLAIN} Siapkan port panel
————————————————
  ${GREEN}7.${PLAIN} mulai x-ui
  ${GREEN}8.${PLAIN} hentikan x-ui
  ${GREEN}9.${PLAIN} mulai ulang x-ui
 ${GREEN}10.${PLAIN} Lihat status x-ui
 ${GREEN}11.${PLAIN} Lihat log x-ui
————————————————
 ${GREEN}12.${PLAIN} Atur x-ui untuk memulai secara otomatis saat boot
 ${GREEN}13.${PLAIN} Batalkan mulai otomatis boot x-ui
————————————————
 ${GREEN}14.${PLAIN} 一kunci instal bbr (kernel terbaru)
 ${GREEN}15.${PLAIN} 一kunci untuk mengajukan sertifikat SSL (aplikasi acme)
 ${GREEN}16.${PLAIN} Firewall VPS membuka semua port jaringan
 "
    show_status
    echo && read -p "Silakan masukkan pilihan [0-16]: " num

    case "${num}" in
        0) exit 0 ;;
        1) check_uninstall && install ;;
        2) check_install && update ;;
        3) check_install && uninstall ;;
        4) check_install && reset_user ;;
        5) check_install && reset_config ;;
        6) check_install && set_port ;;
        7) check_install && start ;;
        8) check_install && stop ;;
        9) check_install && restart ;;
        10) check_install && status ;;
        11) check_install && show_log ;;
        12) check_install && enable_xui ;;
        13) check_install && disable_xui ;;
        14) install_bbr ;;
        15) ssl_cert_issue ;;
        16) open_ports ;;
        *) red "Silakan masukkan nomor yang benar [0-16]" ;;
    esac
}

if [[ $# > 0 ]]; then
    case $1 in
    "start") check_install 0 && start 0 ;;
    "stop") check_install 0 && stop 0 ;;
    "restart") check_install 0 && restart 0 ;;
    "status") check_install 0 && status 0 ;;
    "enable") check_install 0 && enable_xui 0 ;;
    "disable") check_install 0 && disable_xui 0 ;;
    "log") check_install 0 && show_log 0 ;;
    "v2-ui") check_install 0 && migrate_v2_ui 0 ;;
    "update") check_install 0 && update 0 ;;
    "install") check_uninstall 0 && install 0 ;;
    "uninstall") check_install 0 && uninstall 0 ;;
    *) show_usage ;;
    esac
else
    show_menu
fi
