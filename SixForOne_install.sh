#!/bin/bash
#=================================================
#	System Required: :Debian 9+/Ubuntu 18.04+/Centos 7+
#	Description: Trojan&V2ray&SSR script
#	Version: 1.0.0
#	Author: Jeannie
#	Blog: https://jeanniestudio.top/
# Official document: www.v2ray.com
#=================================================
sh_ver="1.0.0"
#fonts color
RED="\033[0;31m"
NO_COLOR="\033[0m"
GREEN="\033[32m\033[01m"
FUCHSIA="\033[0;35m"
YELLOW="\033[33m"
BLUE="\033[0;36m"
GreenBG="\033[42;37m"
RedBG="\033[41;37m"
Font="\033[0m"
Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[信息]${Font_color_suffix}"
Error="${Red_font_prefix}[错误]${Font_color_suffix}"
Tip="${Green_font_prefix}[注意]${Font_color_suffix}"
nginx_bin_file="/usr/sbin/nginx"
nginx_conf_dir="/etc/nginx/conf.d"
nginx_conf="${nginx_conf_dir}/default.conf"
nginx_dir="/etc/nginx"
v2ray_bin_dir="/usr/bin/v2ray"
v2ray_systemd_file="/etc/systemd/system/v2ray.service"
v2ray_conf_dir="/etc/v2ray"
v2ray_conf="${v2ray_conf_dir}/config.json"
v2ray_shadowrocket_qr_config_file="${v2ray_conf_dir}/shadowrocket_qrconfig.json"
v2ray_win_and_android_qr_config_file="${v2ray_conf_dir}/win_and_android_qrconfig.json"
caddy_bin_dir="/usr/local/bin"
caddy_conf_dir="/etc/caddy"
caddy_conf="${caddy_conf_dir}/Caddyfile"
caddy_systemd_file="/etc/systemd/system/caddy.service"
trojan_bin_dir="/usr/local/bin/trojan"
trojan_conf_dir="/usr/local/etc/trojan"
trojan_conf="${trojan_conf_dir}/config.json"
trojan_qr_config_file="${trojan_conf_dir}/qrconfig.json"
trojan_systemd_file="/etc/systemd/system/trojan.service"
ssr_conf_dir="/etc/shadowsocks-r"
ssr_conf="${ssr_conf_dir}/config.json"
ssr_qr_config_file="${ssr_conf_dir}/qrconfig.json"
ssr_systemd_file="/etc/init.d/shadowsocks-r"
ssr_bin_dir="/usr/local/shadowsocks"
web_dir="/usr/wwwroot"
set_SELINUX() {
  if [ -s /etc/selinux/config ] && grep 'SELINUX=enforcing' /etc/selinux/config; then
    sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
    setenforce 0
  fi
}
set_PATH() {
  [[ -z "$(grep "export PATH=/bin:/sbin:" /etc/bashrc)" ]] && echo "export PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin" >>/etc/bashrc && source /etc/profile
}
check_root() {
  [[ $EUID != 0 ]] && echo -e "${Error} 当前非ROOT账号(或没有ROOT权限)，无法继续操作，请执行命令 ${Green_background_prefix}sudo -i${Font_color_suffix} 更换ROOT账号" && exit 1
}
check_nginx_pid() {
  PID=$(ps -ef | grep "nginx" | grep -v "grep" | grep -v "init.d" | grep -v "service" | awk '{print $2}')
  [[ ! -z ${PID} ]] && kill -9 ${PID}
}
check_caddy_pid() {
  PID=$(ps -ef | grep "caddy" | grep -v "grep" | grep -v "init.d" | grep -v "service" | awk '{print $2}')
  [[ ! -z ${PID} ]] && kill -9 ${PID}
}
check_v2ray_pid() {
  PID=$(ps -ef | grep "v2ray" | grep -v "grep" | grep -v "init.d" | grep -v "service" | awk '{print $2}')
  [[ ! -z ${PID} ]] && kill -9 ${PID}
}
check_ssr_pid() {
  PID=$(ps -ef | grep "ssr" | grep -v "grep" | grep -v "init.d" | grep -v "service" | awk '{print $2}')
  [[ ! -z ${PID} ]] && kill -9 ${PID}
}
check_trojan_pid() {
  PID=$(ps -ef | grep "trojan" | grep -v "grep" | grep -v "init.d" | grep -v "service" | awk '{print $2}')
  [[ ! -z ${PID} ]] && kill -9 ${PID}
}
check_sys() {
  if [[ -f /etc/redhat-release ]]; then
    release="centos"
  elif cat /etc/issue | grep -q -E -i "debian"; then
    release="debian"
  elif cat /etc/issue | grep -q -E -i "ubuntu"; then
    release="ubuntu"
  elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
    release="centos"
  elif cat /proc/version | grep -q -E -i "debian"; then
    release="debian"
  elif cat /proc/version | grep -q -E -i "ubuntu"; then
    release="ubuntu"
  elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
    release="centos"
  fi
  #bit=`uname -m`
}

