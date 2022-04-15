//
//  NSAlert+Factory.swift
//  CoreTootin
//
//  Created by Bruno Philipe on 30.09.19.
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

import Cocoa

public extension NSAlert
{
	static func confirmReuploadAttachmentsDialog() -> NSAlert
	{
		return NSAlert.makeAlert(title: 🔠("dialog.reupload.title"), message: 🔠("dialog.reupload.message"),
								 dialogMode: .custom(proceed: 🔠("dialog.reupload.proceed"),
													 dismiss: 🔠("dialog.reupload.cancel")))
	}

	static func accountNeedsAuthorizationDialog(account: AuthorizedAccount) -> NSAlert
	{
		return NSAlert.makeAlert(style: .warning, title: 🔠("dialog.reauth.title"),
								 message: 🔠("dialog.reauth.message", account.uri ?? account.bestDisplayName),
								 dialogMode: .custom(proceed: 🔠("dialog.reauth.proceed"),
													 dismiss: 🔠("dialog.reauth.cancel")))
	}
}
