---
layout: post
title: （二）iOS 上使用 OpenCV 的人脸识别
categories: 人脸识别
tags: iOS 人脸识别 opencv 
description: 非常好用
---

## 环境

OpenCV 4.1.0 (CocoaPods 管理)

Xcode11

## 头文件和编译配置

OpenCV 从2.4之后，开始支持人脸识别。相对于 iOS 系统级的，代码量还挺少，包括视频流。

可以看看参考里的第1条 URL ，官方文档。

视频流和静态图片处理逻辑是一致的，都是操作 ```cv::Mat``` 这个数据结构。

这是我们这里需要用到的头文件：

```
#ifdef __cplusplus

#import <opencv2/imgcodecs/ios.h> // Mat 和 UIImage互转
#import <opencv2/objdetect/objdetect.hpp> // 物体识别相关的类
#import <opencv2/imgproc.hpp> // 颜色空间 cvtColor 等

#endif
```

另外，你在 OC 文件里是 .m 可能需要改名为 .mm，或者修改编译类型，才能使用 OpenCV。

![compile_type](/_img/20191115/compile_type)

## 图片识别

看一下 OpenCV 怎么识别一张图片里的人脸。参考官方Example [facedetect.cpp](https://docs.opencv.org/4.1.2/d4/d26/samples_2cpp_2facedetect_8cpp-example.html)

首先你需要额外把 opencv 的源码包下载回来，然后找到 /data 下的训练好的 xml 模型来使用。

比如我下载的路径是：opencv-4.1.0/data/haarcascades/haarcascade_frontalface_alt2

![file_xml](/_img/20191115/file_xml.png)

```
cv::Mat orignalImg;
UIImageToMat([UIImage imageNamed:@"face1"], orignalImg);
    
std::vector<cv::Rect> faces;
NSString *path = [[NSBundle mainBundle] pathForResource:@"haarcascade_frontalface_alt2" ofType:@"xml"];
faceDetector.load([path UTF8String]);
faceDetector.detectMultiScale(orignalImg, faces, 1.2, 6, 0, cv::Size(0, 0));
    
cv::Scalar color = cv::Scalar( rand() & 255, rand() & 255, rand() & 255 );
for ( size_t i = 0; i < faces.size(); i++ ) {
    cv::rectangle(orignalImg, cv::Point(faces[i].x, faces[i].y), cv::Point(faces[i].x + faces[i].width, faces[i].y + faces[i].height),
    color);
}
self.resultView.image = MatToUIImage(orignalImg);
```

UIImageToMat 和 MatToUIImage 这个是 OpenCV 专门为 iOS 提供的 UIImage 与 cv::Mat 互转的方法。头文件在 ```<opencv2/imgcodecs/ios.h> ```下。

faceDetector.load 将你要使用的 xml 模型加载进去。然后调用 faceDetector.detectMultiScale 传参数进去，将识别到的脸的位置，都存进 faces 里。

然后我们还在 orignalImg 这个 Mat 上绘制矩形框，标注脸的位置。

## 视频流

官方文档，已经给出非常清晰的视频使用方法 [OpenCV iOS - Video Processing](https://docs.opencv.org/master/db/dc8/tutorial_video_processing.html)

按照文档的写，就能显示视频了。

我们需要处理的是 ```CvVideoCameraDelegate``` 这个的回调 ```processImage``` 方法的回调。

注意```processImage:(cv::Mat &)image```这里的是引用传递，所以直接修改 image 就能修改 cv::Mat 的数据。

我们可以直接拿图片识别的方法来测试，发现是可以的，但是有很严重的掉帧现象，视频里看到的是一卡一卡的慢速运动。

参考 facedetect.cpp 文档，我们学习它一样，将图片灰度化、缩小、增加对比度后，然后再去识别，减小识别难度，加快速度。

提升性能版，我们将图片灰度化后，缩小到25%。然后再去识别，整个速度就提上来了。

我们最终还在原图image上画框，但是计算是用缩小的 smallImg 图，所以在 faces 的坐标需要转换回去。

```
- (void)processImage:(cv::Mat &)image {
    double scale = 1.0 / 4.0;
    cv::Mat gray, smallImg;

    // 灰度化、缩小、直方图增强对比
    cvtColor( image, gray, cv::COLOR_BGRA2GRAY);
    resize( gray, smallImg, smallImg.size(), scale, scale, cv::INTER_LINEAR_EXACT  );
    equalizeHist( smallImg, smallImg );

    std::vector<cv::Rect> faces;
    NSString *path = [[NSBundle mainBundle] pathForResource:@"haarcascade_frontalface_alt2" ofType:@"xml"];
    faceDetector.load([path UTF8String]);
    faceDetector.detectMultiScale(smallImg, faces, 1.2, 6, 0, cv::Size(0, 0));
        
    cv::Scalar color = cv::Scalar( rand() & 255, rand() & 255, rand() & 255 );
    for ( size_t i = 0; i < faces.size(); i++ ) {
        cv::rectangle(image, cv::Point(faces[i].x / scale, faces[i].y / scale), cv::Point(faces[i].x / scale + faces[i].width / scale, faces[i].y / scale + faces[i].height / scale),
        color);
    }
}
```

## 总结

OpenCV 整个使用流程还蛮顺畅，且操作逻辑统一。OpenCV的文档非常棒，又齐全，又完整。

UIView 的图片和视频就感觉完全是2个团队的风格，不仅数据格式不同，坐标系也不同。实际代码量也挺大。

## 参考

[Face Recognition with OpenCV](https://docs.opencv.org/2.4/modules/contrib/doc/facerec/facerec_tutorial.html)

[OpenCV iOS - Video Processing](https://docs.opencv.org/master/db/dc8/tutorial_video_processing.html)

[facedetect.cpp](https://docs.opencv.org/3.4.0/db/d3a/facedetect_8cpp-example.html)