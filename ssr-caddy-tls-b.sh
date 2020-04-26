#!/usr/bin/env bash
# Author: Jeannie
#######color code########
RED_COLOR="\033[0;31m"
NO_COLOR="\033[0m"
GREEN="\033[32m\033[01m"
BLUE="\033[0;36m"
FUCHSIA="\033[0;35m"
echo "export PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin:$PATH" >> ~/.bashrc
source ~/.bashrc
echo "先睡一会儿……"
sleep 3
mkdir /etc/caddy /etc/ssl/caddy
isRoot(){
  if [[ "$EUID" -ne 0 ]]; then
    echo "false"
  else
    echo "true"
  fi
}
init_release(){
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
  if [[ $release = "ubuntu" || $release = "debian" ]]; then
    PM='apt'
  elif [[ $release = "centos" ]]; then
    PM='yum'
  else
    exit 1
  fi
  # PM='apt'
}
tools_install(){
  PID=$(ps -ef | grep "v2ray" | grep -v grep | awk '{print $2}')
  [[ ! -z ${PID} ]] && kill -9 ${PID}
  PID=$(ps -ef | grep "trojan" | grep -v grep | awk '{print $2}')
  [[ ! -z ${PID} ]] && kill -9 ${PID}
  PID=$(ps -ef | grep "nginx" | grep -v grep | awk '{print $2}')
  [[ ! -z ${PID} ]] && kill -9 ${PID}
  PID=$(ps -ef | grep "caddy" | grep -v grep | awk '{print $2}')
	[[ ! -z ${PID} ]] && kill -9 ${PID}
  init_release
  if [ $PM = 'apt' ] ; then
    apt-get update -y
    apt-get install -y dnsutils wget unzip zip curl tar git
  elif [ $PM = 'yum' ]; then
    yum update -y
    yum -y install bind-utils wget unzip zip curl tar git
  fi
}
left_second(){
    seconds_left=30
    while [ $seconds_left -gt 0 ];do
      echo -n $seconds_left
      sleep 1
      seconds_left=$(($seconds_left - 1))
      echo -ne "\r     \r"
    done
}
caddy_install(){
  curl https://getcaddy.com | bash -s personal hook.service
}
caddy_conf(){
  read -p "输入您的域名:" domainname
  real_addr=`ping ${domainname} -c 1 | sed '1{s/[^(]*(//;s/).*//;q}'`
  local_addr=`curl ipv4.icanhazip.com`
  while [ "$real_addr" != "$local_addr" ]; do
     read -p "本机ip和绑定域名的IP不一致，请检查域名是否解析成功,并重新输入域名:" domainname
     real_addr=`ping ${domainname} -c 1 | sed '1{s/[^(]*(//;s/).*//;q}'`
     local_addr=`curl ipv4.icanhazip.com`
  done
  read -p "请输入您的邮箱：" emailname
  read -p "您输入的邮箱正确吗? [y/n]?" answer
  if [ $answer != "y" ]; then
     read -p "请重新输入您的邮箱：" emailname
  fi
  echo "http://${domainname}:80 {
        redir https://${domainname}:1234{url}
       }
        https://${domainname}:1234 {
        gzip
        timeouts none
        tls ${emailname}
        root /var/www
       }" > /etc/caddy/Caddyfile
}
ssr_install(){
  /etc/init.d/shadowsocks-r stop
   wget --no-check-certificate -O shadowsocks-all.sh https://raw.githubusercontent.com/JeannieStudio/all_install/master/shadowsocks-all.sh
   chmod +x shadowsocks-all.sh
   ./shadowsocks-all.sh 2>&1 | tee shadowsocks-all.log
    #分别将配置/etc/shadowsocks-r/config.json文件的第4行和第14行改为下面内容
    sed -i '4c "server_port":443,' /etc/shadowsocks-r/config.json
    sed -i "14c \"redirect\": [\"*:443#127.0.0.1:1234\"]," /etc/shadowsocks-r/config.json
    cp shadowsocks-all.sh /etc/shadowsocks-r/shadowsocks-all.sh
}
web_get(){
  mkdir /var/www
  echo -e "下面提供了15个不同的伪装网站模板，按对应的数字进行安装，安装之前可以查看网站demo:
  ${GREEN}1. https://templated.co/intensify
  ${GREEN}2. https://templated.co/binary
  ${GREEN}3. https://templated.co/retrospect
  ${GREEN}4. https://templated.co/spatial
  ${GREEN}5. https://templated.co/monochromed
  ${GREEN}6. https://templated.co/transit
  ${GREEN}7. https://templated.co/interphase
  ${GREEN}8. https://templated.co/ion
  ${GREEN}9. https://templated.co/solarize
  ${GREEN}10. https://templated.co/phaseshift
  ${GREEN}11. https://templated.co/horizons
  ${GREEN}12. https://templated.co/grassygrass
  ${GREEN}13. https://templated.co/breadth
  ${GREEN}14. https://templated.co/undeviating
  ${GREEN}15. https://templated.co/lorikeet${NO_COLOR}
  "
read -p "您输入你要安装的网站的数字:" aNum
case $aNum in
    1)wget -O web.zip --no-check-certificate https://templated.co/intensify/download
    ;;
    2)wget -O web.zip --no-check-certificate https://templated.co/binary/download
    ;;
    3)wget -O web.zip --no-check-certificate https://templated.co/retrospect/download
    ;;
    4)wget -O web.zip --no-check-certificate https://templated.co/spatial/download
    ;;
    5)wget -O web.zip --no-check-certificate https://templated.co/monochromed/download
    ;;
    6)wget -O web.zip --no-check-certificate https://templated.co/transit/download
    ;;
    7)wget -O web.zip --no-check-certificate https://templated.co/interphase/download
    ;;
    8)wget -O web.zip --no-check-certificate https://templated.co/ion/download
    ;;
    9)wget -O web.zip --no-check-certificate https://templated.co/solarize/download
    ;;
    10)wget -O web.zip --no-check-certificate https://templated.co/phaseshift/download
    ;;
    11)wget -O web.zip --no-check-certificate https://templated.co/horizons/download
    ;;
    12)wget -O web.zip --no-check-certificate https://templated.co/grassygrass/download
    ;;
    13)wget -O web.zip --no-check-certificate https://templated.co/breadth/download
    ;;
    14)wget -O web.zip --no-check-certificate https://templated.co/undeviating/download
    ;;
    15)wget -O web.zip --no-check-certificate https://templated.co/lorikeet/download
    ;;
    *)wget -O web.zip --no-check-certificate https://templated.co/intensify/download
    ;;
