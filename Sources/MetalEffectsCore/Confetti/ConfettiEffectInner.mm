//
//  ConfettiEffect.m
//  MetalEffects
//
//  Created by Plamen Terziev on 21.04.18.
//  Copyright © 2018 Plamen Terziev. All rights reserved.
//

#import <simd/simd.h>
#import <Metal/Metal.h>
#import <UIKit/UIKit.h>
#import <random>

#import "ConfettiEffectInner.h"
#import "ConfettiShaderTypes.h"

static const long kMaxBufferBytesPerFrame = 1024 * 1024;
static const long kInFlightCommandBuffers = 3;

@implementation ConfettiEffectInnerConfiguration
@end

@interface ConfettiEffectInner ()

@property (nonatomic, strong) ConfettiEffectInnerConfiguration *configuration;

@property (nonatomic, strong) id<MTLDevice> device;

@property (nonatomic) NSInteger vertexCount;
@property (nonatomic) NSInteger instancesCount;;
@property (nonatomic, strong) id<MTLBuffer> vertexBuffer;
@property (nonatomic, strong) id<MTLBuffer> perInstanceUniformsBuffer;

@property (nonatomic, strong) id<MTLBuffer> uniformsBuffer;

@property (nonatomic, strong) id<MTLRenderPipelineState> pipelineState;

@property (nonatomic, strong) dispatch_semaphore_t inflightSemaphore;

@property (nonatomic) CFTimeInterval startingTimeInterval;
@property (nonatomic) CFTimeInterval comletionTimeInterval;

@end

@implementation ConfettiEffectInner

- (instancetype)init:(ConfettiEffectInnerConfiguration *)configuration {
    if ((self = [super init])) {
        self.configuration = configuration;
    }
    
    return self;
}

- (BOOL)isCompleted {
    CFTimeInterval elapsedTime = CACurrentMediaTime() - self.startingTimeInterval;
    
    return (elapsedTime > self.comletionTimeInterval);
}

- (void)prepareWithDevice:(id<MTLDevice>)device viewSize:(CGSize)viewSize {
    self.device = device;
    
    self.uniformsBuffer = [self.device newBufferWithLength:kMaxBufferBytesPerFrame options:0];
    self.uniformsBuffer.label = [NSString stringWithFormat:@"UniformsBuffer"];
    
    //[self build:viewSize];
    [self updateWithSize:viewSize];
        
    id<MTLLibrary> library = [self.device newDefaultLibraryWithBundle:SWIFTPM_MODULE_BUNDLE error:NULL];
    
    MTLRenderPipelineDescriptor *pipelineStateDescriptor = [MTLRenderPipelineDescriptor new];
    pipelineStateDescriptor.vertexFunction = [library newFunctionWithName:@"vertexShader"];
    pipelineStateDescriptor.fragmentFunction = [library newFunctionWithName:@"fragmentShader"];
    pipelineStateDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    
    self.pipelineState = [self.device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:NULL];
    
    self.startingTimeInterval = 0;
    
    self.inflightSemaphore = dispatch_semaphore_create(kInFlightCommandBuffers);
}

- (void)renderWithCommandQueue:(id<MTLCommandQueue>)commandQueue drawable:(id<CAMetalDrawable>)drawable {
    [self renderWithCommandQueue:commandQueue drawable:drawable shouldClearOnly:NO];
}

- (void)reshapeWithSize:(CGSize)size {
    [self updateWithSize:size];
}

- (void)update {
    CFTimeInterval elapsedTime = 0;
    if(self.startingTimeInterval == 0) {
        self.startingTimeInterval = CACurrentMediaTime();
    } else {
        elapsedTime = CACurrentMediaTime() - self.startingTimeInterval;
    }
    
    Uniforms *bufferPointer = (Uniforms *) self.uniformsBuffer.contents;
    bufferPointer->t = elapsedTime;
}

- (void)disposeWithCommandQueue:(id<MTLCommandQueue>)commandQueue drawable:(id<CAMetalDrawable>)drawable {
    [self renderWithCommandQueue:commandQueue drawable:drawable shouldClearOnly:YES];
}

#pragma mark -
#pragma mark Private methods

- (void)build:(CGSize)viewSize {
    ConfettiVertex vertices[] = {
        {{-0.5, -0.5, 0}},
        {{0.5, -0.5, 0}},
        {{0.5, 0.5, 0}},
        {{-0.5, -0.5, 0}},
        {{0.5, 0.5, 0}},
        {{-0.5, 0.5, 0}},
    };
    
    self.vertexCount = 6;
    NSMutableData* data = [NSMutableData dataWithLength:self.vertexCount * sizeof(ConfettiVertex)];
    memcpy(data.mutableBytes, &vertices[0], sizeof(vertices));
    
    self.vertexBuffer = [self.device newBufferWithLength:data.length options:MTLResourceStorageModeShared];
    memcpy(self.vertexBuffer.contents, data.bytes, data.length);
    
    [self buildInstancesData:viewSize];
}

