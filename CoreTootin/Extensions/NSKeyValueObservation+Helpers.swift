//
//  NSKeyValueObservation+Helpers.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 05.01.19.
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

public extension Array where Element == NSKeyValueObservation
{
	mutating func observePreference<Value>(on queue: DispatchQueue? = nil,
										   _ keyPath: KeyPath<MastonautPreferences, Value>,
										   changeHandler: @escaping (MastonautPreferences, NSKeyValueObservedChange<Value>) -> Void)
	{
		guard let queue = queue else
		{
			append(Preferences.observe(keyPath, changeHandler: changeHandler))
			return
		}

		append(Preferences.observe(keyPath)
			{
				preferences, change in

				queue.async
					{
						changeHandler(preferences, change)
					}
			})
	}

	mutating func observe<Object: NSObject, Value>(on queue: DispatchQueue? = nil,
												   _ object: Object,
												   _ keyPath: KeyPath<Object, Value>,
												   sendInitial: Bool = false,
												   changeHandler: @escaping (Object, NSKeyValueObservedChange<Value>) -> Void)
	{
		let options: NSKeyValueObservingOptions

		if sendInitial
		{
			options = [.old, .new, .initial]
		}
		else
		{
			options = [.old, .new]
		}

		guard let queue = queue else
		{
			append(object.observe(keyPath, options: options, changeHandler: changeHandler))
			return
		}

		append(object.observe(keyPath, options: options)
			{
				object, change in

				queue.async
					{
						changeHandler(object, change)
					}
			})
	}
}
