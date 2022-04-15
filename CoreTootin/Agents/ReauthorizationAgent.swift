//
//  ReauthorizationAgent.swift
//  CoreTootin
//
//  Created by Bruno Philipe on 03.10.19.
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

public extension Foundation.Notification.Name
{
	static let accountNeedsNewClientToken = Self("ReauthorizationAgentAccountNeedsNewClientToken")
}

public class ReauthorizationAgent: ClientDelegate
{
	public let account: AuthorizedAccount

	private let authorizationFuture: FutureTask? = nil
	private unowned let keychainController: KeychainController

	init(account: AuthorizedAccount, keychainController: KeychainController)
	{
		self.account = account
		self.keychainController = keychainController
	}

	public var isRequestingNewAccessToken: Bool
	{
		return authorizationFuture != nil
	}

	public func clientProducedUnauthorizedError(_ client: ClientType)
	{
		var client = client

		guard
			let credentials = try? keychainController.query(authorizedAccount: account),
			let clientApplication = credentials.clientApplication,
			let grantCode = credentials.grantCode
		else {
			DispatchQueue.main.async
				{
					self.invalidateCurentToken(client: &client)
				}
			return
		}

		let accountIdentifier = account.account!

		client.run(Login.oauth(clientID: clientApplication.clientID,
							   clientSecret: clientApplication.clientSecret,
							   scopes: [.read, .write, .follow, .push],
							   redirectURI: clientApplication.redirectURI,
							   code: grantCode))
			{
				[weak self] result in

				switch result
				{
				case .success(let login, _):
					DispatchQueue.main.async {
						client.accessToken = login.accessToken

						self?.storeUpdatedCredentials(accessToken: login.accessToken,
													  accountIdentifier: accountIdentifier,
													  clientApplication: clientApplication,
													  grantCode: grantCode)
					}

				case .failure(let error):
					if case .unauthorized = error
					{
						DispatchQueue.main.async { self?.invalidateCurentToken(client: &client) }
					}
					else
					{
						DispatchQueue.main.asyncAfter(deadline: .now() + 3.0)
							{
								self?.clientProducedUnauthorizedError(client)
							}
					}
				}
			}
	}

	private func storeUpdatedCredentials(accessToken: String,
										 accountIdentifier: String,
										 clientApplication: ClientApplication,
										 grantCode: String)
	{
		let accountAccessToken = AccountAccessToken(account: accountIdentifier,
													accessToken: accessToken,
													clientApplication: clientApplication,
													grantCode: grantCode)

		try? keychainController.store(accountAccessToken, overwite: true)
	}

	private func invalidateCurentToken(client: inout ClientType)
	{
		assert(Thread.isMainThread)

		client.accessToken = nil
		account.needsAuthorization = true

		NotificationCenter.default.post(name: .accountNeedsNewClientToken, object: self)
	}
}
