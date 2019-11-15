---
layout: post
title: （三）iOS 上使用 dlib 来检测人脸特征（landmarks）
categories: 人脸识别
tags: iOS 人脸识别 dlib landmarks 
description: 特征点标出来，还挺好玩
---

我们用 dlib 来做一下人脸特征识别。

## [dlib](http://dlib.net/)是什么？

官方的自定义是：

lib is a modern C++ toolkit containing machine learning algorithms and tools for creating complex software in C++ to solve real world problems.

它和 opencv 的关系还蛮紧密的，是 opencv 的有效补充。也有专门的库来处理 opencv 的格式转换什么的。

## iOS 项目导入 dlib

步骤：1.自己编译静态库 2.copy 源码头文件 3.下载模型

虽然 CocoadPods 有搜索到 pod，但是不可用。

github 上项目负责人也说，不是官方的负责的pod。所以这里我们采用下载源码，自己编译静态库的方式。

```
$ cd examples
$ mkdir build
$ cd build
$ cmake -G Xcode .. 
$ cmake --build . --config Release
```

编译完之后在 ```dlib_build``` 下有一个 dlib.xcodeproj 可以打开，打静态包。

你需要分别打模拟器和真机的静态库，自己合并。

```
lipo -create xx1.a xx2.a -output libdlib.a 
```

然后将 dlib 的源码 copy 出来，即头文件了。

![dlib_header](/_img/20191115/dlib_header.png)

