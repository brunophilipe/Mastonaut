//
//  FileMetadataGenerator.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 14.03.19.
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
import QuickLook
import AVFoundation

public struct FileMetadataGenerator
{
	public static func thumbnail(for fileUrl: URL, maxSize: CGSize) -> NSImage
	{
		assert(!Thread.isMainThread)

		let options: [CFString: Any] = [
			kQLThumbnailOptionIconModeKey: kCFBooleanFalse!,
			kQLThumbnailOptionScaleFactorKey: 1.0 as CFNumber
		]

		guard let thumbnail = QLThumbnailImageCreate(nil, fileUrl as CFURL, maxSize, options as CFDictionary) else
		{
			return NSWorkspace.shared.icon(forFile: fileUrl.path)
		}

		let cgImage = thumbnail.takeUnretainedValue()
		let image = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))

		thumbnail.release()

		return image
	}

	public static func metadata(for fileUrl: URL) -> Metadata
	{
		assert(!Thread.isMainThread)

		if fileUrl.fileConforms(toUTI: kUTTypeMovie)
		{
			let duration = AVURLAsset(url: fileUrl).duration.seconds
			return .movie(duration: duration)
		}
		else if fileUrl.fileConforms(toUTI: kUTTypeImage)
		{
			guard
				let imageSource = CGImageSourceCreateWithURL(fileUrl as CFURL, nil),
				let propertiesDict = CGImageSourceCopyProperties(imageSource, nil) as? [CFString: Any],
				let fileSize = propertiesDict[kCGImagePropertyFileSize] as? Int64
			else
			{
				return .picture(byteCount: 0)
			}

			return .picture(byteCount: fileSize)
		}
		else
		{
			return .unknown
		}
	}
}

public enum Metadata
{
	case picture(byteCount: Int64)
	case movie(duration: TimeInterval)
	case unknown
}
