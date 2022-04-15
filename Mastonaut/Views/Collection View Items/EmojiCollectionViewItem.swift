//
//  EmojiCollectionViewItem.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 29.05.19.
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
import MastodonKit

class EmojiCollectionViewItem: NSCollectionViewItem
{
	@IBOutlet private weak var backgroundBox: NSBox!
	@IBOutlet private weak var animatedImageView: AnimatedImageView!

	var displayedItemHashValue: Int = 0

	var animates: Bool
	{
		get { return animatedImageView?.animates ?? false }
		set { animatedImageView?.animates = newValue }
	}

	override var isSelected: Bool
	{
		didSet { backgroundBox.isHidden = !isSelected }
	}

	func setEmojiTooltip(from emoji: CacheableEmoji)
	{
		view.toolTip = ":\(emoji.shortcode):"
	}

	func setEmojiImage(from data: Data)
	{
		if let imageView = animatedImageView
		{
			imageView.animates = true
			imageView.setAnimatedImage(from: data)
		}

		imageView?.alphaValue = 1.0
	}

	override func prepareForReuse()
	{
		super.prepareForReuse()

		imageView?.alphaValue = 0.0
		animatedImageView?.clearAnimatedImage()
	}
}
