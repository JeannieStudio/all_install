#!/usr/bin/env bash
RED_COLOR="\033[0;31m"
NO_COLOR="\033[0m"
GREEN="\033[0;32m"
echo "export PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin:$PATH" >> ~/.bashrc
source ~/.bashrc
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
  curl https://getcaddy.com | bash -s personal
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
supervisor_install(){
  supervisorctl shutdown
  init_release
  if [[ ${PM} = 'apt' ]]; then
      apt-get install supervisor
      echo "[program:caddy]
command = /usr/local/bin/caddy -log stdout -agree=true -conf=/etc/caddy/Caddyfile
directory = /etc/caddy
autorstart=true
environment=CADDYPATH=/etc/ssl/caddy" > /etc/supervisor/conf.d/caddy.conf
  elif [[ ${PM} = 'yum' ]]; then
      yum install supervisor
      echo "[program:caddy]
command = /usr/local/bin/caddy  -conf /etc/caddy/Caddyfile -agree
directory = /etc/caddy
autorstart=true
autoresart = true
user=root" > /etc/supervisord.d/caddy.ini
  fi
}
ssr_install(){
   wget --no-check-certificate -O shadowsocks-all.sh https://raw.githubusercontent.com/teddysun/shadowsocks_install/master/shadowsocks-all.sh
   chmod +x shadowsocks-all.sh
   ./shadowsocks-all.sh 2>&1 | tee shadowsocks-all.log
    #分别将配置/etc/shadowsocks-r/config.json文件的第4行和第14行改为下面内容
    sed -i '4c "server_port":443,' /etc/shadowsocks-r/config.json
    sed -i "14c \"redirect\": [\"*:443#127.0.0.1:1234\"]," /etc/shadowsocks-r/config.json
}
CA_check(){
    error=" too many certificates already issued for exact set of domains:"
    if [ `grep -c "$error" $install.log` -ne '0' ];  then
      echo "http://${domainname}:80 {
gzip
timeouts none
tls off
root /var/www
proxy / 127.0.0.1:5678
}" > /etc/caddy/Caddyfile
     sed -i '4c "server_port":80,' /etc/shadowsocks-r/config.json
     sed -i "14c \"redirect\": [\"*:80#127.0.0.1:1234\"]," /etc/shadowsocks-r/config.json
     FLAG='yes'
    fi
}
filebrowser_install(){
    systemctl stop filebrowser.service
    curl -fsSL https://filebrowser.xyz/get.sh | bash
    filebrowser -d /etc/filebrowser.db config init
    filebrowser -d /etc/filebrowser.db config set --address 0.0.0.0
    filebrowser -d /etc/filebrowser.db config set --port 5678
    filebrowser -d /etc/filebrowser.db config set --locale zh-cn
    filebrowser -d /etc/filebrowser.db config set --log /var/log/filebrowser.log
    read -p  "输入用户名:" user
    read -p  "输入密码:" pswd
    filebrowser -d /etc/filebrowser.db users add $user $pswd --perm.admin
    echo "[Unit]
    Description=File Browser
    After=network.target
    [Service]
    ExecStart=/usr/local/bin/filebrowser -d /etc/filebrowser.db
    [Install]
    WantedBy=multi-user.target" > /lib/systemd/system/filebrowser.service
}
main(){
   isRoot=$( isRoot )
  if [[ "${isRoot}" != "true" ]]; then
    echo -e "${RED_COLOR}error:${NO_COLOR}Please run this script as as root"
    exit 1
  else
  caddy_install
  caddy_conf
  supervisor_install
  ssr_install
  filebrowser_install
  supervisorctl start all
  CA_check
  /etc/init.d/shadowsocks-r stop
  /etc/init.d/shadowsocks-r start
  supervisorctl stop all
  supervisorctl start all
  systemctl enable filebrowser.service
  systemctl restart filebrowser.service
  var=$(sed -n '7p' /etc/shadowsocks-r/config.json)
  echo -e "恭喜你，安装和配置成功"
  if [ $FLAG = 'yes' ]; then
      echo "但该域名证书申请次数超限，但仍然可以科学上网，且只能访问http://${domainname},看清了是http不是https
      详情： https://letsencrypt.org/docs/rate-limits"
  fi
echo "域名:\"${domainname}\""
if [ $FLAG = 'yes' ]; then
   echo "端口:\"80\""
else
    echo "端口:\"443\""
fi
echo "密码:${var##*:}
密码方式:\"none\"
协议:\"auth_china_a\"
混淆:\"tls1.2_ticket_auth\"
"
  fi
}
main
