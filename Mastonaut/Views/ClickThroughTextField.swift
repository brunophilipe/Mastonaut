//
//  ClickThroughTextField.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 12.02.19.
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

class ClickThroughTextField: NSTextField
{
	@IBOutlet weak var clickTarget: NSResponder? = nil

	override func mouseUp(with event: NSEvent)
	{
		super.mouseUp(with: event)

		if let window = self.window, let clickTarget = self.clickTarget
		{
			window.makeFirstResponder(clickTarget)
		}
	}
}
