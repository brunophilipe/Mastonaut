//
//  PropertyObserver.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 16.02.19.
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

class PropertyObserver<Root: NSObject, Value>
{
	private let observation: NSKeyValueObservation

	init(object: Root, keyPath: ReferenceWritableKeyPath<Root, Value>)
	{
		let selfPromise = WeakPromise<PropertyObserver>()

		observation = object.observe(keyPath)
		{
			(preferences, change) in

			selfPromise.value?.changed(value: preferences[keyPath: keyPath])
		}

		selfPromise.value = self
	}

	internal func changed(value: Value)
	{
		// To be overriden
	}
}

class PreferenceCheckboxObserver: PropertyObserver<MastonautPreferences, Bool>
{
	private let keyPath: ReferenceWritableKeyPath<MastonautPreferences, Bool>
	private let checkbox: NSButton

	init(preference keyPath: ReferenceWritableKeyPath<MastonautPreferences, Bool>, checkbox: NSButton)
	{
		self.keyPath = keyPath
		self.checkbox = checkbox
		super.init(object: Preferences, keyPath: keyPath)

		checkbox.state = Preferences[keyPath: keyPath] ? .on : .off
		checkbox.target = self
		checkbox.action = #selector(PreferenceCheckboxObserver.clickedCheckbox(_:))
	}

	@objc private func clickedCheckbox(_ sender: NSButton)
	{
		let preferences = Preferences
		preferences[keyPath: keyPath] = checkbox.state == .on
	}
}

typealias PopUpOptionCapable = (CaseIterable & RawRepresentable & MenuItemRepresentable)

class PropertyEnumPopUpObserver<Root: NSObject, Value: PopUpOptionCapable>: PropertyObserver<Root, Value>
{
	private let keyPath: ReferenceWritableKeyPath<Root, Value>
	private let popUpButton: NSPopUpButton

	private weak var object: Root?

	init(object: Root, keyPath: ReferenceWritableKeyPath<Root, Value>, popUpButton: NSPopUpButton)
	{
		self.keyPath = keyPath
		self.popUpButton = popUpButton
		self.object = object
		super.init(object: object, keyPath: keyPath)

		var menuItems = [NSMenuItem]()

		for value in Value.allCases
		{
			let item = NSMenuItem()
			item.title = value.localizedTitle
			item.image = value.icon
			item.target = self
			item.action = #selector(PropertyEnumPopUpObserver.selectedMenuItem(_:))
			item.representedObject = value.rawValue
			
			menuItems.append(item)
		}

		let menu = NSMenu(title: "")
		menu.setItems(menuItems)

		popUpButton.menu = menu
	}

	@objc private func selectedMenuItem(_ sender: NSMenuItem)
	{
		if let rawValue = sender.representedObject as? Value.RawValue, let newValue = Value.init(rawValue: rawValue)
		{
			object?[keyPath: keyPath] = newValue
		}
	}
}

class PreferenceEnumPopUpObserver<Value: PopUpOptionCapable>: PropertyEnumPopUpObserver<MastonautPreferences, Value>
{
	init(preference keyPath: ReferenceWritableKeyPath<MastonautPreferences, Value>, popUpButton: NSPopUpButton)
	{
		super.init(object: Preferences, keyPath: keyPath, popUpButton: popUpButton)
	}
}

class PropertyEnumRadioObserver<Root: NSObject, Value: Hashable>: PropertyObserver<Root, Value>
{
	private let buttonMap: [Value: NSButton]
	private let valueMap: [NSButton: Value]
	private let keyPath: ReferenceWritableKeyPath<Root, Value>
	private weak var object: Root?

	init(object: Root, keyPath: ReferenceWritableKeyPath<Root, Value>, buttonMap: [Value: NSButton])
	{
		self.buttonMap = buttonMap
		self.keyPath = keyPath
		self.object = object

		var valueMap: [NSButton: Value] = [:]

		for (buttonValue, button) in buttonMap
		{
			valueMap[button] = buttonValue
		}

		self.valueMap = valueMap

		super.init(object: object, keyPath: keyPath)
		self.updateAllButtons()

		for (_, button) in buttonMap
		{
			button.target = self
			button.action = #selector(PropertyEnumRadioObserver.clickedButton(_:))
		}
	}

	override func changed(value: Value)
	{
		for (buttonValue, button) in buttonMap
		{
			button.state = buttonValue == value ? .on : .off
		}
	}

	func updateAllButtons()
	{
		object.map { changed(value: $0[keyPath: self.keyPath]) }
	}

	@objc private func clickedButton(_ sender: NSButton)
	{
		guard let buttonValue = valueMap[sender] else { return }
		object?[keyPath: keyPath] = buttonValue
	}
}

class PreferenceEnumRadioObserver<Value: Hashable>: PropertyEnumRadioObserver<MastonautPreferences, Value>
{
	init(preference keyPath: ReferenceWritableKeyPath<MastonautPreferences, Value>, buttonMap: [Value: NSButton])
	{
		super.init(object: Preferences, keyPath: keyPath, buttonMap: buttonMap)
	}
}
