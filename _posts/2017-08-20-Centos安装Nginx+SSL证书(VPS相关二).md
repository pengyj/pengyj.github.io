---
layout: post
title: Centos安装Nginx+SSL证书(VPS相关二)
categories: vps
tags: ssh 安全
---
## 环境
* Mac OSX 操作 
* 搬瓦工VPS Centos 6 x86_64 bbr
* Python2.6（centos 6默认自带）

## 目标
* 安装Nginx
* SSL证书(LetsEncrypt)

## 安装Nginx
```
vi /etc/yum.repos.d/nginx.repo
```

写入

```
[nginx]
name=nginx repo
baseurl=http://nginx.org/packages/centos/$releasever/$basearch/
gpgcheck=0
enabled=1
```

保存后：

```
sudo yum install nginx -y
sudo chkconfig nginx on ##设置nginx为开机启动
sudo service nginx start ##开启nginx
```

打开ip测试，就会看到“Welcome to Nginx!”的经典界面了。

## 编辑Nginx配置文件
找到nginx主目录，命令是```nginx -t```,就会看到相关路径

```
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
```

编辑默认配置文件, 80端口就是http的默认端口，更改root目录可以修改website的目录指向。

```
vi /etc/nginx/conf.d/default.conf
```

## Let's Encrypt

* 安装wget

```
yum -y install wget
```

* 安装easy_install和pip
```
wget https://bootstrap.pypa.io/ez_setup.py -O - | python
easy_install pip
```

* 下载certbot-auto

```
wget https://dl.eff.org/certbot-auto
```

* 修改certbot-auto操作权限

```
chmod a+x certbot-auto
```

* 安装virtualenv(否则下一步有可能出错)

```
pip install virtualenv
```

* 安装certbot-auto

```
./certbot-auto
```

python2.6的环境会有一堆报错提示，可以忽略，或者自行解决升级到python2.7。

* 认证域名，然后开始填邮箱、同意服务协议、是否接收相关服务邮件等。

```
certbot certonly --webroot -w /website主目录/ -d 域名
```

* 成功提示

```
IMPORTANT NOTES:
 - Congratulations! Your certificate and chain have been saved at:
   /etc/letsencrypt/live/你填写的域名/fullchain.pem
   Your key file has been saved at:
   /etc/letsencrypt/live/你填写的域名/privkey.pem
   Your cert will expire on 2017-11-17. To obtain a new or tweaked
   version of this certificate in the future, simply run certbot-auto
   again. To non-interactively renew *all* of your certificates, run
   "certbot-auto renew"
 - Your account credentials have been saved in your Certbot
   configuration directory at /etc/letsencrypt. You should make a
   secure backup of this folder now. This configuration directory will
   also contain certificates and private keys obtained by Certbot so
   making regular backups of this folder is ideal.
 - If you like Certbot, please consider supporting our work by:

   Donating to ISRG / Let's Encrypt:   https://letsencrypt.org/donate
   Donating to EFF:                    https://eff.org/donate-le

```

* 自动更新证书

因为Let's encrypt只有90天有效期。具体操作可以看官方文档。[https://certbot.eff.org](https://certbot.eff.org)

* 更新子域名证书
最近尝试加了一个子域名，对子域名也加SSL证书。
```
./certbot-bot certonly --cert-name 原域名 --expand -d 原域名 -d 子域名
```

## 参考
[certbot](https://certbot.eff.org/#centos6-nginx)

[Let’s Encrypt官方推荐Certbot工具快速部署SSL证书](http://www.vpsss.net/1304.html)