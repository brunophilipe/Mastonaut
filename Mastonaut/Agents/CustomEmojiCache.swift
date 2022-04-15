//
//  CustomEmojiCache.swift
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

import AppKit
import MastodonKit
import SVGKit
import CoreTootin

class CustomEmojiCache: NSObject, Cache
{
	private typealias EmojiReferenceDatabase = [String: [String: EmojiReference]]

	private lazy var resourcesFetcher: ResourcesFetcher =
		{
			let configuration = URLSessionConfiguration.forResources.copy() as! URLSessionConfiguration
			#if MOCK
			configuration.timeoutIntervalForRequest = 1
			#else
			configuration.timeoutIntervalForRequest = 10
			#endif
			return ResourcesFetcher(urlSession: URLSession(configuration: configuration))
		}()

	private let diskAccessQueue: OperationQueue = {
		let queue = OperationQueue()
		queue.maxConcurrentOperationCount = 5
		queue.qualityOfService = .background
		queue.isSuspended = false
		return queue
	}()

	private var cacheLocation: URL?
	private var shortcodeDatabase: EmojiReferenceDatabase = [:]

	weak var delegate: Delegate?

	var isLoaded: Bool {
		return cacheLocation != nil
	}

	private let inMemoryCache = NSCache<NSString, EmojiImageCacheStateClassAdapter>()

	init(delegate: Delegate? = nil)
	{
		self.delegate = delegate

		super.init()

		loadFromDiskStorage()
	}

	func prepareForTermination()
	{
		CustomEmojiCache.cancelPreviousPerformRequests(withTarget: self)
		writeEmojiReferenceDatabase()

		diskAccessQueue.waitUntilAllOperationsAreFinished()
	}

	deinit
	{
		CustomEmojiCache.cancelPreviousPerformRequests(withTarget: self)
	}

	// MARK: Reading from Cache

	func cachedEmoji(with url: URL, fetchIfNeeded: Bool, completion: @escaping (Data?) -> Void)
	{
		diskAccessQueue.addOperation
			{
				[weak self] in

				guard let self = self, let fileUrl = self.cacheFileUrl(for: url) else
				{
					completion(nil)
					return
				}

				let key = keyForURL(url)
				if let state = self.inMemoryCache.object(forKey: key as NSString)?.state
				{
					switch state {
					case .missing where !fetchIfNeeded:
						completion(nil)
						return
					case .present(let imageData):
						completion(imageData)
						return
					case .missing:
						break
					}
				}

				let imageData: Data

				if let data = try? Data(contentsOf: fileUrl)
				{
					imageData = data
				}
				else if fetchIfNeeded, let data = self.scheduleEmojiFetch(url: url, cacheFileKey: key)
				{
					imageData = data
				}
				else
				{
					self.inMemoryCache.setObject(EmojiImageCacheStateClassAdapter(.missing), forKey: key as NSString)
					completion(nil)
					return
				}

				self.inMemoryCache.setObject(EmojiImageCacheStateClassAdapter(.present(imageData)),
											 forKey: key as NSString)

				completion(imageData)
			}
	}

	func cachedEmoji(forInstance instance: String) -> [CacheableEmoji]
	{
		guard let references = shortcodeDatabase[instance] else
		{
			return []
		}

		return references.map()
			{
				(arg) -> CacheableEmoji in
				let (key, emojiReference) = arg

				let emoji = Emoji(shortcode: key,
								  staticURL: emojiReference.staticUrl,
								  url: emojiReference.fullUrl,
								  visibleInPicker: emojiReference.visibleInPicker)

				return CacheableEmoji(emoji, instance: instance)
			}
	}

	// MARK: Writing to Cache

	func cacheEmojis(for emojiContainers: [EmojiProvider], completion: @escaping ([URL: Data]) -> Void)
	{
		cacheEmojis(emojiContainers.flatMap({ $0.cacheableEmojis }), completion: completion)
	}

