//
//  NSString+Emoji.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 13.09.19.
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
import CoreTootin

extension NSString
{
	func applyingEmojiAttachments(_ emojis: [CacheableEmoji],
								  staticOnly: Bool = false,
								  font: NSFont? = nil,
								  containerView: NSView? = nil) -> NSAttributedString
	{
		return NSAttributedString(string: self as String).applyingEmojiAttachments(emojis,
																				   staticOnly: staticOnly,
																				   font: font,
																				   containerView: containerView)
	}
}

extension NSAttributedString
{
	func applyingEmojiAttachments(_ emojis: [CacheableEmoji],
								  staticOnly: Bool = false,
								  font overrideFont: NSFont? = nil,
								  containerView: NSView? = nil) -> NSAttributedString
	{
		let mutableString = self.mutableCopy() as! NSMutableAttributedString
		let emojiCache = AppDelegate.shared.customEmojiCache

		for emoji in emojis
		{
			var totalOffset = 0
			let emojiShortcode = ":\(emoji.shortcode):"

			for shortcodeRange in mutableString.string.allRanges(of: emojiShortcode)
			{
				let replacementRange = NSMakeRange(shortcodeRange.location + totalOffset, shortcodeRange.length)
				let shortcodeLineRange = (mutableString.string as NSString).lineRange(for: replacementRange)
				let shortcodeLine = (mutableString.string as NSString).substring(with: shortcodeLineRange)
				let hasMoreChars = shortcodeLine.trimmingCharacters(in: .newlines) != emojiShortcode

				let attachment = StringCapableTextAttachment()
				attachment.stringRepresentation = emojiShortcode

				let font = overrideFont ?? mutableString.attribute(.font,
																   at: replacementRange.location,
																   effectiveRange: nil) as? NSFont

				let emojiURL = staticOnly ? emoji.staticURL : emoji.url
				let emojiLoader: (@escaping (Data?) -> Void) -> Void =
					{
						completion in emojiCache.cachedEmoji(with: emojiURL,
															 fetchIfNeeded: true,
															 completion: completion)
					}

				let attachmentCell: AnimatableEmojiCell

				if staticOnly
				{

					attachmentCell = StaticEmojiCell(emojiLoader: emojiLoader,
													 lineHasMoreCharacters: hasMoreChars,
													 lineHasEmoji: shortcodeLine.hasEmoji,
													 font: font)
				}
				else
				{
					attachmentCell = AnimatableEmojiCell(emojiLoader: emojiLoader,
														 lineHasMoreCharacters: hasMoreChars,
														 lineHasEmoji: shortcodeLine.hasEmoji,
														 font: font)
				}

				attachmentCell.containerView = containerView
				attachmentCell.toolTip = emojiShortcode
				attachment.attachmentCell = attachmentCell

				let attachmentString = NSAttributedString(attachment: attachment)
				mutableString.replaceCharacters(in: replacementRange, with: attachmentString)
				totalOffset += attachmentString.length - shortcodeRange.length
			}
		}

		mutableString.fixAttributes(in: NSMakeRange(0, mutableString.length))

		return mutableString
	}

	func strippingEmojiAttachments(insertJoinersBetweenEmojis addJoiners: Bool) -> String
	{

		let zeroWidthJoiner = Character.zeroWidthJoiner
		let strippedString = mutableCopy() as! NSMutableAttributedString
		var lengthOffset: Int = 0
		var lastAttachmentRange: NSRange = NSMakeRange(NSNotFound, 0)

		enumerateAttachments()
			{
				(attachment, range) in

				guard let stringAttachment = attachment as? StringCapableTextAttachment else
				{
					return
				}

				var shortcode = stringAttachment.stringRepresentation

				if addJoiners,
					lastAttachmentRange.upperBound != NSNotFound,
					lastAttachmentRange.upperBound == range.lowerBound
				{
					shortcode.insert(zeroWidthJoiner, at: shortcode.startIndex)
				}

				strippedString.replaceCharacters(in: NSMakeRange(range.location + lengthOffset, range.length),
												 with: shortcode)

				lengthOffset += (shortcode as NSString).length - range.length

				lastAttachmentRange = range
			}

		return strippedString.string
	}
}
