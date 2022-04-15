//
//  NonVibrantPopUpButton.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 29.09.19.
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

import Foundation

class NonVibrantPopUpButton: NSPopUpButton
{
	override var allowsVibrancy: Bool
	{
		return false
	}

	override var effectiveAppearance: NSAppearance
	{
		let defaultAppearance = super.effectiveAppearance

		if #available(OSX 10.14, *), defaultAppearance.name == NSAppearance.Name.vibrantDark {
			return NSAppearance(named: .darkAqua)!
		} else {
			return defaultAppearance
		}
	}
}