	func cacheEmojis(_ cacheableEmojis: [CacheableEmoji], completion: @escaping ([URL: Data]) -> Void)
	{
		diskAccessQueue.addOperation {
			var didWriteToEmojiDatabase = false
			var completionData: [URL: Data] = [:]

			for emoji in cacheableEmojis
			{
				let cacheKeyStatic = keyForURL(emoji.staticURL)
				let cacheKeyFull = keyForURL(emoji.url)

				var emojiForInstance = self.shortcodeDatabase[emoji.instance] ?? [:]

				if emojiForInstance[emoji.shortcode] == nil
				{
					emojiForInstance[emoji.shortcode] = EmojiReference(emoji: emoji)
					self.shortcodeDatabase[emoji.instance] = emojiForInstance
					didWriteToEmojiDatabase = true
				}

				let staticState = self.inMemoryCache.object(forKey: cacheKeyStatic as NSString)?.state ?? .missing
				if case EmojiImageCacheState.missing = staticState
				{
					let data = self.scheduleEmojiFetch(url: emoji.staticURL, cacheFileKey: cacheKeyStatic)
					data.map { completionData[emoji.staticURL] = $0 }
				}

				let fullState = self.inMemoryCache.object(forKey: cacheKeyFull as NSString)?.state ?? .missing
				if case EmojiImageCacheState.missing = fullState
				{
					let data = self.scheduleEmojiFetch(url: emoji.url, cacheFileKey: cacheKeyFull)
					data.map { completionData[emoji.url] = $0 }
				}
			}

			if didWriteToEmojiDatabase
			{
				self.scheduleWritingEmojiReferenceDatabase()
			}

			DispatchQueue.global(qos: .utility).async { completion(completionData) }
		}
	}

	// MARK: - Private stuff

	private func loadFromDiskStorage()
	{
		guard !isLoaded else { return }

		diskAccessQueue.addOperation
			{
				let fileManager = FileManager.default

				let cachesDirectoryURL = try! fileManager.url(for: .cachesDirectory,
															  in: .userDomainMask,
															  appropriateFor: nil,
															  create: true)
				let cacheLocation = cachesDirectoryURL.appendingPathComponent("Mastonaut/Emoji", isDirectory: true)
				try? fileManager.createDirectory(at: cacheLocation, withIntermediateDirectories: true, attributes: [:])

				for previousReferenceFile in self.previousReferenceFileURLs(baseURL: cacheLocation)
				{
					if fileManager.fileExists(atPath: previousReferenceFile.path)
					{
						try? fileManager.removeItem(at: previousReferenceFile)
					}
				}

				let referenceFileURL = self.currentReferenceFileURL(baseURL: cacheLocation)
				if let shortcodeDatabaseData = try? Data(contentsOf: referenceFileURL),
					let database = try? PropertyListDecoder().decode(EmojiReferenceDatabase.self, from: shortcodeDatabaseData)
				{
					self.shortcodeDatabase = database
				}

				self.cacheLocation = cacheLocation
				self.delegate?.cacheDidFinishLoadingFromDisk(self)
			}
	}

	private func currentReferenceFileURL(baseURL: URL) -> URL
	{
		return baseURL.appendingPathComponent("reference-v2.bin", isDirectory: false)
	}

	private func previousReferenceFileURLs(baseURL: URL) -> [URL]
	{
		return [baseURL.appendingPathComponent("reference.bin", isDirectory: false)]
	}

	private func scheduleWritingEmojiReferenceDatabase()
	{
		let writeSelector = #selector(writeEmojiReferenceDatabase)

		CustomEmojiCache.cancelPreviousPerformRequests(withTarget: self, selector: writeSelector, object: nil)
		perform(writeSelector, with: nil, afterDelay: 5.0)
	}

	@objc private func writeEmojiReferenceDatabase()
	{
		// self is captured strongly here deliberately to prevent the object from going
		// away while a write is happening.
		diskAccessQueue.addOperation
			{
				[cacheLocation, shortcodeDatabase] in

				guard let cacheLocation = cacheLocation else { return }

				let encoder = PropertyListEncoder()
				encoder.outputFormat = .binary
				if let databaseData = try? encoder.encode(shortcodeDatabase)
				{
					try? databaseData.write(to: self.currentReferenceFileURL(baseURL: cacheLocation))
				}

				self.delegate?.cacheDidFinishWritingToDisk(self)
			}
	}

