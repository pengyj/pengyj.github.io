---
layout: post
title: （一）认识 iOS 上的人脸识别：CIDetector
categories: 人脸识别
tags: iOS CIDetector 人脸识别
description: iOS 系统自带的人脸识别
---

iOS 系统自带了人脸识别的方法，而且非常简单。无论针对图片 or 摄像头，都有系统级方法。

## iOS 系统级 UIImage 人脸识别

iOS 系统的 CIDetector 封装得非常简洁易于使用。

代码量极小，就能完成识别，而且速度非常快。

但缺点就是识别特征过少，只有脸、眼、嘴相关的。相对于 dlib 的 68 个点位特征，实在有点不够用。

```
UIImage *faceImage = [UIImage imageNamed:@"face1.png"];
self.resultView.image = faceImage;
    
CIImage *image = [CIImage imageWithCGImage:faceImage.CGImage];

CIContext *context = [CIContext contextWithOptions:nil];
NSDictionary *param = [NSDictionary dictionaryWithObject:CIDetectorAccuracyHigh forKey:CIDetectorAccuracy];
CIDetector *faceDetector = [CIDetector detectorOfType:CIDetectorTypeFace context:context options:param];

NSArray *detectResult = [faceDetector featuresInImage:image];
    
CGAffineTransform transform = CGAffineTransformScale(CGAffineTransformIdentity, 1, -1);
transform = CGAffineTransformTranslate(transform, 0, -faceImage.size.height);
    
for (CIFaceFeature *faceFeature in detectResult) {
    CGRect rect = CGRectApplyAffineTransform(faceFeature.bounds, transform);
    
    UIView *borderView = [[UIView alloc] initWithFrame:rect];
    borderView.layer.borderColor = [UIColor yellowColor].CGColor;
    borderView.layer.borderWidth = 1;
    [self.resultView addSubview:borderView];
}
```
看一下 CIFaceFeature 这个类的参数，提供了少量可供识别使用的参数。
![CIFaceFeature](/_img/20191115/CIFaceFeature.png)

要注意的是，这个类的坐标系 和我们 UIView 里的坐标系是不一样的。

所以如果用到，所以我们做了一些转换。

```
CGAffineTransform transform = CGAffineTransformScale(CGAffineTransformIdentity, 1, -1);

transform = CGAffineTransformTranslate(transform, 0, -faceImage.size.height);

CGRect rect = CGRectApplyAffineTransform(CIFaceFeature.bounds, transform);

```

![Coordinate](/_img/20191115/Coordinate.jpeg)

## iOS 系统级视频流的人脸识别

视频我们会使用 ```AVCaptureSession``` 这个类来完成。

我们需要一个 AVCaptureSession 来完成视频流，一个 AVCaptureVideoPreviewLayer 来完成展示。

AVCaptureSession 里需要有一个 input 和一个 output。这里，我们其实是有2种 output 可以用的，分别对应的2种 delegate 处理。

```
- (AVCaptureSession *)session {
    if (!_session) {
        _session = [[AVCaptureSession alloc] init];
        [_session setSessionPreset:AVCaptureSessionPreset1280x720];
    }
    return _session;
}

- (void)addVideoInput {
    AVCaptureDevice *deviceI = nil;
    for (AVCaptureDevice *device in [AVCaptureDevice devices]) {
        if (device.position == AVCaptureDevicePositionFront && [device hasMediaType:AVMediaTypeVideo]) {
            deviceI = device;
            break;
        }
    }
    
    AVCaptureDeviceInput*input = [[AVCaptureDeviceInput alloc] initWithDevice:deviceI error:nil];
    if ([self.session canAddInput:input]) {
        [self.session addInput:input];
    }
}

- (void)setupPreviewLayer {
    self.previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
    [self.previewLayer setVideoGravity:AVLayerVideoGravityResizeAspect];
    self.previewLayer.frame = CGRectMake(0, 0, VideoWidth, VideoHeight);
    [self.videoView.layer addSublayer:self.previewLayer];
}
```

一、使用 ```AVCaptureVideoDataOutput ``` 需要实现```AVCaptureVideoDataOutputSampleBufferDelegate``` 的代理方法。

这个 delegate 会返回每个视频帧给我们，但不是我们常见的 UIImage，需要我们做格式转换。

并且 delegate 是在非主线程，我们要做 UI 展示的时候，需要主动切换主线程。

你还是可以用视频获取到的每一帧转换为 UIImage 来识别，速度就...所以我们不会直接用这种方法来做人脸识别。

