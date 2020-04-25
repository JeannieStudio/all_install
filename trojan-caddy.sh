#!/usr/bin/env bash
RED_COLOR="\033[0;31m"
NO_COLOR="\033[0m"
GREEN="\033[0;32m"
echo "export PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin:$PATH" >> ~/.bashrc
source ~/.bashrc
echo "等3秒……"
sleep 3
mkdir /etc/caddy /etc/ssl/caddy /var/www
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
caddy_install(){
  curl https://getcaddy.com | bash -s personal hook.service
}
caddy_conf(){
  read -p "输入您的域名:" domainname
  read -p "您输入的域名正确吗? [y/n]?" answer
  if [ $answer != "y" ]; then
     read -p "请重新输入您的域名:" domainname
  fi
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
        proxy / 127.0.0.1:5678
       }" > /etc/caddy/Caddyfile
}
main(){
   isRoot=$( isRoot )
  if [[ "${isRoot}" != "true" ]]; then
    echo -e "${RED_COLOR}error:${NO_COLOR}Please run this script as as root"
    exit 1
  else
  caddy_install
  caddy_conf
  caddy -service stop
  caddy -service uninstall
  caddy -service install -agree -email ${emailname} -conf /etc/caddy/Caddyfile
  caddy -service start
  echo -e "${GREEN}恭喜你，安装和配置成功
访问：${GREEN}https://${domainname}  可在线trojan多用户管." 2>&1 | tee info
  touch /etc/motd
  cat info > /etc/motd
  fi
}
main
