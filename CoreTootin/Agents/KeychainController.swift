//
//  KeychainController.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 01.01.19.
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
import Security

public protocol KeychainStorable: Codable
{
	/// Unique identifier of this storable element.
	///
	/// Attempting to write to the keychain using the same account string will overwrite any previous value.
	var account: String { get }
}

/// This class can be used to store data into the device's keychain. Every record is identified by its account value
/// and the `service` value of this class. These two items must match in order for any one record to be successfully
/// retrieved between app launches.
///
/// Setting the `keychainGroupIdentifier` value to your app's "group identifier" allows items stored in the keychain
/// to be retrieved by other apps with the same group identifier running in the same device, or on different devices
/// using the same Apple ID that have the "iCloud Keychain" service enabled.
public class KeychainController
{
	/// The unique identifier of this controller service.
	fileprivate let service: String

	/// The user-visible label of this controller service, which is added to the label of keychain items.
	fileprivate let serviceLabel: String

	/// Set this property to a keychain group identifier use a shared keychain, or set it to
	/// `nil` to use the local keychain. The default value is nil.
	public var keychainGroupIdentifier: String? = nil

	/// Initializes the Keychain controller.
	///
	/// - Parameter service: The service name. Should be a unique name (such as your app's unique identifier).
	public init(service: String, serviceLabel: String? = nil)
	{
		self.service = service
		self.serviceLabel = serviceLabel ?? service
	}

	/// Store a storable object into the keychain.
	///
	///	**Warning:** If `overwrite` is `false` and an object with the respective `account` value is
	/// already stored in the keychain, an error will be thrown.
	///
	/// - Parameters:
	///   - storable: The storable object to write to the keychain.
	///   - overwite: Whether the object should be overwritten in case it already exists.
	/// - Throws: Errors.secItemError
	public func store<T: KeychainStorable>(_ storable: T, overwite: Bool = true) throws
	{
		if overwite, try queryData(for: storable.account) != nil
		{
			try delete(storable.account)
		}

		let encoder = PropertyListEncoder()
		encoder.outputFormat = .binary

		try storeData(try encoder.encode(storable), account: storable.account)
	}

	/// Queries the keychain for an item with the given account value, and returns that item decoded if successful.
	///
	/// If no element with such account value is found, returns nil.
	/// If an error occurs, throws that error.
	///
	/// - Parameters:
	///   - account: The account identifier of the storable to lookup, fetch, and parse.
	public func query<T: KeychainStorable>(account: String) throws -> T?
	{
		if let encodedData = try queryData(for: account, useGroupIfPossible: false)
		{
			return try PropertyListDecoder().decode(T.self, from: encodedData)
		}

		return nil
	}

	/// Convenience method which invokes `delete(_ account: String)` using the account value of the given storable.
	public func delete(_ storable: KeychainStorable) throws
	{
		try delete(storable.account)
	}

	/// Queries the keychain for an item with the given account, and deletes it if such an element is found.
	public func delete(_ account: String) throws
	{
		try deleteItem(account, useGroupIfPossible: true)
	}

	/// Delete EVERY entry on the keychain that matches the receiver's service property.
	public func deleteAllStorablesForService() throws
	{
		let localResult = SecItemDelete(basicQueryAttributes(useGroupIfPossible: false) as CFDictionary)

		guard localResult == errSecSuccess else
		{
			throw Errors.secItemError(localResult)
		}

		guard keychainGroupIdentifier != nil else { return }

		let groupResult = SecItemDelete(basicQueryAttributes(useGroupIfPossible: true) as CFDictionary)

		guard groupResult == errSecSuccess else
		{
			throw Errors.secItemError(groupResult)
		}
	}

