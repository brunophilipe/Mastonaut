//
//  AttachmentUploader.swift
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

import Foundation
import MastodonKit
import AVFoundation

let kUTTypeHEIC = "public.heic" as CFString

public class AttachmentUploader
{
	public typealias ConvertedDataProvider = () throws -> Data

	public static let supportedImageTypes = [kUTTypeJPEG, kUTTypePNG, kUTTypeJPEG2000, kUTTypeHEIC, kUTTypeGIF, kUTTypeTIFF]
	public static let supportedMovieTypes = [kUTTypeMovie]
	public static let supportedAttachmentTypes = supportedImageTypes + supportedMovieTypes
	public static let maxAttachmentImageSize = NSSize(width: 4096, height: 4096)

	public static let imageTypeConversionMap: [CFString: CFString] = [
		kUTTypeJPEG2000: kUTTypeJPEG,
		kUTTypeHEIC: kUTTypeJPEG,
		kUTTypeTIFF: kUTTypeJPEG
	]

	private var activeUploadFutures: [Upload: FutureTask] = [:]
	private var activeDescriptionUpdateFutures: [Upload: FutureTask] = [:]
	private var pendingUploadDescriptionUpdates: [Upload: String?] = [:]

	public private(set) lazy var imageRestrainer = ImageRestrainer(typeConversionMap: AttachmentUploader.imageTypeConversionMap,
																   maximumImageSize: AttachmentUploader.maxAttachmentImageSize)

	public weak var delegate: AttachmentUploaderDelegate? = nil

	public var hasActiveTasks: Bool
	{
		return activeUploadFutures.count > 0 || activeDescriptionUpdateFutures.count > 0
	}

	public init(delegate: AttachmentUploaderDelegate? = nil)
	{
		self.delegate = delegate
	}

	public func startUploading(uploads: [Upload], for client: ClientType)
	{
		uploads.forEach({ prepareData(upload: $0, for: client) })
	}

	public func cancel(upload: Upload)
	{
		activeUploadFutures[upload]?.task?.cancel()
		activeUploadFutures[upload] = nil
	}

	public func uploadProgress(for upload: Upload) -> Double?
	{
		guard let task = activeUploadFutures[upload]?.task else { return nil }
		return task.progress.fractionCompleted
	}

	public func set(description: String?, of upload: Upload, for client: ClientType)
	{
		guard let attachment = upload.attachment, activeDescriptionUpdateFutures[upload] == nil else
		{
			pendingUploadDescriptionUpdates[upload] = description
			return
		}

		let previousDescription = attachment.description

		let task = (client.run(Media.update(id: attachment.id, description: description), resumeImmediately: true)
		{
			[weak self] result in

			guard let self = self else { return }

			self.activeDescriptionUpdateFutures.removeValue(forKey: upload)
			self.dispatchPendingDescriptionUpdate(of: upload, for: client)

			switch result
			{
			case .success(let attachment, _):
				upload.set(attachment: attachment)
				self.delegate?.attachmentUploader(self, updatedDescription: attachment.description, for: upload)

			case .failure(let error):
				#if DEBUG
				NSLog("Failed updating description: \(error)")
				#endif
				self.delegate?.attachmentUploader(self,
												  failedUpdatingDescriptionFor: upload,
												  previousValue: previousDescription)
			}
		})

		activeDescriptionUpdateFutures[upload] = task
	}

	public func isPendingCompletion(forSettingDescriptionOf upload: Upload) -> Bool
	{
		return pendingUploadDescriptionUpdates[upload] != nil
	}

	private func dispatchPendingDescriptionUpdate(of upload: Upload, for client: ClientType)
	{
		if let pendingDescription = pendingUploadDescriptionUpdates[upload]
		{
			pendingUploadDescriptionUpdates.removeValue(forKey: upload)
			set(description: pendingDescription, of: upload, for: client)
		}
	}

	private func cancelPendingDescriptionUpdate(of upload: Upload)
	{
		if pendingUploadDescriptionUpdates[upload] != nil
		{
			pendingUploadDescriptionUpdates.removeValue(forKey: upload)
			delegate?.attachmentUploader(self, failedUpdatingDescriptionFor: upload, previousValue: nil)
		}
	}

	private func prepareData(upload: Upload, for client: ClientType)
	{
		DispatchQueue.global(qos: .userInitiated).async
			{
				[weak self] in

				guard let self = self else { return }

				guard upload.needsUploading else
				{
					self.delegate?.attachmentUploader(self, finishedUploading: upload)
					self.dispatchPendingDescriptionUpdate(of: upload, for: client)
					return
				}

				let data: Data

				do { data = try upload.data() } catch
				{
					DispatchQueue.main.async
					{
						[weak self] in

						guard let self = self else { return }

						self.delegate?.attachmentUploader(self, produced: UploadError.encodeError(error), for: upload)
						self.cancelPendingDescriptionUpdate(of: upload)
					}
					return
				}

				DispatchQueue.main.async
					{
						[weak self] in self?.dispatch(for: upload, data: data, client: client)
					}
		}
	}

	private func dispatch(for upload: Upload, data: Data, client: ClientType)
	{
		let observationPromise = Promise<NSKeyValueObservation>()
		let media = MediaAttachment.other(data, fileExtension: upload.fileExtension, mimeType: upload.mimeType)

		guard let future = (client.run(Media.upload(media: media), resumeImmediately: false)
		{
			[weak self, observationPromise] result in

			observationPromise.value = nil

			DispatchQueue.main.async
			{
				[weak self] in

				guard let self = self else { return }

				self.activeUploadFutures.removeValue(forKey: upload)

				switch result
				{
				case .success(let attachment, _):
					upload.set(attachment: attachment)
					self.delegate?.attachmentUploader(self, finishedUploading: upload)
					self.dispatchPendingDescriptionUpdate(of: upload, for: client)

				case .failure(let error):
					self.delegate?.attachmentUploader(self, produced: UploadError.serverError(error), for: upload)
					self.cancelPendingDescriptionUpdate(of: upload)
				}
			}
		})
		else
		{
			return
		}

		activeUploadFutures[upload] = future

		future.resolutionHandler = { task in

			observationPromise.value = task.observe(\URLSessionDataTask.countOfBytesSent)
			{
				[weak self] (task, _) in

				guard let self = self else { return }

				let progress = Double(task.countOfBytesSent) / Double(task.countOfBytesExpectedToSend)
				self.delegate?.attachmentUploader(self, updatedProgress: progress, for: upload)
			}

			task.resume()
		}
	}

	public enum UploadError: Error
	{
		case noKnownMimeForUTI
		case failedEncodingResizedImage
		case encodeError(Error)
		case serverError(Error)
	}
}

public protocol AttachmentUploaderDelegate: AnyObject
{
	func attachmentUploader(_: AttachmentUploader, finishedUploading upload: Upload)
	func attachmentUploader(_: AttachmentUploader, updatedProgress progress: Double, for upload: Upload)

	func attachmentUploader(_: AttachmentUploader, produced error: AttachmentUploader.UploadError, for upload: Upload)

	func attachmentUploader(_: AttachmentUploader, updatedDescription: String?, for upload: Upload)
	func attachmentUploader(_: AttachmentUploader, failedUpdatingDescriptionFor upload: Upload, previousValue: String?)
}
