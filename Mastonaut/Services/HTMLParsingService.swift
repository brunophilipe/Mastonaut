//
//  HTMLParsingService.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 04.07.19.
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

class HTMLParsingService {
	static let shared = HTMLParsingService()

	private let cache: NSCache<CacheReference, NSAttributedString> = {
		let cache = NSCache<CacheReference, NSAttributedString>()
		cache.countLimit = 512
		return cache
	}()

	func parse(HTML htmlString: String,
			   removingTrailingUrl url: URL? = nil,
			   removingInvisibleSpans removeInvisibles: Bool = true) -> NSAttributedString {
		let cacheReference = CacheReference(htmlString: htmlString,
											removedTrailingURL: url,
											removedInvisibleSpans: removeInvisibles)

		if let cachedParsedString = cache.object(forKey: cacheReference) {
			return cachedParsedString
		}

		let parsedString = NSAttributedString(simpleHTML: htmlString,
											  removingTrailingUrl: url,
											  removingInvisibleSpans: removeInvisibles)

		cache.setObject(parsedString, forKey: cacheReference, cost: htmlString.count)

		return parsedString
	}
}

private class CacheReference: NSObject {
	let htmlString: String
	let removedTrailingURL: URL?
	let removedInvisibleSpans: Bool

	init(htmlString: String, removedTrailingURL: URL?, removedInvisibleSpans: Bool) {
		self.htmlString = htmlString
		self.removedTrailingURL = removedTrailingURL
		self.removedInvisibleSpans = removedInvisibleSpans
		super.init()
	}

	override var hash: Int {
		var hasher = Hasher()
		hasher.combine(htmlString)
		removedTrailingURL.map { hasher.combine($0) }
		hasher.combine(removedInvisibleSpans ? "1" : "0")
		return hasher.finalize()
	}

	override func isEqual(_ object: Any?) -> Bool {
		guard let other = object as? CacheReference else { return false }

		return htmlString == other.htmlString
				&& removedTrailingURL == other.removedTrailingURL
				&& removedInvisibleSpans == other.removedInvisibleSpans
	}
}
