//
//  NSWindow+Additions.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 31.12.18.
//  Mastonaut - Mastodon Client for Mac
//  Copyright © 2018 Bruno Philipe.
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

extension NSWindow
{
	func dismissSheetOrClose(modalResponse: NSApplication.ModalResponse? = nil)
	{
		if let sheetParent = sheetParent
		{
			if let modalResponse = modalResponse
			{
				sheetParent.endSheet(self, returnCode: modalResponse)
			}
			else
			{
				sheetParent.endSheet(self)
			}
		}
		else
		{
			close()
		}
	}
}
