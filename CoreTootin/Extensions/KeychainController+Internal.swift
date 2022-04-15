//
//  KeychainController+Internal.swift
//  CoreTootin
//
//  Created by Bruno Philipe on 17.09.19.
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

internal extension KeychainController
{
	func query(authorizedAccount: AuthorizedAccount) throws -> AccountAccessToken?
	{
		return try authorizedAccount.account.flatMap { try query(account: $0) }
	}

	func migrateStorableToSharedLocalKeychain(_ authorizedAccount: AuthorizedAccount) throws
	{
		guard let account = authorizedAccount.account else {
			throw MigrationError.badAccoountParameter
		}

		try migrateStorableToSharedLocalKeychain(account)
	}
}

enum MigrationError: LocalizedError {
	case badAccoountParameter

	var errorDescription: String? {
		return "The account parameter is empty or nil"
	}
}
