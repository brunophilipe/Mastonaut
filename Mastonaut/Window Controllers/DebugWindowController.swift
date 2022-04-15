//
//  DebugWindowController.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 20.08.19.
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

#if DEBUG

class DebugWindowController: NSWindowController {

	@objc dynamic var eventListenerCount = 0
	@objc dynamic var eventReceiverCount = 0

	private var observers: [NSKeyValueObservation] = []

	override var windowNibName: NSNib.Name?
	{
		return "DebugWindowController"
	}

	override func windowDidLoad()
	{
		super.windowDidLoad()

		observers.observe(RemoteEventsCoordinator.shared, \.listenerCount, sendInitial: true)
			{
				[weak self] coordinator, _ in
				self?.eventListenerCount = coordinator.listenerCount
			}

		observers.observe(RemoteEventsCoordinator.shared, \.totalReceiverCount, sendInitial: true)
			{
				[weak self] coordinator, _ in
				self?.eventReceiverCount = coordinator.totalReceiverCount
			}
	}

}

#endif
