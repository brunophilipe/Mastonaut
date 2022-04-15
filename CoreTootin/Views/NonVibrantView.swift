//
//  NonVibrantView.swift
//  CoreTootin
//
//  Created by Bruno Philipe on 20.09.19.
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

public class NonVibrantView: NSView {

	public override var allowsVibrancy: Bool
	{
		return false
	}

	public override var effectiveAppearance: NSAppearance
	{
		let appearance = super.effectiveAppearance

		if #available(OSXApplicationExtension 10.14, *), appearance.name == .vibrantDark
		{
			return NSAppearance(named: .darkAqua)!
		}
		else if appearance.name == .vibrantLight
		{
			return NSAppearance(named: .aqua)!
		}
		else
		{
			return appearance
		}
	}
}
