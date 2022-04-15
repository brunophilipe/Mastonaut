//
//  RefreshingTextField.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 28.01.19.
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

class RefreshingFormattedTextField: NSTextField
{
	static let refreshNotificationName = NSNotification.Name(rawValue: "RefreshingTextFieldRefreshNotificationName")

	private static var updateTimer: Timer? = nil

	private var notificationObserver: NSObjectProtocol? = nil
	private var lastObjectValue: Any? = nil

	override init(frame frameRect: NSRect)
	{
		super.init(frame: frameRect)
		setupTimerIfNeeded()
		setupNotificationObserver()
	}

	required init?(coder: NSCoder)
	{
		super.init(coder: coder)
		setupTimerIfNeeded()
		setupNotificationObserver()
	}

	override var objectValue: Any?
	{
		didSet
		{
			lastObjectValue = objectValue
		}
	}

	deinit
	{
		if let observer = notificationObserver {
			NotificationCenter.default.removeObserver(observer)
		}
	}

	private func setupNotificationObserver()
	{
		notificationObserver = NotificationCenter.observer(for: RefreshingFormattedTextField.refreshNotificationName,
														   object: nil,
														   queue: OperationQueue.main)
		{
			[weak self] _ in

			if let formatter = self?.formatter, let stringValue = formatter.string(for: self?.lastObjectValue)
			{
				self?.stringValue = stringValue
			}
		}
	}

	private func setupTimerIfNeeded()
	{
		if RefreshingFormattedTextField.updateTimer == nil
		{
			RefreshingFormattedTextField.updateTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true)
			{
				_ in

				NotificationCenter.default.post(name: RefreshingFormattedTextField.refreshNotificationName,
												object: RefreshingFormattedTextField.self)
			}
		}
	}
}
