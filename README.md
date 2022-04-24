# MetalEffects

This framework provides out of the box effects for your iOS app or game. The framework uses Metal API so it only runs on iOS devices with Metal support (all devices equipped with A7 processors or higher)

**NOTE:** Metal is not supported in the Simulator so you need real device.

## Features

- [x] Confetti effect

<p align="left" >
  <img src="confetti.png" title="Confetti" float=left>
</p>

## Requirements

- iOS 9.0 or later
- Xcode 9.4 or later
- iOS device with Metal support, i.e. with A7 processor or higher

## How to use

```swift
import MetalEffects

// EffectsManager is the main class to work with
let effectsManager = EffectsManager()

// The effect is rendered in a custom UIView so you need to add this view to your view hierarchy
addSubview(effectsManager.view!)

// Show the effect (currently only Confetti is supported)
effectsManager.show(effectType: .confetti(configuration: .default)) { result in
   // TODO: Handle completion of the effect
}
```

## Instalation

MetalEffects usese Swift Package Manager.

```https://github.com/plamenterziev/MetalEffects```

## Author

- [Plamen Terziev](https://github.com/plamenterziev)

## Showcase

This framework is used in [Solitaire The Game](https://itunes.apple.com/us/app/solitaire-the-game/id1251359095?mt=8) distributed by [Mobishape](https://mobishape.com) which is featured in the article [World of Solitaire](https://topgamescenter.com/world-of-solitaire/) of [TopGamesCenter](https://topgamescenter.com)

## TODO

- Add more effects

