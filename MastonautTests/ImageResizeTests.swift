//
//  ImageResizeTests.swift
//  MastonautTests
//
//  Created by Bruno Philipe on 22.05.19.
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

import XCTest
@testable import Mastonaut

class ImageResizeTests: XCTestCase
{
	func testResizeGrayscaleImage()
	{
		let imageUrl = Bundle.init(for: ImageResizeTests.self).urlForImageResource("grayscale")!
		let imageSource = CGImageSourceCreateWithURL(imageUrl as CFURL, nil)!
		let image = CGImageSourceCreateImageAtIndex(imageSource, 0, nil)!

		XCTAssertNotNil(image.resizedImage(newSize: CGSize(width: 30, height: 30), scale: 2.0))
		XCTAssertNotNil(image.resizedImage(newSize: CGSize(width: 10, height: 10), scale: 1.0))
		XCTAssertNotNil(image.resizedImage(newSize: CGSize(width: 36, height: 36), scale: 2.0))
		XCTAssertNotNil(image.resizedImage(newSize: CGSize(width: 100, height: 100), scale: 1.0))
		XCTAssertNotNil(image.resizedImage(newSize: CGSize(width: 25, height: 25), scale: 2.0))
	}

	func testResizeSRGBImage()
	{
		let imageUrl = Bundle.init(for: ImageResizeTests.self).urlForImageResource("sRGB")!
		let imageSource = CGImageSourceCreateWithURL(imageUrl as CFURL, nil)!
		let image = CGImageSourceCreateImageAtIndex(imageSource, 0, nil)!

		XCTAssertNotNil(image.resizedImage(newSize: CGSize(width: 10, height: 10), scale: 1.0))
		XCTAssertNotNil(image.resizedImage(newSize: CGSize(width: 100, height: 100), scale: 1.0))
		XCTAssertNotNil(image.resizedImage(newSize: CGSize(width: 25, height: 25), scale: 2.0))
	}

	func testResizeARGBImage()
	{
		let imageUrl = Bundle.init(for: ImageResizeTests.self).urlForImageResource("aRGB")!
		let imageSource = CGImageSourceCreateWithURL(imageUrl as CFURL, nil)!
		let image = CGImageSourceCreateImageAtIndex(imageSource, 0, nil)!

		XCTAssertNotNil(image.resizedImage(newSize: CGSize(width: 10, height: 10), scale: 1.0))
		XCTAssertNotNil(image.resizedImage(newSize: CGSize(width: 100, height: 100), scale: 1.0))
		XCTAssertNotNil(image.resizedImage(newSize: CGSize(width: 25, height: 25), scale: 2.0))
	}
}
