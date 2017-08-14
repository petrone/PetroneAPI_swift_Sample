//
//  OpenCVWrapper.m
//  PetroneOpenCVExample
//
//  Created by Byrobot on 2017. 8. 11..
//  Copyright © 2017년 Byrobot. All rights reserved.
//

#import <opencv2/opencv.hpp>
#include "opencv2/imgcodecs/ios.h"

#import "OpenCVWrapper.h"

@interface OpenCVWrapper() {
	cv::Mat         cvImage;
}
@end

@implementation OpenCVWrapper

#ifdef __cplusplus
- (UIImage*)getFeature:(UIImage*)image {
    if( image == nil ) return nil;
    
    UIImageToMat(image, cvImage);
    
    if(!cvImage.empty()){
        cv::Mat gray;
        cv::cvtColor(cvImage,gray,CV_RGB2GRAY);
        cv::GaussianBlur(gray, gray, cv::Size(5,5), 1.2,1.2);
        cv::Mat edges;
        cv::Canny(gray, edges, 0, 50);
        cvImage.setTo(cv::Scalar::all(225));
        cvImage.setTo(cv::Scalar(0,128,255,255),edges);
    }
    
    return MatToUIImage(cvImage);
}
#endif

@end
