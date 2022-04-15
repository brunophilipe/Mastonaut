//
//  NSImage+Additions.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 10.02.19.
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

public extension NSImage
{
	func resizedImage(withSize newSize: NSSize) -> NSImage
	{
		assert(!Thread.isMainThread)

		let resizedImageRepresentation = NSBitmapImageRep(bitmapDataPlanes: nil,
														  pixelsWide: Int(newSize.width),
														  pixelsHigh: Int(newSize.height),
														  bitsPerSample: 8,
														  samplesPerPixel: 4,
														  hasAlpha: true,
														  isPlanar: false,
														  colorSpaceName: .calibratedRGB,
														  bytesPerRow: 0,
														  bitsPerPixel: 0)!

		resizedImageRepresentation.size = newSize

		NSGraphicsContext.saveGraphicsState()
		NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: resizedImageRepresentation)

		draw(in: NSRect(origin: .zero, size: newSize),
			 from: NSRect(origin: .zero, size: size),
			 operation: .copy,
			 fraction: 1.0,
			 respectFlipped: true,
			 hints: [.interpolation : NSNumber(value: NSImageInterpolation.medium.rawValue)])

		NSGraphicsContext.restoreGraphicsState()

		let resizedImage = NSImage(size: newSize)
		resizedImage.addRepresentation(resizedImageRepresentation)
		return resizedImage
	}

	var pixelSize: NSSize
	{
		guard let bitmapRep = largestBitmapImageRep else
		{
			NSLog("pixelSize should not be called on non-bitmap backed images")
			abort()
		}

		return NSSize(width: bitmapRep.pixelsWide, height: bitmapRep.pixelsHigh)
	}

	private var largestBitmapImageRep: NSBitmapImageRep?
	{
		return representations.compactMap({ $0 as? NSBitmapImageRep })
							  .max(by: { ($0.pixelsWide * $0.pixelsHigh) < ($1.pixelsWide * $1.pixelsHigh) })
	}

	private static let utiTypeMap: [CFString: NSBitmapImageRep.FileType] = [
		kUTTypePNG: .png,
		kUTTypeJPEG: .jpeg,
		kUTTypeJPEG2000: .jpeg2000,
		kUTTypeGIF: .gif,
		kUTTypeBMP: .bmp,
		kUTTypeTIFF: .tiff
	]

	func dataUsingRepresentation(for UTI: CFString?) throws -> Data
	{
		guard let rawData = tiffRepresentation, let bitmap = NSBitmapImageRep(data: rawData) else
		{
			throw EncodeErrors.noRawData
		}

		guard let fileType = NSImage.utiTypeMap[UTI ?? kUTTypePNG] else
		{
			throw EncodeErrors.unknownExpectedFormat
		}

		guard let formattedData = bitmap.representation(using: fileType, properties: [:]) else
		{
			throw EncodeErrors.bitmapEncoderReturnedNil
		}

		return formattedData
	}

	enum EncodeErrors: Error
	{
		case noRawData
		case unknownExpectedFormat
		case bitmapEncoderReturnedNil
	}
}
