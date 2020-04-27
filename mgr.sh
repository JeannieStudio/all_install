#!/bin/bash
RED="\033[0;31m"
NO_COLOR="\033[0m"
GREEN="\033[32m\033[01m"
BLUE="\033[0;36m"
green(){
    echo -e "\033[32m\033[01m$1\033[0m"
}
isRoot(){
  if [[ "$EUID" -ne 0 ]]; then
    echo "false"
  else
    echo "true"
  fi
}
genId(){
    id1=$(cat /proc/sys/kernel/random/uuid | md5sum |cut -c 1-8)
    id2=$(cat /proc/sys/kernel/random/uuid | md5sum |cut -c 1-4)
    id3=$(cat /proc/sys/kernel/random/uuid | md5sum |cut -c 1-4)
    id4=$(cat /proc/sys/kernel/random/uuid | md5sum |cut -c 1-4)
    id5=$(cat /proc/sys/kernel/random/uuid | md5sum |cut -c 1-12)
    id=$id1'-'$id2'-'$id3'-'$id4'-'$id5
    echo "$id"
}
mgr(){
  isRoot=$( isRoot )
  if [[ "${isRoot}" != "true" ]]; then
    echo -e "${RED_COLOR}error:${NO_COLOR}Please run this script as as root"
    exit 1
  else
      #=========安装的trojan+caddy+tls一键脚本==============================
      if [ -e "/usr/local/bin/caddy" -a -e "/usr/local/bin/trojan" ]; then
            echo -e "
      $FUCHSIA===================================================
      ${GREEN}系统检测到您目前安装的是trojan+caddy+tls一键脚本
      $FUCHSIA===================================================
      ${GREEN}1. 停止trojan             ${GREEN}2. 重启trojan
      $FUCHSIA===================================================
      ${GREEN}3. 修改trojan密码         ${GREEN}4. 停止caddy
      $FUCHSIA===================================================
      ${GREEN}5. 重启caddy             ${GREEN}0. 啥也不做，退出
      $FUCHSIA===================================================${NO_COLOR}"
      read -p "请输入您要执行的操作的数字:" aNum
      case $aNum in
          1)systemctl stop trojan
            echo -e  "${GREEN}trojan服务停止${NO_COLOR}"
          ;;
          2)systemctl restart trojan
            echo -e  "${GREEN}trojan服务启动${NO_COLOR}"
          ;;
          3)if [ -f "/usr/local/etc/trojan/config.json" ]; then
                password=`sed -n "1p" /usr/local/etc/trojan/trojan_info`
                rm -f /var/www/${password}.html
                rm -f /var/www/${password}.png
                read -p "新密码：" password
                fl="no"
                while [[ $fl = "no" ]]; do
                    read -p "密码只能是字母和数字的组合：" password
                    for ((i=0;$i<${#password};i++));
                    do
                        str=${password:$i:1};
                        case "$str" in
                        [a-z]|[A-Z]|[0-9])fl="yes"
                            ;;
                           *)echo "密码中含非法字符"
                             fl="no"
                              break
                            ;;
                        esac
                    done
                done
                while [ "${password}" = "" ]; do
                      read -p "密码不能为空，请重新输入：" password
                done
                sed -i "8c \"$password\"," /usr/local/etc/trojan/config.json
                domainname=`sed -n "2p" /usr/local/etc/trojan/trojan_info`
                vps=`sed -n "3p" /usr/local/etc/trojan/trojan_info`
                code="trojan://${password}@${domainname}:443"
                qrencode -o /var/www/${password}.png -s 8 "${code}"
                wget --no-check-certificate -O /var/www/trojan_tmpl.html https://raw.githubusercontent.com/JeannieStudio/all_install/master/trojan_tmpl.html
                chmod +x /var/www/trojan_tmpl.html
                end_time=$(echo | openssl s_client -servername $domainname -connect $domainname:443 2>/dev/null | openssl x509 -noout -dates |grep 'After'| awk -F '=' '{print $2}'| awk -F ' +' '{print $1,$2,$4 }' )
                end_times=$(date +%s -d "$end_time")
                now_time=$(date +%s -d "$(date | awk -F ' +'  '{print $2,$3,$6}')")
                RST=$(($((end_times-now_time))/(60*60*24)))
                eval "cat <<EOF
                $(< /var/www/trojan_tmpl.html)
                EOF
                "  > /var/www/${password}.html
                systemctl stop trojan
                systemctl start trojan
                sed -i "1c ${password}" /usr/local/etc/trojan/trojan_info
                sed -i "/详情：https:/c 详情：https://${domainname}/${password}.html " /etc/motd
                echo -e  "${GREEN}恭喜你，密码修改成功,详情：https://${domainname}/${password}.html${NO_COLOR}"
            else
                echo -e  "${RED}很遗憾，Trojan配置文件不存在${NO_COLOR}"
            fi
            systemctl start trojan
          ;;
          4)caddy -service stop
            echo -e  "${GREEN}caddy服务停止${NO_COLOR}"
          ;;
          5)caddy -service restart
            echo -e  "${GREEN}caddy服务启动${NO_COLOR}"
          ;;
          0) exit
          ;;
          *)echo -e "${RED}输入错误！！！${NO_COLOR}"
            exit
          ;;
      esac
      fi
      #=========安装的trojan+nginx+tls一键脚本===============================
      if [ -e "/usr/sbin/nginx" -a -e "/usr/local/bin/trojan" ]; then
            echo -e "
      $FUCHSIA===================================================
      ${GREEN}系统检测到您目前安装的是trojan+nginx+tls一键脚本
      $FUCHSIA===================================================
      ${GREEN}1. 停止trojan          ${GREEN}2. 重启trojan
      $FUCHSIA===================================================
      ${GREEN}3. 修改trojan密码      ${GREEN}4. 停止nginx
      $FUCHSIA===================================================
      ${GREEN}5. 重启nginx           ${GREEN}0. 啥也不做，退出
      $FUCHSIA===================================================${NO_COLOR}"
      read -p "请输入您要执行的操作的数字:" aNum
      case $aNum in
          1)systemctl stop trojan
            echo -e  "${GREEN}trojan服务停止${NO_COLOR}"
          ;;
          2)systemctl restart trojan
            echo -e  "${GREEN}trojan服务启动${NO_COLOR}"
          ;;
          3)if [ -f "/usr/local/etc/trojan/config.json" ]; then
                password=`sed -n "1p" /usr/local/etc/trojan/trojan_info`
                rm -f /var/www/${password}.html
                rm -f /var/www/${password}.png
                read -p "新密码：" password
                fl="no"
                while [[ $fl = "no" ]]; do
                    read -p "密码只能是字母和数字的组合：" password
                    for ((i=0;$i<${#password};i++));
                    do
                        str=${password:$i:1};
                        case "$str" in
                        [a-z]|[A-Z]|[0-9])fl="yes"
                            ;;
                           *)echo "密码中含非法字符"
                             fl="no"
                              break
                            ;;
                        esac
                    done
                done
                while [ "${password}" = "" ]; do
                      read -p "密码不能为空，请重新输入：" password
                done
                sed -i "8c \"$password\"," /usr/local/etc/trojan/config.json
                domainname=`sed -n "2p" /usr/local/etc/trojan/trojan_info`
                vps=`sed -n "3p" /usr/local/etc/trojan/trojan_info`
                code="trojan://${password}@${domainname}:443"
                qrencode -o /var/www/${password}.png -s 8 "${code}"
                wget --no-check-certificate -O /var/www/trojan_tmpl.html https://raw.githubusercontent.com/JeannieStudio/all_install/master/trojan_tmpl.html
                chmod +x /var/www/trojan_tmpl.html
                end_time=$(echo | openssl s_client -servername $domainname -connect $domainname:443 2>/dev/null | openssl x509 -noout -dates |grep 'After'| awk -F '=' '{print $2}'| awk -F ' +' '{print $1,$2,$4 }' )
                end_times=$(date +%s -d "$end_time")
                now_time=$(date +%s -d "$(date | awk -F ' +'  '{print $2,$3,$6}')")
                RST=$(($((end_times-now_time))/(60*60*24)))
                eval "cat <<EOF
                $(< /var/www/trojan_tmpl.html)
                EOF
                "  > /var/www/${password}.html
                systemctl stop trojan
                systemctl start trojan
                sed -i "1c ${password}" /usr/local/etc/trojan/trojan_info
                sed -i "/详情：https:/c 详情：https://${domainname}/${password}.html " /etc/motd
                echo -e  "${GREEN}恭喜你，密码修改成功,详情：https://${domainname}/${password}.html${NO_COLOR}"
            else
                echo -e  "${RED}很遗憾，Trojan配置文件不存在${NO_COLOR}"
            fi
            systemctl start trojan
          ;;
          4)nginx -s stop
            echo -e  "${GREEN}nginx服务停止${NO_COLOR}"
          ;;
          5)nginx
            echo -e  "${GREEN}nginx服务启动${NO_COLOR}"
          ;;
          0) exit
          ;;
          *)echo -e "${RED}输入错误！！！${NO_COLOR}"
            exit
          ;;
      esac
      fi
      #=========安装的v2ray+caddy+tls一键脚本==============================
      if [ -e "/usr/local/bin/caddy" -a -e "/usr/bin/v2ray/v2ray" ]; then
            echo -e "
      $FUCHSIA===================================================
      ${GREEN}系统检测到您目前安装的是v2ray+caddy+tls一键脚本
      $FUCHSIA===================================================
      ${GREEN}1. 停止v2ray      ${GREEN}2. 重启v2ray
      $FUCHSIA===================================================
      ${GREEN}3. 修改UUID       ${GREEN}4. 停止caddy
      $FUCHSIA===================================================
      ${GREEN}5. 重启caddy      ${GREEN}0. 啥也不做，退出
      $FUCHSIA===================================================${NO_COLOR}"
      read -p "请输入您要执行的操作的数字:" aNum
      case $aNum in
          1)service v2ray stop
            echo -e  "${GREEN}v2ray服务停止${NO_COLOR}"
          ;;
          2)service v2ray restart
            echo -e  "${GREEN}v2ray服务启动${NO_COLOR}"
          ;;
          3)if [  -f "/etc/v2ray/config.json" ]; then
                id=`sed -n "1p" /etc/v2ray/v2ray_info`
                rm -f /var/www/${id}.html
                rm -f /var/www/$id.png
                rm -f code_config.json
                genId
                domainname=`sed -n "2p" /etc/v2ray/v2ray_info`
                vps=`sed -n "3p" /etc/v2ray/v2ray_info`
                read -p  "已帮您随机产生一个uuid:
                $id，
                满意吗？（输入y表示不满意再生成一个，按其他键表示接受）" answer
                while [[ "$answer" = "y" ]]; do
                    genId
                    read -p  "uuid:$id，满意吗？（不满意输入y,按其他键表示接受）" answer
                done
                curl -s -o code_config.json https://raw.githubusercontent.com/JeannieStudio/jeannie/master/config.json
                sed -i "s/"b831381d-6324-4d53-ad4f-8cda48b30811"/$id/g" code_config.json
                \cp -rf code_config.json /etc/v2ray/config.json
                sed -i '/"network": "ws",/i "security": "tls",' code_config.json
                wget --no-check-certificate -O json2vmess.py https://raw.githubusercontent.com/JeannieStudio/all_install/master/json2vmess.py
                chmod +x json2vmess.py
                code=$(./json2vmess.py --addr ${domainname} --filter ws --amend port:443 code_config.json)
                qrencode -o /var/www/$id.png -s 8 "${code}"
                end_time=$(echo | openssl s_client -servername $domainname -connect $domainname:443 2>/dev/null | openssl x509 -noout -dates |grep 'After'| awk -F '=' '{print $2}'| awk -F ' +' '{print $1,$2,$4 }' )
                end_times=$(date +%s -d "$end_time")
                now_time=$(date +%s -d "$(date | awk -F ' +'  '{print $2,$3,$6}')")
                RST=$(($((end_times-now_time))/(60*60*24)))
                eval "cat <<EOF
                $(< /var/www/v2ray_tmpl.html)
                EOF
                "  > /var/www/${id}.html
                sed -i "/详情：https:/c 详情：https://${domainname}/${id}.html " /etc/motd
                service v2ray stop
                service v2ray start
                sed -i "1c ${id}" /etc/v2ray/v2ray_info
                echo -e  "${GREEN}恭喜你，UUID修改成功,详情：https://${domainname}/${id}.html ${NO_COLOR}"
            else
                echo -e  "${RED}很遗憾，v2ray配置文件不存在${NO_COLOR}"
            fi
          ;;
          4)caddy -service stop
            echo -e  "${GREEN}caddy服务停止${NO_COLOR}"
          ;;
          5)caddy -service restart
            echo -e  "${GREEN}caddy服务启动${NO_COLOR}"
          ;;
          0) exit
          ;;
          *)echo -e "${RED}输入错误！！！${NO_COLOR}"
            exit
          ;;
      esac
      fi
      #=========安装的v2ray+nginx+tls一键脚本==============================
      if [ -e "/usr/sbin/nginx" -a -e "/usr/bin/v2ray/v2ray" ]; then
            echo -e "
      $FUCHSIA===================================================
      ${GREEN}系统检测到您目前安装的是v2ray+nginx+tls一键脚本
      $FUCHSIA===================================================
      ${GREEN}1. 停止v2ray     ${GREEN}2. 重启v2ray
      $FUCHSIA===================================================
      ${GREEN}3. 修改UUID      ${GREEN}4. 停止nginx
      $FUCHSIA===================================================
      ${GREEN}5. 重启nginx     ${GREEN}0. 啥也不做，退出
      $FUCHSIA===================================================${NO_COLOR}"
      read -p "请输入您要执行的操作的数字:" aNum
      case $aNum in
          1)service v2ray stop
            echo -e  "${GREEN}v2ray服务停止${NO_COLOR}"
          ;;
          2)service v2ray restart
            echo -e  "${GREEN}v2ray服务启动${NO_COLOR}"
          ;;
          3)if [ -f "/etc/v2ray/config.json" ]; then
                id=`sed -n "1p" /etc/v2ray/v2ray_info`
                rm -f /var/www/${id}.html
                rm -f /var/www/$id.png
                rm -f code_config.json
                genId
                domainname=`sed -n "2p" /etc/v2ray/v2ray_info`
                vps=`sed -n "3p" /etc/v2ray/v2ray_info`
                read -p  "已帮您随机产生一个uuid:
                $id，
                满意吗？（输入y表示不满意再生成一个，按其他键表示接受）" answer
                while [[ "$answer" = "y" ]]; do
                    genId
                    read -p  "uuid:$id，满意吗？（不满意输入y,按其他键表示接受）" answer
                done
                curl -s -o code_config.json https://raw.githubusercontent.com/JeannieStudio/jeannie/master/config.json
                sed -i "s/"b831381d-6324-4d53-ad4f-8cda48b30811"/$id/g" code_config.json
                \cp -rf code_config.json /etc/v2ray/config.json
                sed -i '/"network": "ws",/i "security": "tls",' code_config.json
                wget --no-check-certificate -O json2vmess.py https://raw.githubusercontent.com/JeannieStudio/all_install/master/json2vmess.py
                chmod +x json2vmess.py
                code=$(./json2vmess.py --addr ${domainname} --filter ws --amend port:443 code_config.json)
                qrencode -o /var/www/$id.png -s 8 "${code}"
                end_time=$(echo | openssl s_client -servername $domainname -connect $domainname:443 2>/dev/null | openssl x509 -noout -dates |grep 'After'| awk -F '=' '{print $2}'| awk -F ' +' '{print $1,$2,$4 }' )
                end_times=$(date +%s -d "$end_time")
                now_time=$(date +%s -d "$(date | awk -F ' +'  '{print $2,$3,$6}')")
                RST=$(($((end_times-now_time))/(60*60*24)))
                eval "cat <<EOF
                $(< /var/www/v2ray_tmpl.html)
                EOF
                "  > /var/www/${id}.html
                sed -i "/详情：https:/c 详情：https://${domainname}/${id}.html " /etc/motd
                service v2ray stop
                service v2ray start
                sed -i "1c ${id}" /etc/v2ray/v2ray_info
                echo -e  "${GREEN}恭喜你，UUID修改成功,详情：https://${domainname}/${id}.html ${NO_COLOR}"
            else
                echo -e  "${RED}很遗憾，v2ray配置文件不存在${NO_COLOR}"
            fi
          ;;
          4)nginx -s stop
            echo -e  "${GREEN}nginx服务停止${NO_COLOR}"
          ;;
          5)nginx
            echo -e  "${GREEN}nginx服务启动${NO_COLOR}"
          ;;
          0) exit
          ;;
          *)echo -e "${RED}输入错误！！！${NO_COLOR}"
            exit
          ;;
      esac
      fi
      #=========安装的ssr+caddy+tls一键脚本==============================
      if [ -e "/usr/local/bin/caddy" -a -d "/usr/local/shadowsocks" ]; then
            echo -e "
      $FUCHSIA===================================================
      ${GREEN}系统检测到您目前安装的是ssr+caddy+tls一键脚本
      $FUCHSIA===================================================
      ${GREEN}1. 停止ssr      ${GREEN}2. 重启ssr
      $FUCHSIA===================================================
      ${GREEN}3. 修改密码       ${GREEN}4. 停止caddy
      $FUCHSIA===================================================
      ${GREEN}5. 重启caddy      ${GREEN}0. 啥也不做，退出
      $FUCHSIA===================================================${NO_COLOR}"
      read -p "请输入您要执行的操作的数字:" aNum
      case $aNum in
          1)/etc/init.d/shadowsocks-r stop
            echo -e  "${GREEN}ssr服务停止${NO_COLOR}"
          ;;
          2)/etc/init.d/shadowsocks-r restart
            echo -e  "${GREEN}ssr服务启动${NO_COLOR}"
          ;;
          3)shadowsockspwd=`sed -n "1p" /etc/shadowsocks-r/ssr_info`
            shadowsockprotocol=`sed -n "2p" /etc/shadowsocks-r/ssr_info`
            shadowsockscipher=`sed -n "3p" /etc/shadowsocks-r/ssr_info`
            shadowsockobfs=`sed -n "4p" /etc/shadowsocks-r/ssr_info`
            domainname=`sed -n "5p" /etc/shadowsocks-r/ssr_info`
            vps=`sed -n "6p" /etc/shadowsocks-r/ssr_info`
            rm -f /var/www/${shadowsockspwd}.html
            rm -f /var/www/${shadowsockspwd}.png
            read -p "请输入您要修改的密码：" shadowsockspwd
            fl="no"
            while [[ $fl = "no" ]]; do
                read -p "密码只能是字母和数字的组合：" shadowsockspwd
                # [ -z "${shadowsockspwd}" ] && shadowsockspwd="teddysun.com"
                for ((i=0;$i<${#shadowsockspwd};i++));
                do
                    str=${shadowsockspwd:$i:1};
                    case "$str" in
                    [a-z]|[A-Z]|[0-9])fl="yes"
                        ;;
                       *)echo "密码中含非法字符"
                         fl="no"
                          break
                        ;;
                    esac
                done
            done
            while [ "${shadowsockspwd}" = "" ]; do
              read -p "密码不能为空，请重新输入：" shadowsockspwd
            done
            sed -i "7c \"password\":\"$shadowsockspwd\"," /etc/shadowsocks-r/config.json
            tmp1=$(echo -n "${shadowsockspwd}" | base64 -w0 | sed 's/=//g;s/\//_/g;s/+/-/g')
            tmp2=$(echo -n "${domainname}:443:${shadowsockprotocol}:${shadowsockscipher}:${shadowsockobfs}:${tmp1}/?obfsparam=" | base64 -w0)
            code="ssr://${tmp2}"
            qrencode -o /var/www/${shadowsockspwd}.png -s 8 "${code}"
            end_time=$(echo | openssl s_client -servername $domainname -connect $domainname:443 2>/dev/null | openssl x509 -noout -dates |grep 'After'| awk -F '=' '{print $2}'| awk -F ' +' '{print $1,$2,$4 }' )
            end_times=$(date +%s -d "$end_time")
            now_time=$(date +%s -d "$(date | awk -F ' +'  '{print $2,$3,$6}')")
            RST=$(($((end_times-now_time))/(60*60*24)))
            eval "cat <<EOF
            $(< /var/www/ssr_tmpl.html)
            EOF
            "  > /var/www/${shadowsockspwd}.html
            sed -i "1c ${shadowsockspwd}" /etc/shadowsocks-r/ssr_info
            sed -i "/详情：https:/c 详情：https://${domainname}/${shadowsockspwd}.html " /etc/motd
            /etc/init.d/shadowsocks-r stop
            /etc/init.d/shadowsocks-r start
            echo -e  "${GREEN}恭喜你，密码修改成功,详情：https://${domainname}/${shadowsockspwd}.html ${NO_COLOR}"
          ;;
          4)caddy -service stop
            echo -e  "${GREEN}caddy服务停止${NO_COLOR}"
          ;;
          5)caddy -service restart
            echo -e  "${GREEN}caddy服务启动${NO_COLOR}"
          ;;
          0) exit
          ;;
          *)echo -e "${RED}输入错误！！！${NO_COLOR}"
            exit
          ;;
      esac
      fi
fi
}
mgr