```
- (void)addVideoOutput1 {
    AVCaptureVideoDataOutput *videoOutput = [[AVCaptureVideoDataOutput alloc] init];
    [videoOutput setSampleBufferDelegate:self queue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)];
    if ([self.session canAddOutput:videoOutput]) {
        [self.session addOutput:videoOutput];
    }
    
    for (AVCaptureConnection *conn in videoOutput.connections) {
        if (conn.supportsVideoMirroring) {
            conn.videoOrientation = AVCaptureVideoOrientationPortrait;
            conn.videoMirrored = YES;
        }
    }
    
    NSDictionary *settings = @{(NSString *)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA)};
    [videoOutput setVideoSettings:settings];
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    
    CVImageBufferRef buffer;
    buffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    CVPixelBufferLockBaseAddress(buffer, 0);
    uint8_t *base;
    size_t width, height, bytesPerRow;
    base = (uint8_t *)CVPixelBufferGetBaseAddress(buffer);
    width = CVPixelBufferGetWidth(buffer);
    height = CVPixelBufferGetHeight(buffer);
    bytesPerRow = CVPixelBufferGetBytesPerRow(buffer);
    
    CGColorSpaceRef colorSpace;
    CGContextRef cgContext;
    colorSpace = CGColorSpaceCreateDeviceRGB();
    cgContext = CGBitmapContextCreate(base, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGColorSpaceRelease(colorSpace);
    
    CGImageRef cgImage;
    UIImage *image;
    cgImage = CGBitmapContextCreateImage(cgContext);
    image = [UIImage imageWithCGImage:cgImage];
    [self detectFace:image]; // 静态图片的识别方法
    CGImageRelease(cgImage);
    CGContextRelease(cgContext);
    
    CVPixelBufferUnlockBaseAddress(buffer, 0);
}
```

二、 使用 ```AVCaptureMetadataOutput ``` 需要实现```AVCaptureMetadataOutputObjectsDelegate ``` 的代理方法。

它会识别到指定的 ```metadataObjectTypes``` 后，回调 delegate 通知我们处理。

如果没有识别到，不会调用。

这里我们指定了人脸，那么它在识别到人脸后，产生回调。

```
- (void)addVideoOutput2 {
    AVCaptureMetadataOutput *metaOutput = [[AVCaptureMetadataOutput alloc] init];
    [metaOutput setMetadataObjectsDelegate:self queue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)];

    if ([self.session canAddOutput:metaOutput]) {
        [self.session addOutput:metaOutput];
    }
    
    metaOutput.metadataObjectTypes = @[AVMetadataObjectTypeFace];
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate

- (void)captureOutput:(AVCaptureOutput *)output didOutputMetadataObjects:(NSArray<__kindof AVMetadataObject *> *)metadataObjects fromConnection:(AVCaptureConnection *)connection {

    dispatch_async(dispatch_get_main_queue(), ^(void) {
        [self.videoView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    });
    
    if (metadataObjects.count > 0) {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            CGSize size = self.previewLayer.bounds.size;
            size.width = 720.0 / 1280.0 * size.height;
            CGFloat offsetX = (self.previewLayer.bounds.size.width - size.width) / 2.0;
            
            for (AVMetadataObject *obj in metadataObjects) {
                CGFloat x = size.width * obj.bounds.origin.y;
                CGFloat y = size.height * obj.bounds.origin.x;
                CGFloat width = obj.bounds.size.height * size.width;
                CGFloat height = obj.bounds.size.width * size.height;
                CGRect rect = CGRectMake(x + offsetX, y, width, height);

                UIView *faceView = [[UIView alloc] initWithFrame:rect];
                faceView.layer.borderColor = [UIColor greenColor].CGColor;
                faceView.layer.borderWidth = 2;
                [self.videoView addSubview:faceView];
            }
        });
    }
}
```

可能实际过程中，会把 ```AVCaptureVideoDataOutput``` 和 ```AVCaptureMetadataOutput``` 结合起来用，一个拿到视频帧，一个拿到头像位置。

然后把这2组数据，传给下一步处理识别更多、更快的框架来使用。比如参考链接里的第2个，即是使用这种方式。它将这2组数据，传给了 dlib 来处理。

## 测试

单人原图:

![face1](/_img/20191115/face1.png)

单人识别:

![result_1](/_img/20191115/result_1.png)

多人原图:

![face5](/_img/20191115/face5.png)

多人识别:

![result_2](/_img/20191115/result_2.png)

## 参考
[刀客传奇-人脸识别技术 （一） —— 基于CoreImage实现对静止图片中人脸的识别](https://www.jianshu.com/p/15fad9efe5ba)

[会飞的大马猴
-iOS 相机流人脸识别(一)-人脸框检测（基于iOS原生，附demo）](https://www.jianshu.com/p/5545e1c224ab)