//
//  Upload.swift
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

import Foundation
import MastodonKit

public class Upload
{
	public static let maxThumbnailSize = CGSize(width: 300, height: 300)

	private let thumbnailProvider: () -> NSImage
	private let dataLoader: () throws -> Data
	private let metadataProvider: () -> Metadata
	private let hashProvider: (inout Hasher) -> Void

	private var cachedData: Data? = nil

	private lazy var thumbnail: NSImage = thumbnailProvider()
	private lazy var metadata: Metadata = metadataProvider()

	public private(set) var fileExtension: String
	public private(set) var fileName: String?
	public private(set) var mimeType: String
	public private(set) var attachment: Attachment? = nil

	public var needsUploading: Bool { return attachment == nil }

	public init?(fileUrl: URL, imageRestrainer: ImageRestrainer)
	{
		guard let preferredMimeType = fileUrl.preferredMimeType, let fileUTI = fileUrl.fileUTI else { return nil }

		if UTTypeConformsTo(fileUTI as CFString, kUTTypeImage)
		{
			let restrainedType = imageRestrainer.restrain(type: fileUTI as CFString)
			dataLoader = { try imageRestrainer.restrain(imageAtURL: fileUrl, fileUTI: restrainedType) }
			mimeType = restrainedType as String
		}
		else
		{
			dataLoader = { try Data(contentsOf: fileUrl, options: .alwaysMapped) }
			mimeType = preferredMimeType
		}

		hashProvider = { $0.combine(fileUrl) }
		fileExtension = fileUrl.pathExtension
		fileName = fileUrl.lastPathComponent
		thumbnailProvider = { FileMetadataGenerator.thumbnail(for: fileUrl, maxSize: Upload.maxThumbnailSize) }
		metadataProvider = { FileMetadataGenerator.metadata(for: fileUrl) }
	}

	public init(image: NSImage)
	{
		hashProvider = { $0.combine(image) }
		fileExtension = "png"
		fileName = nil
		mimeType = "image/png"
		dataLoader = { try image.dataUsingRepresentation(for: kUTTypePNG) }
		thumbnailProvider = { image }

		let selfPromise = WeakPromise<Upload>()

		metadataProvider =
			{
				if let byteCount = try? selfPromise.value?.data().count
				{
					return .picture(byteCount: Int64(byteCount))
				}
				else
				{
					return .unknown
				}
			}

		selfPromise.value = self
	}

	public init(attachment: Attachment)
	{
		hashProvider = { $0.combine(attachment.id) }
		fileExtension = attachment.bestUrl.pathExtension
		fileName = nil
		mimeType = attachment.bestUrl.preferredMimeType ?? "image/png"
		dataLoader = { throw UploadError.remoteAttachment }
		thumbnailProvider = { return #imageLiteral(resourceName: "missing.png") }
		metadataProvider =
			{
				switch attachment.type
				{
				case .image: return .picture(byteCount: 0)
				case .video: return .movie(duration: 0)
				case .gifv: return .movie(duration: 0)
				case .unknown: return .unknown
				}
			}

		self.attachment = attachment
	}

	public func set(thumbnail: NSImage)
	{
		self.thumbnail = thumbnail
	}

	public func loadThumbnail(completion: @escaping (NSImage) -> Void)
	{
		DispatchQueue.global(qos: .utility).async
			{
				completion(self.thumbnail)
			}
	}

	public func loadMetadata(completion: @escaping (Metadata) -> Void)
	{
		DispatchQueue.global(qos: .utility).async
			{
				completion(self.metadata)
			}
	}

	public func data() throws -> Data
	{
		assert(!Thread.isMainThread)

		if let data = cachedData { return data }

		let data = try dataLoader()
		cachedData = data

		return data
	}

	public func set(attachment: Attachment)
	{
		self.attachment = attachment
	}

	public func hash(into hasher: inout Hasher)
	{
		hashProvider(&hasher)
	}

	public func discardAttachment()
	{
		attachment = nil
	}

	public enum UploadError: LocalizedError
	{
		case remoteAttachment

		var localizedDescription: String
		{
			switch self
			{
			case .remoteAttachment: return 🔠("This is a remote attachment that was already uploaded")
			}
		}
	}
}

extension Upload: Hashable
{
	public static func == (lhs: Upload, rhs: Upload) -> Bool
	{
		return lhs.hashValue == rhs.hashValue
	}
}
