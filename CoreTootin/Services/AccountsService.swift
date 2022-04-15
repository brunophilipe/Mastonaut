//
//  AccountsService.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 01.05.19.
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
import CoreData
import MastodonKit

public class AccountsService: NSObject
{
	public private(set) lazy var order = AccountOrder.default(context: context)

	private let context: NSManagedObjectContext
	private let urlSession = URLSession(configuration: .forClients)
	private unowned let keychainController: KeychainController

	private var countObserver: NSKeyValueObservation? = nil

	private var accountDetailsMap: [UUID: AccountDetails] = [:]
	private var reauthorizationAgents: [UUID: ReauthorizationAgent] = [:]

	@objc dynamic public var authorizedAccountsCount: Int = 0

	public var authorizedAccounts: [AuthorizedAccount]
	{
		return order.sortedAccounts
	}

	public init(context: NSManagedObjectContext, keychainController: KeychainController)
	{
		self.context = context
		self.keychainController = keychainController

		super.init()

		let observer = order.observe(\.accounts, changeHandler: { [weak self] (_, _) in
			DispatchQueue.main.async {
				guard let self = self else { return }
				self.authorizedAccountsCount = self.authorizedAccounts.count
			}
		})

		countObserver = observer
		authorizedAccountsCount = authorizedAccounts.count
	}

	public func set(sortOrder: Int, for account: AuthorizedAccount)
	{
		assert(Thread.isMainThread)
		order.set(sortOrder: sortOrder, for: account)
	}

	public func account(with uuid: UUID) -> AuthorizedAccount?
	{
		return order.sortedAccounts.first(where: { $0.uuid == uuid })
	}

	public func flushCachedDetails(for account: AuthorizedAccount)
	{
		accountDetailsMap.removeValue(forKey: account.uuid)
	}

	public func details(for account: AuthorizedAccount, completion: @escaping (Swift.Result<AccountDetails, Error>) -> Void)
	{
		let accountUUID = account.uuid

		if let details = accountDetailsMap[accountUUID]
		{
			completion(.success(details))
			return
		}

		let reauthAgent = reauthorizationAgent(for: account)

		let client = Client.create(for: account, keychainController: keychainController,
								   reauthAgent: reauthAgent, urlSession: urlSession)

		client?.fetchAccountAndInstance()
			{
				[weak self] result in

				switch result
				{
				case .success((let account, let instance)):
					let details = AccountDetails(account: account, instance: instance)
					self?.accountDetailsMap[accountUUID] = details
					completion(.success(details))

				case .failure(let error):
					completion(.failure(error))
				}
			}
	}

	public func migrateAllAccountsToSharedLocalKeychain(keychainController: KeychainController) -> [MigrationError]
	{
		var errors = [MigrationError]()

		for account in authorizedAccounts
		{
			do
			{
				try keychainController.migrateStorableToSharedLocalKeychain(account)
			}
			catch
			{
				if case KeychainController.Errors.secItemError(errSecItemNotFound) = error
				{
					continue
				}

				#if DEBUG
				NSLog("Could not migrate account to group keychain: \(error)")
				#endif
				errors.append(MigrationError(account: account, underlyingError: error))
			}
		}

		return errors
	}

	public func reauthorizationAgent(for account: AuthorizedAccount) -> ReauthorizationAgent
	{
		if let agent = reauthorizationAgents[account.uuid] {
			return agent
		}

		let agent = ReauthorizationAgent(account: account, keychainController: keychainController)
		reauthorizationAgents[account.uuid] = agent

		return agent
	}

	public struct MigrationError: Error
	{
		public let account: AuthorizedAccount
		public let underlyingError: Error
	}
}

public struct AccountDetails
{
	public let account: Account
	public let instance: Instance
}
