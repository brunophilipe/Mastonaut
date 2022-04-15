//
//  WelcomePlaceholderController.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 11.03.19.
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
import SVGKit

class WelcomePlaceholderController: NSViewController
{
	@IBOutlet private weak var imageView: NSImageView!

	private var svgSourceCode: String? = nil
	private var effectiveAppearanceObserver: NSObjectProtocol? = nil

	override func awakeFromNib()
	{
		super.awakeFromNib()

		guard
			let svgUrl = Bundle.main.url(forResource: "welcome", withExtension: "svg"),
			let svgSourceCode = try? String(contentsOf: svgUrl)
		else
		{
			return
		}

		self.svgSourceCode = svgSourceCode

		effectiveAppearanceObserver = view.observe(\NSView.effectiveAppearance)
			{
				[weak self] (view, change) in

				self?.updatePlaceholderImage()
			}
	}

	private func updatePlaceholderImage()
	{
		guard
			let tintColor = NSColor.safeControlTintColor.rgbHexString,
			let tintedSource = svgSourceCode?.replacingOccurrences(of: "#A1B2C3", with: tintColor),
			let svgImage = SVGKImage.make(fromSVGSourceCode: tintedSource)
		else { return }

		imageView.image = svgImage.nsImage
	}

	@IBAction private func createAccount(_ sender: Any?)
	{
		NSWorkspace.shared.open(URL(string: "https://joinmastodon.org")!)
	}
}
