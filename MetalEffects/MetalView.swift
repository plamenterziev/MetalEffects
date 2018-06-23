//
//  MetalView.swift
//  MetalEffects
//
//  Created by Plamen Terziev on 22.04.18.
//  Copyright © 2018 Plamen Terziev. All rights reserved.
//

import UIKit

protocol MetalViewDelegate: class {
    func metalView(sender: MetalView, didChangeSizeTo size: CGSize)
}

class MetalView: UIView {
    
    weak var delegate: MetalViewDelegate?
    
    private var metalLayer: CAMetalLayer {
        return self.layer as! CAMetalLayer
    }
    
    override class var layerClass: AnyClass {
        return CAMetalLayer.self
    }
    
    private var previousSize: CGSize!
    
    init(device: MTLDevice) {
        super.init(frame: .zero)
        
        self.metalLayer.device = device
        self.metalLayer.pixelFormat = .bgra8Unorm
        self.metalLayer.framebufferOnly = true
        self.metalLayer.isOpaque = false
        
        self.previousSize = self.bounds.size
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let scale = UIScreen.main.scale
        self.metalLayer.drawableSize = CGSize(width: self.bounds.width * scale, height: self.bounds.height * scale)
        
        if self.previousSize != self.bounds.size {
            self.delegate?.metalView(sender: self, didChangeSizeTo: self.bounds.size)
        }
        
        self.previousSize = self.bounds.size
    }
    
    func nextDrawable() -> CAMetalDrawable? {
        return self.metalLayer.nextDrawable()
    }
}
