//
//  InstanceService.swift
//  CoreTootin
//
//  Created by Bruno Philipe on 29.09.19.
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

public class InstanceService
{
	private let urlSession: URLSession
	private let accountsObservation: NSKeyValueObservation
	private unowned let keychainController: KeychainController
	private unowned let accountsService: AccountsService

	private var instancesMap: [UUID: Instance] = [:]

	public init(urlSessionConfiguration: URLSessionConfiguration,
				keychainController: KeychainController,
				accountsService: AccountsService)
	{
		urlSession = URLSession(configuration: urlSessionConfiguration)
		self.keychainController = keychainController
		self.accountsService = accountsService

		let promise = WeakPromise<InstanceService>()

		accountsObservation = accountsService.observe(\.authorizedAccountsCount, options: [.initial])
			{
				(accountsService, _) in promise.value?.updateInstances(for: accountsService.authorizedAccounts)
			}

		promise.value = self
	}

	public func instance(for account: AuthorizedAccount, completion: @escaping (Instance?) -> Void)
	{
		if let instance = instancesMap[account.uuid]
		{
			completion(instance)
		}
		else
		{
			fetchInstance(for: account, completion: completion)
		}
	}

	private func fetchInstance(for account: AuthorizedAccount, completion: ((Instance?) -> Void)? = nil)
	{
		let reauthAgent = accountsService.reauthorizationAgent(for: account)

		guard
			let client = Client.create(for: account,
									   keychainController: keychainController,
									   reauthAgent: reauthAgent,
									   urlSession: urlSession)
		else
		{
			completion?(nil)
			return
		}

		client.run(Instances.current())
			{
				[weak self] result in

				switch result
				{
				case .success(let instance, _):
					self?.instancesMap[account.uuid] = instance
					completion?(instance)

				case .failure(let error):
					completion?(nil)
					#if DEBUG
					NSLog("Failed fetching instance: \(error)")
					#endif
				}
			}
	}

	private func updateInstances(for accounts: [AuthorizedAccount])
	{
		for account in accounts
		{
			fetchInstance(for: account)
		}
	}
}
