//
//  Account+Shims.swift
//  CoreTootin
//
//  Created by Bruno Philipe on 15.09.19.
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

import MastodonKit

public extension Account
{
	var bestDisplayName: String
	{
		return displayName.isEmpty ? username : displayName
	}

	func uri(in instance: Instance) -> String
	{
		guard acct.contains("@") else
		{
			return "@\(username)@\(instance.uri)"
		}

		return "@\(acct)"
	}
}
