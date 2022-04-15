//
//  PreferencesController.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 05.01.18.
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

import Foundation

public class PreferencesController: NSObject
{
	internal lazy var defaults = UserDefaults(suiteName: suiteName) ?? .standard

	/// The suite name. Should be the same as the App's App Group identifier.
	internal var suiteName: String?
	{
		return nil
	}

	// Default helpers

	public func number(forKey key: String) -> NSNumber?
	{
		return defaults.object(forKey: key) as? NSNumber
	}

	public func string(forKey key: String) -> String?
	{
		return defaults.string(forKey: key)
	}

	public func bool(forKey key: String) -> Bool?
	{
		return number(forKey: key)?.boolValue
	}

	public func rect(forKey key: String) -> NSRect?
	{
		return string(forKey: key).map { NSRectFromString($0) }
	}

	public func object<T>(forKey key: String) -> T?
	{
		return defaults.object(forKey: key) as? T
	}

	public func integerRepresentable<T: RawRepresentable>(for key: String, default: T) -> T where T.RawValue == Int
	{
		guard let number = number(forKey: key) else
		{
			return `default`
		}

		return T.init(rawValue: number.intValue) ?? `default`
	}

	public func uuid(forKey key: String) -> UUID?
	{
		guard let uuid = string(forKey: key) else { return nil }
		return UUID(uuidString: uuid)
	}
}