	private func scheduleEmojiFetch(url: URL, cacheFileKey: String) -> Data?
	{
		let resourcesFetcher = self.resourcesFetcher

		do
		{
			guard let cacheFileURL = self.cacheFileUrl(for: cacheFileKey) else
			{
				assertionFailure()
				return nil
			}

			guard case .success(let data) = resourcesFetcher.fetchDataSynchronously(from: url) else
			{
				self.inMemoryCache.setObject(EmojiImageCacheStateClassAdapter(.missing),
											 forKey: cacheFileKey as NSString)
				return nil
			}

			try data.write(to: cacheFileURL)

			return data
		}
		catch
		{
			self.inMemoryCache.setObject(EmojiImageCacheStateClassAdapter(.missing),
										 forKey: cacheFileKey as NSString)
			NSLog("Error fetching emoji: \(error)")

			return nil
		}
	}

	private func cacheFileUrl(for key: String) -> URL?
	{
		return cacheLocation?.appendingPathComponent(key, isDirectory: false)
	}

	private func cacheFileUrl(for url: URL) -> URL?
	{
		return cacheFileUrl(for: keyForURL(url))
	}

	// MARK: - Types

	private enum EmojiImageCacheState
	{
		case missing
		case present(Data)
	}

	private final class EmojiImageCacheStateClassAdapter
	{
		let state: EmojiImageCacheState

		init(_ state: EmojiImageCacheState)
		{
			self.state = state
		}
	}

	private struct EmojiReference: Codable
	{
		let staticUrl: URL
		let fullUrl: URL
		let visibleInPicker: Bool

		init(emoji: CacheableEmoji)
		{
			staticUrl = emoji.staticURL
			fullUrl = emoji.url
			visibleInPicker = emoji.visibleInPicker
		}
	}
}

private extension String
{
	static let shortcodeRegex = try! NSRegularExpression(pattern: "(?<=:)\\w+(?=:)", options: [.caseInsensitive])

	var emojiShortcodes: [String]
	{
		let string = self as NSString
		var shortcodes = [String]()

		String.shortcodeRegex.enumerateMatches(in: self, options: [], range: string.range)
		{
			(result, _, _) in

			if let range = result?.range
			{
				shortcodes.append(string.substring(with: range))
			}
		}

		return shortcodes
	}
}

protocol EmojiProvider
{
	var cacheableEmojis: [CacheableEmoji] { get }
}

struct CacheableEmoji: Hashable
{
	private let emoji: Emoji
	let instance: String

	var shortcode: String { return emoji.shortcode }
	var staticURL: URL { return emoji.staticURL }
	var url: URL { return emoji.url }
	var visibleInPicker: Bool { return emoji.visibleInPicker ?? true }

	init(_ emoji: Emoji, instance: String)
	{
		self.emoji = emoji
		self.instance = instance
	}

	func hash(into hasher: inout Hasher)
	{
		hasher.combine(emoji.shortcode)
	}
}

extension Status: EmojiProvider
{
	var cacheableEmojis: [CacheableEmoji]
	{
		var allEmoji = (emojis + account.emojis).cacheable(instance: account.url.host!)

		if let reblog = self.reblog
		{
			allEmoji.append(contentsOf: reblog.cacheableEmojis)
		}

		return allEmoji
	}
}

extension MastodonNotification: EmojiProvider
{
	var cacheableEmojis: [CacheableEmoji]
	{
		var allEmoji = account.cacheableEmojis

		if let status = self.status
		{
			allEmoji.append(contentsOf: status.cacheableEmojis)
		}

		return allEmoji
	}
}

extension Account: EmojiProvider
{
	var cacheableEmojis: [CacheableEmoji]
	{
		return emojis.cacheable(instance: url.host!)
	}
}

extension Array where Element == Emoji
{
	func cacheable(instance: String) -> [CacheableEmoji]
	{
		return map { CacheableEmoji($0, instance: instance) }
	}
}

private func keyForURL(_ url: URL) -> String
{
	return url.path.sha256Hash()
}
