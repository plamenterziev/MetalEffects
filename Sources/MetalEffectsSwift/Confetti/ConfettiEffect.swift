//
//  ConfettiEffect.swift
//  MetalEffects
//
//  Created by Plamen Terziev on 2.05.18.
//  Copyright © 2018 Plamen Terziev. All rights reserved.
//

import UIKit
import MetalEffectsCore

public class ConfettiEffect: Effect {

    public struct Configuration {
        // available colors to choose randomly from
        public var colors: Set<UIColor>
        // size (in points) of each individual confetti particle
        public var confettiSize: CGSize
        // speed multiplier of the default yaw speed (the default yaw speed is in [-pi/2, +pi/2] per second
        public var yawSpeedMultiplier: CGFloat
        // speed multiplier of the default pitch speed (the default pitch speed is in [-pi/2, +pi/2] per second
        public var pitchSpeedMultiplier: CGFloat
        // speed multiplier of the default roll speed (the default roll speed is in [-pi/2, +pi/2] per second
        public var rollSpeedMultiplier: CGFloat
        // multiplier of the default total count (the default total count is area(view) / area(confetti))
        public var totalCountMultiplier: CGFloat
        // multiplier of the default initial velocity (the default initial velocity is view.height / sec)
        public var initialVelocityMultiplier: CGFloat
        // multiplier of the default acceleration (the default acceleration is view.height / sec^2)
        public var accelerationMultiplier: CGFloat
        // multiplier of the time offset distribution
        public var timeOffsetMultiplier: CGFloat
        
        public static let `default`: Configuration = {
            return Configuration(colors: [.white, .blue],
                                 confettiSize: CGSize(width: 16, height: 8),
                                 yawSpeedMultiplier: 1.6,
                                 pitchSpeedMultiplier: 6.3,
                                 rollSpeedMultiplier: 6.3,
                                 totalCountMultiplier: 0.4,
                                 initialVelocityMultiplier: 0.2,
                                 accelerationMultiplier: 1.0,
                                 timeOffsetMultiplier: 0.4)
        }()
    }
    
    private let effect: ConfettiEffectInner
    
    public var isCompleted: Bool {
        return self.effect.isCompleted
    }
        
    public init(configuration: Configuration) {
        let innerConfiguration = ConfettiEffectInnerConfiguration()
        innerConfiguration.colors = Array<UIColor>(configuration.colors)
        innerConfiguration.confettiSize = configuration.confettiSize
        innerConfiguration.yawSpeedMultiplier = configuration.yawSpeedMultiplier
        innerConfiguration.pitchSpeedMultiplier = configuration.pitchSpeedMultiplier
        innerConfiguration.rollSpeedMultiplier = configuration.rollSpeedMultiplier
        innerConfiguration.totalCountMultiplier = configuration.totalCountMultiplier
        innerConfiguration.initialVelocityMultiplier = configuration.initialVelocityMultiplier
        innerConfiguration.accelerationMultiplier = configuration.accelerationMultiplier
        innerConfiguration.timeOffsetMultiplier = configuration.timeOffsetMultiplier
        self.effect = ConfettiEffectInner(innerConfiguration)
    }
    
    func prepare(device: MTLDevice, viewSize: CGSize) {
        self.effect.prepare(with: device, viewSize: viewSize)
    }
    
    func reshape(size: CGSize) {
        self.effect.reshape(with: size)
    }
    
    func update() {
        self.effect.update()
    }
    
    func render(commandQueue: MTLCommandQueue, metalView: MetalView) {
        self.effect.render(with: commandQueue, drawable: metalView.nextDrawable())
    }
    
    func dispose(commandQueue: MTLCommandQueue,  metalView: MetalView) {
        self.effect.dispose(with: commandQueue, drawable: metalView.nextDrawable())
    }
}
