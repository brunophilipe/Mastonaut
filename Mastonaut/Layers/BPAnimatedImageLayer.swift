//
//  BPAnimatedImageLayer.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 23.06.20.
//  Mastonaut - Mastodon Client for Mac
//  Copyright © 2020 Bruno Philipe.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//

import QuartzCore
import CoreGraphics

class BPAnimatedImageLayer: CALayer {

	// MARK: Initializers

	convenience init?(imageAt url: URL) {
		guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
			return nil
		}
		self.init(imageSource: source)
	}

	init(imageSource: CGImageSource) {
		self.imageSource = imageSource
		isCopy = false
		super.init()

		addSublayer(scaledAtlasLayer)

		guard CGImageSourceGetCount(imageSource) > 0 else {
			fatalError("Image Source is empty!")
		}

		recomputeImageAtlas()
	}

	override init(layer: Any) {
		guard let layer = layer as? BPAnimatedImageLayer else { fatalError() }
		imageSource = layer.imageSource
		atlasGenerator = layer.atlasGenerator
		atlasImage = layer.atlasImage
		frameDelays = layer.frameDelays
		isCopy = true
		super.init(layer: layer)
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	// MARK: - Overrides

	override var frame: CGRect {
		didSet {
			recomputeScaledLayer()
		}
	}

	deinit {
		scaledAtlasLayer.removeAllAnimations()
		scaledAtlasLayer.removeFromSuperlayer()
	}

	// MARK: - Public Stuff

	func startAnimation() {
		scaledAtlasLayer.speed = 1.0
	}

	func stopAnimation() {
		scaledAtlasLayer.speed = 0.0
	}

	// MARK: - Private Stuff

	private let isCopy: Bool
	private let imageSource: CGImageSource
	private let scaledAtlasLayer: CALayer = CALayer()
	private var atlasGenerator: LayerImageAtlasGenerator?
	fileprivate var atlasImage: CGImage?
	fileprivate var frameDelays: [TimeInterval] = []

	private func recomputeImageAtlas() {
		let generator = atlasGenerator ?? .init(layer: self)
		generator.createAtlas(imageSource: imageSource)
		self.atlasGenerator = generator
	}

	fileprivate func recomputeScaledLayer() {
		contentsScale = superlayer?.contentsScale ?? 1.0

		guard let scaledAtlasImage = atlasImage?.resizedImage(newHeight: frame.height, scale: contentsScale) else {
			return
		}

		scaledAtlasLayer.frame = CGRect(x: 0, y: 0,
										width: CGFloat(scaledAtlasImage.width) / contentsScale,
										height: CGFloat(scaledAtlasImage.height) / contentsScale)
		scaledAtlasLayer.contentsScale = contentsScale
		scaledAtlasLayer.contents = scaledAtlasImage

		setUpSpriteAnimation()
	}

	private func setUpSpriteAnimation() {
		scaledAtlasLayer.removeAllAnimations()

		scaledAtlasLayer.anchorPoint = .zero
		scaledAtlasLayer.position = .zero

		let frameWidth = scaledAtlasLayer.frame.width / CGFloat(frameDelays.count)
		let spriteKeyframeAnimation = CAKeyframeAnimation(keyPath: "position.x")
		spriteKeyframeAnimation.values = (0..<frameDelays.count).map({ CGFloat($0) * -frameWidth })
		spriteKeyframeAnimation.duration = frameDelays.reduce(0, +)
		spriteKeyframeAnimation.timingFunction = CAMediaTimingFunction(name: .linear)
		spriteKeyframeAnimation.repeatCount = .greatestFiniteMagnitude
		spriteKeyframeAnimation.calculationMode = .discrete

		scaledAtlasLayer.add(spriteKeyframeAnimation, forKey: "spriteKeyframeAnimation")
	}
}

func CGImageSourceCopyDelayTimeAtIndex(_ source: CGImageSource, _ index: Int) -> TimeInterval?
{
	func validDelay(_ input: TimeInterval?) -> TimeInterval?
	{
		guard case .some(let delay) = input, delay > 0 else { return nil }
		return input
	}

	if let infoDict = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as NSDictionary?
	{
		if let pngDict = infoDict[kCGImagePropertyPNGDictionary] as? NSDictionary,
		   let delayTime = validDelay(pngDict[kCGImagePropertyAPNGUnclampedDelayTime] as? TimeInterval)
			?? pngDict[kCGImagePropertyAPNGDelayTime] as? TimeInterval
		{
			return delayTime
		}
		else if let gifDict = infoDict[kCGImagePropertyGIFDictionary] as? NSDictionary,
				let delayTime = validDelay(gifDict[kCGImagePropertyGIFUnclampedDelayTime] as? TimeInterval)
					?? gifDict[kCGImagePropertyGIFDelayTime] as? TimeInterval
		{
			return delayTime
		}
	}

	return nil
}

private class LayerImageAtlasGenerator {

	weak var originalLayer: BPAnimatedImageLayer?

	weak var layer: BPAnimatedImageLayer? = nil {
		didSet {
			guard let result = lastGeneratedAtlas else { return }

			originalLayer.map { update(layer: $0, with: result) }
			layer.map { update(layer: $0, with: result) }
		}
	}

	private var lastGeneratedAtlas: AtlasResult? {
		didSet {
			guard let result = lastGeneratedAtlas else { return }

			originalLayer.map { update(layer: $0, with: result) }
			layer.map { update(layer: $0, with: result) }
		}
	}

	init(layer: BPAnimatedImageLayer) {
		self.originalLayer = layer
		self.layer = layer
	}

	func createAtlas(imageSource: CGImageSource) {
		let frameCount = CGImageSourceGetCount(imageSource)
		let firstImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil)!

		guard let atlasContext = CGContext(data: nil, width: firstImage.width * frameCount, height: firstImage.height,
										   bitsPerComponent: 8,
										   bytesPerRow: 4 * firstImage.width * frameCount, // 4 bytes per RGBA pixel
										   space: CGColorSpaceCreateDeviceRGB(),
										   bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
			fatalError("Could not create CGBitmapContext")
		}

		DispatchQueue.global(qos: .background).async { [weak self] in

			var delays = [TimeInterval]()

			atlasContext.draw(firstImage, in: CGRect(x: 0, y: 0, width: firstImage.width, height: firstImage.height))
			delays.append(CGImageSourceCopyDelayTimeAtIndex(imageSource, 0) ?? 0.05)

			for index in 1..<frameCount {
				let frameImage = CGImageSourceCreateImageAtIndex(imageSource, index, nil)!
				atlasContext.draw(frameImage, in: CGRect(x: firstImage.width * index, y: 0,
														 width: frameImage.width, height: frameImage.height))

				delays.append(CGImageSourceCopyDelayTimeAtIndex(imageSource, index) ?? 0.05)
			}

			guard let atlasImage = atlasContext.makeImage() else {
				fatalError("Could not create image from atlas context!")
			}

			DispatchQueue.main.async {
				guard let self = self else {
					print("Nil animated layer")
					return
				}
				self.lastGeneratedAtlas = AtlasResult(atlasImage: atlasImage, frameDelays: delays)
			}
		}
	}

	private func update(layer: BPAnimatedImageLayer, with result: AtlasResult) {
		layer.atlasImage = result.atlasImage
		layer.frameDelays = result.frameDelays
		layer.recomputeScaledLayer()
	}

	struct AtlasResult {
		let atlasImage: CGImage
		let frameDelays: [TimeInterval]
	}
}
