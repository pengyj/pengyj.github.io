---
layout: post
title: Xcode多种Build Configuration配置使用
categories: iOS
tags: iOS Xcode Configuration
---
## 测试环境
OS X Yosemite 10.10.5

Xcode 7.0.1

## Build Configuration?
Xcode默认会有2个编译模式，一个是Debug，一个是Release。Release下不能调试程序，编译时有做编译优化，会比用Debug打包出来的运行快，另外包也会更小。


![pic1.png](/_img/20151005/pic1.png)


## 使用场景
我自己碰到的使用场景是，我司的域名有3套：

1. 针对开发时的域名
2. 针对预上线时的域名
3. 针对上线时对外公开的域名

这个时候，就会有多套域名，全部加起来可能有15个左右。每次打包时，就会特别混乱。（注释掉现在使用的域名，打开原本注释掉的那部分，出差错的可能蛮高的，而且不利于阅读）

这个时候，我们就使用它来针对3个环境下不同域名做配置。

## 配置Build Configuration
### 1. 添加Configuration

这里我们添加DEVELOP、BETA、保留原有的(release)。这里我们选择直接duplicatte Debug的配置，因为Release的不能做断点调试。

![pic2.png](/_img/20151005/pic2.png)

### 2. 查看Configuration

添加完第1步的Configuration之后，在Edit Scheme里就会看到新添加的配置项

![pic3.png](/_img/20151005/pic3.png)

### 3. 更改Preprocessor Macros

第1步里我们直接复制了Debug的配置项，那这里的值就会有问题，需要自己设置。

![pic4.png](/_img/20151005/pic4.png)

### 4. 在程序里配置对应的Configuration下不同域名

![pic5.png](/_img/20151005/pic5.png)

### 5. 测试

运行程序，修改Scheme下不同的Configuration，就能得到不同的值，那结果就是正确的了。

***
基于以上的实验，app还可以在不同环境下配置不同的AppIcon和AppName

## AppIcon
使用Asset Catalog，分别给三种环境下配置3个名字

* AppIcon
* AppIconDEVELOP
* AppIconBETA

然后去Target - Build Settings里搜索Asset Catalog App Icon Set Name这一项

![pic6.png](/_img/20151005/pic6.png)

![pic7.png](/_img/20151005/pic7.png)

## App Name 
Target - Build Settings里点+号，添加一个User-Defined Setting

比如我们请一个叫APP_DISPLAY_NAME的key值，下面BETA叫BETA，DEVELOP叫DEVELOP， Release还是用系统原配置。

进到Target - Info里，修改Bundle name为$(APP_DISPLAY_NAME)

![pic8.png](/_img/20151005/pic8.png)

![pic9.png](/_img/20151005/pic9.png)

![pic10.png](/_img/20151005/pic10.png)

## 运行结果
![iconDev.png](/_img/20151005/iconDev.png)

![iconBeta.png](/_img/20151005/iconBeta.png)

![iconRelease.png](/_img/20151005/iconRelease.png)

## 打包配置
这几天我们做了一件很蠢的事，把开发用的环境打包发给了Apple。
为了弥补这件事，顺便规范以后的打包问题，于是做了一些配置上的补救。
查了下Apple的文档，原来可以配置，我将Release环境以外的Skip Install配置成NO，就不会Archive出ipa了。

![TN2215_SkipInstall.png](/_img/20151005/TN2215_SkipInstall.png)

## 参考
http://nickcheng.com/post/unique-icons-for-your-app-in-different-state-in-xcode5-debug-release

https://developer.apple.com/library/ios/technotes/tn2215/_index.html