esac
    unzip -o -d /var/www web.zip
}
CA_exist(){
  if [ -d "/root/.caddy/acme/acme-v02.api.letsencrypt.org/sites/$domainname" -o -d "/.caddy/acme/acme-v02.api.letsencrypt.org/sites/$domainname" ]; then
    FLAG="YES"
  else
    FLAG="NO"
  fi
}
check_CA(){
    CA_exist
    if [ $FLAG = "YES" ]; then
        end_time=$(echo | openssl s_client -servername $domainname -connect $domainname:443 2>/dev/null | openssl x509 -noout -dates |grep 'After'| awk -F '=' '{print $2}'| awk -F ' +' '{print $1,$2,$4 }' )
    while [ "${end_time}" = "" ]; do
        end_time=$(echo | openssl s_client -servername $domainname -connect $domainname:443 2>/dev/null | openssl x509 -noout -dates |grep 'After'| awk -F '=' '{print $2}'| awk -F ' +' '{print $1,$2,$4 }' )
    done
    end_times=$(date +%s -d "$end_time")
    now_time=$(date +%s -d "$(date | awk -F ' +'  '{print $2,$3,$6}')")
    RST=$(($((end_times-now_time))/(60*60*24)))
    fi
}
add_CA(){
  init_release
  CA_exist
  if [ $FLAG = "YES" ]; then
      curl -s -o /etc/RST.sh https://raw.githubusercontent.com/JeannieStudio/jeannie/master/RST.sh
      chmod +x /etc/RST.sh
      if [ $PM = 'apt' ] ; then
        cron_job="30 4 * * * /etc/RST.sh"
        ( crontab -l | grep -v "$cron_job"; echo "$cron_job" ) | crontab -
        service cron restart
      elif [ $PM = 'yum' ]; then
        echo "SHELL=/bin/bash
30 4 * * * /etc/RST.sh" > /var/spool/cron/root
        service crond reload
        service crond restart
      fi
  fi
}
mgr(){
  if [ -f "/etc/mgr.sh" ]; then
      rm -f /etc/mgr.sh
  fi
  while [ ! -f "/etc/mgr.sh" ]; do
      curl -s -o /etc/mgr.sh https://raw.githubusercontent.com/JeannieStudio/all_install/master/mgr.sh
  done
  chmod +x /etc/mgr.sh
}
info(){
    shadowsockspwd=`sed -n "1p" /root/ssr_info`
    shadowsockprotocol=`sed -n "2p" /root/ssr_info`
    shadowsockscipher=`sed -n "3p" /root/ssr_info`
    shadowsockobfs=`sed -n "4p" /root/ssr_info`
    tmp1=$(echo -n "${shadowsockspwd}" | base64 -w0 | sed 's/=//g;s/\//_/g;s/+/-/g')
    tmp2=$(echo -n "${real_addr}:443:${shadowsockprotocol}:${shadowsockscipher}:${shadowsockobfs}:${tmp1}/?obfsparam=" | base64 -w0)
    code="ssr://${tmp2}"
    qrencode -o code.png -s 8 "${code}"
    vps=ssr
    wget --no-check-certificate -O ssr_tmpl.html https://raw.githubusercontent.com/JeannieStudio/all_install/master/ssr_tmpl.html
    chmod +x ssr_tmpl.html
    eval "cat <<EOF
    $(< ssr_tmpl.html)
    EOF
    "  > ssr.html
    cp /root/ssr.html /var/www/ssr.html
    cp /root/code.png  /var/www/code.png
}
main(){
   isRoot=$( isRoot )
  if [[ "${isRoot}" != "true" ]]; then
    echo -e "${RED_COLOR}error:${NO_COLOR}Please run this script as as root"
    exit 1
  else
  tools_install
  web_get
  caddy_install
  caddy_conf
  ssr_install
  caddy -service install -agree -email ${emailname} -conf /etc/caddy/Caddyfile
  caddy -service start
  echo -e " ${GREEN}正在下载证书，请稍等……${NO_COLOR}"
  left_second
  caddy -service start
  /etc/init.d/shadowsocks-r restart
  caddy -service restart
  CA_exist
  check_CA
  add_CA
  mgr
  info
  echo "再睡一会儿……"
  sleep 5
  if [ $FLAG = "YES" ]; then
  echo -e "
${GREEN} ===================================================
${GREEN}       恭喜你，SSR安装和配置成功
${GREEN} ===================================================
详情：https://${domainname}/ssr.html
 $NO_COLOR " 2>&1 | tee info
    elif [ $FLAG = "NO" ]; then
      echo -e "
$RED=====================================================
$RED              很遗憾，安装和配置失败
$RED=====================================================
${RED}由于证书申请失败，无法科学上网，请重装或更换一个域名重新安装， 详情：https://letsencrypt.org/docs/rate-limits/
进一步验证证书申请情况，参考：https://www.ssllabs.com/ssltest/${NO_COLOR}" 2>&1 | tee info
  fi
  touch /etc/motd
  cat info > /etc/motd
  fi
}
main
