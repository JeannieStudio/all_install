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
nginx_bin_file="/usr/sbin/nginx"
nginx_conf_dir="/etc/nginx/conf.d"
nginx_conf="${nginx_conf_dir}/default.conf"
nginx_dir="/etc/nginx"
v2ray_bin_dir="/usr/bin/v2ray"
v2ray_systemd_file="/etc/systemd/system/v2ray.service"
nginx_bin_file_new="/etc/nginx/sbin/nginx"
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
}
output_v2ray_information() {
  uuid=$(v2ray_info_extraction '\"id\"')
  domain=$(v2ray_info_extraction '\"add\"')
}
output_ssr_information(){
  uuid=$(ssr_qr_info_extraction '\"uuid\"')
  domain=$(ssr_qr_info_extraction '\"domain\"')
  protocol=$(ssr_qr_info_extraction '\"protocol\"')
  method=$(ssr_qr_info_extraction '\"method\"')
  obfs=$(ssr_qr_info_extraction '\"obfs\"')
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
trojan_conf() {
  read -p "$(echo -e "${Info}请输入您的trojan密码1:")" password1
  while [[ -z ${password1} ]]; do
    read -p "$(echo -e "${Info}密码1不能为空,请重新输入您的trojan密码1:")" password1
  done
  read -p "$(echo -e "${Info}请输入您的trojan密码2:")" password2
  while [[ -z ${password2} ]]; do
    read -p "$(echo -e "${Info}密码2不能为空,请重新输入您的trojan密码2:")" password2
  done
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
v2ray_conf() {
  uuid=$(cat /proc/sys/kernel/random/uuid)
  read -p "$(echo -e "${Tip}已为您生成了uuid:${uuid},确认使用吗?[Y/n]?")" yn
  while [[ "${yn}" != [Yy] ]]; do
    uuid=$(cat /proc/sys/kernel/random/uuid)
    read -p "$(echo -e "${Tip}已为您生成了uuid:${uuid},确认使用吗?[Y/n]?")" yn
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
ssr_conf() {
  read -p "$(echo -e "${Info}请输入新密码:")" password
  while [[ -z ${password} ]]; do
    read -p "$(echo -e "${Info}密码不能为空,请重新输入新密码:")" password
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
    "method":"chacha20-ietf",
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
ssr_qr_link_image(){
  uuid=$(cat /proc/sys/kernel/random/uuid)
  tmp1=$(echo -n "${password}" | base64 -w0 | sed 's/=//g;s/\//_/g;s/+/-/g')
  tmp2=$(echo -n "${domain}:443:${protocol}:${method}:${obfs}:${tmp1}/?obfsparam=" | base64 -w0)
  ssr_link="ssr://${tmp2}"
  qrencode -o ${web_dir}/${uuid}.png -s 8 "${ssr_link}"
}
trojan_qr_link_image() {
  uuid=$(cat /proc/sys/kernel/random/uuid)
  trojan_link1="trojan://${password1}@${domain}:443"
  trojan_link2="trojan://${password2}@${domain}:443"
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
EOF
}
v2ray_qr_config() {
  sed -i "6c \"id\": \"${uuid}\"," ${v2ray_shadowrocket_qr_config_file}
  sed -i "6c \"id\": \"${uuid}\"," ${v2ray_win_and_android_qr_config_file}
}
ssr_qr_config() {
  sed -i "2c \"uuid\":\"${uuid}\"," ${ssr_qr_config_file}
  sed -i "4c \"password\":\"${password}\"," ${ssr_qr_config_file}
}
ssr_basic_information() {
  {
echo -e "
${GREEN}=========================ssr+tls 安装成功==============================
${FUCHSIA}=========================   SSR 配置信息  =============================
${GREEN}地址：   $(ssr_qr_info_extraction '\"domain\"')
${GREEN}端口：   443
${GREEN}密码：   ${password}
${GREEN}加密方式：  $(ssr_qr_info_extraction '\"method\"')
${GREEN}协议：  $(ssr_qr_info_extraction '\"protocol\"')
${GREEN}混淆：  $(ssr_qr_info_extraction '\"obfs\"')
${FUCHSIA}=========================   分享链接和二维码  ===============================
${GREEN}分享链接：
${ssr_link}
${GREEN}二维码：  ${web_dir}/${uuid}.png
${FUCHSIA}=========================   懒人请往这儿瞧  ===============================
${GREEN}详细信息：https://${domain}/${uuid}.html${NO_COLOR}"
} | tee /etc/motd
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
${BLUE}windows和安卓客户端v2rayN分享链接：
${GREEN}${v2ray_link2}
${BLUE}ios客户端shadowroket分享链接：
${GREEN}${v2ray_link1}
${BLUE}windows和安卓客户端v2rayN二维码：
${GREEN}${web_dir}/${uuid}-1.png
${BLUE}ios客户端shadowroket二维码：
${GREEN}${web_dir}/${uuid}-2.png
${FUCHSIA}=========================   懒人请往这儿瞧  ======================================
${GREEN}https://$(v2ray_info_extraction '\"add\"')/${uuid}.html${NO_COLOR}"
  } | tee /etc/motd
}
trojan_qr_config() {
  cat >${trojan_qr_config_file} <<-EOF
  "domain": "${domain}"
  "uuid": "${uuid}"
  "password1": "${password1}"
  "password2": "${password2}"
EOF
}
count_days(){
  [[ -f ${trojan_qr_config_file} ]] && trojan_info_extraction && output_trojan_information
  [[ -f ${v2ray_shadowrocket_qr_config_file} ]] && v2ray_info_extraction && output_v2ray_information
  [[ -f ${ssr_qr_config_file} ]] && ssr_qr_info_extraction && output_ssr_information
  end_time=$(echo | openssl s_client -servername $domain -connect $domain:443 2>/dev/null | openssl x509 -in /data/$domain/fullchain.crt -noout -dates |grep 'After'| awk -F '=' '{print $2}'| awk -F ' +' '{print $1,$2,$4 }' )
  end_times=$(date +%s -d "$end_time")
  now_time=$(date +%s -d "$(date | awk -F ' +'  '{print $2,$3,$6}')")
  RST=$(($((end_times-now_time))/(60*60*24)))
  echo -e "${GREEN}证书有效期剩余天数为：${RST}${NO_COLOR}"
}
change_trojan_password(){
  trojan_info_extraction
  output_trojan_information
  remove_trojan_old_information
  trojan_conf
  trojan_qr_link_image
  trojan_info_html
  trojan_qr_config
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
  v2ray_basic_information
}
change_ssr_password(){
  ssr_qr_info_extraction
  output_ssr_information
  remove_ssr_old_information
  ssr_conf
  ssr_qr_link_image
  ssr_info_html
  ssr_qr_config
  ssr_basic_information
}
mgr(){
  check_root
  if [[ -e "${nginx_bin_file_new}" ]] && [[ -e "${trojan_bin_dir}" ]]; then
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
      ${GREEN}7. 更新证书有效期       ${GREEN}0. 啥也不做，退出
      $FUCHSIA=======================================================${NO_COLOR}"
      read -rp "请输入您要执行的操作的数字:" aNum
      case $aNum in
          1)systemctl stop trojan
            echo -e  "${GREEN}trojan服务停止${NO_COLOR}"
          ;;
          2)systemctl restart trojan
            echo -e  "${GREEN}trojan服务启动${NO_COLOR}"
          ;;
          3)change_trojan_password
            systemctl restart trojan
          ;;
          4)nginx -s stop
            echo -e  "${GREEN}nginx服务停止${NO_COLOR}"
          ;;
          5)nginx
            echo -e  "${GREEN}nginx服务启动${NO_COLOR}"
          ;;
          6)count_days
          ;;
          7)echo -e "目前证书在 60 天以后会自动更新, 你无需任何操作. 今后有可能会缩短这个时间, 不过都是自动的, 你不用关心."
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
      ${GREEN}7. 更新证书有效期          ${GREEN}0. 啥也不做，退出
      $FUCHSIA=========================================================${NO_COLOR}"
      read -p "请输入您要执行的操作的数字:" aNum
      case $aNum in
          1)systemctl stop trojan
            echo -e  "${GREEN}trojan服务停止${NO_COLOR}"
          ;;
          2)systemctl restart trojan
            echo -e  "${GREEN}trojan服务启动${NO_COLOR}"
          ;;
          3)change_trojan_password
            systemctl restart trojan
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
          0) exit
          ;;
          *)echo -e "${RED}输入错误！！！${NO_COLOR}"
            exit
          ;;
      esac
  elif [[ -e "${nginx_bin_file_new}" ]] && [[ -e "${v2ray_bin_dir}/v2ray" ]]; then
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
      ${GREEN}0. 啥也不做，退出
      $FUCHSIA=======================================================${NO_COLOR}"
      read -p "请输入您要执行的操作的数字:" aNum
      case $aNum in
          1)service v2ray stop
            echo -e  "${GREEN}v2ray服务停止${NO_COLOR}"
          ;;
          2)service v2ray restart
            echo -e  "${GREEN}v2ray服务启动${NO_COLOR}"
          ;;
          3)change_v2ray_uuid
            service v2ray restart
          ;;
          4)nginx -s stop
            echo -e  "${GREEN}nginx服务停止${NO_COLOR}"
          ;;
          5)nginx
            echo -e  "${GREEN}nginx服务启动${NO_COLOR}"
          ;;
          6)count_days
          ;;
          7)echo -e "目前证书在 60 天以后会自动更新, 你无需任何操作. 今后有可能会缩短这个时间, 不过都是自动的, 你不用关心."
          ;;
          8)bash <(curl -L -s https://install.direct/go.sh)
            service v2ray restart
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
      ${GREEN}0. 啥也不做，退出
      $FUCHSIA=======================================================${NO_COLOR}"
      read -p "请输入您要执行的操作的数字:" aNum
      case $aNum in
          1)service v2ray stop
            echo -e  "${GREEN}v2ray服务停止${NO_COLOR}"
          ;;
          2)service v2ray restart
            echo -e  "${GREEN}v2ray服务启动${NO_COLOR}"
          ;;
          3)change_v2ray_uuid
            service v2ray restart
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
      ${GREEN}7. 更新证书有效期     ${GREEN}0. 啥也不做，退出
      $FUCHSIA===================================================${NO_COLOR}"
      read -p "请输入您要执行的操作的数字:" aNum
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
          0) exit
          ;;
          *)echo -e "${RED}输入错误！！！${NO_COLOR}"
            exit
          ;;
      esac
  fi
}
mgr
