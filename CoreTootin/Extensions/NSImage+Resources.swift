//
//  NSImage+Resources.swift
//  CoreTootin
//
//  Created by Bruno Philipe on 14.09.19.
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

public extension NSImage
{
	enum CoreTootin
	{
		public static var globe: NSImage
		{
			return Bundle(for: Persistence.self).image(forResource: "globe")!
		}
		
		public static var padlock_open: NSImage
		{
			return Bundle(for: Persistence.self).image(forResource: "padlock_open")!
		}
		
		public static var padlock: NSImage
		{
			return Bundle(for: Persistence.self).image(forResource: "padlock")!
		}
		
		public static var envelope: NSImage
		{
			return Bundle(for: Persistence.self).image(forResource: "envelope")!
		}
	}
}
