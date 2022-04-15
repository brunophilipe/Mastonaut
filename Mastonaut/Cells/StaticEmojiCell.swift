//
//  EmojiCell.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 06.05.19.
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

class StaticEmojiCell: AnimatableEmojiCell
{
	private var emojiImageStorage: NSImage? = nil
	private var emojiImage: NSImage?
	{
		if let image = emojiImageStorage
		{
			return image
		}
		else if let data = emojiData, let image = NSImage(data: data)
		{
			emojiImageStorage = image
			return image
		}
		else
		{
			return nil
		}
	}

	internal override func informContainerViewOfUpdatedContent()
	{
		guard let control = containerView as? NSControl else { return }
		let string = control.attributedStringValue
		control.attributedStringValue = string
	}

	override func draw(withFrame cellFrame: NSRect, in controlView: NSView?)
	{
		guard let image = emojiImage else
		{
			return
		}

		let rect: NSRect

		if controlView == nil
		{
			rect = cellFrame
		}
		else
		{
			rect = attachment?.bounds ?? cellFrame
		}

		let spacing = round(rect.height * 0.1)
		var offsetRect = rect
		offsetRect.size.width -= spacing
		offsetRect.origin.y = cellFrame.origin.y

		image.draw(in: offsetRect)
	}
}
