//
//  AccountSearchService.swift
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

public class AccountSearchService
{
	private let client: ClientType
	private let instance: Instance

	public init(client: ClientType, activeInstance: Instance)
	{
		self.client = client
		self.instance = activeInstance
	}

	public func search(query: String, completion: @escaping ([Account]) -> Void)
	{
		client.run(Accounts.search(query: query)) { (result) in

			guard case .success(let accounts, _) = result else
			{
				completion([])
				return
			}

			completion(accounts)
		}
	}
}

extension AccountSearchService: SuggestionTextViewSuggestionsProvider
{
	public func suggestionTextView(_ textView: SuggestionTextView,
								   suggestionsForMention mention: String,
								   completion: @escaping ([Suggestion]) -> Void)
	{
		let instance = self.instance

		search(query: mention)
		{
			(accounts) in

			DispatchQueue.main.async
				{
					completion(accounts.map({ AccountSuggestion(account: $0, instance: instance) }))
				}
		}
	}
}

private class AccountSuggestion: Suggestion {
	let text: String
	let imageUrl: URL?
	let displayName: String

	init(account: Account, instance: Instance) {
		text = account.uri(in: instance)
		imageUrl = account.avatarURL
		displayName = account.bestDisplayName
	}
}
