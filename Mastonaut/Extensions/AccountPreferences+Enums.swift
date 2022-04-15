//
//  AccountPreferences+Enums.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 22.08.19.
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
import CoreTootin

extension AccountPreferences
{
	@objc dynamic var notificationDisplayMode: NotificationDisplayMode
	{
		get { NotificationDisplayMode(rawValue: showNotifications) ?? .always }
		set { showNotifications = newValue.rawValue }
	}

	@objc dynamic var notificationDetailMode: NotificationDetailMode
	{
		get { NotificationDetailMode(rawValue: showNotificationDetails) ?? .whenClean }
		set { showNotificationDetails = newValue.rawValue }
	}

	@objc enum NotificationDisplayMode: Int16
	{
		case always = 1
		case never = 2
		case whenActive = 3
	}

	@objc enum NotificationDetailMode: Int16
	{
		case always = 1
		case never = 2
		case whenClean = 3
	}
}
