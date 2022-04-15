//
//  String+Additions.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 18.01.19.
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
import CommonCrypto

public extension String
{
	func sha256Hash() -> String
	{
		let data = Data(utf8)
		var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))

		data.withUnsafeBytes({ _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &digest) })

		return digest.map({ String(format: "%02hhx", $0) }).joined(separator: "")
	}

	func substring(afterPrefix prefix: String) -> String
	{
		if let nextIndex = zip(self, prefix).reduce(startIndex, { (index, chars) -> Index? in
			return (chars.0 == chars.1 && index != nil) ? self.index(after: index!) : nil
		})
		{
			return String(self[nextIndex...])
		}
		else
		{
			return self
		}
	}

	var hasEmoji: Bool
	{
		for character in self
		{
			if character.isEmoji
			{
				return true
			}
		}

		return false
	}

	func ellipsedPrefix(maxLength: Int) -> String
	{
		if count <= maxLength
		{
			return self
		}
		else
		{
			return prefix(maxLength) + "…"
		}
	}

	static var zeroWidthJoiner = "\(Character.zeroWidthJoiner)"

	func matches(regex pattern: String, options: NSRegularExpression.Options = []) -> Bool {
		guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else {
			return false
		}

		return regex.firstMatch(in: self, options: [], range: NSMakeRange(0, (self as NSString).length)) != nil
	}
}

public extension Character
{
	var isEmoji: Bool
	{
		return unicodeScalars.reduce(true, { $0 && $1.properties.isEmoji && $1.properties.isEmojiPresentation })
	}

	static var zeroWidthJoiner = Character("\u{200D}")
}
