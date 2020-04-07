---
layout: post
title: 微信和QQ的 Universal Link 配置
categories: iOS
tags: iOS 微信 QQ 设备未授权 错误码25105
description: 有实效性，可能过段时间腾讯SDK又不一样了
---

# 微信和QQ的 Universal Link 配置

最近，由于腾讯家的政策，我们把陈年老 App 们都拿出来更新了一波。记录一下被QQ坑的辛酸过程。

QQ 开放平台的配置文档实在是过于模糊，我们摸索了好半天。

## 目标

假如，我有2个 App，它们的 universal Link 我预计配置成：

https://www.exmaple.com/app1/

https://www.exmaple.com/test/app2/

这个 ```www.example.com``` 是我写的测试域名，你们需要用替换为自己的后台的域名。

## iOS 端的证书和项目配置

一、profile 证书，需要添加 Associated Domains 支持。

![profile证书](/_img/20200407/profile.png)

二、在项目里，添加 Associated Domans.entitlements, 增加 ```applinks:域名```，这里我们使用 "applinks:www.example.com"。

这里，注意是用，千万不要写成 http/https 之类的。

后面使用的是根域名，不要带path。

![entitlements](/_img/20200407/entitlements.png)

三、LSApplicationQueriesSchemes 和 URL Types 要填对。旧版本升级上来的，QQ不需要变动，微信需要增加 ```weixinULAPI```。

## 后台配置

一、首先，你的域名要支持 https 啦。

二、配置 apple-app-site-association

```
https://www.exmaple.com/apple-app-site-association

https://www.exmaple.com/.well-known/apple-app-site-association
```

上面的任何一个链接，能访问到就可以，任选其一。

![json](/_img/20200407/json.png)

## 验证

确认首次安装app有访问域名，下载json。

在 iOS13+ 系统里，你可以打开配置的路径，往下拉，只要配置正确，会显示打开 App。

![browser](/_img/20200407/browser.png)

iOS13- 的系统里，在备忘录里输入链接，长按链接，可以看到打开 APP 选项。

![note](/_img/20200407/note.png)

## 微信开放平台配置

无坑，按文档配置即可。

如果你的分享步骤始终是2次，请检查。（理论上一步验证没问题，这里不会出问题。）

```
首次分享：
App - 微信验证页 - App - 微信分享列表

非首次分享：
App - 微信分享列表
```

## QQ 开放平台配置

文档不全。

URL Scehema的配置，请使用tencent开头的编号。

网上流传了一个QQ开头的编号，但是我们测试总是报“设备未授权(错误码：25105)”

配完后发现 url schema 后的编号与 universal link 后的数字一致。如果不一致，请检查是否配对。

当你配完QQ，请把后台的 ```apple-app-site-association``` 加上腾讯给的路径。然后回来开放平台点击验证。通过后，就能QQ就能正常了。

首次分享和非首次分享情形与微信一致。

![QQ](/_img/20200407/QQ.png)

![error](/_img/20200407/error.png)

## 总结

微信的 universal link 是由我们自己定的。

QQ的却是它们分配的。

所以至少有2个访问路径。（除非你微信也用QQ一样的）

```
app1:
https://www.exmaple.com/app1/
https://www.exmaple.com/qq_conn/5544332211

app2:
https://www.exmaple.com/test/app2/
https://www.exmaple.com/qq_conn/1122334455
```

universal link的路径，都是配在 apple-app-site-association 文件里。

程序里是不需要配置的，它会在首次安装app时自己下载。

(ShareSDK)微信在注册时，需要填写 universal link，但 QQ 不需要。

## 参考
[Apple - Support Universal Links](https://developer.apple.com/library/archive/documentation/General/Conceptual/AppSearch/UniversalLinks.html#//apple_ref/doc/uid/TP40016308-CH12-SW2)

[微信 - iOS SDK接入指南](https://developers.weixin.qq.com/doc/oplatform/Mobile_App/Access_Guide/iOS.html)

[QQ互联 - 创建、填写及校验UniversalLinks](https://wiki.connect.qq.com/%E5%A1%AB%E5%86%99%E5%8F%8A%E6%A0%A1%E9%AA%8Cuniversallinks)