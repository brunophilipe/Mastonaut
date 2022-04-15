//
//  PostingService.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 10.06.19.
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

public class PostingService: NSObject
{
	public let client: ClientType

	@objc dynamic public private(set) var characterCount: Int = 0
	@objc dynamic public private(set) var submitTaskFuture: FutureTask?

	public var isSubmiting: Bool { return submitTaskFuture != nil }

	private var status: String = ""
	private var contentWarning: String? = nil

	public init(client: ClientType)
	{
		self.client = client
	}

	public func reset()
	{
		status = ""
		contentWarning = nil
		submitTaskFuture?.task?.cancel()
		submitTaskFuture = nil
		updateCharacterCount()
	}

	public func set(status: String)
	{
		self.status = status
		updateCharacterCount()
	}

	public func set(contentWarning: String?)
	{
		self.contentWarning = contentWarning
		updateCharacterCount()
	}

	public func post(visibility: Visibility,
					 isSensitive: Bool,
					 attachmentIds: [String],
					 replyStatusId: String?,
					 poll: PollPayload?,
					 completion: @escaping (Swift.Result<Status, Error>) -> Void)
	{
		let isSensitive = attachmentIds.count > 0 && isSensitive

		let createStatusRequest = Statuses.create(status: status,
												  replyToID: replyStatusId,
												  mediaIDs: attachmentIds,
												  sensitive: isSensitive,
												  spoilerText: contentWarning,
												  poll: poll,
												  visibility: visibility)

		let taskPromise = Promise<URLSessionTask>()
		guard let future = client.run(createStatusRequest, resumeImmediately: false, completion:
			{
				[weak self] result in

				DispatchQueue.main.async
					{
						guard let self = self else { return }

						if self.submitTaskFuture === taskPromise.value
						{
							self.submitTaskFuture = nil
						}

						switch result
						{
						case .success(let status, _):
							completion(.success(status))

						case .failure(let error):
							completion(.failure(error))
						}
					}
		})
			else
		{
			return
		}

		self.submitTaskFuture = future

		future.resolutionHandler = { task in
			taskPromise.value = task
			task.resume()
		}
	}

	private func updateCharacterCount()
	{
		characterCount = status.mastodonCount + (contentWarning?.count ?? 0)
	}
}

private extension String
{
	static let linkPlaceholder = String(repeating: "x", count: 23)

	var mastodonCount: Int
	{
		let mutableCopy = (self as NSString).mutableCopy() as! NSMutableString
		var replacementRanges: [NSRange: String] = [:]

		// Mastodon counts any sequence joined by a ZWJ as a single character, regardless of whether the characters are
		// joinable. This regex replaces all groups with a single char to reproduce this behavior.
		NSRegularExpression.zwjGroupRegex.enumerateMatches(in: mutableCopy as String, options: [], range: mutableCopy.range)
		{
			(result, flags, stop) in

			guard let result = result else { return }

			replacementRanges[result.range] = "x"
		}

		mutableCopy.replaceCharacters(in: replacementRanges)
		replacementRanges.removeAll()

		// Mastodon always counts every link URL as having 23 characters, regardless of the actual length of the URL.
		NSRegularExpression.uriRegex.enumerateMatches(in: mutableCopy as String, options: [], range: mutableCopy.range)
		{
			(result, flags, stop) in

			guard let result = result, result.numberOfRanges > 1 else
			{
				return
			}

			let prefix = mutableCopy.substring(with: result.range(at: 1))
			replacementRanges[result.range] = "\(prefix)\(String.linkPlaceholder)"
		}

		mutableCopy.replaceCharacters(in: replacementRanges)
		replacementRanges.removeAll()

		// Mastodon only counts the username part of a mention towards the character limit, so we drop the instance URI
		// in case it is present.
		NSRegularExpression.mentionRegex.enumerateMatches(in: mutableCopy as String, options: [], range: mutableCopy.range)
		{
			(result, flags, stop) in

			guard let result = result, result.numberOfRanges > 1 else
			{
				return
			}

			replacementRanges[result.range] = "@\(mutableCopy.substring(with: result.range(at: 3)))"
		}

		mutableCopy.replaceCharacters(in: replacementRanges)
		return (mutableCopy as String).count
	}
}
