//
//  FFMpegWrapper.m
//  PetroneOpenCVExample
//
//  Created by Byrobot on 2017. 8. 11..
//  Copyright © 2017년 Byrobot. All rights reserved.
//

#import "FFMpegWrapper.h"

#import <AVFoundation/AVAsset.h>
#import <AVFoundation/AVAssetWriter.h>
#import <AVFoundation/AVAssetWriterInput.h>

#include <libavcodec/avcodec.h>
#include <libavformat/avformat.h>
#include <libswscale/swscale.h>
#include <libavutil/frame.h>
#include <libavutil/imgutils.h>

@interface FFMpegWrapper() {
    AVFormatContext         *gFormatCtx;
    AVCodecContext          *gVideoCodecCtx;
    AVCodec                 *gVideoCodec;
    
    int                     gVideoStreamIdx;
    
    AVFrame                 *gFrame;
    AVFrame                 *gFrameRGB;
    
    struct SwsContext       *gImgConvertCtx;
    
    int                     gPictureSize;
    uint8_t                 *gVideoBuffer;
    int64_t                 prevFrame;
    
    
    int                     _scale_width;
    int                     _scale_height;
}
@end

@implementation FFMpegWrapper

- (bool)isConnected {
    if( gFormatCtx != NULL) {
        if( gFormatCtx->iformat != NULL ) {
            if( gFormatCtx->iformat->flags != AVFMT_TS_DISCONT )
                return true;
            return false;
        }
        
        return false;
    }
    
    return false;
}
- (int)onConnect {
    
    avformat_network_init();
    av_register_all();
    
    if(gFormatCtx != NULL) {
        gFormatCtx = NULL;
    }
    
    gFormatCtx = avformat_alloc_context();
    
    if( gFormatCtx == NULL)
    {
        NSLog(@"Could not create AVContext");
    }
    
    if(avformat_open_input(&gFormatCtx, "rtsp://192.168.100.1/cam1/mpeg4", NULL, NULL) != 0)
        return -2;
    
    if(avformat_find_stream_info(gFormatCtx, NULL) < 0)
        return -3;
    
    if(gFormatCtx == NULL)
        return -4;
    
    int i;
    for(i = 0; i < gFormatCtx->nb_streams; i++) {
        if(gFormatCtx->streams[i] == NULL)
            continue;
        if(gFormatCtx->streams[i]->codec == NULL)
            continue;
        if(gFormatCtx->streams[i]->codec->codec_type == AVMEDIA_TYPE_VIDEO) {
            gVideoStreamIdx = i;
            break;
        }
    }
    
    if(gVideoStreamIdx == -1)
        return -5;
    
    gVideoCodecCtx = gFormatCtx->streams[gVideoStreamIdx]->codec;
    gVideoCodec = avcodec_find_decoder(gVideoCodecCtx->codec_id);
    
    if(gVideoCodec == NULL)
        return -6;
    
    if(avcodec_open2(gVideoCodecCtx, gVideoCodec, NULL) < 0)
        return -7;
    
    gFrame = av_frame_alloc();
    if(gFrame == NULL)
        return -8;
    
    gFrameRGB = av_frame_alloc();
    if(gFrameRGB == NULL)
        return -9;
    
    
    gPictureSize = av_image_get_buffer_size(AV_PIX_FMT_ARGB, gVideoCodecCtx->width, gVideoCodecCtx->height, 1);
    
    gVideoBuffer = (uint8_t*)(malloc(sizeof(uint8_t)*gPictureSize));
    
    
    av_image_fill_arrays(gFrameRGB->data, gFrameRGB->linesize, gVideoBuffer, AV_PIX_FMT_ARGB, gVideoCodecCtx->width, gVideoCodecCtx->height, 1);
    
    return 0;
}

- (void)onDisconnect {
    if(gVideoBuffer != NULL) {
        free(gVideoBuffer);
        gVideoBuffer = NULL;
    }
    
    if(gFrame != NULL) {
        av_frame_free(&gFrame);
    }
    
    if(gFrameRGB != NULL) {
        av_frame_free(&gFrameRGB);
    }
    
    if(gVideoCodecCtx != NULL) {
        avcodec_close(gVideoCodecCtx);
        gVideoCodecCtx = NULL;
    }
    
    if(gFormatCtx != NULL) {
        avformat_close_input(&gFormatCtx);
        gFormatCtx = NULL;
    }
    
    avformat_network_deinit();
}

- (int)decodeFrame {
    int frameFinished = 0;
    AVPacket packet;
    while(av_read_frame(gFormatCtx, &packet) >= 0) {
        if(packet.stream_index == gVideoStreamIdx) {
            int ret = avcodec_decode_video2(gVideoCodecCtx, gFrame, &frameFinished, &packet);
            
            if(ret < 0) return ret;
            if(frameFinished) {
                av_packet_unref(&packet);
                @autoreleasepool {
                    dispatch_queue_t queue2 = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
                    
                    dispatch_sync(queue2, ^{
                        gImgConvertCtx = sws_getCachedContext(gImgConvertCtx,
                                                              gVideoCodecCtx->width, gVideoCodecCtx->height, gVideoCodecCtx->pix_fmt,
                                                              gVideoCodecCtx->width, gVideoCodecCtx->height, AV_PIX_FMT_ARGB, SWS_BICUBIC, NULL, NULL, NULL);
                        
                        sws_scale(gImgConvertCtx, (const uint8_t * const *) gFrame->data, gFrame->linesize, 0, gVideoCodecCtx->height, gFrameRGB->data, gFrameRGB->linesize);
                        
                        prevFrame = true;
                    });
                }
                return 0;
            }
        }
    }
    
    return -1;
}
- (UIImage*)getFrame {
    if( gFrameRGB != NULL && gFrameRGB->data[0] != NULL) {
        UIImage* ret;
        CGBitmapInfo bitmapInfo = kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrderDefault;
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGContextRef ctx = CGBitmapContextCreate((void*)gFrameRGB->data[0], [self getWidth], [self getHeight], 8, [self getWidth]*4, colorSpace, bitmapInfo);
        
        if( ctx != nil) {
            CGImageRef imageRef = CGBitmapContextCreateImage(ctx);
            ret = [UIImage imageWithCGImage:imageRef];
            CGColorSpaceRelease(colorSpace);
            CGContextRelease(ctx);
            CGImageRelease(imageRef);
            
            return ret;
        }
        else {
            CGColorSpaceRelease(colorSpace);
        }
    }
    else
        NSLog(@"**** frame is NULL");
    
    return nil;
}

- (int)getPictureSize {
    return gPictureSize;
}

- (int)getWidth {
    if(gVideoCodecCtx != NULL)
        return gVideoCodecCtx->width;
    else return 2;
}

- (int)getHeight {
    if(gVideoCodecCtx != NULL)
        return gVideoCodecCtx->height;
    else return 2;
}
@end
