//
//  MastodonKit+Shims.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 31.12.18.
//  Mastonaut - Mastodon Client for Mac
//  Copyright © 2018 Bruno Philipe.
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

typealias MastodonNotification = MastodonKit.Notification

extension ClientType
{
	var parsedBaseUrl: URL?
	{
		return URL(string: baseURL)
	}
}

extension Client
{
	static func create(for account: AuthorizedAccount) -> ClientType?
	{
		return Client.create(for: account,
							 keychainController: AppDelegate.shared.keychainController,
							 reauthAgent: AppDelegate.shared.accountsService.reauthorizationAgent(for: account),
							 urlSession: AppDelegate.shared.clientsUrlSession)
	}

	static func registerMockResponses(for client: MockClient)
	{
		let timelineUrl = Bundle.main.url(forResource: "mock_data_timeline_home", withExtension: "json")!
		try! client.set(response: try! Data(contentsOf: timelineUrl), for: Timelines.home(range: .default))

		let accountUrl = Bundle.main.url(forResource: "mock_data_account", withExtension: "json")!
		try! client.set(response: try! Data(contentsOf: accountUrl), for: Accounts.account(id: "102480"))

		let accountStatusesUrl = Bundle.main.url(forResource: "mock_data_account_statuses", withExtension: "json")!
		try! client.set(response: try! Data(contentsOf: accountStatusesUrl), for: Accounts.statuses(id: "102480"))

		let customEmojiUrl = Bundle.main.url(forResource: "mock_data_custom_emoji", withExtension: "json")!
		try! client.set(response: try! Data(contentsOf: customEmojiUrl), for: Instances.customEmojis())
	}
}

extension Status
{
	var authorName: String
	{
		return account.bestDisplayName
	}
	
	var authorAccount: String
	{
		return account.acct
	}
	
	var attributedContent: NSAttributedString
	{
		return HTMLParsingService.shared.parse(HTML: content, removingTrailingUrl: card?.url,
											   removingInvisibleSpans: true)
	}

	var fullAttributedContent: NSAttributedString
	{
		return HTMLParsingService.shared.parse(HTML: content, removingTrailingUrl: nil, removingInvisibleSpans: false)
	}

	var attributedSpoiler: NSAttributedString
	{
		return HTMLParsingService.shared.parse(HTML: spoilerText).removingLinks
	}

	var resolvableURI: String
	{
		if uri.hasSuffix("/activity")
		{
			return String(uri.prefix(uri.count - "/activity".count))
		}
		else
		{
			return uri
		}
	}

	var links: [URL: String]
	{
		let attributedContent = self.attributedContent
		let range = NSMakeRange(0, attributedContent.length)
		var links: [URL: String] = [:]

		attributedContent.enumerateAttribute(.link, in: range, options: [])
			{
				(value, linkRange, _) in

				if let url = value as? URL
				{
					let title = attributedContent.attributedSubstring(from: linkRange).string
					guard !title.hasPrefix("#") && !title.hasPrefix("@") else { return }
					links[url] = title
				}
			}

		return links
	}
}

extension Instance
{
	var attributedDescription: NSAttributedString
	{
		return HTMLParsingService.shared.parse(HTML: description)
	}
}

extension ClientType
{
	func makeStreamIdentifier(for stream: RemoteEventsListener.Stream) -> RemoteEventsCoordinator.StreamIdentifier? {

		guard
			let baseUrl = URL(string: baseURL),
			let accessToken = accessToken
		else
		{
			return nil
		}

		return RemoteEventsCoordinator.StreamIdentifier(baseURL: baseUrl, accessToken: accessToken, stream: stream)
	}
}

extension MastodonNotification
{
	var authorName: String
	{
		let displayName = account.displayName
		return displayName.isEmpty ? account.username : displayName
	}

	var authorAccount: String
	{
		return account.acct
	}

	var isClean: Bool
	{
		if let status = self.status
		{
			if status.spoilerText.isEmpty == false { return false }
			if status.sensitive == true { return false }
			if status.tags.contains(where: { $0.name.lowercased() == "nsfw" }) { return false }

			return true
		}

		if account.attributedNote.string.localizedCaseInsensitiveContains("#nsfw") { return false }

		return true
	}
}

extension Account
{
	var attributedNote: NSAttributedString
	{
		return HTMLParsingService.shared.parse(HTML: note)
	}
}

extension Card
{
	private static let cardResourcesFetcher = ResourcesFetcher(urlSession: AppDelegate.shared.resourcesUrlSession)

	func fetchImage(completion: @escaping (NSImage?) -> Void)
	{
		guard let cardImageUrl = self.imageUrl else
		{
			completion(nil)
			return
		}

		Card.cardResourcesFetcher.fetchImage(with: cardImageUrl) { result in
			switch result {
			case .success(let image):
				completion(image)
			case .failure:
				// FIXME: pass along error
				completion(nil)
			case .emptyResponse:
				completion(nil)
			}
		}
	}
}

extension AttachmentMetadata
{
	var size: NSSize?
	{
		guard let width = self.width, let height = self.height else { return nil }
		return NSSize(width: width, height: height)
	}
}

extension Visibility
{
	var allowsReblog: Bool
	{
		switch self
		{
		case .public, .unlisted:
			return true

		case .private, .direct:
			return false
		}
	}

	var reblogIcon: NSImage
	{
		switch self
		{
		case .public, .unlisted:	return #imageLiteral(resourceName: "retoot")
		case .private:				return #imageLiteral(resourceName: "private")
		case .direct:				return #imageLiteral(resourceName: "direct")
		}
	}

	func reblogToolTip(didReblog: Bool) -> String
	{
		guard didReblog == false else {
			return 🔠("Unboost this toot")
		}

		switch self
		{
		case .public, .unlisted:
			return 🔠("Boost this toot")

		case .private:
			return 🔠("This toot can not be boosted because it is private.")

		case .direct:
			return 🔠("This toot can not be boosted because it is a direct message.")
		}
	}
}

extension Attachment: Equatable
{
	public static func ==(lhs: Attachment, rhs: Attachment) -> Bool
	{
		return lhs.id == rhs.id
	}

	public var hashValue: Int
	{
		return id.hashValue
	}
}

extension ClientError: UserDescriptionError
{
	public var userDescription: String
	{
		return localizedDescription
	}
}

extension NSAttributedString
{
	func replacingMentionsWithURIs(mentions: [Mention]) -> String
	{
		var composedString = String()

		enumerateAttribute(.link, in: NSMakeRange(0, length), options: []) { (value, effectiveRange, _) in
			guard let linkURL = value as? URL, let mention = mentions.first(where: { $0.url == linkURL }) else
			{
				composedString.append(self.attributedSubstring(from: effectiveRange).string)
				return
			}

			composedString.append("@\(mention.acct)")
		}

		return composedString
	}
}
