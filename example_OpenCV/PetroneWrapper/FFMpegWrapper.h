//
//  FFMpegWrapper.h
//  PetroneOpenCVExample
//
//  Created by Byrobot on 2017. 8. 11..
//  Copyright © 2017년 Byrobot. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FFMpegWrapper : NSObject 

- (bool)isConnected;
- (int)onConnect;
- (void)onDisconnect;
- (int)decodeFrame;
- (UIImage*)getFrame;
- (int)getPictureSize;
- (int)getWidth;
- (int)getHeight;
@end