然后下载 68 个点位的人脸特征模型 shape_predictor_68_face_landmarks.dat [dlib model file donwload](http://dlib.net/files/)，当然你也可以下载5个点位的模型，因为68挺大的，将近100M了。

现在我们有3个文件了

![dlib_folder](/_img/20191115/dlib_folder.png)

导入Xcode，不要将 dlib 这个文件夹的头文件导入，否则会报错。

Xcode 里填写 ```Header Search Paths``` 和 ```Library Search Path```，将 dlib 的目录填进去。比如我的是

```
$(PROJECT_DIR)/FaceDemo/resources/dlib
```

Xcode 视角

![dlib_xcode](/_img/20191115/dlib_xcode.png)

另外网上有一些 blog 说要导入一些参数，但我测试不导也没问题，可能这就是我后面测试到的性能问题。但官方文档里的预处理指令和一些 blog 的又不到一致，我也不太确定这里，但做为 demo，也就不这么严格了。[官方文档](http://dlib.net/compile.html)

![dlib_Preprocessor](/_img/20191115/dlib_Preprocessor.png)

## 头文件引用

```
#import <dlib/image_processing.h>
#import <dlib/image_processing/frontal_face_detector.h>
#import <dlib/image_processing/render_face_detections.h>
#import <dlib/opencv.h>
```

frontal_face_detector.h 是用来做人脸识别的，但我们一般不会用 dlib 来做人脸识别，所以可以不用导入。

render_face_detections.h 是用来做人脸特征识别的

opencv.h 是 dlib 专门用来处理 Mat 和 dlib::array2d 数据结构转换的。

## 颜色空间

因为都是处理图片有关，我们会用到很多像素格式问题。官方文档 [Image Processing](http://dlib.net/imaging.html) 里讲得还是比较清楚的。

如果你使用 RGB，那么对应，就应该使用 rgb_pixel 和 bgr_pixel 的格式。

opencv 的默认格式是 bgr，所以对应应该使用 ```bgr_pixel```。但如果是 UIImageToMat 转过来的，它是带 alpha通道的，所以要使用 ```rbg_alpha_pixel```。

一个有趣的点，是 opencv 里默认的是 BGR，但是我们平时经常说和用的，都是RBG。这就出现了通道顺序的问题，如果没有注意，可能出现图片颜色失真的问题。找到一篇文章 [Satya Mallick: Why does OpenCV use BGR color format ?](https://www.learnopencv.com/why-does-opencv-use-bgr-color-format/) 解释大意就是：历史遗留问题。那个有趣的铁轨的故事，差不多。可能当时的厂商们比较通用 BGR，但是现在又比较通用 RBG。虽然如此，opencv 的库，还是给出了各种格式之间的转换，非常贴心易用。这在使用上应该没有什么难度，只是需要额外注意这个问题而已。

![dlib_Image Processing](./dlib_Image Processing.png)

## dlib 的人脸识别

性能问题堪忧。不知道是不是我的静态库配置有问题。

dlib 也有人脸识别，但实际测试下来，速度出乎意料的慢。

平均都要 5s+ 才能识别一张图片。而同一张图片，在 CIDector 和 OpenCV 里，都不到0.1秒。

```
cv::Mat cvImg, bgrImg;
UIImageToMat([UIImage imageNamed:@"face5"], cvImg);
cvtColor(cvImg, bgrImg, cv::COLOR_RGBA2BGR);
    
dlib::frontal_face_detector detector = dlib::get_frontal_face_detector();
    
dlib::array2d<dlib::bgr_pixel> dlibImg;
dlib::assign_image(dlibImg, dlib::cv_image<dlib::bgr_pixel>(bgrImg));
    
std::vector<dlib::rectangle> dets = detector(dlibImg);
NSLog(@"人脸个数 %lu",dets.size());//检测到人脸的数量
```

dlib 是不允许 带 alpha 通道的数据处理。所以我们需要在 OpenCV 转换一下。

要注意的一点，是 iOS 系统和 OpenCV 的颜色空间通道顺序是不同的。

UIImage里是 RGB+Alpha 的形式，但是 OpenCV 的颜色空间顺序是 BGR

如果这一步，你的 Mat 是 灰度图，那么 ```<dlib::bgr_pixel>```就写成```<unsigned char>``` 来处理。

总之，不同处理算法的颜色通道顺序一定需要注意一下。

## dlib 获取 landmarks（特征）

虽然 dlib 的人脸识别性能是大问题，但特征识别的速度却非常快，并且特别简单。

我们用 dlib::shape_predictor，它是可以当做全局变量使用的，不是一次性的。

```
NSString *landmarkPath = [[NSBundle mainBundle] pathForResource:@"shape_predictor_68_face_landmarks" ofType:@"dat"];
std::string modelFileString = [landmarkPath UTF8String];

dlib::shape_predictor sp;
dlib::deserialize(modelFileString) >> sp;
```

将我们之前 OpenCV 优化过的处理加上 dlib

同样因为处理的是灰度图，所以应该写 ```<unsigned char>``` 格式。如果这里，你传 cv::Mat 是摄像头的原图，而不是灰度图，那么就要用 ```<dlib::bgr_pixel>```。

并且涉及到 cv::Rect 和 dlib::rectangle、cv::Point 和 dlib::point 的单位转换，需要注意一下。

```
double scale = 1.0 / 4.0;
cv::Mat orignalImg, gray, smallImg;
UIImageToMat([UIImage imageNamed:@"face1"], orignalImg);
    
// 灰度化、缩小、直方图增强对比
cvtColor( orignalImg, gray, cv::COLOR_BGRA2GRAY);
resize( gray, smallImg, smallImg.size(), scale, scale, cv::INTER_LINEAR_EXACT  );
equalizeHist( smallImg, smallImg );
    
std::vector<cv::Rect> faces;
cv::Size minimumSize(0, 0);
faceDetector.detectMultiScale(smallImg, faces, 1.2, 6, 0, minimumSize);
    
dlib::array2d<unsigned char> dlibImage;
dlib::assign_image(dlibImage, dlib::cv_image<unsigned char>(smallImg));
    
cv::Scalar color = cv::Scalar( rand() & 255, rand() & 255, rand() & 255 );
for ( size_t i = 0; i < faces.size(); i++ ) {
    cv::rectangle(orignalImg, cv::Point(faces[i].x / scale, faces[i].y / scale), cv::Point(faces[i].x / scale + faces[i].width / scale, faces[i].y / scale + faces[i].height / scale),
    color);
    
    // dlib Landmarks
    dlib::rectangle det(faces[i].tl().x,faces[i].tl().y, faces[i].br().x, faces[i].br().y);
    dlib::full_object_detection shape = sp(dlibImage, det);
    for (unsigned long k = 0; k < shape.num_parts(); k++) {
        dlib::point p = shape.part(k);
        cv::circle(orignalImg, cv::Point(p.x() / scale, p.y() / scale), 2, color, 2);
    }
}
self.resultView.image = MatToUIImage(orignalImg);
```

## 测试

![face1_landmarks](/_img/20191115/face1_landmarks.png)

## 应用

当你拥有了这些特征点之后，就可以做很多事。


比如测试某几个点的比，看是不是皱眉啦、眨眼啦。甚至换脸等等操作(我没有试过，猜的)。

![dlib_point](/_img/20191115/dlib_point.png)

## 参考

[dlib: Miscellaneous Preprocessor Directives](http://dlib.net/compile.html)

[dlib: Image Processing](http://dlib.net/imaging.html)

[dlib: model file donwload](http://dlib.net/files/)

[Ngxin: Dlib与OpenCV图片转换](https://zhuanlan.zhihu.com/p/36489663)

[Convert OpenCV's Rect to dlib's rectangle?](https://stackoverflow.com/questions/34871740/convert-opencvs-rect-to-dlibs-rectangle)

[会飞的大马猴: iOS 相机流人脸识别(二)-关键点检测(face landmark --Dlib 附demo)](https://www.jianshu.com/p/c4b6f51d6768)

[Satya Mallick: Why does OpenCV use BGR color format ?](https://www.learnopencv.com/why-does-opencv-use-bgr-color-format/)