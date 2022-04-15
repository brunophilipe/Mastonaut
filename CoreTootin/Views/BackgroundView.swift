//
//  BackgroundView.swift
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

import Cocoa

@IBDesignable
open class BackgroundView: NSView
{
	@IBInspectable
	public var drawsBackground: Bool = true
	{ didSet { needsDisplay = true } }

	@IBInspectable
	public var backgroundColor: NSColor = .clear
	{ didSet { needsDisplay = true } }

	public override var wantsUpdateLayer: Bool
	{
		return true
	}

	public override func updateLayer()
	{
		super.updateLayer()

		guard drawsBackground else {
			layer?.backgroundColor = .clear
			return
		}

		layer?.backgroundColor = backgroundColor.cgColor
	}
}
