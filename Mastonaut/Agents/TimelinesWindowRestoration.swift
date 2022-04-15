//
//  TimelinesWindowRestoration.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 14.04.19.
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

@objc class TimelinesWindowRestoration: NSObject, NSWindowRestoration
{
	static func restoreWindow(withIdentifier identifier: NSUserInterfaceItemIdentifier,
							  state: NSCoder,
							  completionHandler: @escaping (NSWindow?, Error?) -> Void)
	{
		guard identifier.rawValue == "Timelines" else
		{
			completionHandler(nil, Errors.unknownIdentifier)
			return
		}

		guard
			let controller = AppDelegate.shared.makeNewTimelinesWindow(forDecoder: true),
			let window = controller.window
			else
		{
			completionHandler(nil, Errors.windowCreationFailed)
			return
		}

		completionHandler(window, nil)
	}

	enum Errors: String, Error
	{
		case unknownIdentifier = "Unknown window restoration identifier."
		case windowCreationFailed = "Could not create window."

		var localizedDescription: String
		{
			return rawValue
		}
	}
}
