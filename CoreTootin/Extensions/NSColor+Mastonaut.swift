//
//  NSColor+Mastonaut.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 08.01.19.
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

import AppKit

public extension NSColor
{
	static let statusReblogged	= #colorLiteral(red: 0, green: 0.6039215686, blue: 1, alpha: 1)
	static let statusFavorited	= #colorLiteral(red: 1, green: 0.6509803922, blue: 0, alpha: 1)

	static var safeControlTintColor: NSColor
	{
		if #available(OSX 10.14, *) {
			return .controlAccentColor
		} else {
			return .init(for: NSColor.currentControlTint)
		}
	}

	static func labelColor(for remainingCount: Int) -> NSColor
	{
		if remainingCount > 50
		{
			return .labelColor
		}
		else if remainingCount > 25
		{
			return .systemBlue
		}
		else if remainingCount >= 0
		{
			return .systemOrange
		}
		else
		{
			return .systemRed
		}
	}

	static let timelineBackground = NSColor(named: "TimelinesBackground")!

	var rgbHexString: String?
	{
		guard let rgbColor = usingColorSpace(.deviceRGB) else { return nil }
		return String(format: "#%02X%02X%02X", Int(rgbColor.redComponent * 255),
					  						   Int(rgbColor.greenComponent * 255),
											   Int(rgbColor.blueComponent * 255))
	}
}
