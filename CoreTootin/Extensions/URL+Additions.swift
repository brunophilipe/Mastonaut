//
//  URL+Additions.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 05.02.19.
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

public extension URL
{
	var fileUTI: String?
	{
		return (try? resourceValues(forKeys: [.typeIdentifierKey]).typeIdentifier) ?? fallbackFileUTI
	}

	/// This routine allows computing the UTI for remote URLs and URLs for files that don't exist.
	private var fallbackFileUTI: String?
	{
		let utiRef = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension as CFString, nil)

		guard let utiCFString = utiRef?.takeUnretainedValue() else
		{
			utiRef?.release()
			return nil
		}

		let utiString = String(utiCFString)
		utiRef?.release()
		return utiString
	}

	var preferredMimeType: String?
	{
		guard
			let fileUTI = self.fileUTI,
			let mimeReference = UTTypeCopyPreferredTagWithClass(fileUTI as CFString, kUTTagClassMIMEType)
		else
		{
			return nil
		}

		let mimeType = String(mimeReference.takeUnretainedValue())
		mimeReference.release()

		return mimeType
	}

	func fileConforms(toUTI: String) -> Bool
	{
		return fileConforms(toUTI: toUTI as CFString)
	}

	func fileConforms(toUTI: CFString) -> Bool
	{
		guard let fileUTI = self.fileUTI else
		{
			return false
		}

		return UTTypeConformsTo(fileUTI as CFString, toUTI)
	}

	var mastodonHandleFromAccountURI: String
	{
		guard let instance = host else
		{
			// Fallback
			return absoluteStringByDroppingScheme
		}

		// Mastodon: instance.domain/@username
		if pathComponents.count == 2, pathComponents[1].hasPrefix("@")
		{
			return "\(pathComponents[1])@\(instance)"
		}

		// Pleroma: instance.domain/users/username
		if pathComponents.count == 3, pathComponents[1] == "users"
		{
			return "@\(pathComponents[2])@\(instance)"
		}

		// Plume: instance.domain/@/username
		if pathComponents.count == 3, pathComponents[1] == "@", !pathComponents[2].hasPrefix("@")
		{
			return "@\(pathComponents[2])@\(instance)"
		}

		// PeerTube: instance.domain/accounts/username
		if pathComponents.count == 3, pathComponents[1] == "accounts"
		{
			return "@\(pathComponents[2])@\(instance)"
		}

		// Write.as: instance.domain/username
		if pathComponents.count == 2
		{
			return "@\(pathComponents[1])@\(instance)"
		}

		// Fallback
		return absoluteStringByDroppingScheme
	}

	var absoluteStringByDroppingScheme: String
	{
		let absoluteString = self.absoluteString

		guard let scheme = scheme else
		{
			return absoluteString
		}

		return absoluteString.substring(afterPrefix: "\(scheme)://")
	}
}
