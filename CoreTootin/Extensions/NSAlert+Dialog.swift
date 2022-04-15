//
//  NSAlert+Dialog.swift
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

public extension NSAlert
{
	static func makeAlert(style: NSAlert.Style = .informational,
						  title: String, message: String,
						  dialogMode: DialogMode? = nil) -> NSAlert
	{
		let alert = NSAlert(style: style, title: title, message: message)

		if let dialogMode = dialogMode
		{
			alert.addButton(withTitle: dialogMode.proceedTitle)
			alert.addButton(withTitle: dialogMode.dismissTitle)
		}

		return alert
	}
}
