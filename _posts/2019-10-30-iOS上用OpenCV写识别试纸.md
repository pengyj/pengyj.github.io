---
layout: post
title: iOS上用OpenCV写识别试纸
categories: iOS
tags: iOS OpenCV canny sobel 试纸识别
description: 一个尝试，但不严密
---

demo 向，逻辑示例，场景测试不全。

久闻 opencv 的大名，想要了解一下。于是我司每周挑战做题的内容，让大家试了一下这个。

过程遇到很多困难，往上流传的接入教程不是比较久，就是以 python 语言为准。而我们可能更多偏向用 C++ 语言的比较方便，有些时候要去了解 python 代码，然后转写成 C++。

C++ 又会遇到 namespace 的问题，因为不太有这方面的经验。遇到几次导入命名空间不对的问题。

## 计算机如何理解图片，如何做识别？

![Corgi3](/_img/20191030/Corgi3.png)

左边是人眼看到的，是3只狗。

右边是计算机看到的一种数据模拟。

当你需要计算机识别出来3只狗，说到底，就是用一系列合适的数学方法，找到数字规律，得到需要的部分。

如果你数学不好，就有种沦为调参工程师的错觉（事实）

经过系列过滤之后，你可能就换到了你要的线条部分了。

![Filter](/_img/20191030/Filter.png)

## 原图和识别后

勉强识别出来，但是很容易受到背景的噪声污染，如果是那种虎皮桌子的当背景，就完全识别不出来了。

![原图](/_img/20191030/origin.jpg)

然后我想要识别出来是以试纸集中区域的部分。

![识别后](/_img/20191030/after.png)

## 部署 OpenCV

Cocoapods 就能搞定了。并不像网上说的，你需要处理一堆引用bug，手动解决xxx。

除了非常慢，甚至网络链接失败。

```
pod 'OpenCV', '~> 4.1.0'
```

