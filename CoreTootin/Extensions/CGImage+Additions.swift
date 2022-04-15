//
//  CGImage+Additions.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 28.04.19.
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
import Accelerate

public extension CGImage
{
	var size: NSSize
	{
		return NSSize(width: width, height: height)
	}

	func resizedImage(newHeight: CGFloat, scale: CGFloat = 1.0) -> CGImage?
	{
		let newWidth = (newHeight/CGFloat(height)) * CGFloat(width)
		return resizedImage(newSize: CGSize(width: newWidth, height: newHeight), scale: scale)
	}

	func resizedImage(newSize: CGSize, scale: CGFloat = 1.0) -> CGImage?
	{
		var format = vImage_CGImageFormat(bitsPerComponent: 8,
										  bitsPerPixel: 32,
										  colorSpace: nil,
										  bitmapInfo: bitmapInfo,
										  version: 0, decode: nil, renderingIntent: .defaultIntent)

		var sourceBuffer = vImage_Buffer()
		defer
		{
			sourceBuffer.data.deallocate()
		}

		var error: Int = kvImageNoError
		error = vImageBuffer_InitWithCGImage(&sourceBuffer, &format, nil, self, numericCast(kvImageNoFlags))
		guard error == kvImageNoError else
		{
			return nil
		}

		let newWidth = Int(round(newSize.width) * scale)
		let newHeight = Int(round(newSize.height) * scale)
		let bytesPerPixel = bitsPerPixel / 8
		let destBytesPerRow = newWidth * bytesPerPixel
		let destData = UnsafeMutablePointer<UInt8>.allocate(capacity: newHeight * destBytesPerRow)
		defer
		{
			destData.deallocate()
		}

		var destBuffer = vImage_Buffer(data: destData,
									   height: vImagePixelCount(newHeight),
									   width: vImagePixelCount(newWidth),
									   rowBytes: destBytesPerRow)

		if colorSpace?.model == .rgb
		{
			guard vImageScale_ARGB8888(&sourceBuffer, &destBuffer, nil, numericCast(kvImageNoFlags)) == kvImageNoError
			else { return nil }
		}
		else
		{
			guard vImageScale_Planar8(&sourceBuffer, &destBuffer, nil, numericCast(kvImageNoFlags)) == kvImageNoError
			else { return nil }
		}

		error = kvImageNoError
		let resizedImageReference = vImageCreateCGImageFromBuffer(&destBuffer, &format, nil,
																  nil, numericCast(kvImageNoFlags), &error)

		guard error == kvImageNoError, let resizedImage = resizedImageReference?.takeRetainedValue() else
		{
			return nil
		}

		return resizedImage
	}
}
