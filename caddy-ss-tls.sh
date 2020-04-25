#!/bin/bash
mkdir /etc/caddy
mkdir /etc/ssl/caddy
mkdir /var/www
isRoot() {
    if [[ "$EUID" -ne 0 ]]; then
        echo "false"
    else
        echo "true"
    fi
}
conf_caddy() {
    read -p "输入您的域名:" domainname
    read -p "域名输入正确吗？ (y/n)?: " answer
    if [ $answer != "y" ]; then
        read -p "重新输入域名:" domainname
    fi
    read -p "输入您的邮箱，为了申请tls证书用的:" emailname
    read -p "输入的邮箱正确吗？ (y/n)?: " answer
    if [ $answer != "y" ]; then
        echo "请重新输入您的邮箱："
        read emailname
    fi
    echo "http://$domainname:80 {
            redir https://$domainname:443{url}
         }
         https://$domainname:443 {
            gzip
            timeouts none
            tls $emailname
            root /var/www
            proxy / 127.0.0.1:8080
         }" >/etc/caddy/Caddyfile
}

install_supervisor() {
    yum install supervisor
    echo "[program:caddy]
command = /usr/local/bin/caddy -log stdout -agree=true -conf=/etc/caddy/Caddyfile
directory = /etc/caddy
autorstart=true
environment=CADDYPATH=/etc/ssl/caddy" >/etc/supervisord.d/caddy.ini
}
main() {
    isRoot=$(isRoot)
    if [[ "${isRoot}" != "true" ]]; then
        echo -e "${RED_COLOR}error:${NO_COLOR}Please run this script as as root"
        exit 1
    else
        conf_caddy
        install_supervisor
        systemctl enable supervisord             # 开机自启动
        systemctl start supervisord              # 启动supervisord服务 （supervisord -c /etc/supervisord.conf ）
        echo "caddy 安装和配置成功
            启动：supervisorctl start caddy
            停止：supervisorctl stop caddy
            重启：supervisorctl restart caddy
            查看状态：supervisorctl status"
    fi
}
main