- (void)buildInstancesData:(CGSize)viewSize {
    float viewArea = viewSize.width * viewSize.height;
    float confettiArea = self.configuration.confettiSize.width * self.configuration.confettiSize.height;
    
    self.instancesCount = int((viewArea / confettiArea) * self.configuration.totalCountMultiplier) ;
    
    NSMutableData* instanceData = [NSMutableData dataWithLength:self.instancesCount * sizeof(PerInstanceUniforms)];
    
    PerInstanceUniforms *currentUniforms = (PerInstanceUniforms*) instanceData.mutableBytes;
    
    int colorsCount = int(self.configuration.colors.count);
    std::vector<simd::float4> colors;
    
    for (int i = 0; i < colorsCount; i++) {
        UIColor *color = self.configuration.colors[i];
        CGFloat red, green, blue, alpha;
        [color getRed:&red green:&green blue:&blue alpha:&alpha];
        
        colors.push_back(simd::float4 {float(red), float(green), float(blue), float(alpha)});
    }
    
    unsigned seed = (unsigned)std::chrono::system_clock::now().time_since_epoch().count();
    std::default_random_engine generator(seed);
    const int stddev = 1;
    std::normal_distribution<float> distributionTimeOffset(3 * stddev, stddev);
    
    float posY = viewSize.height * 0.5f + MAX(self.configuration.confettiSize.width, self.configuration.confettiSize.height);
    
    float completionTime = 0;
    
    for (int i = 0; i < self.instancesCount; i++) {
        float posX = (drand48() - 0.5) * viewSize.width;
        float timeOffset = 0;
        float posZ = drand48();
        
        do {
            timeOffset = distributionTimeOffset(generator);
        } while (timeOffset < 0 || timeOffset > 6 * stddev);
        timeOffset *= self.configuration.timeOffsetMultiplier;
        
        float yaw = ((float)drand48() - 0.5) * M_PI * self.configuration.yawSpeedMultiplier;
        float pitch = ((float)drand48() - 0.5) * M_PI * self.configuration.pitchSpeedMultiplier;
        float roll = ((float)drand48() - 0.5) * M_PI * self.configuration.rollSpeedMultiplier;
        
        simd::float2 confettiSize = {float(self.configuration.confettiSize.width * (1 - posZ * 0.5f)),
            float(self.configuration.confettiSize.height * (1 - posZ * 0.5f))};
        
        PerInstanceUniforms uniforms = {
            colors[arc4random() % colorsCount],
            confettiSize,
            {posX, posY, posZ},
            {yaw, pitch, roll},
            timeOffset + (1 - posZ),
            float(self.configuration.accelerationMultiplier) * float(viewSize.height * (1 - posZ * 0.5f)),
            float(self.configuration.initialVelocityMultiplier) * float(viewSize.height * (1 - posZ * 0.5f)),
        };
        
        memcpy(currentUniforms, &uniforms, sizeof(PerInstanceUniforms));
        currentUniforms += 1;
        
        // calculate when this confetti will be outside of the screen
        // it is a quadratic equation (a.t^2 + b.t + c = 0) so find the min positive root of the equation
        float a = uniforms.acceleration * 0.5;
        float b = uniforms.initialVelocity;
        float c = (MAX(confettiSize.x, confettiSize.y) - viewSize.height) * 0.5 - uniforms.translation.y;
        float d = b * b - 4 * a * c;
        if (d >= 0) {
            float sqrtD = sqrt(d);
            float time0 = (-b - sqrtD) / (2 * a);
            float time1 = (-b + sqrtD) / (2 * a);
            
            if (time0 >= 0 || time1 >= 0) {
                float instanceCompletionTime = (time0 >= 0) ? time0 : time1;
                instanceCompletionTime += uniforms.timeOffset;
                
                if (instanceCompletionTime > completionTime) {
                    completionTime = instanceCompletionTime;
                }
            }
        }
    }
    
    self.comletionTimeInterval = completionTime;
    
    self.perInstanceUniformsBuffer = [self.device newBufferWithLength:instanceData.length options:MTLResourceStorageModeShared];
    memcpy(self.perInstanceUniformsBuffer.contents, instanceData.bytes, instanceData.length);
}

- (void)updateWithSize:(CGSize)size {
    Uniforms* bufferPointer = (Uniforms *) self.uniformsBuffer.contents;
    bufferPointer->viewSize = {(float)size.width, (float)size.height};    
    
    [self build:size];
}

- (void)renderWithCommandQueue:(id<MTLCommandQueue>)commandQueue
                      drawable:(id<CAMetalDrawable>)drawable
               shouldClearOnly:(BOOL)shouldClearOnly {
    dispatch_semaphore_wait(self.inflightSemaphore, DISPATCH_TIME_FOREVER);
    
    MTLRenderPassDescriptor *renderPassDescriptor = [MTLRenderPassDescriptor new];
    if (drawable && renderPassDescriptor) {
        renderPassDescriptor.colorAttachments[0].texture = drawable.texture;
        renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 0);
        
        id<MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];
        id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        [renderEncoder setRenderPipelineState:self.pipelineState];
        if (!shouldClearOnly) {
            [renderEncoder setVertexBuffer:self.vertexBuffer offset:0 atIndex:0];
            [renderEncoder setVertexBuffer:self.perInstanceUniformsBuffer offset:0 atIndex:1];
            [renderEncoder setVertexBuffer:self.uniformsBuffer offset:0 atIndex:2];
            [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle
                              vertexStart:0
                              vertexCount:self.vertexCount
                            instanceCount:self.instancesCount];
        }
        [renderEncoder endEncoding];
        
        __block dispatch_semaphore_t blockSemaphore = self.inflightSemaphore;
        [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> buffer) {
            dispatch_semaphore_signal(blockSemaphore);
        }];
        
        [commandBuffer presentDrawable:drawable];
        [commandBuffer commit];
    } else {
        dispatch_semaphore_signal(self.inflightSemaphore);
    }
}

@end