get_ip() {
  local_ip=$(curl -s https://ipinfo.io/ip)
  [[ -z ${local_ip} ]] && ${local_ip}=$(curl -s https://api.ip.sb/ip)
  [[ -z ${local_ip} ]] && ${local_ip}=$(curl -s https://api.ipify.org)
  [[ -z ${local_ip} ]] && ${local_ip}=$(curl -s https://ip.seeip.org)
  [[ -z ${local_ip} ]] && ${local_ip}=$(curl -s https://ifconfig.co/ip)
  [[ -z ${local_ip} ]] && ${local_ip}=$(curl -s https://api.myip.com | grep -oE "([0-9]{1,3}\.){3}[0-9]{1,3}")
  [[ -z ${local_ip} ]] && ${local_ip}=$(curl -s icanhazip.com)
  [[ -z ${local_ip} ]] && ${local_ip}=$(curl -s myip.ipip.net | grep -oE "([0-9]{1,3}\.){3}[0-9]{1,3}")
  [[ -z ${local_ip} ]] && echo -e "${Error}获取不到你vps的ip地址" && exit
}
check_domain() {
  read -p "请输入您的域名(如果用Cloudflare解析域名，请点击小云彩使其变灰):" domain
  real_ip=$(ping ${domain} -c 1 | sed '1{s/[^(]*(//;s/).*//;q}')
  while [ "${real_ip}" != "${local_ip}" ]; do
    read -p "本机IP和域名绑定的IP不一致，请检查域名是否解析成功,并重新输入域名:" domain
    real_ip=$(ping ${domain} -c 1 | sed '1{s/[^(]*(//;s/).*//;q}')
  done
}
check_nginx_installed_status() {
  if [[ -f ${nginx_bin_file} ]] && [[ -d ${nginx_dir} ]] && [[ -f ${nginx_conf} ]]; then
    echo -e "${Info}检测到您已经安装了Nginx!"
    nginx_install_flag="YES"
  fi
}
check_trojan_installed_status() {
  if [[ -f ${trojan_bin_dir} ]] && [[ -d ${trojan_conf_dir} ]] && [[ -f ${trojan_systemd_file} ]]; then
    echo -e "${Info}检测到您已经安装了Trojan!"
    trojan_install_flag="YES"
  fi
}
check_v2ray_installed_status() {
  if [[ -d ${v2ray_bin_dir} ]] && [[ -f ${v2ray_systemd_file} ]] && [[ -d ${v2ray_conf_dir} ]]; then
    echo -e "${Info}检测到您已经安装了V2ray!"
    v2ray_install_flag="YES"
  fi
}
check_ssr_installed_status() {
  if [[ -d ${ssr_conf_dir} ]] && [[ -f ${ssr_systemd_file} ]] && [[ -d ${ssr_bin_dir} ]]; then
    echo -e "${Info}检测到您已经安装了SSR!"
    ssr_install_flag="YES"
  fi
}
check_caddy_installed_status() {
  if [[ -d ${caddy_bin_dir} ]] && [[ -f ${caddy_systemd_file} ]] && [[ -d ${caddy_conf_dir} ]]; then
    echo -e "${Info}检测到您已经安装了Caddy!"
    caddy_install_flag="YES"
  fi
}
uninstall_nginx() {
  if [[ -f ${nginx_bin_file} ]] || [[ -d ${nginx_dir} ]] || [[ -f ${nginx_conf} ]]; then
    nginx -s stop
    echo -e "${Info}开始卸载Nginx……"
    if [[ ${release} == "centos" ]]; then
      yum autoremove -y nginx
      rm -rf ${nginx_dir}
    else
      apt-get autoremove -y --purge nginx # 自动删除安装nginx时安装的依赖包和/etc/nginx
      rm -rf ${nginx_dir}
    fi
    echo -e "${Info}Nginx卸载成功！"
  fi
}
uninstall_v2ray() {
  if [[ -d ${v2ray_bin_dir} ]] || [[ -f ${v2ray_systemd_file} ]] || [[ -d ${v2ray_conf_dir} ]]; then
    echo -e "${Info}开始卸载V2ray……"
    [[ -f ${v2ray_systemd_file} ]] && service v2ray stop && rm -f ${v2ray_systemd_file}
    [[ -d ${v2ray_bin_dir} ]] && rm -rf ${v2ray_bin_dir}
    [[ -d ${v2ray_conf_dir} ]] && rm -rf ${v2ray_conf_dir}
    echo -e "${Info}V2ray卸载成功！"
  fi
}
uninstall_caddy() {
  if [[ -f ${caddy_bin_dir}/caddy ]] || [[ -f ${caddy_systemd_file} ]] || [[ -d ${caddy_conf_dir} ]] || [[ -f ${caddy_bin_dir}/caddy_old ]]; then
    echo -e "${Info}开始卸载Caddy……"
    [[ -f ${caddy_bin_dir}/caddy ]] && caddy -service stop && rm -f ${caddy_bin_dir}/caddy
    [[ -f ${caddy_bin_dir}/caddy_old ]] && rm -f ${caddy_bin_dir}/caddy_old
    [[ -d ${caddy_conf_dir} ]] && rm -rf ${caddy_conf_dir}
    [[ -f ${caddy_systemd_file} ]] && rm -f ${caddy_systemd_file}
    echo -e "${Info}Caddy卸载成功！"
  fi
}
uninstall_web() {
  [[ -d ${web_dir} ]] && rm -rf ${web_dir} && echo -e "${Info}开始删除伪装网站……" && echo -e "${Info}伪装网站删除成功！"
}
uninstall_trojan() {
  if [[ -f ${trojan_bin_dir} ]] || [[ -d ${trojan_conf_dir} ]] || [[ -f ${trojan_systemd_file} ]]; then
    systemctl stop trojan
    echo -e "${Info}开始卸Trojan……！"
    [[ -f ${trojan_bin_dir} ]] && rm -f ${trojan_bin_dir}
    [[ -f ${trojan_systemd_file} ]] && rm -f ${trojan_systemd_file}
    [[ -d ${trojan_conf_dir} ]] && rm -rf ${trojan_conf_dir}
    echo -e "${Info}Trojan卸载成功！"
  fi
}
uninstall_ssr() {
  if [[ -d ${ssr_conf_dir} ]] || [[ -f ${ssr_systemd_file} ]] || [[ -d ${ssr_bin_dir} ]]; then
    /etc/init.d/shadowsocks-r stop
    echo -e "${Info}开始卸载SSR……！"
    /etc/shadowsocks-r/shadowsocks-all.sh uninstall
    [[ -f ${ssr_bin_dir} ]] && rm -f ${ssr_bin_dir}
    [[ -f ${ssr_systemd_file} ]] && rm -f ${ssr_systemd_file}
    [[ -f ${ssr_conf_dir} ]] && rm -f ${ssr_conf_dir}
    echo -e "${Info}SSR卸载成功！"
  fi
}
remove_mgr(){
  [[ -f "/etc/all_mgr.sh" ]] && rm -f /etc/all_mgr.sh
}
install_v2ray() {
  if [[ ${trojan_install_flag} == "YES" ]]; then
    echo -e "${Info}开始安装v2ray……"
    bash <(curl -L -s https://install.direct/go.sh)
  fi
}

install_dependency() {
  if [[ ${release} == "centos" ]]; then
    echo -e "${Info}开始升级系统，需要花费几分钟……"
    yum update -y
    echo -e "${Info}开始安装依赖……"
    yum -y install bind-utils wget unzip zip curl tar git crontabs libpng libpng-devel qrencode firewalld
    yum install -y epel-release
    sleep 3
    yum install -y certbot
  else
    echo -e "${Info}开始升级系统，需要花费几分钟……"
    apt-get update -y
    echo -e "${Info}开始安装依赖……"
    apt-get install -y dnsutils wget unzip zip curl tar git qrencode cron firewalld ufw
    sleep 2
    apt-get install -y certbot
  fi
  ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
}
close_firewall() {
  if [[ ${release} == "centos" ]]; then
    systemctl stop firewalld.service
    systemctl disable firewalld.service
  else
    ufw disable
  fi
}
install_nginx() {
  if [[ ${nginx_install_flag} = "YES" ]]; then
    read -p "$(echo -e "${Tip}是否重新安装（Y/n）?(默认：n)")" Yn
    [[ -z ${Yn} ]] && Yn="n"
    while [[ ${Yn} != "Y" ]] && [[ ${Yn} != "y" ]] && [[ ${Yn} != "n" ]]; do
        read -p "$(echo -e "${Tip}输入错误，重新输入：(默认：n)")" Yn
        [[ -z ${Yn} ]] && Yn="n"
    done
    if [[ ${Yn} == "Y" ]] || [[ ${Yn} == "y" ]]; then
      if [[ ${release} == "centos" ]]; then
        echo -e "${Info}开始安装Nginx……"
        yum -y install nginx
      else
        echo -e "${Info}开始安装Nginx……"
        apt-get -y install nginx
      fi
    fi
  else
    echo -e "${Info}开始安装Nginx……"
    if [[ ${release} == "centos" ]]; then
      yum -y install nginx
    else
      apt-get -y install nginx
    fi
  fi
}
install_caddy() {
  if [[ ${caddy_install_flag} == "YES" ]]; then
    read -p "$(echo -e "${Tip}是否重新安装（Y/n）?(默认：n)")" Yn
    [[ -z ${Yn} ]] && Yn="n"
    while [[ ${Yn} != "Y" ]] && [[ ${Yn} != "y" ]] && [[ ${Yn} != "n" ]]; do
        read -p "$(echo -e "${Tip}输入错误，重新输入：(默认：n)")" Yn
        [[ -z ${Yn} ]] && Yn="n"
    done
    if [[ ${Yn} == "Y" ]] || [[ ${Yn} == "y" ]]; then
      echo -e "${Info}开始安装caddy……"
      curl https://getcaddy.com | bash -s personal hook.service
    fi
  else
      echo -e "${Info}开始安装caddy……"
      curl https://getcaddy.com | bash -s personal hook.service
  fi
}
install_caddy_service(){
  rm -f ${caddy_systemd_file}
  #if [[ ${email} == "" ]]; then
  #  read -p "$(echo -e "${Info}请填写您的邮箱：")" email
  #  read -p "$(echo -e "${Info}邮箱输入正确吗（Y/n）？（默认：n）")" Yn
  #  [[ -z ${Yn} ]] && Yn="n"
  #  while [[ ${Yn} != "Y" ]] && [[ ${Yn} != "y" ]]; do
  #      read -p "$(echo -e "${Tip}重新填写您的邮箱：")" email
  #      read -p "$(echo -e "${Info}邮箱输入正确吗（Y/n）？（默认：n）")" Yn
  #      [[ -z ${Yn} ]] && Yn="n"
  #  done
 #fi
 #caddy -service install -agree -email "${email}" -conf "${caddy_conf}"
 caddy -service install -agree -email "example@gmail.com" -conf "${caddy_conf}"
}
install_trojan() {
  if [[ ${trojan_install_flag} == "YES" ]] ; then
    read -p "$(echo -e "${Tip}是否重新安装（Y/n）?(默认：n)")" Yn
    [[ -z ${Yn} ]] && Yn="n"
    while [[ ${Yn} != "Y" ]] && [[ ${Yn} != "y" ]] && [[ ${Yn} != "n" ]]; do
        read -p "$(echo -e "${Tip}输入错误，重新输入：(默认：n)")" Yn
        [[ -z ${Yn} ]] && Yn="n"
    done
    if [[ ${Yn} == "Y" ]] || [[ ${Yn} == "y" ]]; then
      echo -e "${Info}开始安装Trojan……"
      bash -c "$(curl -fsSL https://raw.githubusercontent.com/trojan-gfw/trojan-quickstart/master/trojan-quickstart.sh)"
    fi
  else
    echo -e "${Info}开始安装Trojan……"
    bash -c "$(curl -fsSL https://raw.githubusercontent.com/trojan-gfw/trojan-quickstart/master/trojan-quickstart.sh)"
  fi
}
install_ssr() {
  if [[ ${ssr_install_flag} == "YES" ]]; then
    read -p "$(echo -e "${Tip}是否重新安装（Y/n）?(默认：n)")" Yn
    [[ -z ${Yn} ]] && Yn="n"
    while [[ ${Yn} != "Y" ]] && [[ ${Yn} != "y" ]] && [[ ${Yn} != "n" ]]; do
        read -p "$(echo -e "${Tip}输入错误，重新输入：(默认：n)")" Yn
        [[ -z ${Yn} ]] && Yn="n"
    done
    if [[ ${Yn} == "Y" ]] || [[ ${Yn} == "y" ]]; then
      echo -e "${Info}开始安装SSR……"
      [[ ! -d ${ssr_conf_dir} ]] && mkdir ${ssr_conf_dir}
      wget --no-check-certificate -O ${ssr_conf_dir}/shadowsocks-all.sh https://raw.githubusercontent.com/JeannieStudio/jeannie/master/shadowsocks-all.sh
      chmod +x ${ssr_conf_dir}/shadowsocks-all.sh
      \n | . ${ssr_conf_dir}/shadowsocks-all.sh 2>&1 | tee shadowsocks-all.log
    fi
  else
    echo -e "${Info}开始安装SSR……"
    [[ ! -d ${ssr_conf_dir} ]] && mkdir ${ssr_conf_dir}
    wget --no-check-certificate -O ${ssr_conf_dir}/shadowsocks-all.sh https://raw.githubusercontent.com/JeannieStudio/jeannie/master/shadowsocks-all.sh
    chmod +x ${ssr_conf_dir}/shadowsocks-all.sh
    \n | . ${ssr_conf_dir}/shadowsocks-all.sh 2>&1 | tee shadowsocks-all.log
  fi
}
nginx_trojan_conf() {
  touch ${nginx_conf_dir}/default.conf
  cat >${nginx_conf_dir}/default.conf <<EOF
  server {
    listen 80;
    server_name ${domain};
    root ${web_dir};
}
EOF
}
nginx_v2ray_conf() {
  touch ${nginx_conf_dir}/default.conf
  cat >${nginx_conf_dir}/default.conf <<EOF
  server {
      listen 443 ssl http2;
      ssl_certificate       /etc/letsencrypt/live/$domain/fullchain.pem;
      ssl_certificate_key   /etc/letsencrypt/live/$domain/privkey.pem;
      ssl_protocols         TLSv1.3;
      ssl_ciphers           TLS13-AES-256-GCM-SHA384:TLS13-CHACHA20-POLY1305-SHA256:TLS13-AES-128-GCM-SHA256:TLS13-AES-128-CCM-8-SHA256:TLS13-AES-128-CCM-SHA256:EECDH+CHACHA20:EECDH+CHACHA20-draft:EECDH+ECDSA+AES128:EECDH+aRSA+AES128:RSA+AES128:EECDH+ECDSA+AES256:EECDH+aRSA+AES256:RSA+AES256:EECDH+ECDSA+3DES:EECDH+aRSA+3DES:RSA+3DES:!MD5;
      server_name           $domain;
      index index.html index.htm;
      root ${web_dir};
      error_page 400 = /400.html;
      location /ray/
      {
      proxy_redirect off;
      proxy_pass http://127.0.0.1:10000;
      proxy_http_version 1.1;
      proxy_set_header X-Real-IP \$remote_addr;
      proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
      proxy_set_header Upgrade \$http_upgrade;
      proxy_set_header Connection "upgrade";
      proxy_set_header Host \$http_host;
      }
}
  server {
      listen 80;
      server_name $domain;
      # rewrite ^(.*) https://${domain} permanent;
  }
EOF
}
tls_type() {
  if [[ -f "${nginx_bin_file}" ]] && [[ -f "${nginx_conf}" ]]; then
    echo -e "${Tip}请选择支持的 TLS 版本（default:3）:"
    echo -e "${Tip}请注意,如果你使用 Quantaumlt X / 路由器 / 旧版 Shadowrocket 请选择 兼容模式"
    echo "1: TLS1.1 TLS1.2 and TLS1.3（兼容模式）"
    echo "2: TLS1.2 and TLS1.3 (兼容模式)"
    echo "3: TLS1.3 only"
    [[ -z ${tls_version} ]] && tls_version=3
    read -rp "请输入：" tls_version
    while [[ ${tls_version} != 1 ]] && [[ ${tls_version} != 2 ]] && [[ ${tls_version} != 3 ]]; do
      read -rp "输入错误，请重新输入：" tls_version
    done
    case $tls_version in
    1)
      sed -i 's/ssl_protocols.*/ssl_protocols         TLSv1.1 TLSv1.2 TLSv1.3;/' ${nginx_conf}
      echo -e "${OK} ${GreenBG} 已切换至 TLS1.1 TLS1.2 and TLS1.3 ${Font}"
      ;;
    2)
      sed -i 's/ssl_protocols.*/ssl_protocols         TLSv1.2 TLSv1.3;/' ${nginx_conf}
      echo -e "${OK} ${GreenBG} 已切换至 TLS1.2 and TLS1.3 ${Font}"
      ;;
    3)
      sed -i 's/ssl_protocols.*/ssl_protocols         TLSv1.3;/' ${nginx_conf}
      echo -e "${OK} ${GreenBG} 已切换至 TLS1.3 only ${Font}"
      ;;
    *)
      echo -e "${RedBG}请输入正确的数字${Font}"
      ;;
    esac
  else
    echo -e "${Error} ${RedBG} Nginx 或 配置文件不存在，请正确安装脚本后执行${Font}"
  fi
}
v2ray_conf() {
  uuid=$(cat /proc/sys/kernel/random/uuid)
  read -p "$(echo -e "${Tip}已为您生成了uuid:${uuid},确认使用吗?[Y/n]?")" yn
  while [[ "${yn}" != [Yy] ]]; do
    uuid=$(cat /proc/sys/kernel/random/uuid)
    read -p "$(echo -e "${Tip}已为您生成了uuid:${uuid},确认使用吗?[Y/n]?")" yn
  done
  mkdir ${v2ray_conf_dir}
  cat >${v2ray_conf} <<"_EOF"
	  {
      "inbounds": [
        {
          "port": 10000,
          "listen":"127.0.0.1",
          "protocol": "vmess",
          "settings": {
            "clients": [
              {
                "id": "b831381d-6324-4d53-ad4f-8cda48b30811",
                "alterId": 64
              }
            ]
          },
          "streamSettings": {
            "network": "ws",
            "wsSettings": {
            "path": "/ray/"
            }
          }
        }
      ],
      "outbounds": [
        {
          "protocol": "freedom",
          "settings": {}
        }
      ]
    }
_EOF
  sed -i "s/b831381d-6324-4d53-ad4f-8cda48b30811/${uuid}/g" ${v2ray_conf}
}
web_download() {
  [[ ! -d "${web_dir}" ]] && mkdir "${web_dir}"
  while [[ ! -f "${web_dir}/web.zip" ]]; do
    echo -e "${Tip}伪装网站未下载或下载失败,请选择下面的任意一个进行下载:
      ${Info}1. https://templated.co/intensify
      ${Info}2. https://templated.co/binary
      ${Info}3. https://templated.co/retrospect
      ${Info}4. https://templated.co/spatial
      ${Info}5. https://templated.co/monochromed
      ${Info}6. https://templated.co/transit
      ${Info}7. https://templated.co/interphase
      ${Info}8. https://templated.co/ion
      ${Info}9. https://templated.co/solarize
      ${Info}10. https://templated.co/phaseshift
      ${Info}11. https://templated.co/horizons
      ${Info}12. https://templated.co/grassygrass
      ${Info}13. https://templated.co/breadth
      ${Info}14. https://templated.co/undeviating
      ${Info}15. https://templated.co/lorikeet"
    read -p "$(echo -e "${Tip}请输入你要下载的网站的数字:")" aNum
    case $aNum in
    1)
      wget -O ${web_dir}/web.zip --no-check-certificate https://templated.co/intensify/download
      ;;
    2)
      wget -O ${web_dir}/web.zip --no-check-certificate https://templated.co/binary/download
      ;;
    3)
      wget -O ${web_dir}/web.zip --no-check-certificate https://templated.co/retrospect/download
      ;;
    4)
      wget -O ${web_dir}/web.zip --no-check-certificate https://templated.co/spatial/download
      ;;
    5)
      wget -O ${web_dir}/web.zip --no-check-certificate https://templated.co/monochromed/download
      ;;
    6)
      wget -O ${web_dir}/web.zip --no-check-certificate https://templated.co/transit/download
      ;;
    7)
      wget -O ${web_dir}/web.zip --no-check-certificate https://templated.co/interphase/download
      ;;
    8)
      wget -O ${web_dir}/web.zip --no-check-certificate https://templated.co/ion/download
      ;;
    9)
      wget -O ${web_dir}/web.zip --no-check-certificate https://templated.co/solarize/download
      ;;
    10)
      wget -O ${web_dir}/web.zip --no-check-certificate https://templated.co/phaseshift/download
      ;;
    11)
      wget -O ${web_dir}/web.zip --no-check-certificate https://templated.co/horizons/download
      ;;
    12)
      wget -O ${web_dir}/web.zip --no-check-certificate https://templated.co/grassygrass/download
      ;;
    13)
      wget -O ${web_dir}/web.zip --no-check-certificate https://templated.co/breadth/download
      ;;
    14)
      wget -O ${web_dir}/web.zip --no-check-certificate https://templated.co/undeviating/download
      ;;
    15)
      wget -O ${web_dir}/web.zip --no-check-certificate https://templated.co/lorikeet/download
      ;;
    *)
      wget -O ${web_dir}/web.zip --no-check-certificate https://templated.co/intensify/download
      ;;
    esac
  done
  unzip -o -d ${web_dir} ${web_dir}/web.zip
}
caddy_v2ray_conf() {
  [[ ! -d ${caddy_conf_dir} ]] && mkdir ${caddy_conf_dir}
  touch ${caddy_conf}
  cat >${caddy_conf} <<_EOF
http://${domain}:80 {
    redir https://${domain}:443{url}
   }
