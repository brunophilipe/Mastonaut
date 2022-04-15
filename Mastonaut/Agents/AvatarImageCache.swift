//
//  AvatarImageCache.swift
//  Mastonaut
//
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
import MastodonKit
import CoreTootin

enum AvatarImageCacheResult {
	case inCache(NSImage)
	case loaded(NSImage)
	case noImage(Error)
}

enum AvatarImageCacheError: Error {
	case emptyResponse
}

final class AvatarImageCache
{
	private let resourcesFetcher: ResourcesFetcher
	private let cache = NSCache<NSString, NSImage>()

	init(resourceURLSession: URLSession)
	{
		resourcesFetcher = ResourcesFetcher(urlSession: resourceURLSession)
	}

	/// To be used from UI on the main thread.
	/// Invoking the completion handler immediately when an image is already
	/// in the cache and not ping ponging between queues saves us layout passes during scrolling.
	func fetchImage(account: Account, completionHandler: @escaping (AvatarImageCacheResult) -> ())
	{
		guard let imageURL = account.avatarURL else {
			completionHandler(.noImage(AvatarImageCacheError.emptyResponse))
			return
		}
		fetchImage(key: imageURL.absoluteString, url: imageURL, completionHandler: completionHandler)
	}

	/// To be used from UI on the main thread.
	/// Invoking the completion handler immediately when an image is already
	/// in the cache and not ping ponging between queues saves us layout passes during scrolling.
	func fetchImage(account: AuthorizedAccount, completionHandler: @escaping (AvatarImageCacheResult) -> ())
	{
		guard let imageURL = account.avatarURL else {
			completionHandler(.noImage(AvatarImageCacheError.emptyResponse))
			return
		}
		fetchImage(key: imageURL.absoluteString,
				   url: imageURL,
				   completionHandler: completionHandler)
	}

	/// Removes the cached image for the given account, if any.
	func resetCachedImage(account: Account)
	{
		if let imageURL = account.avatarURL {
			removeCachedImage(key: imageURL.absoluteString)
		}
	}

	/// Removes the cached image for the given account, if any.
	func resetCachedImage(account: AuthorizedAccount)
	{
		if let imageURL = account.avatarURL {
			removeCachedImage(key: imageURL.absoluteString)
		}
	}

	private func removeCachedImage(key: String)
	{
		assert(Thread.isMainThread)
		cache.removeObject(forKey: key as NSString)
	}

	private func fetchImage(key: String, url: URL, completionHandler: @escaping (AvatarImageCacheResult) -> ())
	{
		assert(Thread.isMainThread)

		let key = key as NSString

		if let image = cache.object(forKey: key) {
			completionHandler(.inCache(image))
			return
		}

		resourcesFetcher.fetchImage(with: url) { result in
			switch result {
			case .success(let image):
				assert(!Thread.isMainThread)

				// The largest avatar image view in this app is 100 x 100 points, so we don't
				// images larger than 200 x 200 pixels (where as Mastodon supports images up to
				// 400 x 400 px).

				let maxAvatarImageViewSide = 100
				let maxAvatarImageViewSideInPixels = maxAvatarImageViewSide * 2
				let maxSizeInPixels = NSSize(width: maxAvatarImageViewSideInPixels, height: maxAvatarImageViewSideInPixels)
				let actualMaxSizeInPixels = image.pixelSize.fitting(on: maxSizeInPixels)
				let scaledImage = image.resizedImage(withSize: actualMaxSizeInPixels)
				completionHandler(.loaded(scaledImage))

				DispatchQueue.main.async { [weak self] in
					// The cache is deliberately used from the main queue (see above).
					self?.cache.setObject(scaledImage, forKey: key)
				}
			case .failure(let error):
				completionHandler(.noImage(error))
			case .emptyResponse:
				completionHandler(.noImage(AvatarImageCacheError.emptyResponse))
			}
		}
	}
}
