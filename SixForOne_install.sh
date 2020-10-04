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
nginx_bin_old_file="/usr/sbin/nginx"
nginx_bin_file="/etc/nginx/sbin/nginx"
nginx_conf_dir="/etc/nginx/conf/conf.d"
nginx_conf="${nginx_conf_dir}/default.conf"
nginx_dir="/etc/nginx"
nginx_openssl_src="/usr/local/src"
nginx_systemd_file="/etc/systemd/system/nginx.service"
v2ray_bin_dir="/usr/local/bin/v2ray"
v2ray_systemd_file="/etc/systemd/system/v2ray.service"
v2ray_conf_dir="/usr/local/etc/v2ray"
v2ray_conf="${v2ray_conf_dir}/config.json"
v2ray_shadowrocket_qr_config_file="${v2ray_conf_dir}/shadowrocket_qrconfig.json"
v2ray_win_and_android_qr_config_file="${v2ray_conf_dir}/win_and_android_qrconfig.json"
caddy_bin_dir="/usr/bin/caddy"
caddy_conf_dir="/etc/caddy"
caddy_conf="${caddy_conf_dir}/Caddyfile"
caddy_systemd_file="/lib/systemd/system/caddy.service"
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
nginx_version="1.18.0"
openssl_version="1.1.1g"
jemalloc_version="5.2.1"
old_config_status="off"
# v2ray_plugin_version="$(wget -qO- "https://github.com/shadowsocks/v2ray-plugin/tags" | grep -E "/shadowsocks/v2ray-plugin/releases/tag/"
set_SELINUX() {
  if [ -s /etc/selinux/config ] && grep 'SELINUX=enforcing' /etc/selinux/config; then
    sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
    setenforce 0
  fi
}
sys_cmd() {
  if [[ ${release} == "centos" ]]; then
    cmd="yum"
  else
    cmd="apt"
  fi
}
set_PATH() {
  [[ -z "$(grep "export PATH=/bin:/sbin:" /etc/bashrc)" ]] && echo "export PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin" >>/etc/bashrc && source /etc/profile
}
check_root() {
  [[ $EUID != 0 ]] && echo -e "${Error} ${RedBG} 当前非ROOT账号(或没有ROOT权限)，无法继续操作，请执行命令 ${Green_background_prefix}sudo -i${Font_color_suffix} 更换ROOT账号" && exit 1
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
sucess_or_fail() {
  if [[ 0 -eq $? ]]; then
    echo -e "${Info} ${GreenBG} $1 完成 ${Font}"
    sleep 1
  else
    echo -e "${Error} ${GreenBG}$1 失败${Font}"
    exit 1
  fi
}
GCE_debian10() {
  read -rp "$(echo -e "${Info}因为谷歌云的debian10抽风，所以需要确认您当前是否是谷歌云的debian10系统吗（Y/n）？${RED}注意：只有谷歌云的debian10系统才填y，其他都填n。如果填错，将直接导致您后面无法科学上网（Y/n）(默认：n)${NO_COLOR}")" Yn
  [[ -z ${Yn} ]] && Yn="n"
  case ${Yn} in
  [yY][eE][sS] | [yY])
    is_debian10="y"
    ;;
  *) ;;

  esac
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
  read -rp "请输入您的域名(如果用Cloudflare解析域名，请点击小云彩使其变灰):" domain
  real_ip=$(ping "${domain}" -c 1 | sed '1{s/[^(]*(//;s/).*//;q}')
  while [ "${real_ip}" != "${local_ip}" ]; do
    read -rp "本机IP和域名绑定的IP不一致，请检查域名是否解析成功,并重新输入域名:" domain
    real_ip=$(ping "${domain}" -c 1 | sed '1{s/[^(]*(//;s/).*//;q}')
    read -rp "我已人工确认，本机Ip和域名绑定的IP一致，继续安装（Y/n）？（默认:n）" continue_install
    [[ -z ${continue_install} ]] && continue_install="n"
    case ${continue_install} in
    [yY][eE][sS] | [yY])
      echo -e "${Tip} 继续安装"
      break
      ;;
    *)
      echo -e "${Tip} 安装终止"
      exit 2
      ;;
    esac
  done
}
check_nginx_installed_status() {
  if [[ -f ${nginx_bin_file} ]]; then
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
  if [[ -d ${caddy_bin_dir} ]] && [[ -d ${caddy_conf} ]]; then
    echo -e "${Info}检测到您已经安装了Caddy!"
    caddy_install_flag="YES"
  fi
}
uninstall_old_nginx() {
  if [[ -f ${nginx_bin_old_file} ]]; then
    nginx -s stop
    echo -e "${Info}检测到您安装了旧版Nginx，马上为您卸载旧版……"
    if [[ ${release} == "centos" ]]; then
      yum autoremove -y nginx
      rm -rf ${nginx_dir}
    else
      apt-get autoremove -y --purge nginx # 自动删除安装nginx时安装的依赖包和/etc/nginx
      rm -rf ${nginx_dir}
    fi
    echo -e "${Info}旧版Nginx卸载成功！"
  fi
}
uninstall_nginx() {
  #if [[ -f ${nginx_bin_file} ]]; then
    #echo -e "${Tip} 是否卸载 Nginx [Y/N]? "
    #read -r uninstall_nginx
    #case ${uninstall_nginx} in
    #[yY][eE][sS] | [yY])
      systemctl stop nginx
      rm -rf ${nginx_dir}
      rm -f ${nginx_systemd_file}
      echo -e "${Info} 已卸载 Nginx ${Font}"
      #;;
    #*) ;;
    #esac
  #fi
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
  if [[ -f ${caddy_bin_dir} ]]; then
    echo -e "${Info}开始卸载Caddy……"
    systemctl stop caddy.service
    if [[ ${release} == "debian" || ${release} == "ubuntu" ]]; then
      bash install-release.sh --remove
    elif [[ ${release} == "centos" ]]; then
      bash install-release.sh --remove
    fi
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
remove_mgr() {
  [[ -f "/etc/all_mgr.sh" ]] && rm -f /etc/all_mgr.sh
}
remove_motd() {
  [[ -f "/etc/motd" ]] && rm -f /etc/motd
}
port_used_check() {
  if [[ 0 -eq $(lsof -i:"$1" | grep -i -c "listen") ]]; then
    echo -e "${Info} $1 端口未被占用"
    sleep 1
  else
    echo -e "${Error}检测到 $1 端口被占用，以下为 $1 端口占用信息 ${Font}"
    lsof -i:"$1"
    echo -e "${Info} 5s 后将尝试自动 kill 占用进程 "
    sleep 5
    lsof -i:"$1" | awk '{print $2}' | grep -v "PID" | xargs kill -9
    echo -e "${Info} kill 完成"
    sleep 1
  fi
}
install_v2ray() {
  if [[ ${v2ray_install_flag} == "YES" ]]; then
    read -rp "$(echo -e "${Tip}检测到已经安装了v2ray,是否重新安装（Y/n）?(默认：n)")" Yn
    [[ -z ${Yn} ]] && Yn="n"
    case ${Yn} in
    [yY][eE][sS] | [yY])
      echo -e "${Info}开始安装v2ray……"
      sleep 2
      #bash <(curl -L -s https://install.direct/go.sh)
      #curl -O https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh
      bash <(curl -L https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh)
    sucess_or_fail "安裝和更新 V2Ray"
    #curl -O https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-dat-release.sh
    bash <(curl -L https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-dat-release.sh)
    sucess_or_fail "安裝最新發行的 geoip.dat 和 geosite.dat"
      ;;
    *) ;;

    esac
  else
    echo -e "${Info}开始安装v2ray……"
    sleep 2
    #bash <(curl -L -s https://install.direct/go.sh)
    curl -O https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh
    sucess_or_fail "v2ray包安装下载"
    curl -O https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-dat-release.sh
    sucess_or_fail "v2ray数据包下载"
    bash install-release.sh
    sucess_or_fail "v2ray安装"
    bash install-dat-release.sh
    sucess_or_fail "v2ray数据包安装"
  fi
}
install_v2ray_service() {
  sed -i 's/User=nobody/User=root/' ${v2ray_systemd_file}
}
install_dependency() {
  echo -e "${Info}开始升级系统，需要花费几分钟……"
  ${cmd} update -y
  sucess_or_fail "系统升级"
  echo -e "${Info}开始安装依赖……"
  if [[ ${cmd} == "apt" ]]; then
    apt -y install dnsutils
  else
    yum -y install bind-utils
  fi
  #sucess_or_fail "DNS工具包安装"
  ${cmd} -y install wget
  sucess_or_fail "wget包安装"
  ${cmd} -y install unzip
  sucess_or_fail "unzip安装"
  ${cmd} -y install zip
  sucess_or_fail "zip安装"
  ${cmd} -y install curl
  sucess_or_fail "curl安装"
  ${cmd} -y install tar
  sucess_or_fail "tar安装"
  ${cmd} -y install git
  sucess_or_fail "git安装"
  ${cmd} -y install lsof
  sucess_or_fail "lsof安装"
  #${cmd} -y install firewalld
  #sucess_or_fail "firewalld安装"
  if [[ ${cmd} == "yum" ]]; then
    yum -y install crontabs
  else
    apt -y install cron
  fi
  sucess_or_fail "定时任务工具安装"
  ${cmd} -y install qrencode
  sucess_or_fail "qrencode安装"
  ${cmd} -y install bzip2
  sucess_or_fail "bzip2安装"
  if [[ ${cmd} == "yum" ]]; then
    yum install -y epel-release
  fi
  sucess_or_fail "epel-release安装"
  if [[ "${cmd}" == "yum" ]]; then
    ${cmd} -y groupinstall "Development tools"
  else
    ${cmd} -y install build-essential
  fi
  sucess_or_fail "编译工具包 安装"

  if [[ "${cmd}" == "yum" ]]; then
    ${cmd} -y install pcre pcre-devel zlib-devel epel-release dnf curl
  else
    ${cmd} -y install libpcre3 libpcre3-dev zlib1g-dev dbus curl
  fi
  ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
}
chrony_install() {
  echo -e "${Info}安装 chrony 时间同步服务 "
  timedatectl set-ntp true
  if [[ ${release} == "centos" ]]; then
    systemctl enable chronyd && systemctl restart chronyd
  else
    systemctl enable chrony && systemctl restart chrony
  fi
  echo -e "${Info}chronyd 启动 "
  timedatectl set-timezone Asia/Shanghai
  echo -e "${Info}等待时间同步"
  sleep 10
  chronyc sourcestats -v
  chronyc tracking -v
  date
  read -rp "请确认时间是否准确,误差范围±3分钟(Y/N): " chrony_install
  [[ -z ${chrony_install} ]] && chrony_install="Y"
  case $chrony_install in
  [yY][eE][sS] | [yY])
    echo -e "${GreenBG} 继续安装 ${Font}"
    sleep 2
    ;;
  *)
    echo -e "${RedBG} 安装终止 ${Font}"
    exit 2
    ;;
  esac
}
close_firewall() {
  systemctl stop firewalld.service
  systemctl disable firewalld.service
  echo -e "${Info} firewalld 已关闭 ${Font}"
  iptables -F
}
open_port() {
  if [[ ${release} != "centos" ]]; then
    iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport 80 -j ACCEPT
    iptables -I INPUT -m state --state NEW -m udp -p udp --dport 80 -j ACCEPT
    ip6tables -I INPUT -m state --state NEW -m tcp -p tcp --dport 80 -j ACCEPT
    ip6tables -I INPUT -m state --state NEW -m udp -p udp --dport 80 -j ACCEPT
    iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport 443 -j ACCEPT
    iptables -I INPUT -m state --state NEW -m udp -p udp --dport 443 -j ACCEPT
    ip6tables -I INPUT -m state --state NEW -m tcp -p tcp --dport 443 -j ACCEPT
    ip6tables -I INPUT -m state --state NEW -m udp -p udp --dport 443 -j ACCEPT
  fi
}
install_nginx() {
  if [[ ${nginx_install_flag} == "YES" ]]; then
    echo -e "${Info} Nginx已存在，跳过编译安装过程 ${Font}"
    sleep 2
  else
    wget -nc --no-check-certificate http://nginx.org/download/nginx-${nginx_version}.tar.gz -P ${nginx_openssl_src}
    sucess_or_fail "Nginx 下载"
    wget -nc --no-check-certificate https://www.openssl.org/source/openssl-${openssl_version}.tar.gz -P ${nginx_openssl_src}
    sucess_or_fail "openssl 下载"
    wget -nc --no-check-certificate https://github.com/jemalloc/jemalloc/releases/download/${jemalloc_version}/jemalloc-${jemalloc_version}.tar.bz2 -P ${nginx_openssl_src}
    sucess_or_fail "jemalloc 下载"
    cd ${nginx_openssl_src} || exit

    [[ -d nginx-"$nginx_version" ]] && rm -rf nginx-"$nginx_version"
    tar -zxvf nginx-"$nginx_version".tar.gz

    [[ -d openssl-"$openssl_version" ]] && rm -rf openssl-"$openssl_version"
    tar -zxvf openssl-"$openssl_version".tar.gz

    [[ -d jemalloc-"${jemalloc_version}" ]] && rm -rf jemalloc-"${jemalloc_version}"
    tar -xvf jemalloc-"${jemalloc_version}".tar.bz2

    [[ -d "$nginx_dir" ]] && rm -rf ${nginx_dir}

    echo -e "${Info} 开始编译并安装 jemalloc……"
    sleep 2

    cd jemalloc-${jemalloc_version} || exit
    ./configure
    sucess_or_fail "编译检查……"
    make && make install
    sucess_or_fail "jemalloc 编译安装"
    echo '/usr/local/lib' >/etc/ld.so.conf.d/local.conf
    ldconfig

    echo -e "${Info} 即将开始编译安装 Nginx, 过程稍久，请耐心等待……"
    sleep 4

    cd ../nginx-${nginx_version} || exit

    ./configure --prefix="${nginx_dir}" \
      --with-http_ssl_module \
      --with-http_gzip_static_module \
      --with-http_stub_status_module \
      --with-pcre \
      --with-http_realip_module \
      --with-http_flv_module \
      --with-http_mp4_module \
      --with-http_secure_link_module \
      --with-http_v2_module \
      --with-cc-opt='-O3' \
      --with-ld-opt="-ljemalloc" \
      --with-openssl=../openssl-"$openssl_version"
    sucess_or_fail "编译检查"
    make && make install
    sucess_or_fail "Nginx 编译安装"

    # 修改基本配置
    sed -i 's/#user  nobody;/user  root;/' ${nginx_dir}/conf/nginx.conf
    sed -i 's/worker_processes  1;/worker_processes  3;/' ${nginx_dir}/conf/nginx.conf
    sed -i 's/    worker_connections  1024;/    worker_connections  4096;/' ${nginx_dir}/conf/nginx.conf
    sed -i '$i include conf.d/*.conf;' ${nginx_dir}/conf/nginx.conf

    # 删除临时文件
    rm -rf ../nginx-"${nginx_version}"
    rm -rf ../openssl-"${openssl_version}"
    rm -rf ../nginx-"${nginx_version}".tar.gz
    rm -rf ../openssl-"${openssl_version}".tar.gz

    # 添加配置文件夹，适配旧版脚本
    mkdir ${nginx_dir}/conf/conf.d
  fi
}
nginx_systemd() {
  touch ${nginx_systemd_file}
  cat >${nginx_systemd_file} <<EOF
[Unit]
Description=The NGINX HTTP and reverse proxy server
After=syslog.target network.target remote-fs.target nss-lookup.target
[Service]
Type=forking
PIDFile=/etc/nginx/logs/nginx.pid
ExecStartPre=/etc/nginx/sbin/nginx -t
ExecStart=/etc/nginx/sbin/nginx -c ${nginx_dir}/conf/nginx.conf
ExecReload=/etc/nginx/sbin/nginx -s reload
ExecStop=/bin/kill -s QUIT \$MAINPID
PrivateTmp=true
[Install]
WantedBy=multi-user.target
EOF
  sucess_or_fail "Nginx systemd ServerFile 添加"
  systemctl daemon-reload
}
install_caddy() {
  if [[ ${caddy_install_flag} == "YES" ]]; then
    read -rp "$(echo -e "${Tip}检测到已经安装了caddy,是否重新安装（Y/n）?(默认：n)")" Yn
    [[ -z ${Yn} ]] && Yn="n"
    case ${Yn} in
    [yY][eE][sS] | [yY])
      echo -e "${Info}开始安装caddy……"
      if [[ ${release} == "debian" || ${release} == "ubuntu" ]]; then
        echo "deb [trusted=yes] https://apt.fury.io/caddy/ /" |
          tee -a /etc/apt/sources.list.d/caddy-fury.list
        apt update
        apt install caddy
      elif [[ ${release} == "centos" ]]; then
        yum install yum-plugin-copr
        yum copr enable @caddy/caddy
        yum install caddy
      #elif [[ ${release} == "centos" ]]; then
      #  dnf install 'dnf-command(copr)'
      #  dnf copr enable @caddy/caddy
      #  dnf install caddy
      fi
      ;;
    *)
      echo -e "${Info}跳过caddy安装……"
      ;;
    esac
  else
    echo -e "${Info}开始安装caddy……"
    if [[ ${release} == "debian" || ${release} == "ubuntu" ]]; then
      echo "deb [trusted=yes] https://apt.fury.io/caddy/ /" |
        tee -a /etc/apt/sources.list.d/caddy-fury.list
      apt update
      apt install caddy
    elif [[ ${release} == "centos" ]]; then
      yum install yum-plugin-copr -y
      yum copr enable @caddy/caddy -y
      yum install caddy -y
    fi
  fi
}
install_caddy_service() {
  #rm -f ${caddy_systemd_file}
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
  #random_num=$((RANDOM%12+4))
  #email="$(head -n 10 /dev/urandom | md5sum | head -c ${random_num})@gmail.com"
  #caddy -service install -agree -email "${email}" -conf "${caddy_conf}"

  sed -i 's/User=caddy/User=root/' ${caddy_systemd_file}
  sed -i 's/Group=caddy/Group=root/' ${caddy_systemd_file}
}
install_trojan() {
  if [[ ${trojan_install_flag} == "YES" ]]; then
    read -rp "$(echo -e "${Tip}检测到已经安装了trojan,是否重新安装（Y/n）?(默认：n)")" Yn
    [[ -z ${Yn} ]] && Yn="n"
    case ${Yn} in
    [yY][eE][sS] | [yY])
      echo -e "${Info}开始安装trojan……"
      sleep 2
      bash -c "$(curl -fsSL https://raw.githubusercontent.com/trojan-gfw/trojan-quickstart/master/trojan-quickstart.sh)"
      ;;
    *) ;;

    esac
  else
    echo -e "${Info}开始安装trojan……"
    sleep 2
    bash -c "$(curl -fsSL https://raw.githubusercontent.com/trojan-gfw/trojan-quickstart/master/trojan-quickstart.sh)"
  fi
}
install_ssr() {
  if [[ ${ssr_install_flag} == "YES" ]]; then
    read -rp "$(echo -e "${Tip}检测到已经安装了ssr,是否重新安装（Y/n）?(默认：n)")" Yn
    [[ -z ${Yn} ]] && Yn="n"
    case ${Yn} in
    [yY][eE][sS] | [yY])
      echo -e "${Info}开始安装SSR……"
      sleep 2
      [[ ! -d ${ssr_conf_dir} ]] && mkdir ${ssr_conf_dir}
      wget --no-check-certificate -O ${ssr_conf_dir}/shadowsocks-all.sh https://raw.githubusercontent.com/JeannieStudio/jeannie/master/shadowsocks-all.sh
      chmod +x ${ssr_conf_dir}/shadowsocks-all.sh
      \n | . ${ssr_conf_dir}/shadowsocks-all.sh 2>&1 | tee shadowsocks-all.log
      ;;
    *) ;;

    esac
  else
    echo -e "${Info}开始安装SSR……"
    sleep 2
    [[ ! -d ${ssr_conf_dir} ]] && mkdir ${ssr_conf_dir}
    wget --no-check-certificate -O ${ssr_conf_dir}/shadowsocks-all.sh https://raw.githubusercontent.com/JeannieStudio/jeannie/master/shadowsocks-all.sh
    chmod +x ${ssr_conf_dir}/shadowsocks-all.sh
    \n | . ${ssr_conf_dir}/shadowsocks-all.sh 2>&1 | tee shadowsocks-all.log
  fi
}
set_port() {
  while true; do
    dport=$(shuf -i 9000-19999 -n 1)
    echo -e "${Info}请输入$1端口号 [1-65535],注意：如果安装了v2ray、caddy、trojan、ssr等服务，请不要与这些服务的端口号重复"
    read -rp "(默认端口: ${dport}):" port
    [ -z "$port" ] && port=${dport}
    expr "$port" + 1 &>/dev/null
    if [ $? -eq 0 ]; then
      if [ "$port" -ge 1 ] && [ "$port" -le 65535 ] && [ "$port" != 0 ]; then
        echo
        echo -e "${Info}$1端口是：$port"
        echo
        break
      fi
    fi
    echo -e "${Error} 请输入一个正确的端口[1-65535]"
  done
}
nginx_trojan_conf() {
  touch ${nginx_conf_dir}/default.conf
  cat >${nginx_conf_dir}/default.conf <<EOF
  server {
    listen ${webport};
    server_name ${domain};
    root ${web_dir};
    ssl on;
    ssl_certificate   /data/${domain}/fullchain.crt;
    ssl_certificate_key  /data/${domain}/${domain}.key;
	  ssl_ciphers                 TLS13-AES-256-GCM-SHA384:TLS13-CHACHA20-POLY1305-SHA256:TLS13-AES-128-GCM-SHA256:TLS13-AES-128-CCM-8-SHA256:TLS13-AES-128-CCM-SHA256:EECDH+CHACHA20:EECDH+CHACHA20-draft:EECDH+ECDSA+AES128:EECDH+aRSA+AES128:RSA+AES128:EECDH+ECDSA+AES256:EECDH+aRSA+AES256:RSA+AES256:EECDH+ECDSA+3DES:EECDH+aRSA+3DES:RSA+3DES:!MD5;
    ssl_prefer_server_ciphers    on;
    ssl_protocols                TLSv1 TLSv1.1 TLSv1.2 TLSv1.3;
    ssl_session_cache            shared:SSL:50m;
    ssl_session_timeout          1d;
    ssl_session_tickets          on;
}
EOF
}
nginx_v2ray_conf() {
  touch ${nginx_conf_dir}/default.conf
  cat >${nginx_conf_dir}/default.conf <<EOF
  server {
      listen ${webport} ssl http2;
      ssl_certificate       /data/${domain}/fullchain.crt;
      ssl_certificate_key   /data/${domain}/${domain}.key;
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
EOF
}
nginx_vless_conf() {
  touch ${nginx_conf_dir}/default.conf
  cat >${nginx_conf_dir}/default.conf <<EOF
  server {
      listen ${webport} ssl http2;
      ssl_certificate       /data/${domain}/fullchain.crt;
      ssl_certificate_key   /data/${domain}/${domain}.key;
      ssl_protocols         TLSv1.3;
      ssl_ciphers           TLS13-AES-256-GCM-SHA384:TLS13-CHACHA20-POLY1305-SHA256:TLS13-AES-128-GCM-SHA256:TLS13-AES-128-CCM-8-SHA256:TLS13-AES-128-CCM-SHA256:EECDH+CHACHA20:EECDH+CHACHA20-draft:EECDH+ECDSA+AES128:EECDH+aRSA+AES128:RSA+AES128:EECDH+ECDSA+AES256:EECDH+aRSA+AES256:RSA+AES256:EECDH+ECDSA+3DES:EECDH+aRSA+3DES:RSA+3DES:!MD5;
      server_name           $domain;
      index index.html index.htm;
      root ${web_dir};
      error_page 400 = /400.html;
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
  read -rp "$(echo -e "${Tip}已为您生成了uuid:${uuid},确认使用吗?[Y/n]?")" yn
  while [[ "${yn}" != [Yy] ]]; do
    uuid=$(cat /proc/sys/kernel/random/uuid)
    read -rp "$(echo -e "${Tip}已为您生成了uuid:${uuid},确认使用吗?[Y/n]?")" yn
  done
  [[ ! -d "${v2ray_conf_dir}" ]] && mkdir ${v2ray_conf_dir}
  cat >${v2ray_conf} <<EOF
	  {
      "inbounds": [
        {
          "port": 10000,
          "listen":"127.0.0.1",
          "protocol": "vmess",
          "settings": {
            "clients": [
              {
                "id": "${uuid}",
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
EOF
}
vless_conf() {
  uuid=$(cat /proc/sys/kernel/random/uuid)
  read -rp "$(echo -e "${Tip}已为您生成了uuid:${uuid},确认使用吗?[Y/n]?")" yn
  while [[ "${yn}" != [Yy] ]]; do
    uuid=$(cat /proc/sys/kernel/random/uuid)
    read -rp "$(echo -e "${Tip}已为您生成了uuid:${uuid},确认使用吗?[Y/n]?")" yn
  done
  [[ ! -d "${v2ray_conf_dir}" ]] && mkdir ${v2ray_conf_dir}
  cat >${v2ray_conf} <<EOF
	  {
    "log": {
        "loglevel": "warning"
    },
    "inbounds": [
        {
            "port": ${vlessport},
            "protocol": "vless",
            "settings": {
                "clients": [
                    {
                        "id": "${uuid}",
                        "level": 0,
                        "email": "jeannie@gmail.com"
                    }
                ],
                "decryption": "none",
                "fallbacks": [
                    {
                        "dest": ${webport}
                    },
                    {
                        "path": "/ray/",
                        "dest": 65535,
                        "xver": 1
                    }
                ]
            },
            "streamSettings": {
                "network": "tcp",
                "security": "tls",
                "tlsSettings": {
                    "alpn": [
                        "http/1.1"
                    ],
                    "certificates": [
                        {
                            "certificateFile": "/data/${domain}/fullchain.crt",
                            "keyFile": "/data/${domain}/${domain}.key"
                        }
                    ]
                }
            }
        },
        {
            "port": 65535,
            "listen": "127.0.0.1",
            "protocol": "vless",
            "settings": {
                "clients": [
                    {
                        "id": "${uuid}",
                        "level": 0,
                        "email": "jeannie@gmail.com"
                    }
                ],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "ws",
                "security": "none",
                "wsSettings": {
                    "acceptProxyProtocol": true,
                    "path": "/ray/"
                }
            }
        }
    ],
    "outbounds": [
        {
            "protocol": "freedom"
        }
    ]
}
EOF
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
    read -rp "$(echo -e "${Tip}请输入你要下载的网站的数字:")" aNum
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
  cat >${caddy_conf} <<EOF
https://${domain}:${webport} {
  encode gzip
  tls /data/${domain}/fullchain.crt /data/${domain}/${domain}.key
  root * /usr/wwwroot
  file_server
  root * ${web_dir}
  reverse_proxy /ray/ 127.0.0.1:10000 {
      header_up Host {http.reverse_proxy.upstream.hostport}
      header_up X-Real-IP {http.request.remote}
      header_up X-Forwarded-For {http.request.remote}
      header_up X-Forwarded-Port {http.request.port}
      header_up X-Forwarded-Proto {http.request.scheme}
      }
}
EOF
}
caddy_vless_conf() {
  cat >${caddy_conf} <<EOF
https://${domain}:${webport} {
  encode gzip
  tls /data/${domain}/fullchain.crt /data/${domain}/${domain}.key
  root * /usr/wwwroot
  file_server
  root * ${web_dir}
}
EOF
}
caddy_trojan_conf() {
  [[ ! -d ${caddy_conf_dir} ]] && mkdir ${caddy_conf_dir}
  cat >${caddy_conf} <<_EOF
https://${domain}:${webport} {
  encode gzip
  tls /data/${domain}/fullchain.crt /data/${domain}/${domain}.key
  root * ${web_dir}
  file_server
  header X-Real-IP {http.request.remote.host}
  header X-Forwarded-For {http.request.remote.host}
  header X-Forwarded-Port {http.request.port}
  header X-Forwarded-Proto {http.request.scheme}
}
_EOF
}
caddy_ssr_conf() {
  cat >${caddy_conf} <<_EOF
https://${domain}:${webport} {
  encode gzip
  tls /data/${domain}/fullchain.crt /data/${domain}/${domain}.key
  root * ${web_dir}
  file_server
  header X-Real-IP {http.request.remote.host}
  header X-Forwarded-For {http.request.remote.host}
  header X-Forwarded-Port {http.request.port}
  header X-Forwarded-Proto {http.request.scheme}
}
_EOF
}
trojan_conf() {
  read -rp "$(echo -e "${Info}请输入您的trojan密码1,注意：密码只能是数字或大小写字母的组合")" password1
  while [[ -z ${password1} ]]; do
    read -rp "$(echo -e "${Tip}密码1不能为空,请重新输入您的trojan密码1，注意：密码只能是数字或大小写字母的组合")" password1
  done
  read -rp "$(echo -e "${Info}请输入您的trojan密码2，注意：密码只能是数字或大小写字母的组合")" password2
  while [[ -z ${password2} ]]; do
    read -rp "$(echo -e "${Tip}密码2不能为空,请重新输入您的trojan密码2，注意：密码只能是数字或大小写字母的组合")" password2
  done
  touch ${trojan_conf}
  cat >${trojan_conf} <<_EOF
  {
    "run_type": "server",
    "local_addr": "0.0.0.0",
    "local_port": ${trojanport},
    "remote_addr": "127.0.0.1",
    "remote_port": ${webport},
    "password": [
        "${password1}",
        "${password2}"
    ],
    "log_level": 1,
    "ssl": {
        "cert": "/data/${domain}/fullchain.crt",
        "key": "/data/${domain}/${domain}.key",
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

}

ssr_conf() {
  read -rp "$(echo -e "${Info}请输入ssr的密码:")" password
  while [[ -z ${password} ]]; do
    read -rp "$(echo -e "${Info}密码不能为空,请重新输入:")" password
  done
  #sed -i "\"server_port\": /c         \"server_port\":443," ${ssr_conf}
  #sed -i "\"redirect\": /c        \"redirect\":[\"*:443#127.0.0.1:80\"]," ${ssr_conf}
  cat >${ssr_conf} <<EOF
  {
    "server":"0.0.0.0",
    "server_ipv6":"::",
    "server_port":${ssrport},
    "local_address":"127.0.0.1",
    "local_port":1080,
    "password":"${password}",
    "timeout":120,
    "method":"chacha20-ietf",
    "protocol":"auth_chain_a",
    "protocol_param":"",
    "obfs":"tls1.2_ticket_auth",
    "obfs_param":"",
    "redirect":["*:${ssrport}#127.0.0.1:1234"],
    "dns_ipv6":false,
    "fast_open":true,
    "workers":1
}
EOF
}
tls_generate_script_install() {
  if [[ "${cmd}" == "yum" ]]; then
    ${cmd} install socat nc -y
  else
    ${cmd} install socat netcat -y
  fi
  sucess_or_fail "安装 tls 证书生成脚本依赖"

  curl https://get.acme.sh | sh
  sucess_or_fail "安装 tls 证书生成脚本"
  source ~/.bashrc
}
tls_generate() {
  if [[ -f "/data/${domain}/fullchain.crt" ]] && [[ -f "/data/${domain}/${domain}.key" ]]; then
    echo -e "${Info}证书已存在……不需要再重新签发了……"
  else
    if "$HOME"/.acme.sh/acme.sh --issue -d "${domain}" --standalone -k ec-256 --force --test; then
      echo -e "${Info} TLS 证书测试签发成功，开始正式签发"
      rm -rf "$HOME/.acme.sh/${domain}_ecc"
      sleep 2
    else
      echo -e "${Error}TLS 证书测试签发失败 "
      rm -rf "$HOME/.acme.sh/${domain}_ecc"
      exit 1
    fi

    if "$HOME"/.acme.sh/acme.sh --issue -d "${domain}" --standalone -k ec-256 --force; then
      echo -e "${Info} TLS 证书生成成功 "
      sleep 2
      [[ ! -d "/data" ]] && mkdir /data
      [[ ! -d "/data/${domain}" ]] && mkdir "/data/${domain}"
      if "$HOME"/.acme.sh/acme.sh --installcert -d "${domain}" --fullchainpath /data/"${domain}"/fullchain.crt --keypath /data/"${domain}"/"${domain}".key --ecc --force; then
        echo -e "${Info}证书配置成功 "
        sleep 2
      fi
    else
      echo -e "${Error} TLS 证书生成失败"
      rm -rf "$HOME/.acme.sh/${domain}_ecc"
      exit 1
    fi
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
  "trojanport":"${trojanport}"
  "webport":"${webport}"
EOF
}
trojan_qr_link_image() {
  trojan_link1="trojan://${password1}@${domain}:${trojanport}"
  trojan_link2="trojan://${password2}@${domain}:${trojanport}"
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
${GREEN}端口：   $(trojan_info_extraction '\"trojanport\"')
${GREEN}密码1：  $(trojan_info_extraction '\"password1\"')
${GREEN}密码2：  $(trojan_info_extraction '\"password2\"')
${GREEN}重启服务、修改密码、修改端口号、查看证书有效期等，请执行：/etc/all_mgr.sh
${FUCHSIA}=========================   分享链接和二维码  ===============================
${GREEN}分享链接1：
${trojan_link1}
${GREEN}分享链接2：
${trojan_link2}
${GREEN}二维码1：  ${web_dir}/${uuid}-01.png
${GREEN}二维码2：  ${web_dir}/${uuid}-02.png
${FUCHSIA}=========================   懒人请往这儿瞧  ===============================
${GREEN}详细信息：https://${domain}:${webport}/${uuid}.html${NO_COLOR}"
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
  "ssrport":"${ssrport}"
}
EOF
}
ssr_info_extraction() {
  grep "$1" ${ssr_conf} | awk -F '"' '{print $4}'
}
ssr_qr_info_extraction() {
  grep "$1" ${ssr_qr_config_file} | awk -F '"' '{print $4}'
}
ssr_qr_link_image() {
  password=$(ssr_info_extraction '\"password\"')
  protocol=$(ssr_info_extraction '\"protocol\"')
  method=$(ssr_info_extraction '\"method\"')
  obfs=$(ssr_info_extraction '\"obfs\"')
  tmp1=$(echo -n "${password}" | base64 -w0 | sed 's/=//g;s/\//_/g;s/+/-/g')
  tmp2=$(echo -n "${domain}:${ssrport}:${protocol}:${method}:${obfs}:${tmp1}/?obfsparam=" | base64 -w0)
  ssr_link="ssr://${tmp2}"
  qrencode -o ${web_dir}/${uuid}.png -s 8 "${ssr_link}"
}
ssr_info_html() {
  vps="ssr"
  wget --no-check-certificate -O ${web_dir}/ssr_tmpl.html https://raw.githubusercontent.com/JeannieStudio/jeannie/master/ssr_tmpl.html
  chmod +x ${web_dir}/ssr_tmpl.html
  eval "cat <<EOF
  $(<${web_dir}/ssr_tmpl.html)
EOF
  " >${web_dir}/${uuid}.html
}
ssr_basic_information() {
  {
    echo -e "
${GREEN}=========================ssr+tls 安装成功==============================
${FUCHSIA}=========================   SSR 配置信息  =============================
${GREEN}地址：   ${domain}
${GREEN}端口：   ${ssrport}
${GREEN}密码：  $(ssr_info_extraction '\"password\"')
${GREEN}加密方式：  $(ssr_info_extraction '\"method\"')
${GREEN}协议：  $(ssr_info_extraction '\"protocol\"')
${GREEN}混淆：  $(ssr_info_extraction '\"obfs\"')
${GREEN}重启服务、修改密码、修改端口号、查看证书有效期等，请执行：/etc/all_mgr.sh
${FUCHSIA}=========================   分享链接和二维码  ===============================
${GREEN}分享链接：
${ssr_link}
${GREEN}二维码：  ${web_dir}/${uuid}.png
${FUCHSIA}=========================   懒人请往这儿瞧  ===============================
${GREEN}详细信息：https://${domain}:${ssrport}/${uuid}.html${NO_COLOR}"
  } | tee /etc/motd
}
v2ray_shadowrocket_qr_config() {
  touch ${v2ray_shadowrocket_qr_config_file}
  cat >${v2ray_shadowrocket_qr_config_file} <<EOF
{
  "v":"2",
  "ps": "Jeannie_${domain}",
  "add": "${domain}",
  "port": "${webport}",
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
  "v":"2",
  "ps": "Jeannie_${domain}",
  "add": "${domain}",
  "port": "${webport}",
  "id": "${uuid}",
  "aid": "64",
  "net": "ws",
  "type": "none",
  "host": "/ray/",
  "tls": "tls"
}
EOF
}
vless_shadowrocket_qr_config() {
  touch ${v2ray_shadowrocket_qr_config_file}
  cat >${v2ray_shadowrocket_qr_config_file} <<EOF
{
  "v":"2",
  "ps": "Jeannie_${domain}",
  "add": "${domain}",
  "port": "${vlessport}",
  "id": "${uuid}",
  "aid": "64",
  "net": "ws",
  "type": "none",
  "host": "${domain}",
  "path": "/ray/",
  "tls": "tls",
  "webport":"${webport}"
}
EOF
}
vless_win_and_android_qr_config() {
  touch ${v2ray_win_and_android_qr_config_file}
  cat >${v2ray_win_and_android_qr_config_file} <<EOF
{
  "v":"2",
  "ps": "Jeannie_${domain}",
  "add": "${domain}",
  "port": "${vlessport}",
  "id": "${uuid}",
  "aid": "64",
  "net": "ws",
  "type": "none",
  "host": "/ray/",
  "tls": "tls",
  "webport":"${webport}"
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
vless_shadowrocket_qr_link_image() {
  vless_link1="vless://$(base64 -w 0 ${v2ray_shadowrocket_qr_config_file})"
  qrencode -o ${web_dir}/${uuid}-1.png -s 6 "${vless_link1}"
}
vless_win_and_android_qr_link_image() {
  vless_link2="vless://$(base64 -w 0 ${v2ray_win_and_android_qr_config_file})"
  qrencode -o ${web_dir}/${uuid}-2.png -s 6 "${vless_link2}"
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
vless_info_html() {
  vps="v2ray"
  wget --no-check-certificate -O ${web_dir}/v2ray_tmpl.html https://raw.githubusercontent.com/JeannieStudio/jeannie/master/vless_tmpl.html
  chmod +x ${web_dir}/v2ray_tmpl.html
  eval "cat <<EOF
  $(<${web_dir}/v2ray_tmpl.html)
EOF
" >${web_dir}/${uuid}.html
}
vmess_basic_information() {
  {
    echo -e "
${GREEN}=========================Vmess+ws+tls 安装成功==============================
${FUCHSIA}=========================   V2ray 配置信息   ===============================
${GREEN}地址(address):       $(v2ray_info_extraction '\"add\"')
${GREEN}端口（port）：        ${webport}
${GREEN}用户id（UUID）：      $(v2ray_info_extraction '\"id\"')
${GREEN}额外id（alterId）：   64
${GREEN}加密方式（security）：自适应
${GREEN}传输协议（network）： ws
${GREEN}伪装类型（type）：    none
${GREEN}路径（不要落下/）：   /ray/
${GREEN}底层传输安全：        tls
${GREEN}重启服务、修改密码、修改端口号、查看证书有效期等，请执行：/etc/all_mgr.sh
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
${GREEN}https://$(v2ray_info_extraction '\"add\"'):${webport}/${uuid}.html${NO_COLOR}"
  } | tee /etc/motd
}
vless_basic_information() {
  {
    echo -e "
${GREEN}=========================Vless+ws+tls 安装成功==============================
${FUCHSIA}=========================   V2ray 配置信息   ===============================
${GREEN}地址(address):       $(v2ray_info_extraction '\"add\"')
${GREEN}端口（port）：        ${vlessport}
${GREEN}用户id（UUID）：      $(v2ray_info_extraction '\"id\"')
${GREEN}加密方式（security）：自适应
${GREEN}传输协议（network）： ws
${GREEN}伪装类型（type）：    none
${GREEN}路径（不要落下/）：   /ray/
${GREEN}底层传输安全：        tls
${GREEN}重启服务、修改密码、修改端口号、查看证书有效期等，请执行：/etc/all_mgr.sh
${FUCHSIA}=========================   分享链接和二维码  ===============================
${GREEN}windows和安卓客户端v2rayN分享链接：
${BLUE}官方暂未提供VLESS 的分享链接标准
${GREEN}ios客户端shadowroket分享链接：
${BLUE}官方暂未提供VLESS 的分享链接标准
${GREEN}windows和安卓客户端v2rayN二维码：
${BLUE}官方暂未提供VLESS 的分享链接标准
${GREEN}ios客户端shadowroket二维码：
${BLUE}官方暂未提供VLESS 的分享链接标准
${FUCHSIA}=========================   懒人请往这儿瞧  ======================================
${GREEN}https://$(v2ray_info_extraction '\"add\"'):${webport}/${uuid}.html${NO_COLOR}"
  } | tee /etc/motd
}
download_all_mgr() {
  curl -s -o /etc/all_mgr.sh https://raw.githubusercontent.com/JeannieStudio/all_install/master/all_mgr.sh
  sucess_or_fail "修改密码、重启服务、查询证书相关信息的管理脚本下载"
  chmod +x /etc/all_mgr.sh
}
left_second() {
  seconds_left=5
  while [ $seconds_left -gt 0 ]; do
    echo -n $seconds_left
    sleep 1
    seconds_left=$(($seconds_left - 1))
    echo -ne "\r     \r"
  done
}
reboot_sys() {
  if [[ ${release} == "centos" ]]; then
    echo -e "${Info}系统需要重启后才能生效，马上重启……"
  fi
}
install_trojan_nginx() {
  set_SELINUX
  set_PATH
  check_root
  check_sys
  sys_cmd
  install_dependency
  check_caddy_installed_status
  uninstall_caddy
  check_v2ray_installed_status
  uninstall_v2ray
  check_ssr_installed_status
  uninstall_ssr
  uninstall_web
  get_ip
  check_domain
  port_used_check 80
  port_used_check 443
  tls_generate_script_install
  tls_generate
  check_nginx_installed_status
  install_nginx
  nginx_systemd
  set_port nginx
  webport=$port
  port_used_check "${webport}"
  nginx_trojan_conf
  web_download
  systemctl restart nginx
  systemctl enable nginx
  check_trojan_installed_status
  install_trojan
  set_port trojan
  trojanport=$port
  port_used_check "${trojanport}"
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
  echo "unset MAILCHECK" >>/etc/profile
}
install_trojan_caddy() {
  set_SELINUX
  set_PATH
  check_root
  check_sys
  sys_cmd
  install_dependency
  check_nginx_installed_status
  uninstall_nginx
  check_v2ray_installed_status
  uninstall_v2ray
  check_ssr_installed_status
  uninstall_ssr
  uninstall_web
  get_ip
  check_domain
  port_used_check 80
  port_used_check 443
  tls_generate_script_install
  tls_generate
  check_caddy_installed_status
  install_caddy
  install_caddy_service
  systemctl daemon-reload
  set_port caddy
  webport=$port
  port_used_check "${webport}"
  caddy_trojan_conf
  web_download
  systemctl restart caddy.service
  check_trojan_installed_status
  install_trojan
  set_port trojan
  trojanport=$port
  port_used_check "${trojanport}"
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
  echo "unset MAILCHECK" >>/etc/profile
}
install_vmess_nginx() {
  set_SELINUX
  set_PATH
  check_root
  check_sys
  sys_cmd
  install_dependency
  check_caddy_installed_status
  uninstall_caddy
  check_trojan_installed_status
  uninstall_trojan
  check_ssr_installed_status
  uninstall_ssr
  uninstall_web
  get_ip
  check_domain
  port_used_check 80
  port_used_check 443
  tls_generate_script_install
  tls_generate
  check_nginx_installed_status
  install_nginx
  nginx_systemd
  set_port nginx
  webport=$port
  port_used_check "${webport}"
  nginx_v2ray_conf
  tls_type
  web_download
  systemctl restart nginx
  systemctl enable nginx
  check_v2ray_installed_status
  install_v2ray
  install_v2ray_service
  systemctl daemon-reload
  v2ray_conf
  systemctl enable v2ray
  systemctl restart v2ray
  v2ray_shadowrocket_qr_config
  v2ray_win_and_android_qr_config
  v2ray_shadowrocket_qr_link_image
  v2ray_win_and_android_qr_link_image
  v2ray_info_extraction
  v2ray_info_html
  remove_mgr
  download_all_mgr
  vmess_basic_information
  echo "unset MAILCHECK" >>/etc/profile
}
install_vmess_caddy() {
  set_SELINUX
  set_PATH
  check_root
  check_sys
  sys_cmd
  install_dependency
  check_nginx_installed_status
  uninstall_nginx
  check_trojan_installed_status
  uninstall_trojan
  check_ssr_installed_status
  uninstall_ssr
  uninstall_web
  get_ip
  check_domain
  port_used_check 80
  port_used_check 443
  tls_generate_script_install
  tls_generate
  check_caddy_installed_status
  install_caddy
  install_caddy_service
  systemctl daemon-reload
  set_port caddy
  webport=$port
  port_used_check "${webport}"
  caddy_v2ray_conf
  web_download
  systemctl restart caddy.service
  check_v2ray_installed_status
  install_v2ray
  install_v2ray_service
  v2ray_conf
  service v2ray restart
  systemctl enable v2ray
  v2ray_shadowrocket_qr_config
  v2ray_win_and_android_qr_config
  v2ray_shadowrocket_qr_link_image
  v2ray_win_and_android_qr_link_image
  v2ray_info_extraction
  v2ray_info_html
  remove_mgr
  download_all_mgr
  vmess_basic_information
  echo "unset MAILCHECK" >>/etc/profile
}
install_vless_nginx() {
  set_SELINUX
  set_PATH
  check_root
  check_sys
  sys_cmd
  install_dependency
  check_caddy_installed_status
  uninstall_caddy
  check_trojan_installed_status
  uninstall_trojan
  check_ssr_installed_status
  uninstall_ssr
  uninstall_web
  get_ip
  check_domain
  port_used_check 80
  port_used_check 443
  tls_generate_script_install
  tls_generate
  check_nginx_installed_status
  install_nginx
  nginx_systemd
  set_port nginx
  webport=$port
  port_used_check "${webport}"
  nginx_vless_conf
  tls_type
  web_download
  systemctl restart nginx
  systemctl enable nginx
  check_v2ray_installed_status
  install_v2ray
  install_v2ray_service
  systemctl daemon-reload
  set_port v2ray
  vlessport=$port
  port_used_check "${vlessport}"
  vless_conf
  systemctl enable v2ray
  service v2ray restart
  vless_shadowrocket_qr_config
  vless_win_and_android_qr_config
  vless_shadowrocket_qr_link_image
  vless_win_and_android_qr_link_image
  v2ray_info_extraction
  vless_info_html
  remove_mgr
  download_all_mgr
  vless_basic_information
  echo "unset MAILCHECK" >>/etc/profile
}
install_vless_caddy() {
  set_SELINUX
  set_PATH
  check_root
  check_sys
  sys_cmd
  install_dependency
  check_nginx_installed_status
  uninstall_nginx
  check_trojan_installed_status
  uninstall_trojan
  check_ssr_installed_status
  uninstall_ssr
  uninstall_web
  get_ip
  check_domain
  port_used_check 80
  port_used_check 443
  tls_generate_script_install
  tls_generate
  check_caddy_installed_status
  install_caddy
  install_caddy_service
  systemctl daemon-reload
  set_port caddy
  webport=$port
  port_used_check "${webport}"
  caddy_vless_conf
  web_download
  systemctl restart caddy.service
  check_v2ray_installed_status
  install_v2ray
  install_v2ray_service
  systemctl daemon-reload
  set_port v2ray
  vlessport=$port
  port_used_check "${vlessport}"
  vless_conf
  service v2ray restart
  systemctl enable v2ray
  vless_shadowrocket_qr_config
  vless_win_and_android_qr_config
  vless_shadowrocket_qr_link_image
  vless_win_and_android_qr_link_image
  v2ray_info_extraction
  vless_info_html
  remove_mgr
  download_all_mgr
  vless_basic_information
  echo "unset MAILCHECK" >>/etc/profile
}
install_ssr_caddy() {
  set_SELINUX
  set_PATH
  check_root
  check_sys
  sys_cmd
  install_dependency
  check_nginx_installed_status
  uninstall_nginx
  check_v2ray_installed_status
  uninstall_v2ray
  check_trojan_installed_status
  uninstall_trojan
  uninstall_web
  get_ip
  check_domain
  port_used_check 80
  port_used_check 443
  tls_generate_script_install
  tls_generate
  check_caddy_installed_status
  install_caddy
  install_caddy_service
  systemctl daemon-reload
  set_port caddy
  caddy_ssr_conf
  web_download
  systemctl restart caddy.service
  check_ssr_installed_status
  install_ssr
  set_port ssr
  ssrport=$port
  port_used_check "${ssrport}"
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
  echo "unset MAILCHECK" >>/etc/profile
}
install_bbr() {
  wget -N --no-check-certificate "https://raw.githubusercontent.com/chiakge/Linux-NetSpeed/master/tcp.sh"
  chmod +x tcp.sh
  ./tcp.sh
}
uninstall_all() {
  check_root
  check_sys
  sys_cmd
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
  remove_motd
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
${GREEN}trojan、v2ray、ssr八合一脚本(authored by Jeannie)
${FUCHSIA}===================================================
${GREEN}如果已经安装了下列脚本之一，想要安装其他的，不需要单独执行卸载，直接选择想要安装脚本对应的数字即可……
${GREEN}因为安装的同时会执行卸载，除非想卸载干净回到初始状态,可以执行7……
${FUCHSIA}===================================================
${GREEN}1. 安装trojan+tls+nginx
${FUCHSIA}===================================================
${GREEN}2. 安装trojan+tls+caddy
${FUCHSIA}===================================================
${GREEN}3. 安装vmess+tls+nginx
${FUCHSIA}===================================================
${GREEN}4. 安装vmess+tls+caddy
${FUCHSIA}===================================================
${GREEN}5. 安装vless+tls+nginx
${FUCHSIA}===================================================
${GREEN}6. 安装vless+tls+caddy
${FUCHSIA}===================================================
${GREEN}7. 安装ssr+tls+caddy
${FUCHSIA}===================================================
${GREEN}8. 安装ssr+tls+nginx
${FUCHSIA}===================================================
${GREEN}9. 卸载全部，系统回到初始状态
${FUCHSIA}===================================================
${GREEN}10. 安装BBR加速
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
    install_vmess_nginx
    ;;
  4)
    install_vmess_caddy
    ;;
  5)
    install_vless_nginx
    ;;
  6)
    install_vless_caddy
    ;;
  7)
    install_ssr_caddy
    ;;
  8)
    echo -e "${Tip}脚本开发中，敬请期待……"
    ;;
  9)
    uninstall_all
    ;;
  10)
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
