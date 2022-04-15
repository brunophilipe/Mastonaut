//
//  AnimatedImageView.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 28.04.19.
//  Mastonaut - Mastodon Client for Mac
//  Copyright © 2019 Bruno Philipe.
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

import Cocoa

@objc class AnimatedImageView: NSView
{
	@objc var tagged = false

	private weak var animatedLayer: BPAnimatedImageLayer? = nil

	override var wantsUpdateLayer: Bool
	{
		return true
	}

	deinit
	{
		animatedLayer?.stopAnimation()
	}

	override var frame: NSRect {
		didSet {
			animatedLayer?.frame = bounds
			if oldValue != frame {
				needsDisplay = true
			}
		}
	}

	var animates: Bool = true
	{
		didSet
		{
			assert(Thread.isMainThread)
			if animates {
				animatedLayer?.startAnimation()
			} else {
				animatedLayer?.stopAnimation()
			}
		}
	}

	@objc func clearAnimatedImage()
	{
		self.animatedLayer?.removeFromSuperlayer()
	}

	@objc func setAnimatedImage(from data: Data)
	{
		if data.isEmpty == false, let imageSource = CGImageSourceCreateWithData(data as CFData, nil) {
			wantsLayer = true
			self.animatedLayer?.removeFromSuperlayer()
			let animatedLayer = BPAnimatedImageLayer(imageSource: imageSource)
			layer?.insertSublayer(animatedLayer, at: 0)
			self.animatedLayer = animatedLayer

			if frame.width > 0, frame.height > 0 {
				animatedLayer.frame = bounds
			}
		}
	}

	override func updateLayer() {
		animatedLayer?.frame = bounds
	}
}
