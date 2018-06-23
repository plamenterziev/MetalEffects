//
//  ViewController.swift
//  MetalEffectsExample
//
//  Created by Plamen Terziev on 23.06.18.
//  Copyright © 2018 Plamen Terziev. All rights reserved.
//

import UIKit
import MetalEffects

extension UIColor {
    
    convenience init(red: Int, green: Int, blue: Int) {
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    
    convenience init(hex: Int) {
        self.init(red: (hex >> 16) & 0xFF, green: (hex >> 8) & 0xFF, blue: hex & 0xFF)
    }
}

class ViewController: UIViewController {

    @IBOutlet weak var actionButton: UIButton!
    
    private var effectsManager: EffectsManager!
    
    private var configuration: ConfettiEffect.Configuration = {
        var configuration = ConfettiEffect.Configuration.default
        configuration.confettiSize = CGSize(width: 20, height: 10)
        configuration.totalCountMultiplier = 1.0
        configuration.accelerationMultiplier = 0.3
        configuration.initialVelocityMultiplier = 0.3
        configuration.timeOffsetMultiplier = 0.8
        configuration.colors = [
            UIColor(hex: 0xdba537),
            UIColor(hex: 0x0d19db),
            UIColor(hex: 0xe60000),
            UIColor(hex: 0x008f00),
            UIColor(hex: 0x009169),
            UIColor(hex: 0x8d005f)
        ]
        return configuration
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.effectsManager = EffectsManager()
        self.effectsManager.delegate = self
        
        updateActionButton()
    }
    
    // MARK: - Actions
    
    @IBAction func didTapActionButton(_ sender: Any) {
        guard self.effectsManager.isMetalSupported else {
            let alert = UIAlertController(title: "Error", message: "Metal is not supported on this device", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            present(alert, animated: true, completion: nil)
            
            return
        }
        
        let metalView = self.effectsManager.view!
        metalView.frame = self.view.bounds
        metalView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.view.addSubview(metalView)
        
        self.effectsManager.show(effectType: .confetti(configuration: self.configuration)) { [weak self] result in
            metalView.removeFromSuperview()
            
            self?.updateActionButton()
        }
        
        updateActionButton()
    }
    
    // MARK: - Private methods
    
    private func updateActionButton() {
        let title = self.effectsManager.isShowingEffect ? "Tap anywhere to stop" : "Start Confetti"
        self.actionButton.setTitle(title, for: .normal)
    }
}

extension ViewController: EffectsManagerDelegate {
    
    func effectsManagerDidTapView(_ sender: EffectsManager) {
        self.effectsManager.stop()
    }
}
