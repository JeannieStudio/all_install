#!/bin/bash
RED="\033[0;31m"
NO_COLOR="\033[0m"
GREEN="\033[0;32m"
isRoot() {
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
  init_release
  if [ $PM = 'apt' ] ; then
    apt-get install -y  wget  curl 
  elif [ $PM = 'yum' ]; then
    yum -y install wget curl 
  fi
}
main(){
  #check root permission
  isRoot=$( isRoot )
  if [[ "${isRoot}" != "true" ]]; then
    echo -e "非root用户不能执行该脚本"
    exit 1
  else
    tools_install
    sed -i 's/PermitRootLogin no/PermitRootLogin yes/g' /etc/ssh/sshd_config
    sleep 1
    sed -i 's/#PermitRootLogin yes/PermitRootLogin yes/g' /etc/ssh/sshd_config
    sleep 1
    sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config
    sleep 1
    sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
    sleep 1
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/g' /etc/ssh/sshd_config
    sleep 1
    passwd root 2>&1 | tee info
    sleep 2
    grep "successfully" info >/dev/null
    if [ $? -eq 0 ]; then
        systemctl restart sshd.service
        /etc/init.d/sshd restart
        echo -e "${GREEN}修改成功，请用用户名root和刚设置好的密码登录vps吧，enjoy${NO_COLOR}"
    else
	 echo -e "${RED}两次密码输入不一致,修改不成功${NO_COLOR}"
    fi
  fi
}
main
