//
//  EffectsManager.swift
//  MetalEffects
//
//  Created by Plamen Terziev on 20.04.18.
//  Copyright © 2018 Plamen Terziev. All rights reserved.
//

import UIKit

protocol Effect {
    
    var isCompleted: Bool { get }
    
    func prepare(device: MTLDevice, viewSize: CGSize)
    func reshape(size: CGSize)
    func update()
    func render(commandQueue: MTLCommandQueue,  metalView: MetalView)
    func dispose(commandQueue: MTLCommandQueue,  metalView: MetalView)
}

public protocol EffectsManagerDelegate: class {
    
    func effectsManagerDidTapView(_ sender: EffectsManager)
}

public class EffectsManager {
    
    public enum EffectType {
        case confetti(configuration: ConfettiEffect.Configuration)
    }
    
    public enum CompletionResult {
        case notSupported
        case stopped
        case completed
    }
    
    public typealias CompletionHandler = (CompletionResult) -> Void
    
    private var completionHandler: CompletionHandler?
    
    public var view: UIView? {
        return self.metalView
    }
    
    private let metalView: MetalView?
    
    private let device: MTLDevice?
    private let commandQueue: MTLCommandQueue?
    
    private var effect: Effect?
    
    private var timer: CADisplayLink?
    
    private var shouldReshape = false
    
    public var isMetalSupported: Bool {
        return self.device != nil
    }
    
    public var isShowingEffect: Bool {
        return self.timer != nil
    }
    
    public weak var delegate: EffectsManagerDelegate?
    
    public init() {
        if let device = MTLCreateSystemDefaultDevice() {
            self.device = device
            self.commandQueue = device.makeCommandQueue()
            self.metalView = MetalView(device: device)
            self.metalView?.delegate = self
            
            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapView))
            self.metalView?.addGestureRecognizer(tapGestureRecognizer)
        } else {
            self.device = nil
            self.commandQueue = nil
            self.metalView = nil
        }
    }
    
    @objc func didTapView() {
        self.delegate?.effectsManagerDidTapView(self)
    }
    
    deinit {
        stop()
    }
    
    public func show(effectType: EffectType, completion: CompletionHandler? = nil) {
        guard self.isMetalSupported else {
            completion?(.notSupported)
            return
        }
        
        self.effect?.dispose(commandQueue: self.commandQueue!, metalView: self.metalView!)
        self.completionHandler?(.stopped)
        
        self.completionHandler = completion
        
        self.timer?.invalidate()
        class WeakContainer {
            private weak var parent: EffectsManager?
            
            init(parent: EffectsManager) {
                self.parent = parent
            }
            
            @objc func timerDidFire() {
                self.parent?.timerDidFire()
            }
        }
        self.timer = CADisplayLink(target: WeakContainer(parent: self), selector: #selector(WeakContainer.timerDidFire))        
        self.timer?.add(to: .main, forMode: .commonModes)
        
        switch effectType {
        case .confetti(let configuration):
            self.effect = ConfettiEffect(configuration: configuration)
        }
        
        self.effect!.prepare(device: self.device!, viewSize: self.metalView!.bounds.size)
        
        self.shouldReshape = false
    }
    
    public func stop() {
        guard self.isMetalSupported else {
            return
        }
        
        stop(result: .stopped)
    }
    
    // MARK: - Private methods
    
    private func timerDidFire() {
        guard let metalView = self.metalView else {
            return
        }
        
        if self.shouldReshape {
            self.effect!.reshape(size: self.metalView!.bounds.size)
            self.shouldReshape = false
        }
        self.effect!.update()
        
        autoreleasepool {
            self.effect!.render(commandQueue: self.commandQueue!, metalView: metalView)
        }
        
        if self.effect!.isCompleted {
            stop(result: .completed)
        }
    }
    
    private func stop(result: CompletionResult) {
        guard self.isShowingEffect else {
            return
        }
        guard let metalView = self.metalView else {
            return
        }
        
        self.timer?.invalidate()
        self.timer = nil
        
        self.effect?.dispose(commandQueue: self.commandQueue!, metalView: metalView)
        self.effect = nil
        
        let completionHandler = self.completionHandler
        self.completionHandler = nil        
        completionHandler?(result)
    }
}

extension EffectsManager: MetalViewDelegate {
    
    func metalView(sender: MetalView, didChangeSizeTo size: CGSize) {
        self.shouldReshape = true
    }
}
