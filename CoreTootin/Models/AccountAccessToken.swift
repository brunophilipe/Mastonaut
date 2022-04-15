//
//  AccountAccessToken.swift
//  CoreTootin
//
//  Created by Bruno Philipe on 16.09.19.
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

/// Stores the authorization key for a given used at an individual instance.
public struct AccountAccessToken: KeychainStorable
{
	public let account: String
	public let accessToken: String

	public let clientApplication: ClientApplication?
	public let grantCode: String?

	public init(account: String, accessToken: String, clientApplication: ClientApplication, grantCode: String)
	{
		self.account = account
		self.accessToken = accessToken
		self.clientApplication = clientApplication
		self.grantCode = grantCode
	}
}
