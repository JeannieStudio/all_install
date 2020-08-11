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
trojan_dir=/etc/trojan
trojan_bin_dir=${trojan_dir}/bin
trojan_conf_dir=${trojan_dir}/conf
trojan_conf_file=${trojan_conf_dir}/server.json
trojan_qr_config_file=${trojan_conf_dir}/qrconfig.json
web_dir="/usr/wwwroot"
nginx_bin_file="/etc/nginx/sbin/nginx"
nginx_conf_dir="/etc/nginx/conf/conf.d"
nginx_conf="${nginx_conf_dir}/default.conf"
nginx_dir="/etc/nginx"
nginx_openssl_src="/usr/local/src"
nginx_systemd_file="/etc/systemd/system/nginx.service"
trojan_systemd_file="/etc/systemd/system/trojan.service"
caddy_bin_dir="/usr/bin/caddy"
caddy_conf_dir="/etc/caddy"
caddy_conf="${caddy_conf_dir}/Caddyfile"
caddy_systemd_file="/lib/systemd/system/caddy.service"
nginx_version="1.18.0"
openssl_version="1.1.1g"
jemalloc_version="5.2.1"
old_config_status="off"
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
  bit=`uname -m`
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
GCE_debian10(){
  echo -e "${Tip}${RedBG}因为谷歌云的debian10抽风，所以需要确认您当前是否是谷歌云的debian10系统吗（Y/n）？"
  echo -e "${Tip}${RedBG}只有谷歌云的debian10系统才填y，其他都填n。如果填错，将直接导致您后面无法科学上网（Y/n）(默认：n)${NO_COLOR}"
  read -rp "请输入:" Yn
  [[ -z ${Yn} ]] && Yn="n"
    case ${Yn} in
    [yY][eE][sS] | [yY])
           is_debian10="y"
        ;;
    *)
        ;;
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
    real_ip=$(ping ${domain} -c 1 | sed '1{s/[^(]*(//;s/).*//;q}')
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
sys_cmd(){
  if [[ ${release} == "centos" ]]; then
    cmd="yum"
  else
    cmd="apt"
  fi
}
check_root() {
  [[ $EUID != 0 ]] && echo -e "${Error} ${RedBG} 当前非ROOT账号(或没有ROOT权限)，无法继续操作，请执行命令 ${Green_background_prefix}sudo -i${Font_color_suffix} 更换ROOT账号" && exit 1
}
trojan_info_extraction() {
  grep "$1" ${trojan_qr_config_file} | awk -F '"' '{print $4}'
}
get_info(){
  domain=$(trojan_info_extraction '\"domain\"')
  uuid=$(trojan_info_extraction '\"uuid\"')
  password=$(trojan_info_extraction '\"password\"')
  websocket_status=$(trojan_info_extraction '\"websocket_status\"')
  websocket_path=$(trojan_info_extraction '\"websocket_path\"')
  mux_status=$(trojan_info_extraction '\"mux_status\"')
  trojanport=$(trojan_info_extraction '\"trojanport\"')
  webport=$(trojan_info_extraction '\"webport\"')
}
update_trojan_info(){
  sed -i "s|\"password\":.*|\"password\": \"${password}\"|" ${trojan_qr_config_file}
  sed -i "s|\"websocket_status\":.*|\"websocket_status\": \"${websocket_status}\"|" ${trojan_qr_config_file}
  sed -i "s|\"websocket_path\":.*|\"websocket_path\": \"${websocket_path}\"|" ${trojan_qr_config_file}
  sed -i "s|\"mux_status\":.*|\"mux_status\": \"${mux_status}\"|" ${trojan_qr_config_file}
  sed -i "s|\"trojanport\":.*|\"trojanport\": \"${trojanport}\"|" ${trojan_qr_config_file}
}
open_websocket(){
  if [[ ${websocket_status} == "开启" ]]; then
    echo -e "${Info}websocket已处于开启状态，无需再开启了！"
    exit 1
  else
    echo -e "${Info}如果启用了websocket协议,您就可以开启CDN了，如果用cloudflare解析域名的，搭建完成后可以点亮小云彩了。"
    read -rp "$(echo -e "${Info}是否开启（Y/n）？（默认：n）")" Yn
      case ${Yn} in
      [yY][eE][sS] | [yY])
          sed -i "53c    \"enabled\": true," ${trojan_conf_file}
          sed -i "53c    \"enabled\": true," ${web_dir}/"${uuid}".json
          sed -i "54c    \"path\": \"/trojan\"," ${trojan_conf_file}
          sed -i "54c    \"path\": \"/trojan\"," ${web_dir}/"${uuid}".json
          websocket_path="/trojan"
          websocket_status="开启"
          ;;
      *)
        echo -e "${Info}什么也没做……"
        exit 1
          ;;
      esac
  fi
}
open_mux(){
   if [[ ${mux_status} == "开启" ]]; then
    echo -e "${Info}多路复用已处于开启状态，无需再开启了！"
    exit 1
  else
  echo -e "${Info}是否启用多路复用?注意：开启这个选项不会改善你的链路速度（甚至有可能下降）"
  read -rp "$(echo -e "${Info}是否开启（Y/n）？（默认：n）")" Yn
    case ${Yn} in
    [yY][eE][sS] | [yY])
        sed -i "38c    \"enabled\": true," ${trojan_conf_file}
        sed -i "38c    \"enabled\": true," ${web_dir}/"${uuid}".json
        mux_status="开启"
        ;;
    *)
      echo -e "${Info}什么也没做……"
      exit 1
        ;;
    esac
  fi
}
close_websocket(){
  if [[ ${websocket_status} == "关闭" ]]; then
    echo -e "${Info}websocket已处于禁用，无需再禁用了！"
    exit 1
  else
  echo -e "${Info}确定禁用websocket协议吗?禁用后CDN功能也不能用了。"
  read -rp "$(echo -e "${Info}是否禁用（Y/n）？（默认：n）")" Yn
    case ${Yn} in
    [yY][eE][sS] | [yY])
        sed -i "53c \"enabled\": false," ${trojan_conf_file}
        sed -i "53c \"enabled\": false," ${web_dir}/${uuid}.json
        sed -i "54c    \"path\": \"\"," ${trojan_conf_file}
        sed -i "54c    \"path\": \"\"," ${web_dir}/"${uuid}".json
        websocket_status="关闭"
        websocket_path=""
        ;;
    *)
        echo -e "${Info}什么也没做……"
        exit 1
        ;;
    esac
  fi
}
close_mux(){
  if [[ ${mux_status} == "关闭" ]]; then
    echo -e "${Info}多路复用已处于禁用，无需再禁用了！"
    exit 1
  else
  read -rp "$(echo -e "${Info}是否禁用（Y/n）？（默认：n）")" Yn
    case ${Yn} in
    [yY][eE][sS] | [yY])
        sed -i "38c    \"enabled\": true," ${trojan_conf_file}
        sed -i "38c    \"enabled\": true," ${web_dir}/"${uuid}".json
        mux_status="关闭"
        ;;
    *)
        echo -e "${Info}什么也没做……"
        exit 1
        ;;
    esac
  fi
}
trojan_go_info_html() {
  vps="Trojan-go"
  wget --no-check-certificate -O ${web_dir}/trojan_go_tmpl.html https://raw.githubusercontent.com/JeannieStudio/jeannie/master/trojan_go_tmpl.html
  chmod +x ${web_dir}/trojan_go_tmpl.html
eval "cat <<EOF
  $(<${web_dir}/trojan_go_tmpl.html)
EOF
" >${web_dir}/${uuid}.html
}
change_password(){
  read -rp "$(echo -e "${Info}是否修改密码（Y/n）？（默认：n）")" Yn
    case ${Yn} in
    [yY][eE][sS] | [yY])
        read -rp "$(echo -e "${Info}请输入新密码(不能为空)：")" password
        while [ -z "${password}" ]; do
            read -rp "$(echo -e "${Info}密码不能为空：")" password
        done
        sed -i "10c \"$password\"" ${trojan_conf_file}
        sed -i "10c \"$password\"" ${web_dir}/${uuid}.json
        ;;
    *)
        echo -e "${Info}什么也没做……"
        exit 1
        ;;
    esac
}
set_port() {
    while true
    do
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
change_trojan_port(){
  read -rp "$(echo -e "${Info}是否修改trojan端口（Y/n）？（默认：n）")" Yn
    case ${Yn} in
    [yY][eE][sS] | [yY])
        trojan_info_extraction
        get_info
        set_port trojanport
        trojanport=$port
        port_used_check "${trojanport}"
        sed -i "4c \"local_port\": ${trojanport}," ${trojan_conf_file}
        trojan_go_info_html
        systemctl stop trojan.service
        systemctl start trojan.service
        systemctl enable trojan.service
        trojan_go_basic_information
        update_trojan_info
        ;;
    *)  echo -e "${Info}什么也没做……"
        exit 1
        ;;
    esac
}
count_days(){
  if [[ -f ${trojan_qr_config_file} ]]; then
      trojan_info_extraction
      get_info
      end_time=$(echo | openssl s_client -servername $domain -connect $domain:443 2>/dev/null | openssl x509 -in /data/$domain/fullchain.crt -noout -dates |grep 'After'| awk -F '=' '{print $2}'| awk -F ' +' '{print $1,$2,$4 }' )
      end_times=$(date +%s -d "$end_time")
      now_time=$(date +%s -d "$(date | awk -F ' +'  '{print $2,$3,$6}')")
      RST=$(($((end_times-now_time))/(60*60*24)))
      echo -e "${GREEN}证书有效期剩余天数为：${RST}${NO_COLOR}"
  fi
}
trojan_go_basic_information() {
  {
echo -e "
${GREEN}=========================Trojan-go+tls 安装成功==============================
${FUCHSIA}=========================   Trojan-go 配置信息  =============================
${GREEN}地址：              ${domain}
${GREEN}端口：              ${trojanport}
${GREEN}密码：              ${password}
${GREEN}websocket状态：     ${websocket_status}
${GREEN}websocket路径：     ${websocket_path}
${GREEN}多路复用状态：       ${mux_status}
${FUCHSIA}=========================   客户端配置文件  ===============================
${GREEN}详细信息：https://${domain}:${webport}/${uuid}.html${NO_COLOR}"
} | tee /etc/motd
}

