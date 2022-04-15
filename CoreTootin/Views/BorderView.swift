//
//  BorderView.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 30.01.19.
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

@IBDesignable
open class BorderView: BackgroundView
{
	@IBInspectable
	public var borderWidth: CGFloat = 0
	{
		didSet
		{
			needsDisplay = true
		}
	}

	@IBInspectable
	public var borderColor: NSColor = .clear
	{
		didSet
		{
			needsDisplay = true
		}
	}

	@IBInspectable
	public var borderRadius: CGFloat = 0
	{
		didSet
		{
			needsDisplay = true
		}
	}

	public override func updateLayer()
	{
		super.updateLayer()

		layer?.cornerRadius = borderRadius
		layer?.borderWidth = borderWidth
		layer?.borderColor = borderColor.cgColor
		layer?.masksToBounds = true
	}
}
