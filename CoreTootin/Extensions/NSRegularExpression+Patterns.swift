//
//  NSRegularExpression+Patterns.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 07.03.19.
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

public extension NSRegularExpression
{
	/// Adapted from the RFC2396 Regex, with the following changes:
	/// - Only http and https protocols are allowed
	/// - Must be prefixed by either the start of the string, or by a whitespace character
	///
	/// Notice:
	/// - The contents of the first capture group must be reinserted into the original string.
	static let uriRegex = try! NSRegularExpression(pattern: """
(^|\\s)((http|https):)(//([^/?#]*))?([^?#]*)(\\?([^#]*))?(#(.*))?
""", options: [.caseInsensitive])

	/// Adapted from the Mastodon mention Regex, with changes to make it compatible with the POSIX parser
	/// https://github.com/tootsuite/mastodon/blob/ed3011061896dfc4819d517a0f4f4947e56feac4/app/models/account.rb#L52
	///
	/// Notice: The contents of the 3rd capture group is the username without a domain
	static let mentionRegex = try! NSRegularExpression(pattern: """
((?<=^)|(?<=[^\\/\\w]))@(([a-z0-9_]+([a-z0-9_\\.-]+[a-z0-9_]+)?)(?:@[a-z0-9\\.\\-]+[a-z0-9]+)?)
""", options: [.caseInsensitive])

	/// Pattern used to match shortcodes, and place the keyword in the first match group.
	///
	/// - Example: ":blep:" will be matched, and "blep" placed on the first match group.
	static let shortcodeRegex = try! NSRegularExpression(pattern: ":(\\w+):", options: [.caseInsensitive])

	/// Pattern used to match characters joined by a ZWJ character. Mastodon counts any joined chars as a single one,
	/// not only joinable characters (like String.count does).
	///
	/// - Example: ":ZWJ:" will be matched.
	static let zwjGroupRegex = try! NSRegularExpression(pattern: """
.\(Character.zeroWidthJoiner)(.\(Character.zeroWidthJoiner))*.
""", options: [])
}
