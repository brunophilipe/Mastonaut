//
//  AttributedStringCapable.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 27.01.19.
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
import MastodonKit

protocol AttributedStringCapable: NSView
{
	var attributedStringValue: NSAttributedString { get set }
	var toolTip: String? { get set }

	func setAccessibilityLabel(_: String?)
}

extension NSTextField: AttributedStringCapable {}

extension NSButton: AttributedStringCapable
{
	open override var attributedStringValue: NSAttributedString
	{
		get
		{
			return attributedTitle
		}

		set
		{
			attributedTitle = newValue
		}
	}
}

extension AttributedStringCapable
{
	func set(stringValue string: String,
			 applyingAttributes attributes: [NSAttributedString.Key: AnyObject],
			 applyingEmojis emojis: [CacheableEmoji],
			 tooltipSuffix: String? = nil,
			 staticOnly: Bool = false)
	{
		set(attributedStringValue: NSAttributedString(string: string),
			applyingAttributes: attributes,
			applyingEmojis: emojis,
			tooltipSuffix: tooltipSuffix,
			staticOnly: staticOnly)
	}

	func set(attributedStringValue string: NSAttributedString,
			 applyingAttributes attributes: [NSAttributedString.Key: AnyObject],
			 applyingEmojis emojis: [CacheableEmoji]? = nil,
			 tooltipSuffix: String? = nil,
			 staticOnly: Bool = false)
	{
		let attributedString = string.applyingAttributes(attributes)
		let attributedStringWithEmoji = emojis.map({
			attributedString.applyingEmojiAttachments($0, staticOnly: staticOnly, containerView: self)
		}) ?? attributedString

		attributedStringValue = attributedStringWithEmoji
		installEmojiSubviews(using: attributedStringWithEmoji)

		if attributedStringWithEmoji.length != attributedString.length, staticOnly
		{
			let plainString = attributedString.string
			setAccessibilityLabel(plainString)

			if let suffix = tooltipSuffix
			{
				toolTip = "\(plainString) \(suffix)"
			}
			else
			{
				toolTip = plainString
			}
		}
		else if let suffix = tooltipSuffix
		{
			toolTip = "\(attributedString.string) \(suffix)"
		}
		else
		{
			toolTip = nil
		}
	}
}