main() {
  if [[ -f ${nginx_bin_file} ]] && [[ -d ${trojan_dir} ]]; then
    echo -e "
      $FUCHSIA====================================================================
      ${GREEN}         检测到您当前安装的是Nginx + Trojan-go + Tls
      $FUCHSIA====================================================================
      ${GREEN}1. 停止trojan-go            ${GREEN}2. 重启trojan-go
      $FUCHSIA====================================================================
      ${GREEN}3. 修改trojan-go密码        ${GREEN}4. 停止nginx
      $FUCHSIA====================================================================
      ${GREEN}5. 重启nginx                ${GREEN}6.启用websocket协议
      $FUCHSIA====================================================================
      ${GREEN}7.禁用websocket协议          ${GREEN}8. 查询证书有效期剩余天数
      $FUCHSIA====================================================================
      ${GREEN}9. 更新证书有效期             ${GREEN}10. 启用多路复用
      $FUCHSIA====================================================================
      ${GREEN}11. 禁用多路复用              ${GREEN}12. 修改trojan端口
      $FUCHSIA====================================================================
      ${GREEN}0. 啥也不做，退出
      $FUCHSIA====================================================================${NO_COLOR}"
  read -rp "请输入数字：" menu_num
  case $menu_num in
  1)
    systemctl stop trojan.service
    echo -e  "${GREEN}trojan-go服务停止${NO_COLOR}"
    ;;
  2)
    systemctl start trojan.service
    echo -e  "${GREEN}trojan-go服务启动${NO_COLOR}"

    ;;
  3)
    trojan_info_extraction
    get_info
    change_password
    trojan_go_info_html
    systemctl stop trojan.service
    systemctl start trojan.service
	  systemctl enable trojan.service
    trojan_go_basic_information
    update_trojan_info
    ;;
  4)
    systemctl stop nginx
    echo -e  "${GREEN}nginx服务停止${NO_COLOR}"
    ;;
  5)
    systemctl start nginx
    echo -e  "${GREEN}nginx服务启动${NO_COLOR}"
    ;;
  6)
    trojan_info_extraction
    get_info
    open_websocket
    trojan_go_info_html
    systemctl stop trojan.service
    systemctl start trojan.service
	  systemctl enable trojan.service
	  trojan_go_basic_information
	  update_trojan_info
    ;;
  7)
    trojan_info_extraction
    get_info
    close_websocket
    trojan_go_info_html
    systemctl stop trojan.service
    systemctl start trojan.service
	  systemctl enable trojan.service
	  trojan_go_basic_information
	  update_trojan_info
    ;;
  8)
    count_days
    ;;
  9)

    echo -e "目前证书在 60 天以后会自动更新, 你无需任何操作. 今后有可能会缩短这个时间, 不过都是自动的, 你不用关心."
    ;;
  10)
      trojan_info_extraction
      get_info
      open_mux
      trojan_go_info_html
      systemctl stop trojan.service
      systemctl start trojan.service
      systemctl enable trojan.service
      trojan_go_basic_information
      update_trojan_info
    ;;
  11)
      trojan_info_extraction
      get_info
      close_mux
      trojan_go_info_html
      systemctl stop trojan.service
      systemctl start trojan.service
      systemctl enable trojan.service
      trojan_go_basic_information
      update_trojan_info
    ;;
  12)change_trojan_port
    ;;
  0)
    exit 0
    ;;
  *)
    echo -e "${RedBG}请输入正确的数字${Font}"
    ;;
  esac
  elif  [[ -f "${caddy_conf}" ]] && [[ -d "${trojan_dir}" ]]; then
    echo -e "
      $FUCHSIA====================================================================
      ${GREEN}         检测到您当前安装的是Caddy + Trojan-go + Tls
      $FUCHSIA====================================================================
      ${GREEN}1. 停止trojan-go            ${GREEN}2. 重启trojan-go
      $FUCHSIA====================================================================
      ${GREEN}3. 修改trojan-go密码        ${GREEN}4. 停止caddy
      $FUCHSIA====================================================================
      ${GREEN}5. 重启caddy                ${GREEN}6.启用websocket协议
      $FUCHSIA====================================================================
      ${GREEN}7.禁用websocket协议          ${GREEN}8. 查询证书有效期剩余天数
      $FUCHSIA====================================================================
      ${GREEN}9. 更新证书有效期             ${GREEN}10. 启用多路复用
      $FUCHSIA====================================================================
      ${GREEN}11. 禁用多路复用              ${GREEN}12. 修改trojan端口
      $FUCHSIA====================================================================
      ${GREEN}0. 啥也不做，退出
      $FUCHSIA====================================================================${NO_COLOR}"
  read -rp "请输入数字：" menu_num
  case $menu_num in
  1)
    systemctl stop trojan.service
    echo -e  "${GREEN}trojan-go服务停止${NO_COLOR}"
    ;;
  2)
    systemctl start trojan.service
    echo -e  "${GREEN}trojan-go服务启动${NO_COLOR}"

    ;;
  3)
    trojan_info_extraction
    get_info
    change_password
    trojan_go_info_html
    systemctl stop trojan.service
    systemctl start trojan.service
	  systemctl enable trojan.service
    trojan_go_basic_information
    update_trojan_info
    ;;
  4)
    systemctl stop caddy
    echo -e  "${GREEN}caddy服务停止${NO_COLOR}"
    ;;
  5)
    systemctl restart caddy
    echo -e  "${GREEN}caddy服务启动${NO_COLOR}"
    ;;
  6)
    trojan_info_extraction
    get_info
    open_websocket
    trojan_go_info_html
    systemctl stop trojan.service
    systemctl start trojan.service
	  systemctl enable trojan.service
	  trojan_go_basic_information
	  update_trojan_info
    ;;
  7)
    trojan_info_extraction
    get_info
    close_websocket
    trojan_go_info_html
    systemctl stop trojan.service
    systemctl start trojan.service
	  systemctl enable trojan.service
	  trojan_go_basic_information
	  update_trojan_info
    ;;
  8)
    count_days
    ;;
  9)

    echo -e "目前证书在 60 天以后会自动更新, 你无需任何操作. 今后有可能会缩短这个时间, 不过都是自动的, 你不用关心."
    ;;
  10)
      trojan_info_extraction
      get_info
      open_mux
      trojan_go_info_html
      systemctl stop trojan.service
      systemctl start trojan.service
      systemctl enable trojan.service
      trojan_go_basic_information
      update_trojan_info
    ;;
  11)
      trojan_info_extraction
      get_info
      close_mux
      trojan_go_info_html
      systemctl stop trojan.service
      systemctl start trojan.service
      systemctl enable trojan.service
      trojan_go_basic_information
      update_trojan_info
    ;;
  12)change_trojan_port
    ;;
  0)
    exit 0
    ;;
  *)
    echo -e "${RedBG}请输入正确的数字${Font}"
    ;;
  esac
  fi
}
main
