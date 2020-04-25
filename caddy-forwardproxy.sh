#!/bin/bash
# 用官方的脚本安装caddy
curl https://getcaddy.com | bash -s personal http.forwardproxy

#安装进程管理工具superisor，帮助我们管理caddy服务的启动、停止、重启、查看状态
sudo  apt-get install supervisor

#创建一个目录存放caddy配置文件
sudo mkdir /etc/caddy

#创建一个目录存放tls证书，如果是caddy自动下载的证书则不会放在这个目录下
sudo mkdir /etc/ssl/caddy

#创建一个目录作为网站的根目录
sudo mkdir /var/www

#控制台提示输入域名
echo "请输入您的域名,例如:example.com:"

#读取内存中的字符串放在domainname变量中
read domainname

echo "您输入的域名正确吗?(y/n)"
read answer
if [ $answer != "y" ];then
	echo "请重新输入您的域名:"
	read domainname
fi
sudo mkdir /var/www/$domainname   
echo "请输入您的邮箱："
read emailname
echo "您输入的邮箱正确吗?(y/n)"
read answer
if [ $answer != "y" ];then
	echo "请重新输入您的邮箱："
	read emailname
fi

echo "请输入您的用户名并牢记它："
read user
echo "请输入您的密码并牢记它："
read pswd
echo "http://$domainname:80 {
      redir https://$domainname:443{url}
} 
https://$domainname:443 {  
    gzip  
	timeouts none
	tls $emailname
    root /var/www 
    forwardproxy {
	basicauth $user $pswd 
}
}" > /etc/caddy/Caddyfile

echo "[program:caddy]
command = /usr/local/bin/caddy -log stdout -agree=true -conf=/etc/caddy/Caddyfile
directory = /etc/caddy
autorstart=true
environment=CADDYPATH=/etc/ssl/caddy" > /etc/supervisor/conf.d/caddy.conf

supervisorctl shutdown
supervisord -c /etc/supervisor/supervisord.conf
sudo echo "别急……等10秒！！！！！！！！！！！"
sleep 10
sudo supervisorctl stop caddy
sudo supervisorctl start caddy

#控制台打印如下信息：
echo "******************************
caddy 安装和配置成功
启动：supervisorctl start caddy  
停止：supervisorctl stop caddy    
重启：supervisorctl restart caddy  
查看状态：supervisorctl status 
安装目录为：/usr/local/bin/caddy 
配置文件位置：/etc/caddy/Caddyfile
*****************************************"
