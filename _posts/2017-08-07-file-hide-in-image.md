---
layout: post
title: 将文件隐藏在图片里
categories: 奇技淫巧
tags: 压缩 加密
description: 一个有趣的实验
---
## 目标
我有一个文件，比如叫test.mp3，想把它隐藏到一张叫test.png的图片里。
## 环境
* Mac OSX 10.12.4

## 工具
* Mac Terminal

## 命令
* zip、unzip
* cat

## 压缩

压缩test.mp3

```
zip output.zip test.mp3
```

如果需要加密，可以带上-P命令。

```
zip -P 123456 output.zip test.mp3
```

将压缩包写入图片
```
cat test.png output.zip > final.png
```
这样就得到了最终的图片了，正常是看不到里面的数据的。

## 解压
```
unzip final.png 
```
