//
//  DialogMode.swift
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

import Foundation

public enum DialogMode
{
	case yesNo
	case okCancel
	case discardKeepEditing
	case custom(proceed: String, dismiss: String)

	public var proceedTitle: String
	{
		switch self
		{
		case .yesNo:
			return 🔠("Yes")
		case .okCancel:
			return 🔠("OK")
		case .discardKeepEditing:
			return 🔠("Discard")
		case .custom(let proceed, _):
			return proceed
		}
	}

	public var dismissTitle: String
	{
		switch self
		{
		case .yesNo:
			return 🔠("No")
		case .okCancel:
			return 🔠("Cancel")
		case .discardKeepEditing:
			return 🔠("Keep Editing")
		case .custom(_, let dismiss):
			return dismiss
		}
	}
}