在等待的过程中，发现了一篇非常有意思的 OpenCV 在 pod 时都做了什么的分析，让人长见识。[糖炒小虾 - I have a pod, I have a cartha](http://www.voidcn.com/article/p-xmupzkvq-bbs.html)

## 模仿

主要参考这2个给予灵感，[提取桌面图像](https://www.cnblogs.com/frombeijingwithlove/p/4226489.html) 和 [提取 ppt](https://segmentfault.com/a/1190000013925648) 。非常有意思，对吧！

靠着 ppt 的例子，基本能全程运行起来。但桌面图像基本只有思路分析，但也让人学习了很多思想。

## 边缘检测算子尝试

这是唯一难点，怎么样把我需要的部分检测出来。

opencv 常用的 canny 算子，是边缘识别的首选项。
但实际测试，发现由于试纸太小，且颜色比较复杂，太容易被背景融入进去，导致识别不准确。

因为试纸会有带花的，白色，带字的，甚至绿色待，整体边界不一致，导致 canny 算子识别出来的图结果非常差。形态被割裂的很厉害，连接处不清晰。

类似这样的（找不到自己的图了，1个月前写的...）：

![sobel.png](/_img/20191030/sobel.png)

当了2小时调参工程师之后，我放弃了这个思路。

无意中，发现边缘直方图法补全，sobel 算子能提供帮助。力用sobel算子，可以得到相对完整的一个矩形区域。

## 步骤

一：缩减尺寸

为了加快识别计算时间。最后得到坐标后，还原用到原图裁剪。

```
cv::Mat shrinkPic;
cv::pyrDown(cvImage, shrinkPic);
```

二：灰度图

![grey](/_img/20191030/grey.png)

几乎所有的识别，都会用灰度图。为什么呢？我查了资料一句话就是：降维计算。

我们拿1个象素来说，如果只表示黑和白，那么0和1即可。

如果是 RBG 那么3个信道的值分别是256，3种组合的数量级就是：256 * 256 * 256 = 1600w+多种组合

如果加上 alpha 信道，那么一个象素的可能组合达到40亿。对于计算机来说，一张1024 x 1024的图，从这个数据里找规律，计算量是非常大的。

但如果是灰度图，那么只有 0-255 的灰度值，那么计算量下了很多倍。

```
cv::cvtColor(shrinkPic, greyPic, cv::COLOR_RGBA2GRAY);
```

三：sobel 算子补全形态

![sobel_lh](/_img/20191030/sobel_lh.png)

```
cv::Mat grabX, grabY;
cv::Sobel(greyPic, grabX, CV_32F, 1, 0);
cv::Sobel(greyPic, grabY, CV_32F, 0, 1);
cv::subtract(grabX, grabY, sobPic);
cv::convertScaleAbs(sobPic, sobPic);
```

四：增加对比度

因为补全的部分，虽然是完整的矩形形态，但是边缘还是相对弱，如果直接二值化，容易补全形态丢失。

```
cv::Mat kernel = cv::getStructuringElement(cv::MORPH_RECT, cv::Size(25, 25));
cv::morphologyEx(sobPic, enhancePic, cv::MORPH_CLOSE, kernel);
```

五：去噪和二值化

上一步，过滤了一部分偏小的颜色之后，还是会有不属于识别物的噪点存在。我们做一下过滤，最后转化成二值化的图。

二值化就是全图只前0和1。那么计算机识别速度又加快上百倍了。

![threshold](/_img/20191030/threshold.png)

```
cv::blur(sobPic, threshPic, cv::Size(5,5));
cv::threshold(threshPic, threshPic, 30, 255, cv::THRESH_BINARY);
```

六：找到最小外接矩形中最大的一个得到坐标

![rect](/_img/20191030/rect.png)

识别物和噪点区域，可能被识别成一个数组，交还给你，你需要找到面积最大的一个，那么就是我们的识别目标

```
// 找出轮廓区域
std::vector<std::vector<cv::Point>> contours;
std::vector<cv::Vec4i> hierarchy;
cv::findContours(threshPic, contours, hierarchy, cv::RETR_CCOMP, cv::CHAIN_APPROX_SIMPLE);
    
// 求所有形状的最小外接矩形中最大的一个
cv::RotatedRect box;
for( int i = 0; i < contours.size(); i++ ){
    cv::RotatedRect rect = cv::minAreaRect( cv::Mat(contours[i]) );
    if (box.size.width < rect.size.width) {
        box = rect;
    }
}
```

七：剪裁未缩小后的图，使用放射变换

略

## 完整示例

我展示的代码，缺了对 UIIImage 做处理，在参考链接最后一条。

如果不处理，你拍到的图可能和 OpenCV 拿到的 Mat 图 orientation 不一致。

```
#import "OpenCVWrapper.h"

#import <opencv2/imgproc/imgproc_c.h>
#import <opencv2/imgproc/imgproc.hpp>

#import <opencv2/imgcodecs/ios.h>//MatToUIImage、MatToUIImage用到
#import <opencv2/imgproc.hpp>//cv::域名下的东西会用到
#import <opencv2/highgui.hpp>


+ (UIImage *)change:(UIImage *)image {
    cv::Mat cvImage;
    UIImageToMat(image, cvImage);
    if (cvImage.empty()) {
        return nil;
    }
    
    cv::Mat shrinkPic;
    cv::pyrDown(cvImage, shrinkPic);
    
    int shrinkCount = (image.size.width / 500);
    int multi = 2;
    if (shrinkCount > 1) {
        shrinkCount = shrinkCount / 2;
        multi = pow(2, shrinkCount + 1);
        for (int i = 0; i < shrinkCount; i++) {
            cv::pyrDown(shrinkPic, shrinkPic);
        }
    }
    
    cv::Mat greyPic, sobPic,enhancePic, threshPic;

    cv::cvtColor(shrinkPic, greyPic, cv::COLOR_RGBA2GRAY);
    
    // 边缘直方图法，采用sobel算子提取边缘线，然后水平，垂直分别做直方图
    cv::Mat grabX, grabY;
    cv::Sobel(greyPic, grabX, CV_32F, 1, 0);
    cv::Sobel(greyPic, grabY, CV_32F, 0, 1);
    cv::subtract(grabX, grabY, sobPic);
    cv::convertScaleAbs(sobPic, sobPic);
    
    // 填充空白区域，增强对比度
    cv::Mat kernel = cv::getStructuringElement(cv::MORPH_RECT, cv::Size(25, 25));
    cv::morphologyEx(sobPic, enhancePic, cv::MORPH_CLOSE, kernel);
    
    // 去除噪声
    cv::blur(sobPic, threshPic, cv::Size(5,5));
    cv::threshold(threshPic, threshPic, 30, 255, cv::THRESH_BINARY);//90
    
//    return MatToUIImage(threshPic);
    
    // 找出轮廓区域
    std::vector<std::vector<cv::Point>> contours;
    std::vector<cv::Vec4i> hierarchy;
    cv::findContours(threshPic, contours, hierarchy, cv::RETR_CCOMP, cv::CHAIN_APPROX_SIMPLE);
    
    // 求所有形状的最小外接矩形中最大的一个
    cv::RotatedRect box;
    for( int i = 0; i < contours.size(); i++ ){
        cv::RotatedRect rect = cv::minAreaRect( cv::Mat(contours[i]) );
        if (box.size.width < rect.size.width) {
            box = rect;
        }
    }
    
    {
        // 画出来矩形和4个点, 供调试。此部分代码可以不要
        cv::Mat drawing = cv::Mat::zeros(threshPic.rows, threshPic.cols, CV_8UC3);
        cv::Scalar color = cv::Scalar( rand() & 255, rand() & 255, rand() & 255 );
        cv::Point2f rect_points[4];
        box.points( rect_points );
        for ( int j = 0; j < 4; j++ )
        {
            line( drawing, rect_points[j], rect_points[(j+1)%4], color );
            circle(drawing, rect_points[j], 10, color, 2);
        }
//        return MatToUIImage(drawing);
    }
    
    // 仿射变换
    cv::Point2f corners[4], canvas[4], tmp[4];
    
    // 固定输出尺寸，可以由外部传入
    cv::Size real_size = cv::Size(500, 40);
    
    canvas[0] = cv::Point2f(0, 0);
    canvas[1] = cv::Point2f(real_size.width, 0);
    canvas[2] = cv::Point2f(real_size.width, real_size.height);
    canvas[3] = cv::Point2f(0, real_size.height);
    
    box.points( tmp );
    
    bool sorted = false;
    int n = 4;
    while (!sorted){
        for (int i = 1; i < n; i++){
            sorted = true;
            if (tmp[i-1].x > tmp[i].x){
                swap(tmp[i-1], tmp[i]);
                sorted = false;
            }
        }
        n--;
    }
    if (tmp[0].y < tmp[1].y){
        corners[0] = tmp[0];
        corners[3] = tmp[1];
    }
    else{
        corners[0] = tmp[1];
        corners[3] = tmp[0];
    }
    
    if (tmp[2].y < tmp[3].y){
        corners[1] = tmp[2];
        corners[2] = tmp[3];
    }
    else{
        corners[1] = tmp[3];
        corners[2] = tmp[2];
    }
    for (int i = 0; i < 4; i++){
        corners[i] = cv::Point2f(corners[i].x * multi, corners[i].y * multi); //恢复坐标到原图
    }
    
    cv::Mat result;
    cv::Mat M = cv::getPerspectiveTransform(corners, canvas);
    cv::warpPerspective(cvImage, result, M, real_size);
    return MatToUIImage(result);
}
```


## 参考
[糖炒小虾 - I have a pod, I have a cartha](http://www.voidcn.com/article/p-xmupzkvq-bbs.html)

[Adit Deshpande - A Beginner's Guide To Understanding Convolutional Neural Networks](https://adeshpande3.github.io/adeshpande3.github.io/A-Beginner%27s-Guide-To-Understanding-Convolutional-Neural-Networks/)

[奥卡姆剃刀 - 数字图像的压缩与恢复](https://songshuhui.net/archives/37945)

[達聞西 - 利用OpenCV检测图像中的长方形画布或纸张并提取图像内容](https://www.cnblogs.com/frombeijingwithlove/p/4226489.html)

[才才才 - 利用OpenCV提取图像中的矩形区域（PPT屏幕等）](https://segmentfault.com/a/1190000013925648)

[傻傻小萝卜 - OpenCV(iOS)的边缘检测和Canny算子](https://www.jianshu.com/p/40f27163d355)

 [太一吾鱼水- OpenCV矩形检测](https://www.cnblogs.com/yhlx125/p/7501400.html)
 
 [迭代自己 - 使用 Python 和 OpenCV 检测图像中的物体并将物体裁剪下来](http://www.iterate.site/2018/10/27/%E4%BD%BF%E7%94%A8python%E5%92%8Copencv%E6%A3%80%E6%B5%8B%E5%9B%BE%E5%83%8F%E4%B8%AD%E7%9A%84%E7%89%A9%E4%BD%93%E5%B9%B6%E5%B0%86%E7%89%A9%E4%BD%93%E8%A3%81%E5%89%AA%E4%B8%8B%E6%9D%A5/)
 
[OpenCV - Creating Bounding rotated boxes and ellipses for contours](https://docs.opencv.org/3.4/de/d62/tutorial_bounding_rotated_ellipses.html)

[@qt6hy - iOS で opencv を使う。](https://qiita.com/qt6hy/items/ab4a887cd07fc679c6c6)