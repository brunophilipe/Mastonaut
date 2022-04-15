//
//  NotificationsPreferencesViewController.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 21.08.19.
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

class NotificationsPreferencesViewController: BaseAccountsPreferencesViewController
{
	@IBOutlet unowned var showNotificationsAlwaysRadioButton: NSButton!
	@IBOutlet unowned var showNotificationsNeverRadioButton: NSButton!
	@IBOutlet unowned var showNotificationsWhenActiveRadioButton: NSButton!

	@IBOutlet unowned var notificationsDetailsAlwaysRadioButton: NSButton!
	@IBOutlet unowned var notificationsDetailsNeverRadioButton: NSButton!
	@IBOutlet unowned var notificationsDetailsWhenActiveRadioButton: NSButton!

	@objc dynamic private var accountPreferences: AccountPreferences?
	{
		didSet { updatePropertyObservers() }
	}

	private var accountCountObserver: NSKeyValueObservation?
	private var preferenceObservers: [AnyObject] = []

	override func viewDidLoad() {
		super.viewDidLoad()

		accountCountObserver = AppDelegate.shared.accountsService.observe(\.authorizedAccountsCount)
			{
				[weak self] (service, _) in
				self?.tableView.deselectAll(nil)
				self?.accountPreferences = nil
				self?.accounts = service.authorizedAccounts
			}
	}

	override func viewWillDisappear()
	{
		super.viewWillDisappear()

		AppDelegate.shared.saveContext()
	}

	private func updatePropertyObservers()
	{
		guard let preferences = self.accountPreferences else
		{
			preferenceObservers = []
			return
		}

		let displayModeButtonMap: [AccountPreferences.NotificationDisplayMode: NSButton] = [
			.always: showNotificationsAlwaysRadioButton,
			.never: showNotificationsNeverRadioButton,
			.whenActive: showNotificationsWhenActiveRadioButton
		]

		preferenceObservers.append(PropertyEnumRadioObserver(object: preferences,
												   keyPath: \AccountPreferences.notificationDisplayMode,
												   buttonMap: displayModeButtonMap))

		let displayDetailButtonMap: [AccountPreferences.NotificationDetailMode: NSButton] = [
			.always: notificationsDetailsAlwaysRadioButton,
			.never: notificationsDetailsNeverRadioButton,
			.whenClean: notificationsDetailsWhenActiveRadioButton
		]

		preferenceObservers.append(PropertyEnumRadioObserver(object: preferences,
												   keyPath: \AccountPreferences.notificationDetailMode,
												   buttonMap: displayDetailButtonMap))
	}

	// MARK: - Table View Delegate

	func tableViewSelectionDidChange(_ notification: Foundation.Notification)
	{
		let row = tableView.selectedRow

		guard row >= 0 else
		{
			accountPreferences = nil
			return
		}

		accountPreferences = accounts?[row].preferences(context: AppDelegate.shared.managedObjectContext)
	}
}
