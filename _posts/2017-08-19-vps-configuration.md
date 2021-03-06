---
layout: post
title: 完全小白ssh安全优化
categories: vps
tags: ssh 安全
description: 我的搬瓦工忘记续费被收回了，想它~
---
前几天买了个vps服务，于是玩了一把,对ssh的安全进行优化。

完全业余，仅供参考。

## 环境
* Mac OSX (终端操作)10.12.4 bash
* bash
* 搬瓦工VPS Centos 6 x86 bbr 

## 目标

* 建立普通用户权限的账户，登录后再切换为root
* 禁用root的ssh登录权限
* 使用rsa公钥免密登录

## 必备：vi命令
自行google，操作熟练后再去远程操作。

esc后，shift+:后，输入wq是保存退出，q!是不保存退出。

## 第一次登录ssh
打开Mac的终端(Terminal), 输入

```
ssh root@ip地址 -p 端口号
```
出现：

```
The authenticity of host '[ip地址]:端口号 ([ip地址]:端口号)' can't be established.
RSA key fingerprint is SHA256:bFmpDOKQD0LH6vQYToaLgw3OjelyPHtXw6ZfN4b5XO0.
Are you sure you want to continue connecting (yes/no)? 
```
填yes

```
Warning: Permanently added '[ip地址]:端口号' (RSA) to the list of known hosts.
Last login: Thu Aug  3 23:31:17 2017 from 本机ip地址
```
这时候会在本地的```~/.ssh/known_hosts```添加了刚刚的key，删除下次还会出现新建fingerprint的请求。

操作完之后，我们就登录到远程的ssh上了。

## 修改登录端口和root密码
买了vps之后，服务商会把临时的密码和ssh端口号通过邮件发送给你。
在kiwiVM Control Panel的Main controls的SSH Port项也可以看到同样的端口号和ip地址。

我们需要修改一下端口号，以root的身份登录ssh之后

更改密码:

```
passwd root
```

修改端口号:

```
vi /etc/ssh/sshd_config
```

找到最后一句，这里的端口号就是服务商邮件发给你的那个了:

```
Port 端口号
```

修改完保存之后，重启sshd服务:

```
service sshd restart
```
修改后回wikiVM能看到端口修改了,下次登录也只能用这个端口了。

## 新建用户
```
useradd -m 用户名
passwd 用户名
```
useradd是添加一个用户，-m是添加相关的home目录

passwd是为用户名改密码

做完之后，系统会在/home下建立一个用户名的目录。

## 切换用户
```
su 用户名
```
输入密码就能切换到指定的用户了。

所以当我们用自建的用户名登录后```su root```就能切换回root账户了。

## 禁用root登录
登录后，以root身份操作:

```
vi /etc/ssh/sshd_config
```

找到倒数第二句，改为no：

```PermitRootLogin yes```

wq保存，重启sshd服务（命令以上面）。

<mark>当前已登录的账户不会强制退出，下次登录才生效。</mark>

## 制作免密登录
### 生成密钥
在Mac本地的terminal输入

```
cd ~/.ssh
ssh-keygen -t rsa -C “备注随便填”
```
会出现

```
Generating public/private rsa key pair.
Enter file in which to save the key (/Users/pengyj/.ssh/id_rsa): 【直接回车】
Enter passphrase (empty for no passphrase): 【直接回车,设置空密码】
Enter same passphrase again: 【再次直接回车,确认设置空密码】
Your identification has been saved in /Users/pengyj/.ssh/id_rsa.
Your public key has been saved in /Users/pengyj/.ssh/id_rsa.pub.
The key fingerprint is:
SHA256:GeNbn307rRFeUIQ0D38+/AId4Tb2iGF7uLCa+w4qNxw “abc”
The key's randomart image is:
+---[RSA 2048]----+
|             .=oo|
|             ..B |
|        o   o B +|
|       . + . O.B.|
|        S o = =o+|
|      E  o + B oo|
|     . .o . + = +|
|    . +. +     =o|
|     o..++o   .o.|
+----[SHA256]-----+

```
操作完之后，在本机的~/.ssh/下，会出现以rsa加密的公钥```id_rsa.pub```和私钥```id_rsa```。
### 导入到服务器
使用```ssh-copy-id```命令，将公钥导入到服务器。

在Mac本机Terminal操作，刚刚的~/.ssh 目录下：

```
ssh-copy-id -i id_rsa.pub 用户名@ip地址 -p 端口号
```
上传成功后，后在服务器的用户名目录```~/.ssh/```下有一个```authorized_keys```文件。

在服务器端做修改权限（我一步我没确认过，因为我一开始就做了）：

```
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
```

切换回root用户，或者具有root权限的用户。把以下3句注释去掉，变为:

```
vi /etc/ssh/sshd_config
RSAAuthentication yes
PubkeyAuthentication yes
AuthorizedKeysFile	.ssh/authorized_keys
```
重启sshd服务。

至此，我们已经可以免密登录了。

在本机测试，登录，确认不用密码了后，去服务器更改关闭密码登录。

```
vi /etc/ssh/sshd_config
PasswordAuthentication yes
```

## 优化本机登录
每次在本机登录ssh，都要输入一长串的文字，于是我们优化一下，加个alias:

bash下：

```
vi ~/.bash_profile
alias openvps="ssh 用户名@ip地址 -p 端口号"
```

保存重新载入

```
source ~/.bash_profile
```

这样我们就可以直接在本机的Terminal输入openvps就能登录到ssh了。

## 保存好你的私钥
完！

## 参考
[Dave: Linux 修改SSH端口 和 禁止Root远程登陆](http://blog.csdn.net/tianlesoftware/article/details/6201898)

[秋水逸冰: SSH无密码登录及putty设置](https://teddysun.com/237.html)

[素白流殇: ssh-keygen和ssh-copy-id实现SSH无密钥登陆](http://www.jianshu.com/p/13919b5ba8a2)

[简文：Mac 与服务器 ssh 无密码登录](http://www.jianshu.com/p/ecc744c79d2f)
