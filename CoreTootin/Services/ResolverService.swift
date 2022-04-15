//
//  ResolverService.swift
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

public class ResolverService: NSObject
{
	let client: ClientType

	@objc public dynamic private(set) var resolverFuture: FutureTask? = nil

	public var isResolving: Bool { return resolverFuture != nil }

	public init(client: ClientType)
	{
		self.client = client
	}

	public func resolveStatus(uri: String, completion: @escaping (Swift.Result<Status, ResolverError>) -> Void)
	{
		resolveStatus(uri: uri, fallbackSearch: false, completion: completion)
	}

	public func resolve(account: Account, activeInstance: Instance,
						completion: @escaping (Swift.Result<Account, AccountRevalidationErrors>) -> Void)
	{
		let accountURI = account.uri(in: activeInstance)
		client.run(Accounts.search(query: accountURI, limit: 1))
		{
			result in

			switch result
			{
			case .success(let accounts, _):
				if let account = accounts.first
				{
					completion(.success(account))
				}
				else
				{
					completion(.failure(AccountRevalidationErrors.noResults(🔠("account.notFound", accountURI))))
				}

			case .failure(let error):
				completion(.failure(AccountRevalidationErrors.networkError(error.localizedDescription)))
			}
		}
	}

	private func resolveStatus(uri: String,
							   fallbackSearch: Bool,
							   completion: @escaping (Swift.Result<Status, ResolverError>) -> Void)
	{
		if resolverFuture?.task?.state != .completed { resolverFuture?.task?.cancel() }

		let request: Request<Results>

		if fallbackSearch
		{
			request = Search.fallbackSearch(query: uri, resolve: true)
		}
		else
		{
			request = Search.search(query: uri, limit: 1, resolve: true)
		}

		resolverFuture = client.run(request, resumeImmediately: true)
		{
			[weak self] result in

			if	case .failure(let error) = result,
				case .badStatus(statusCode: 404) = error,
				!fallbackSearch
			{
				self?.resolveStatus(uri: uri, fallbackSearch: true, completion: completion)
			}
			else if case .success(let searchResults, _) = result, let status = searchResults.statuses.first
			{
				self?.resolverFuture = nil
				completion(.success(status))
			}
			else
			{
				self?.resolverFuture = nil
				completion(.failure(.notFound))
			}
		}
	}

	public enum ResolverError: LocalizedError
	{
		case notFound
	}

	public enum AccountRevalidationErrors: UserDescriptionError
	{
		case noResults(String)
		case networkError(String)

		public var userDescription: String
		{
			switch self
			{
			case .noResults(let explanation): return explanation
			case .networkError(let explanation): return 🔠("error.network", explanation)
			}
		}
	}
}
