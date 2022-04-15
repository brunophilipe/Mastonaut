//
//  NSViewController+Alerts.swift
//  CoreTootin
//
//  Created by Bruno Philipe on 25.09.19.
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

public extension NSViewController
{
	func displayError<T: UserDescriptionError>(_ error: T,
											   title: String = 🔠("Error"),
											   dialogMode: DialogMode? = nil,
											   completionHandler handler: ((NSApplication.ModalResponse) -> Void)? = nil)
	{
		let alert = NSAlert.makeAlert(style: .warning, title: title,
									  message: error.userDescription,
									  dialogMode: dialogMode)

		let result = alert.runModal()

		handler?(result)
	}

	func showAlert(style: NSAlert.Style = .informational,
				   title: String, message: String,
				   dialogMode: DialogMode? = nil,
				   completionHandler handler: ((NSApplication.ModalResponse) -> Void)? = nil)
	{
		let alert = NSAlert.makeAlert(style: style, title: title, message: message, dialogMode: dialogMode)
		let result = alert.runModal()

		handler?(result)
	}
}
