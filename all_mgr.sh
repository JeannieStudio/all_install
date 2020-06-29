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
RED="\033[0;31m"
NO_COLOR="\033[0m"
GREEN="\033[32m\033[01m"
FUCHSIA="\033[0;35m"
BLUE="\033[0;36m"
GreenBG="\033[42;37m"
RedBG="\033[41;37m"
Font="\033[0m"
Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[信息]${Font_color_suffix}"
Error="${Red_font_prefix}[错误]${Font_color_suffix}"
Tip="${Green_font_prefix}[注意]${Font_color_suffix}"
nginx_bin_old_file="/usr/sbin/nginx"
nginx_conf_dir="/etc/nginx/conf/conf.d"
nginx_conf="${nginx_conf_dir}/default.conf"
nginx_dir="/etc/nginx"
v2ray_bin_dir="/usr/bin/v2ray"
v2ray_systemd_file="/etc/systemd/system/v2ray.service"
nginx_bin_file="/etc/nginx/sbin/nginx"
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
ssr_systemd_file="/etc/init.d/shadowsocks-r"
ssr_bin_dir="/usr/local/shadowsocks"
ssr_qr_config_file="${ssr_conf_dir}/qrconfig.json"
web_dir="/usr/wwwroot"
check_root(){
  [[ $EUID != 0 ]] && echo -e "${Error} 当前非ROOT账号(或没有ROOT权限)，无法继续操作，请执行命令 ${Green_background_prefix}sudo -i${Font_color_suffix} 更换ROOT账号" && exit 1
}
trojan_info_extraction() {
  grep "$1" ${trojan_qr_config_file} | awk -F '"' '{print $4}'
}
v2ray_info_extraction() {
  grep "$1" ${v2ray_shadowrocket_qr_config_file} | awk -F '"' '{print $4}'
}
ssr_qr_info_extraction() {
  grep "$1" ${ssr_qr_config_file} | awk -F '"' '{print $4}'
}
output_trojan_information() {
  uuid=$(trojan_info_extraction '\"uuid\"')
  domain=$(trojan_info_extraction '\"domain\"')
  password1=$(trojan_info_extraction '\"password1\"')
  password2=$(trojan_info_extraction '\"password2\"')
  trojanport=$(trojan_info_extraction '\"trojanport\"')
  webport=$(trojan_info_extraction '\"webport\"')
}
output_v2ray_information() {
  uuid=$(v2ray_info_extraction '\"id\"')
  domain=$(v2ray_info_extraction '\"add\"')
  webport=$(v2ray_info_extraction '\"port\"')
}
output_ssr_information(){
  uuid=$(ssr_qr_info_extraction '\"uuid\"')
  domain=$(ssr_qr_info_extraction '\"domain\"')
  protocol=$(ssr_qr_info_extraction '\"protocol\"')
  method=$(ssr_qr_info_extraction '\"method\"')
  obfs=$(ssr_qr_info_extraction '\"obfs\"')
  password=$(ssr_qr_info_extraction '\"password\"')
}
remove_trojan_old_information() {
  rm -f ${web_dir}/${uuid}.html
  rm -f ${web_dir}/${uuid}-01.png
  rm -f ${web_dir}/${uuid}-02.png
}
remove_v2ray_old_information() {
  rm -f ${web_dir}/${uuid}.html
  rm -f ${web_dir}/${uuid}-01.png
  rm -f ${web_dir}/${uuid}-02.png
}
remove_ssr_old_information() {
  rm -f ${web_dir}/${uuid}.html
  rm -f ${web_dir}/${uuid}.png
}
input_trojan_password(){
  read -rp "$(echo -e "${Info}请输入您的trojan密码1:")" password1
  while [[ -z ${password1} ]]; do
    read -rp "$(echo -e "${Info}密码1不能为空,请重新输入您的trojan密码1:")" password1
  done
  read -rp "$(echo -e "${Info}请输入您的trojan密码2:")" password2
  while [[ -z ${password2} ]]; do
    read -rp "$(echo -e "${Info}密码2不能为空,请重新输入您的trojan密码2:")" password2
  done
}
trojan_conf() {
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
        "key": "/data/${domain}/privkey.key",
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
v2ray_conf() {
  uuid=$(cat /proc/sys/kernel/random/uuid)
  read -rp "$(echo -e "${Tip}已为您生成了uuid:${uuid},确认使用吗?[Y/n]?")" yn
  while [[ "${yn}" != [Yy] ]]; do
    uuid=$(cat /proc/sys/kernel/random/uuid)
    read -rp "$(echo -e "${Tip}已为您生成了uuid:${uuid},确认使用吗?[Y/n]?")" yn
  done
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
input_ssr_password(){
  read -rp "$(echo -e "${Info}请输入新密码:")" password
  while [[ -z ${password} ]]; do
    read -rp "$(echo -e "${Info}密码不能为空,请重新输入新密码:")" password
  done
}
ssr_conf() {
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
ssr_qr_link_image(){
  uuid=$(cat /proc/sys/kernel/random/uuid)
  tmp1=$(echo -n "${password}" | base64 -w0 | sed 's/=//g;s/\//_/g;s/+/-/g')
  tmp2=$(echo -n "${domain}:${ssrport}:${protocol}:${method}:${obfs}:${tmp1}/?obfsparam=" | base64 -w0)
  ssr_link="ssr://${tmp2}"
  qrencode -o ${web_dir}/${uuid}.png -s 8 "${ssr_link}"
}
trojan_qr_link_image() {
  uuid=$(cat /proc/sys/kernel/random/uuid)
  trojan_link1="trojan://${password1}@${domain}:${trojanport}"
  trojan_link2="trojan://${password2}@${domain}:${trojanport}"
  qrencode -o ${web_dir}/${uuid}-01.png -s 6 "${trojan_link1}"
  qrencode -o ${web_dir}/${uuid}-02.png -s 6 "${trojan_link2}"
}

v2ray_shadowrocket_qr_link_image() {
  v2ray_link1="vmess://$(base64 -w 0 ${v2ray_shadowrocket_qr_config_file})"
  qrencode -o ${web_dir}/${uuid}-1.png -s 6 "${v2ray_link1}"
}
v2ray_win_and_android_qr_link_image() {
  v2ray_link2="vmess://$(base64 -w 0 ${v2ray_win_and_android_qr_config_file})"
  qrencode -o ${web_dir}/${uuid}-2.png -s 6 "${v2ray_link2}"
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
v2ray_info_html() {
  vps="v2ray"
  wget --no-check-certificate -O ${web_dir}/v2ray_tmpl.html https://raw.githubusercontent.com/JeannieStudio/jeannie/master/v2ray_tmpl.html
  chmod +x ${web_dir}/v2ray_tmpl.html
  eval "cat <<EOF
  $(<${web_dir}/v2ray_tmpl.html)
EOF
  " >${web_dir}/${uuid}.html
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
trojan_qr_config() {
  cat >${trojan_qr_config_file} <<-EOF
  "domain": "${domain}"
  "uuid": "${uuid}"
  "password1": "${password1}"
  "password2": "${password2}"
  "trojanport":"${trojanport}"
  "webport":"${webport}"
EOF
}
v2ray_qr_config() {
  sed -i "6c \"id\": \"${uuid}\"," ${v2ray_shadowrocket_qr_config_file}
  sed -i "6c \"id\": \"${uuid}\"," ${v2ray_win_and_android_qr_config_file}
}
v2ray_qr_port_config() {
  sed -i "5c \"port\": \"${webport}\"," ${v2ray_shadowrocket_qr_config_file}
  sed -i "5c \"port\": \"${webport}\"," ${v2ray_win_and_android_qr_config_file}
}
ssr_qr_config() {
  sed -i "2c \"uuid\":\"${uuid}\"," ${ssr_qr_config_file}
  sed -i "4c \"password\":\"${password}\"," ${ssr_qr_config_file}
  sed -i "8c \"ssrport\":\"${ssrport}\"" ${ssr_qr_config_file}
}

ssr_basic_information() {
  {
echo -e "
${GREEN}=========================ssr+tls 安装成功==============================
${FUCHSIA}=========================   SSR 配置信息  =============================
${GREEN}地址：   $(ssr_qr_info_extraction '\"domain\"')
${GREEN}端口：   ${ssrport}
${GREEN}密码：   ${password}
${GREEN}加密方式：  $(ssr_qr_info_extraction '\"method\"')
${GREEN}协议：  $(ssr_qr_info_extraction '\"protocol\"')
${GREEN}混淆：  $(ssr_qr_info_extraction '\"obfs\"')
${GREEN}重启服务、修改密码、修改端口号、查看证书有效期等，请执行：/etc/all_mgr.sh
${FUCHSIA}=========================   分享链接和二维码  ===============================
${GREEN}分享链接：
${ssr_link}
${GREEN}二维码：  ${web_dir}/${uuid}.png
${FUCHSIA}=========================   懒人请往这儿瞧  ===============================
${GREEN}详细信息：https://${domain}:${ssrport}/${uuid}.html${NO_COLOR}"
} | tee /etc/motd
}
trojan_basic_information() {
  {
echo -e "
${GREEN}=========================trojan+tls 安装成功==============================
${FUCHSIA}=========================   Trojan 配置信息  =============================
${GREEN}地址：   $(trojan_info_extraction '\"domain\"')
${GREEN}端口：   ${trojanport}
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
${GREEN}详细信息：https://${domain}:${trojanport}/${uuid}.html${NO_COLOR}"
} | tee /etc/motd
}
v2ray_basic_information() {
  {
    echo -e "
${GREEN}=========================V2ray+ws+tls 安装成功==============================
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
${BLUE}windows和安卓客户端v2rayN分享链接：
${GREEN}${v2ray_link2}
${BLUE}ios客户端shadowroket分享链接：
${GREEN}${v2ray_link1}
${BLUE}windows和安卓客户端v2rayN二维码：
${GREEN}${web_dir}/${uuid}-1.png
${BLUE}ios客户端shadowroket二维码：
${GREEN}${web_dir}/${uuid}-2.png
${FUCHSIA}=========================   懒人请往这儿瞧  ======================================
${GREEN}https://$(v2ray_info_extraction '\"add\"'):${webport}/${uuid}.html${NO_COLOR}"
  } | tee /etc/motd
}

count_days(){
  if [[ -f ${trojan_qr_config_file} ]]; then
    trojan_info_extraction
    output_trojan_information
    end_time=$(echo | openssl s_client -servername "$domain" -connect "$domain":"${trojanport}" 2>/dev/null | openssl x509 -in /data/$domain/fullchain.crt -noout -dates |grep 'After'| awk -F '=' '{print $2}'| awk -F ' +' '{print $1,$2,$4 }' )
    end_times=$(date +%s -d "$end_time")
    now_time=$(date +%s -d "$(date | awk -F ' +'  '{print $2,$3,$6}')")
    RST=$(($((end_times-now_time))/(60*60*24)))
    echo -e "${GREEN}证书有效期剩余天数为：${RST}${NO_COLOR}"
  fi
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
left_second(){
    seconds_left=10
    echo "$1正在重启，请等待${seconds_left}秒……"
    while [ $seconds_left -gt 0 ];do
      echo -n $seconds_left
      sleep 1
      seconds_left=$(($seconds_left - 1))
      echo -ne "\r     \r"
    done
}
change_nginx_port(){
  v2ray_info_extraction
  output_v2ray_information
  rm -f ${web_dir}/${uuid}-01.png
  rm -f ${web_dir}/${uuid}-02.png
  set_port nginx
  webport=$port
  port_used_check "${webport}"
  sed -i "2c listen ${webport} ssl http2;" ${nginx_conf}
  v2ray_qr_port_config
  v2ray_shadowrocket_qr_link_image
  v2ray_win_and_android_qr_link_image
  v2ray_info_html
  left_second ${webserver}
  systemctl restart nginx
  v2ray_basic_information
}
change_caddy_port(){
  v2ray_info_extraction
  output_v2ray_information
  rm -f ${web_dir}/${uuid}-01.png
  rm -f ${web_dir}/${uuid}-02.png
  set_port nginx
  webport=$port
  port_used_check "${webport}"
  sed -i "1c https://${domain}:${webport} {" ${caddy_conf}
  v2ray_qr_port_config
  v2ray_shadowrocket_qr_link_image
  v2ray_win_and_android_qr_link_image
  v2ray_info_html
  caddy -service restart
  left_second ${webserver}
  v2ray_basic_information
}
change_trojan_port(){
  trojan_info_extraction
  output_trojan_information
  remove_trojan_old_information
  set_port trojanport
  trojanport=$port
  port_used_check "${trojanport}"
  trojan_conf
  trojan_qr_link_image
  trojan_info_html
  trojan_qr_config
  systemctl restart trojan
  left_second ${webserver}
  trojan_basic_information
}
change_trojan_password(){
  trojan_info_extraction
  output_trojan_information
  remove_trojan_old_information
  input_trojan_password
  trojan_conf
  trojan_qr_link_image
  trojan_info_html
  trojan_qr_config
  systemctl restart trojan
  left_second ${webserver}
  trojan_basic_information
}
change_v2ray_uuid(){
  v2ray_info_extraction
  output_v2ray_information
  remove_v2ray_old_information
  v2ray_conf
  v2ray_qr_config
  v2ray_shadowrocket_qr_link_image
  v2ray_win_and_android_qr_link_image
  v2ray_info_html
  left_second ${webserver}
  service v2ray restart
  v2ray_basic_information
}
change_ssr_password(){
  ssr_qr_info_extraction
  output_ssr_information
  remove_ssr_old_information
  input_ssr_password
  ssr_conf
  ssr_qr_link_image
  ssr_info_html
  ssr_qr_config
  ssr_basic_information
}
change_ssr_port(){
  ssr_qr_info_extraction
  output_ssr_information
  remove_ssr_old_information
  set_port ssr
  ssrport=$port
  port_used_check "${ssrport}"
  ssr_conf
  ssr_qr_link_image
  ssr_info_html
  ssr_qr_config
  ssr_basic_information
}
mgr(){
  check_root
  if [[ -e "${nginx_bin_file}" ]] && [[ -e "${trojan_bin_dir}" ]]; then
      echo -e "
      $FUCHSIA=======================================================
      ${GREEN}系统检测到您目前安装的是trojan+nginx+tls一键脚本
      $FUCHSIA=======================================================
      ${GREEN}1. 停止trojan          ${GREEN}2. 重启trojan
      $FUCHSIA=======================================================
      ${GREEN}3. 修改trojan密码      ${GREEN}4. 停止nginx
      $FUCHSIA=======================================================
      ${GREEN}5. 重启nginx           ${GREEN}6. 查询证书有效期剩余天数
      $FUCHSIA=======================================================
      ${GREEN}7. 更新证书有效期       ${GREEN}8. 修改trojan端口号（端口被墙修改该端口即可）
      $FUCHSIA=======================================================
      ${GREEN}0. 啥也不做，退出
      $FUCHSIA=======================================================${NO_COLOR}"
      read -rp "请输入您要执行的操作的数字:" aNum
      case $aNum in
          1)systemctl stop trojan
            echo -e  "${GREEN}trojan服务停止${NO_COLOR}"
          ;;
          2)systemctl restart trojan
            echo -e  "${GREEN}trojan服务启动${NO_COLOR}"
          ;;
          3)webserver=trojan
            change_trojan_password
          ;;
          4)systemctl stop nginx
            echo -e  "${GREEN}nginx服务停止${NO_COLOR}"
          ;;
          5)systemctl restart nginx
            echo -e  "${GREEN}nginx服务启动${NO_COLOR}"
          ;;
          6)count_days
          ;;
          7)echo -e "目前证书在 60 天以后会自动更新, 你无需任何操作. 今后有可能会缩短这个时间, 不过都是自动的, 你不用关心."
          ;;
          8)webserver=trojan
            change_trojan_port
          ;;
          0) exit
          ;;
          *)echo -e "${RED}输入错误！！！${NO_COLOR}"
            exit
          ;;
      esac
  elif [[ -e "${caddy_bin_dir}/caddy" ]] && [[ -e "${trojan_bin_dir}" ]]; then
      echo -e "
      $FUCHSIA=========================================================
      ${GREEN}系统检测到您目前安装的是trojan+caddy+tls一键脚本
      $FUCHSIA=========================================================
      ${GREEN}1. 停止trojan             ${GREEN}2. 重启trojan
      $FUCHSIA=========================================================
      ${GREEN}3. 修改trojan密码         ${GREEN}4. 停止caddy
      $FUCHSIA=========================================================
      ${GREEN}5. 重启caddy              ${GREEN}6. 查询证书有效期剩余天数
      $FUCHSIA=========================================================
      ${GREEN}7. 更新证书有效期          ${GREEN}8. 修改trojan端口号（端口被墙修改该端口即可）
      $FUCHSIA=======================================================
      ${GREEN}0. 啥也不做，退出
      $FUCHSIA=======================================================${NO_COLOR}"
      read -rp "请输入您要执行的操作的数字:" aNum
      case $aNum in
          1)systemctl stop trojan
            echo -e  "${GREEN}trojan服务停止${NO_COLOR}"
          ;;
          2)systemctl restart trojan
            echo -e  "${GREEN}trojan服务启动${NO_COLOR}"
          ;;
          3)webserver=trojan
            change_trojan_password
          ;;
          4)caddy -service stop
            echo -e  "${GREEN}caddy服务停止${NO_COLOR}"
          ;;
          5)caddy -service restart
            echo -e  "${GREEN}caddy服务启动${NO_COLOR}"
          ;;
          6)count_days
          ;;
          7)echo -e "目前证书在 60 天以后会自动更新, 你无需任何操作. 今后有可能会缩短这个时间, 不过都是自动的, 你不用关心."
          ;;
          8)webserver=trojan
            change_trojan_port
          ;;
          0) exit
          ;;
          *)echo -e "${RED}输入错误！！！${NO_COLOR}"
            exit
          ;;
      esac
  elif [[ -e "${nginx_bin_file}" ]] && [[ -e "${v2ray_bin_dir}/v2ray" ]]; then
       echo -e "
      $FUCHSIA=======================================================
      ${GREEN}系统检测到您目前安装的是v2ray+nginx+tls一键脚本
       $FUCHSIA=======================================================
      ${GREEN}1. 停止v2ray           ${GREEN}2. 重启v2ray
      $FUCHSIA=======================================================
      ${GREEN}3. 修改UUID            ${GREEN}4. 停止nginx
      $FUCHSIA=======================================================
      ${GREEN}5. 重启nginx           ${GREEN}6. 查询证书有效期剩余天数
      $FUCHSIA=======================================================
      ${GREEN}7. 更新证书有效期       ${GREEN}8. 更新v2ray core
      $FUCHSIA=======================================================
      ${GREEN}9. 修改nginx端口号（端口被墙修改该端口即可）
      $FUCHSIA=======================================================
      ${GREEN}0. 啥也不做，退出
      $FUCHSIA=======================================================${NO_COLOR}"
      read -rp "请输入您要执行的操作的数字:" aNum
      case $aNum in
          1)service v2ray stop
            echo -e  "${GREEN}v2ray服务停止${NO_COLOR}"
          ;;
          2)service v2ray restart
            echo -e  "${GREEN}v2ray服务启动${NO_COLOR}"
          ;;
          3)webserver=v2ray
            change_v2ray_uuid
          ;;
          4)systemctl stop nginx
            echo -e  "${GREEN}nginx服务停止${NO_COLOR}"
          ;;
          5)systemctl restart nginx
            echo -e  "${GREEN}nginx服务启动${NO_COLOR}"
          ;;
          6)count_days
          ;;
          7)echo -e "目前证书在 60 天以后会自动更新, 你无需任何操作. 今后有可能会缩短这个时间, 不过都是自动的, 你不用关心."
          ;;
          8)bash <(curl -L -s https://install.direct/go.sh)
            service v2ray restart
          ;;
          9)webserver=nginx
            change_nginx_port
          ;;
          0) exit
          ;;
          *)echo -e "${RED}输入错误！！！${NO_COLOR}"
            exit
          ;;
      esac
  elif [[ -e "${caddy_bin_dir}/caddy" ]] && [[ -e "${v2ray_bin_dir}/v2ray" ]]; then
      echo -e "
      $FUCHSIA=======================================================
      ${GREEN}系统检测到您目前安装的是v2ray+caddy+tls一键脚本
      $FUCHSIA=======================================================
      ${GREEN}1. 停止v2ray            ${GREEN}2. 重启v2ray
      $FUCHSIA=======================================================
      ${GREEN}3. 修改UUID             ${GREEN}4. 停止caddy
      $FUCHSIA=======================================================
      ${GREEN}5. 重启caddy            ${GREEN}6. 查询证书有效期剩余天数
      $FUCHSIA=======================================================
      ${GREEN}7. 更新证书有效期        ${GREEN}8. 更新v2ray core
      $FUCHSIA=======================================================
      ${GREEN}9. 修改caddy端口号（端口被墙修改该端口即可）
      $FUCHSIA=======================================================
      ${GREEN}0. 啥也不做，退出
      $FUCHSIA=======================================================${NO_COLOR}"
      read -rp "请输入您要执行的操作的数字:" aNum
      case $aNum in
          1)service v2ray stop
            echo -e  "${GREEN}v2ray服务停止${NO_COLOR}"
          ;;
          2)service v2ray restart
            echo -e  "${GREEN}v2ray服务启动${NO_COLOR}"
          ;;
          3)webserver=v2ray
            change_v2ray_uuid
          ;;
          4)caddy -service stop
            echo -e  "${GREEN}caddy服务停止${NO_COLOR}"
          ;;
          5)caddy -service restart
            echo -e  "${GREEN}caddy服务启动${NO_COLOR}"
          ;;
          6)count_days
          ;;
          7)echo -e "目前证书在 60 天以后会自动更新, 你无需任何操作. 今后有可能会缩短这个时间, 不过都是自动的, 你不用关心."
          ;;
          8)bash <(curl -L -s https://install.direct/go.sh)
            service v2ray restart
          ;;
          9)webserver=caddy
            change_caddy_port
          ;;
          0) exit
          ;;
          *)echo -e "${RED}输入错误！！！${NO_COLOR}"
            exit
          ;;
      esac

  elif [[ -e "${caddy_bin_dir}/caddy" ]] && [[ -d "${ssr_bin_dir}" ]]; then
      echo -e "
      $FUCHSIA===================================================
      ${GREEN}系统检测到您目前安装的是ssr+caddy+tls一键脚本
      $FUCHSIA===================================================
      ${GREEN}1. 停止ssr           ${GREEN}2. 重启ssr
      $FUCHSIA===================================================
      ${GREEN}3. 修改密码          ${GREEN}4. 停止caddy
      $FUCHSIA===================================================
      ${GREEN}5. 重启caddy         ${GREEN}6. 查询证书有效期剩余天数
      $FUCHSIA===================================================
      ${GREEN}7. 更新证书有效期     ${GREEN}8.修改ssr端口号（端口被墙修改该端口即可）
      $FUCHSIA=======================================================
      ${GREEN}0. 啥也不做，退出
      $FUCHSIA=======================================================${NO_COLOR}"
      read -rp "请输入您要执行的操作的数字:" aNum
      case $aNum in
          1)/etc/init.d/shadowsocks-r stop
            echo -e  "${GREEN}ssr服务停止${NO_COLOR}"
          ;;
          2)/etc/init.d/shadowsocks-r restart
            echo -e  "${GREEN}ssr服务启动${NO_COLOR}"
          ;;
          3)change_ssr_password
            /etc/init.d/shadowsocks-r restart
          ;;
          4)caddy -service stop
            echo -e  "${GREEN}caddy服务停止${NO_COLOR}"
          ;;
          5)caddy -service restart
            echo -e  "${GREEN}caddy服务启动${NO_COLOR}"
          ;;
          6)count_days
          ;;
          7)echo -e "目前证书在 60 天以后会自动更新, 你无需任何操作. 今后有可能会缩短这个时间, 不过都是自动的, 你不用关心."
          ;;
          8)change_ssr_port
            /etc/init.d/shadowsocks-r restart
          ;;
          0) exit
          ;;
          *)echo -e "${RED}输入错误！！！${NO_COLOR}"
            exit
          ;;
      esac
  fi
}
mgr
