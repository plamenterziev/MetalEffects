//
//  ConfettiEffect.h
//  MetalEffects
//
//  Created by Plamen Terziev on 21.04.18.
//  Copyright © 2018 Plamen Terziev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol MTLDevice;
@protocol MTLCommandQueue;

@interface ConfettiEffectInnerConfiguration: NSObject

@property (nonatomic, strong) NSArray<UIColor*> *colors;
@property (nonatomic) CGSize confettiSize;
@property (nonatomic) CGFloat yawSpeedMultiplier;
@property (nonatomic) CGFloat pitchSpeedMultiplier;
@property (nonatomic) CGFloat rollSpeedMultiplier;
@property (nonatomic) CGFloat totalCountMultiplier;
@property (nonatomic) CGFloat initialVelocityMultiplier;
@property (nonatomic) CGFloat accelerationMultiplier;
@property (nonatomic) CGFloat timeOffsetMultiplier;

@end

@interface ConfettiEffectInner: NSObject

@property (nonatomic, readonly) BOOL isCompleted;

- (instancetype)init:(ConfettiEffectInnerConfiguration *)configuration;

- (void)prepareWithDevice:(id<MTLDevice>)device viewSize:(CGSize)viewSize;
- (void)renderWithCommandQueue:(id<MTLCommandQueue>)commandQueue drawable:(id<CAMetalDrawable>)drawable;
- (void)reshapeWithSize:(CGSize)size;
- (void)update;
- (void)disposeWithCommandQueue:(id<MTLCommandQueue>)commandQueue drawable:(id<CAMetalDrawable>)drawable;

@end
