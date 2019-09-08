---
layout: post
title: Mac 下使用 Jenkins 和 hg 代码库
categories: iOS
tags: iOS 国际化 多语方 i18N NSLocale RTL Localizable.strings plural
description: 大家都用 git，hg 相关资料较少
---

由于公司的代码库并不是使用 git 而是使用 Mercurial，网上常用的 jenkins 和 hg 配置的东西比较少，于是有了此篇分享。

我们的目标是能使用 Jenkins 拉取 hg 上的代码，并能根据 Xcode build configuration 里的配置来拉取各自环境的代码构建[Xcode多种Build Configuration配置使用](/ios/2015/10/05/Xcode&Configuration.html)，最后由 nginx 反向代理到端口由外网访问。

### Jenkins是什么

我理解的，简单来说它就是一个 web 服务，提供执行脚本的能力。
是基于 Java 语言开发的 web 服务。
拥有完善的 web 服务：登录注册、权限管理、插件扩展、系统日志各种功能。

我们在 iOS 下，所有的 pod、fastlane、代码版本库管理、打包其实都是可以由脚本来完成。Jenkins 提供了一个这样的 web 容器，能整合执行这些零散的需要人为操作的动作改由脚本触发执行。

### 工具和环境

homebrew

brew-cast

java

Jenkins

hg

nginx

### 安装 homebrew 和 brew-cast

使用 homebrew 来安装 jenkins 的原因是方便管理
brew services 可以自己管理它的开关机启动项等，而且后面涉及到一个重要的环境变量问题。
当然，还有一个安装途径是 pkg 安装包

由于 jenkins 是基于 java 来运行的，所以需要安装 java 环境，我们这里选择用brew-cast 来安装。

```
安装brew-cast
brew install brew-cask-completion
brew-cast java

安装jenkins
brew install jenkins
```
开启 jenkins 运行有2种方式，一是使用 brew 的```brew services start jenkins```，或者直接命令行前台运行```jenkins```做调试使用。

关闭使用```brew services stop jenkins```

### 安装 Jenkins 

详细步骤请自行搜索。

第一次进入，会要求输入一个```initialAdminPassword```，如果你是使用前台运行的方式，命令行能直接看到，如果不是，按照页面提示找到路径下的码复制。

输入完之后按推荐步骤安装插件。

进行后就可以创建第一个登录用户了。

### 安装插件

```Mercurial```这是使用 hg 必须安装的

```Extended Choice Parameter Plug-In```用来配置 Xcode Build Configuration 对应的选项

```Role-based Authorization Strategy```用来管理注册用户的权限

### Jenkins 环境变量

一般安装 PATH 目录是/usr/bin:/bin:/usr/sbin:/sbin这个，但 hg 却是在/usr/local/bin下，始终无法运行起来。

找到```/usr/local/opt/jenkins```目录下的homebrew.mxcl.jenkins.plist的文件。这个是 brew 管理的启动项 plist，我们在原基础上增加了几项，就变成下面这样。

EnvironmentVariables 我们增加了 PATH 路径，把我们想要的路径写到上面，LANG是语言。
httpPort 默认是8080，我们改为6666（可以不改，仅为测试）。
--prefix=/jenkins 可以先不配置，如果你没有使用到nginx，或者其它服务器代码，请不要加。这里是为了后面和 nginx 配置使用，因为nginx我们的 Location /目录已经有其它配置，只能放在二级目录。

```
<plist version="1.0">
  <dict>
    <key>Label</key>
    <string>homebrew.mxcl.jenkins</string>
    <key>ProgramArguments</key>
    <array>
      <string>/usr/libexec/java_home</string>
      <string>-v</string>
      <string>1.8</string>
      <string>--exec</string>
      <string>java</string>
      <string>-Dmail.smtp.starttls.enable=true</string>
      <string>-jar</string>
      <string>/usr/local/opt/jenkins/libexec/jenkins.war</string>
      <string>--httpListenAddress=127.0.0.1</string>
      <string>--httpPort=6666</string>
      <string>--prefix=/jenkins</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
        <key>LANG</key>
        <string>zh_CN.UTF-8</string>
    </dict>
  </dict>
</plist>
```

### Job 关键配置

这里配置对应 Xcode build configuration里的配置，比如我这里配置了3个环境。

![xcode_build_configuration](/_img/20190807/xcode_build_configuration.png)


![parameter_choice](/_img/20190807/parameter_choice.png)

源码管理选择Mercurial，

Repository URL：版本库地址

Credentials：版本库的用户名密码，自己新建，可以在凭据那里统一管理。

Revision: Branch下填分支名

![mercurial](/_img/20190807/mercurial.png)

构建脚本

将 ipa 包放到程序根目录的 path/to/xxx.ipa 下，后续可以自己上传、删除等。

```
cd DistDemo

time=$(date "+%m%d_%H%M")
output="path/to"
IPANAME="demo${time}_jenkins.ipa"
fastlane archive name:$IPANAME env:$app_Evn path:$output
```

### 邮件配置
默认的模板肯定不符合大家所要。

网上有很多blog介绍。比如官方有一个邮件模板，可以试下
[groovy-html.template](https://github.com/jenkinsci/email-ext-plugin/blob/master/src/main/resources/hudson/plugins/emailext/templates/groovy-html.template)

在jenkins的根目录，一般为```~/.jenkins```下，新建一个```email-templates```目录，将上面的模板放入。

Jenkins 系统配置 - Extended E-mail Notification - Default Content 更改为下面，构建完就会发这个模板邮件了。

```
${SCRIPT, template="groovy.template"}
```

当然，如果你的 Job 配置了构建后操作的Editable Email Notification，你也可以在 Job 的配置项右侧，做模板测试。它可以将历史的构建内容填充到模板供观看。

![email_template_testing](/_img/20190807/email_template_testing.png)

![failure](/_img/20190807/failure.png)


### 带配置环境选择的打包

当你配置了 Extended parameter choices 之后，点击开始构建，就会跳到下图这样的页面，选择构建环境，再开始打包。

![打包](/_img/20190807/打包.png)

### nginx反向代理

完成上面的这些，我们的 Jenkins 还都是通过 http://127.0.0.1:6666 来访问的，现在我有一个已经在运行的 nginx ，想要将它和 Jenkins 搭配起来，通过域名能让其它连网设备访问到本机 Jenkins。

中途我碰到 Jenkins 显示反向代码配置有误的问题。最后找到 ```X-Forwarded-Proto  ```这一条很重要。
因为我的 nginx 是已经支持 https 的，中间由 https 转发回 http，scheme变了。

jenkins的系统配置里，Jenkins URL 写为你 nginx 下jenkins 的地址，比如 nginx 的配置域名是 [https://example.com](https://example.com)，那 jenkins url 就是 [https://example.com/jenkins](https://example.com/jenkins)

```
location /jenkins {
	proxy_pass     http://127.0.0.1:6666;
	proxy_redirect  http:// https://;
	proxy_set_header Host $host;
	proxy_set_header X-Real-IP $remote_addr;
	proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
	proxy_set_header X-Forwarded-Proto $scheme;
}
```