https://${domain}:443 {
gzip
timeouts none
tls /etc/letsencrypt/live/$domain/fullchain.pem /etc/letsencrypt/live/$domain/privkey.pem {
   protocols tls1.0 tls1.3
}
root ${web_dir}
proxy /ray/ 127.0.0.1:10000 {
       websocket
       header_upstream -Origin
    }
}
_EOF
}
caddy_trojan_conf() {
   [[ ! -d ${caddy_conf_dir} ]] && mkdir ${caddy_conf_dir}
  touch ${caddy_conf}
  cat >${caddy_conf} <<_EOF
http://${domain}:80 {
  gzip
  timeouts none
  tls /etc/letsencrypt/live/$domain/fullchain.pem /etc/letsencrypt/live/$domain/privkey.pem {
       protocols tls1.0 tls1.3
    }
  root ${web_dir}
}
_EOF
}
caddy_ssr_conf() {
   [[ ! -d ${caddy_conf_dir} ]] && mkdir ${caddy_conf_dir}
  touch ${caddy_conf}
  cat >${caddy_conf} <<_EOF
http://${domain}:80 {
redir https://${domain}:1234{url}
       }
  https://${domain}:1234 {
  gzip
  timeouts none
  tls /etc/letsencrypt/live/$domain/fullchain.pem /etc/letsencrypt/live/$domain/privkey.pem {
       protocols tls1.0 tls1.3
    }
  root ${web_dir}
}
_EOF
}
trojan_conf() {
  read -p "$(echo -e "${Info}请输入您的trojan密码1:")" password1
  while [[ -z ${password1} ]]; do
    read -p "$(echo -e "${Tip}密码1不能为空,请重新输入您的trojan密码1:")" password1
  done
  read -p "$(echo -e "${Info}请输入您的trojan密码2:")" password2
  while [[ -z ${password2} ]]; do
    read -p "$(echo -e "${Tip}密码2不能为空,请重新输入您的trojan密码2:")" password2
  done
  touch ${trojan_conf}
  cat >${trojan_conf} <<_EOF
  {
    "run_type": "server",
    "local_addr": "0.0.0.0",
    "local_port": 443,
    "remote_addr": "127.0.0.1",
    "remote_port": 80,
    "password": [
        "${password1}",
        "${password2}"
    ],
    "log_level": 1,
    "ssl": {
        "cert": "/etc/letsencrypt/live/${domain}/fullchain.pem",
        "key": "/etc/letsencrypt/live/${domain}/privkey.pem",
        "key_password": "",
        "cipher": "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384",
        "cipher_tls13": "TLS_AES_128_GCM_SHA256:TLS_CHACHA20_POLY1305_SHA256:TLS_AES_256_GCM_SHA384",
        "prefer_server_cipher": true,
        "alpn": [
            "http/1.1"
        ],
        "alpn_port_override": {
            "h2": 81
        },
        "reuse_session": true,
        "session_ticket": false,
        "session_timeout": 600,
        "plain_http_response": "",
        "curves": "",
        "dhparam": ""
    },
    "tcp": {
        "prefer_ipv4": false,
        "no_delay": true,
        "keep_alive": true,
        "reuse_port": false,
        "fast_open": false,
        "fast_open_qlen": 20
    },
    "mysql": {
        "enabled": false,
        "server_addr": "127.0.0.1",
        "server_port": 3306,
        "database": "trojan",
        "username": "trojan",
        "password": "",
        "cafile": ""
    }
}
_EOF
  # sed -i "8c \"$password1\"," ${trojan_conf}
  # sed -i "9c \"$password2\"," ${trojan_conf}
  # sed -i "s/password1/${password1}/g" ${trojan_conf}
  # sed -i "s/password2/${password2}/g" ${trojan_conf}
  # sed -i "/\"cert\":/c \"cert\": \"/etc/letsencrypt/live/$domain/fullchain.pem\"," ${trojan_conf}
  # sed -i "/\"key\":/c \"key\": \"/etc/letsencrypt/live/$domain/privkey.pem\"," ${trojan_conf}
}
ssr_conf() {
  read -p "$(echo -e "${Info}请输入ssr的密码:")" password
  while [[ -z ${password} ]]; do
    read -p "$(echo -e "${Info}密码不能为空,请重新输入:")" password
  done
  #sed -i "\"server_port\": /c         \"server_port\":443," ${ssr_conf}
  #sed -i "\"redirect\": /c        \"redirect\":[\"*:443#127.0.0.1:80\"]," ${ssr_conf}
  cat >${ssr_conf} <<EOF
  {
    "server":"0.0.0.0",
    "server_ipv6":"::",
    "server_port":443,
    "local_address":"127.0.0.1",
    "local_port":1080,
    "password":"${password}",
    "timeout":120,
    "method":"none",
    "protocol":"auth_chain_a",
    "protocol_param":"",
    "obfs":"tls1.2_ticket_auth",
    "obfs_param":"",
    "redirect":["*:443#127.0.0.1:1234"],
    "dns_ipv6":false,
    "fast_open":true,
    "workers":1
}
EOF
}
tls_generate() {
  echo -e "${Info}开始签发证书……"
  if [[ -f "/etc/letsencrypt/live/$domain/fullchain.pem" ]] && [[ -f "/etc/letsencrypt/live/$domain/privkey.pem" ]]; then
    echo -e "${Info}证书已存在……不需要再重新签发了……"
  else
    read -p "$(echo -e "${Info}请输入您的邮箱:")" email
    read -p "$(echo -e "${Tip}您输入的邮箱正确吗?[Y/n]?")" yn
    while [[ "${yn}" != [Yy] ]]; do
      read -p "$(echo -e "${Info}请输入您的邮箱:")" email
      read -p "$(echo -e "${Tip}您输入的邮箱正确吗?[Y/n]?")" yn
    done
    certbot certonly --standalone -n --agree-tos --email $email -d $domain
    [[ ! -d "/etc/letsencrypt/live/$domain" ]] && echo -e "${RED}证书签发失败，原因1：域名申请次数过多，换个域名试试；2：由于网络原因，申请证书所需的依赖包没下载下来，重装即可${NO_COLOR}" && exit 1
  fi
}
trojan_qr_config() {
  uuid=$(cat /proc/sys/kernel/random/uuid)
  touch ${trojan_qr_config_file}
  cat >${trojan_qr_config_file} <<-EOF
  "domain": "${domain}"
  "uuid": "${uuid}"
  "password1": "${password1}"
  "password2": "${password2}"
EOF
}
trojan_qr_link_image() {
  trojan_link1="trojan://${password1}@${domain}:443"
  trojan_link2="trojan://${password2}@${domain}:443"
  qrencode -o ${web_dir}/${uuid}-01.png -s 6 "${trojan_link1}"
  qrencode -o ${web_dir}/${uuid}-02.png -s 6 "${trojan_link2}"
  #tmp1=$(echo -n "${password1}" | base64 -w0 | sed 's/=//g;s/\//_/g;s/+/-/g')
  #tmp2=$(echo -n "${tmp1}@${domain}:443" | base64 -w0)
  #trojan_link1="trojan://${tmp2}"
  #tmp3=$(echo -n "${password2}" | base64 -w0 | sed 's/=//g;s/\//_/g;s/+/-/g')
  #tmp4=$(echo -n "${tmp3}@${domain}:443" | base64 -w0)
  #trojan_link2="trojan://${tmp4}"
  #qrencode -o ${web_dir}/${uuid}-01.png -s 6 "${trojan_link1}"
  #qrencode -o ${web_dir}/${uuid}-02.png -s 6 "${trojan_link2}"
}
trojan_info_html() {
  vps="trojan"
  wget --no-check-certificate -O ${web_dir}/trojan_tmpl.html https://raw.githubusercontent.com/JeannieStudio/jeannie/master/trojan_tmpl.html
  chmod +x ${web_dir}/trojan_tmpl.html
eval "cat <<EOF
  $(<${web_dir}/trojan_tmpl.html)
EOF
" >${web_dir}/${uuid}.html
}
trojan_info_extraction() {
  grep "$1" ${trojan_qr_config_file} | awk -F '"' '{print $4}'
}
trojan_basic_information() {
  {
echo -e "
${GREEN}=========================trojan+tls 安装成功==============================
${FUCHSIA}=========================   Trojan 配置信息  =============================
${GREEN}地址：   $(trojan_info_extraction '\"domain\"')
${GREEN}端口：   443
${GREEN}密码1：  $(trojan_info_extraction '\"password1\"')
${GREEN}密码2：  $(trojan_info_extraction '\"password2\"')
${FUCHSIA}=========================   分享链接和二维码  ===============================
${GREEN}分享链接1：
${trojan_link1}
${GREEN}分享链接2：
${trojan_link2}
${GREEN}二维码1：  ${web_dir}/${uuid}-01.png
${GREEN}二维码2：  ${web_dir}/${uuid}-02.png
${FUCHSIA}=========================   懒人请往这儿瞧  ===============================
${GREEN}详细信息：https://${domain}/${uuid}.html${NO_COLOR}"
} | tee /etc/motd
}
ssr_qr_config() {
  uuid=$(cat /proc/sys/kernel/random/uuid)
  touch ${ssr_qr_config_file}
  cat >${ssr_qr_config_file} <<EOF
{
  "uuid":"${uuid}",
  "domain":"${domain}",
  "password": "$(ssr_info_extraction '\"password\"')",
  "protocol": "$(ssr_info_extraction '\"protocol\"')",
  "method": "$(ssr_info_extraction '\"method\"')",
  "obfs": "$(ssr_info_extraction '\"obfs\"')",
}
EOF
}
ssr_info_extraction() {
  grep "$1" ${ssr_conf} | awk -F '"' '{print $4}'
}
ssr_qr_info_extraction() {
  grep "$1" ${ssr_qr_config_file} | awk -F '"' '{print $4}'
}
ssr_qr_link_image(){
    password=$(ssr_info_extraction '\"password\"')
    protocol=$(ssr_info_extraction '\"protocol\"')
    method=$(ssr_info_extraction '\"method\"')
    obfs=$(ssr_info_extraction '\"obfs\"')
    tmp1=$(echo -n "${password}" | base64 -w0 | sed 's/=//g;s/\//_/g;s/+/-/g')
    tmp2=$(echo -n "${domain}:443:${protocol}:${method}:${obfs}:${tmp1}/?obfsparam=" | base64 -w0)
    ssr_link="ssr://${tmp2}"
    qrencode -o ${web_dir}/${uuid}.png -s 8 "${ssr_link}"
}
ssr_info_html(){
  vps="ssr"
  wget --no-check-certificate -O ${web_dir}/ssr_tmpl.html https://raw.githubusercontent.com/JeannieStudio/jeannie/master/ssr_tmpl.html
  chmod +x ${web_dir}/ssr_tmpl.html
  eval "cat <<EOF
  $(< ${web_dir}/ssr_tmpl.html)
EOF
  "  > ${web_dir}/${uuid}.html
}
ssr_basic_information() {
  {
echo -e "
${GREEN}=========================ssr+tls 安装成功==============================
${FUCHSIA}=========================   SSR 配置信息  =============================
${GREEN}地址：   ${domain}
${GREEN}端口：   443
${GREEN}密码：  $(ssr_info_extraction '\"password\"')
${GREEN}加密方式：  $(ssr_info_extraction '\"method\"')
${GREEN}协议：  $(ssr_info_extraction '\"protocol\"')
${GREEN}混淆：  $(ssr_info_extraction '\"obfs\"')
${FUCHSIA}=========================   分享链接和二维码  ===============================
${GREEN}分享链接：
${ssr_link}
${GREEN}二维码：  ${web_dir}/${uuid}.png
${FUCHSIA}=========================   懒人请往这儿瞧  ===============================
${GREEN}详细信息：https://${domain}/${uuid}.html${NO_COLOR}"
} | tee /etc/motd
}
v2ray_shadowrocket_qr_config() {
  touch ${v2ray_shadowrocket_qr_config_file}
  cat >${v2ray_shadowrocket_qr_config_file} <<EOF
{
  "v": "v2ray",
  "ps": "Jeannie_${domain}",
  "add": "${domain}",
  "port": "443",
  "id": "${uuid}",
  "aid": "64",
  "net": "ws",
  "type": "none",
  "host": "${domain}",
  "path": "/ray/",
  "tls": "tls"
}
EOF
}
v2ray_win_and_android_qr_config() {
  touch ${v2ray_win_and_android_qr_config_file}
  cat >${v2ray_win_and_android_qr_config_file} <<EOF
{
  "v": "v2ray",
  "ps": "Jeannie_${domain}",
  "add": "${domain}",
  "port": "443",
  "id": "${uuid}",
  "aid": "64",
  "net": "ws",
  "type": "none",
  "host": "/ray/",
  "tls": "tls"
}
EOF
}