	/// Migrates an existing storable found on the group keychain to the local keychain, adding the SecAccess control
	/// flag so it can be shared between the app and its extensions.
	///
	/// - Parameter account: The account identifier used to fetch and store the keychain item.
	public func migrateStorableToSharedLocalKeychain(_ account: String) throws
	{
		if keychainGroupIdentifier != nil, let localData = try queryData(for: account, useGroupIfPossible: true)
		{
			try deleteItem(account, useGroupIfPossible: true)
			try storeData(localData, account: account)
		}
		else if let localData = try queryData(for: account, useGroupIfPossible: false)
		{
			try deleteItem(account, useGroupIfPossible: false)
			try storeData(localData, account: account)
		}
		else
		{
			throw Errors.secItemError(errSecItemNotFound)
		}
	}

	public enum Errors: Error
	{
		/// Thrown when a `SecItem…` function returns a value different from `errSecSuccess`.
		case secItemError(OSStatus)
	}
}

private extension KeychainController // Helpers
{
	/// Store a blob of data into the keychain. If a `keychainGroupIdentifier` is set, also applies the group to the
	/// keychain item, as well as the "synchronizable" flag.
	///
	/// - Parameter data: The data to encode
	/// - Parameter account: The account indentifier
	/// - Throws: Errors.secItemError
	func storeData(_ data: Data, account: String) throws
	{
		let now = Date()

		var attributes: [String: AnyObject] = [
			kSecClass as String: kSecClassGenericPassword,
			kSecAttrCreationDate as String: now as AnyObject,
			kSecAttrModificationDate as String: now as AnyObject,
			kSecAttrAccount as String: account as AnyObject,
			kSecAttrService as String: service as AnyObject,
			kSecValueData as String: data as AnyObject,
			kSecAttrLabel as String: "\(serviceLabel) (\(account))" as AnyObject
		]

		if let secAccess = Bundle.main.mastonautSecurityAccess() as AnyObject?
		{
			attributes[kSecAttrAccess as String] = secAccess
		}

		let result = SecItemAdd(attributes as CFDictionary, nil)

		guard result == errSecSuccess else
		{
			throw Errors.secItemError(result)
		}
	}

	/// Delete a storable from the keychain. If `useGroupIfPossible` is `false`, will always try deleting from the
	/// local keychain.
	func deleteItem(_ account: String, useGroupIfPossible useGroup: Bool) throws
	{
		let result = SecItemDelete(basicQueryAttributes(for: account, useGroupIfPossible: useGroup) as CFDictionary)

		guard result == errSecSuccess else
		{
			throw Errors.secItemError(result)
		}
	}

	/// Returns the basic query attribuites to match a leychain record stored with this library.
	func basicQueryAttributes(for account: String, useGroupIfPossible: Bool = true) -> [String: AnyObject]
	{
		var attributes = basicQueryAttributes(useGroupIfPossible: useGroupIfPossible)
		attributes[kSecAttrAccount as String] = account as AnyObject
		return attributes
	}

	/// Fetches any data associated with the given account without trying to parse it.
	func queryData(for account: String, useGroupIfPossible: Bool = true) throws -> Data?
	{
		var attributes = basicQueryAttributes(for: account, useGroupIfPossible: useGroupIfPossible)

		attributes[kSecReturnData as String] = true as AnyObject

		var output: AnyObject?
		let result = SecItemCopyMatching(attributes as CFDictionary, &output)

		guard [errSecSuccess, errSecItemNotFound].contains(result) else
		{
			throw Errors.secItemError(result)
		}

		if let encodedData = output as? Data
		{
			return encodedData
		}

		return nil
	}

	func basicQueryAttributes(useGroupIfPossible: Bool) -> [String: AnyObject]
	{
		var attributes: [String: AnyObject] = [
			kSecClass as String: kSecClassGenericPassword,
			kSecAttrService as String: service as AnyObject
		]

		if useGroupIfPossible, let accessGroup = keychainGroupIdentifier
		{
			attributes[kSecAttrSynchronizable as String] = kSecAttrSynchronizableAny
			attributes[kSecAttrAccessGroup as String] = accessGroup as AnyObject
		}

		return attributes
	}
}
