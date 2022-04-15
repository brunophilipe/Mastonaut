//
//  ImageRestrainer.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 15.03.19.
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

public class ImageRestrainer {
	let typeConversionMap: [CFString: CFString]
	let maximumImageSize: NSSize

	init(typeConversionMap: [CFString: CFString], maximumImageSize: NSSize) {
		self.typeConversionMap = typeConversionMap
		self.maximumImageSize = maximumImageSize
	}

	func restrain(imageAtURL fileURL: URL, fileUTI: CFString) throws -> Data {
		let restrainedFileUTI = restrain(type: fileUTI)

		func fallbackData() throws -> Data {
			let image = NSImage(byReferencing: fileURL)
			return try restrain(staticImage: image).dataUsingRepresentation(for: restrainedFileUTI)
		}

		// Check if this is an animation. If not, just use the static image restrainer.
		guard
			let imageSource = CGImageSourceCreateWithURL(fileURL as CFURL, nil),
			CGImageSourceGetCount(imageSource) > 1,
			let originalSize = CGImageSourceCreateImageAtIndex(imageSource, 0, nil)?.size
		else {
			return try fallbackData()
		}

		let originalData = try Data(contentsOf: fileURL, options: .alwaysMapped)
		let frameCount = CGImageSourceGetCount(imageSource)

		// Check if animated image needs to be resized or converted
		guard originalSize.area >= maximumImageSize.area || restrainedFileUTI != fileUTI,
			  let destinationData = CFDataCreateMutable(kCFAllocatorDefault, originalData.count),
			  let imageDestination = CGImageDestinationCreateWithData(destinationData,
																	  restrainedFileUTI,
																	  frameCount, nil)
		else {
			return originalData
		}

		let newSize = originalSize.fitting(on: maximumImageSize)

		for frameIndex in 0..<frameCount {
			guard
				let originalFrame = CGImageSourceCreateImageAtIndex(imageSource, frameIndex, nil),
				let resizedFrame = originalFrame.resizedImage(newSize: newSize)
			else {
				continue
			}

			CGImageDestinationAddImage(imageDestination, resizedFrame, nil)
		}

		CGImageDestinationFinalize(imageDestination)

		return destinationData as Data
	}

	func restrain(staticImage: NSImage) -> NSImage {
		guard staticImage.isValid, let representation = staticImage.representations.first else
		{
			return staticImage
		}

		let originalSize = NSSize(width: representation.pixelsWide, height: representation.pixelsHigh)

		guard originalSize.area >= maximumImageSize.area else { return staticImage }

		let newSize = originalSize.fitting(on: maximumImageSize)

		return staticImage.resizedImage(withSize: newSize)
	}

	func restrain(type: CFString) -> CFString {
		return typeConversionMap[type] ?? type
	}
}