v2ray_shadowrocket_qr_link_image() {
  v2ray_link1="vmess://$(base64 -w 0 ${v2ray_shadowrocket_qr_config_file})"
  qrencode -o ${web_dir}/${uuid}-1.png -s 6 "${v2ray_link1}"
}
v2ray_win_and_android_qr_link_image() {
  v2ray_link2="vmess://$(base64 -w 0 ${v2ray_win_and_android_qr_config_file})"
  qrencode -o ${web_dir}/${uuid}-2.png -s 6 "${v2ray_link2}"
}
v2ray_info_extraction() {
  grep "$1" ${v2ray_shadowrocket_qr_config_file} | awk -F '"' '{print $4}'
}
v2ray_info_html() {
  vps="v2ray"
  wget --no-check-certificate -O ${web_dir}/v2ray_tmpl.html https://raw.githubusercontent.com/JeannieStudio/jeannie/master/v2ray_tmpl.html
  chmod +x ${web_dir}/v2ray_tmpl.html
eval "cat <<EOF
  $(<${web_dir}/v2ray_tmpl.html)
EOF
" >${web_dir}/${uuid}.html
}
v2ray_basic_information() {
  {
    echo -e "
${GREEN}=========================V2ray+ws+tls 安装成功==============================
${FUCHSIA}=========================   V2ray 配置信息   ===============================
${GREEN}地址(address):       $(v2ray_info_extraction '\"add\"')
${GREEN}端口（port）：        443
${GREEN}用户id（UUID）：      $(v2ray_info_extraction '\"id\"')
${GREEN}额外id（alterId）：   64
${GREEN}加密方式（security）：自适应
${GREEN}传输协议（network）： ws
${GREEN}伪装类型（type）：    none
${GREEN}路径（不要落下/）：   /ray/
${GREEN}底层传输安全：        tls
${FUCHSIA}=========================   分享链接和二维码  ===============================
${GREEN}windows和安卓客户端v2rayN分享链接：
${BLUE}${v2ray_link2}
${GREEN}ios客户端shadowroket分享链接：
${BLUE}${v2ray_link1}
${GREEN}windows和安卓客户端v2rayN二维码：
${BLUE}${web_dir}/${uuid}-1.png
${GREEN}ios客户端shadowroket二维码：
${BLUE}${web_dir}/${uuid}-2.png
${FUCHSIA}=========================   懒人请往这儿瞧  ======================================
${GREEN}https://$(v2ray_info_extraction '\"add\"')/${uuid}.html${NO_COLOR}"
  } | tee /etc/motd
}
download_all_mgr() {
  curl -s -o /etc/all_mgr.sh https://raw.githubusercontent.com/JeannieStudio/all_install/master/all_mgr.sh
  curl -s -o /etc/all_mgr.sh https://raw.githubusercontent.com/JeannieStudio/all_install/master/all_mgr.sh
  if [ -s /etc/all_mgr.sh ] && grep '/bin/bash' /etc/all_mgr.sh; then
    chmod +x /etc/all_mgr.sh
  else
    echo -e "${RED}您的网络不给力，导致修改密码或uuid的脚本下载不下来,稍后执行以下2句命令自行下载吧："
    echo -e "curl -s -o /etc/all_mgr.sh https://raw.githubusercontent.com/JeannieStudio/all_install/master/all_mgr.sh"
    echo -e "chmod +x /etc/all_mgr.sh"
    echo -e "如果您不自行下载，将导致无法修改密码、UUID、重启caddy、nginx、trojan、ssr、v2ray，查看和延长证书有效期等，自己看着办吧……${NO_COLOR}"
    sleep 6
  fi

}
left_second(){
    seconds_left=5
    while [ $seconds_left -gt 0 ];do
      echo -n $seconds_left
      sleep 1
      seconds_left=$(($seconds_left - 1))
      echo -ne "\r     \r"
    done
}
reboot_sys(){
  if [[ ${release} == "centos" ]]; then
    echo -e "${Info}系统需要重启后才能生效，马上重启……"
  fi
}
install_trojan_nginx() {
  set_SELINUX
  set_PATH
  check_root
  check_sys
  install_dependency
  close_firewall
  check_caddy_installed_status
  uninstall_caddy
  check_v2ray_installed_status
  uninstall_v2ray
  check_ssr_installed_status
  uninstall_ssr
  uninstall_web
  get_ip
  check_domain
  tls_generate
  check_nginx_installed_status
  install_nginx
  nginx_trojan_conf
  web_download
  systemctl restart nginx
  systemctl enable nginx
  check_trojan_installed_status
  install_trojan
  trojan_conf
  systemctl restart trojan
  systemctl enable trojan
  trojan_qr_config
  trojan_qr_link_image
  trojan_info_html
  trojan_info_extraction
  remove_mgr
  download_all_mgr
  trojan_basic_information
}
install_trojan_caddy() {
  set_SELINUX
  set_PATH
  check_root
  check_sys
  install_dependency
  close_firewall
  check_nginx_installed_status
  uninstall_nginx
  check_v2ray_installed_status
  uninstall_v2ray
  check_ssr_installed_status
  uninstall_ssr
  uninstall_web
  get_ip
  check_domain
  tls_generate
  check_caddy_installed_status
  install_caddy
  install_caddy_service
  caddy_trojan_conf
  web_download
  caddy -service start
  check_trojan_installed_status
  install_trojan
  trojan_conf
  systemctl restart trojan
  systemctl enable trojan
  trojan_qr_config
  trojan_qr_link_image
  trojan_info_html
  trojan_info_extraction
  remove_mgr
  download_all_mgr
  trojan_basic_information
}
install_v2ray_nginx() {
  set_SELINUX
  set_PATH
  check_root
  check_sys
  install_dependency
  close_firewall
  check_caddy_installed_status
  uninstall_caddy
  check_trojan_installed_status
  uninstall_trojan
  check_ssr_installed_status
  uninstall_ssr
  uninstall_web
  get_ip
  check_domain
  tls_generate
  check_nginx_installed_status
  install_nginx
  nginx_v2ray_conf
  tls_type
  web_download
  systemctl restart nginx
  systemctl enable nginx
  check_v2ray_installed_status
  install_v2ray
  v2ray_conf
  service v2ray restart
  # systemctl enable v2ray
  v2ray_shadowrocket_qr_config
  v2ray_win_and_android_qr_config
  v2ray_shadowrocket_qr_link_image
  v2ray_win_and_android_qr_link_image
  v2ray_info_extraction
  v2ray_info_html
  remove_mgr
  download_all_mgr
  v2ray_basic_information
}
install_v2ray_caddy() {
  set_SELINUX
  set_PATH
  check_root
  check_sys
  install_dependency
  close_firewall
  check_nginx_installed_status
  uninstall_nginx
  check_trojan_installed_status
  uninstall_trojan
  check_ssr_installed_status
  uninstall_ssr
  uninstall_web
  get_ip
  check_domain
  tls_generate
  check_caddy_installed_status
  install_caddy
  caddy_v2ray_conf
  web_download
  install_caddy_service
  caddy -service restart
  check_v2ray_installed_status
  install_v2ray
  v2ray_conf
  service v2ray restart
  systemctl enable v2ray
  # systemctl enable v2ray
  v2ray_shadowrocket_qr_config
  v2ray_win_and_android_qr_config
  v2ray_shadowrocket_qr_link_image
  v2ray_win_and_android_qr_link_image
  v2ray_info_extraction
  v2ray_info_html
  remove_mgr
  download_all_mgr
  v2ray_basic_information
}
install_ssr_caddy() {
  set_SELINUX
  set_PATH
  check_root
  check_sys
  install_dependency
  close_firewall
  check_nginx_installed_status
  uninstall_nginx
  check_v2ray_installed_status
  uninstall_v2ray
  check_trojan_installed_status
  uninstall_trojan
  uninstall_web
  get_ip
  check_domain
  tls_generate
  check_caddy_installed_status
  install_caddy
  caddy_ssr_conf
  web_download
  install_caddy_service
  caddy -service restart
  check_ssr_installed_status
  install_ssr
  ssr_conf
  ssr_info_extraction
  ssr_qr_config
  ssr_qr_link_image
  ssr_info_html
  /etc/init.d/shadowsocks-r restart
  /etc/init.d/shadowsocks-r enable
  remove_mgr
  download_all_mgr
  ssr_basic_information
}
install_bbr() {
  wget -N --no-check-certificate "https://raw.githubusercontent.com/chiakge/Linux-NetSpeed/master/tcp.sh"
  chmod +x tcp.sh
  ./tcp.sh
}
uninstall_all() {
  check_root
  check_sys
  check_nginx_installed_status
  uninstall_nginx
  check_trojan_installed_status
  uninstall_trojan
  check_ssr_installed_status
  uninstall_ssr
  uninstall_web
  check_caddy_installed_status
  uninstall_caddy
  check_v2ray_installed_status
  uninstall_v2ray
  remove_mgr
  check_nginx_pid
  check_caddy_pid
  check_v2ray_pid
  check_ssr_pid
  check_trojan_pid
  echo -e "${Info}卸载完成，系统回到初始状态！"
}
main() {
  echo -e "
${FUCHSIA}===================================================
${GREEN}trojan、v2ray、ssr六合一脚本(authored by Jeannie)
${FUCHSIA}===================================================
${GREEN}如果已经安装了下列脚本之一，想要安装其他的，不需要单独执行卸载，直接选择想要安装脚本对应的数字即可……
${GREEN}因为安装的同时会执行卸载，除非想卸载干净回到初始状态,可以执行7……
${FUCHSIA}===================================================
${GREEN}1. 安装trojan+tls+nginx
${FUCHSIA}===================================================
${GREEN}2. 安装trojan+tls+caddy
${FUCHSIA}===================================================
${GREEN}3. 安装v2ray+tls+nginx
${FUCHSIA}===================================================
${GREEN}4. 安装v2ray+tls+caddy
${FUCHSIA}===================================================
${GREEN}5. 安装ssr+tls+nginx
${FUCHSIA}===================================================
${GREEN}6. 安装ssr+tls+caddy
${FUCHSIA}===================================================
${GREEN}7. 卸载全部，系统回到初始状态
${FUCHSIA}===================================================
${GREEN}8. 安装BBR加速
${FUCHSIA}===================================================
${GREEN}0. 啥也不做，退出${NO_COLOR}"
  read -rp "请输入数字：" menu_num
  case $menu_num in
  1)
    install_trojan_nginx
    ;;
  2)
    install_trojan_caddy
    ;;
  3)
    install_v2ray_nginx
    ;;
  4)
    install_v2ray_caddy
    ;;
  5)
    install_ssr_caddy
    ;;
  6)
    echo -e "${Tip}脚本开发中，敬请期待……"
    ;;
  7)
    uninstall_all
    ;;
  8)
    install_bbr
    ;;
  0)
    exit 0
    ;;
  *)
    echo -e "${RedBG}请输入正确的数字${Font}"
    ;;
  esac
}
main
