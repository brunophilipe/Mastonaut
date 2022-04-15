//
//  NetworkError.swift
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

/// This struct wraps network errors, which are known to be NSErrors, meaning `localizedDescription` works properly.
public struct NetworkError: UserDescriptionError
{
	public let error: Error

	public init(_ error: Error)
	{
		self.error = error
	}

	public var userDescription: String
	{
		return 🔠("error.network", error.localizedDescription)
	}
}

public struct UserLocalizedDescriptionError: UserDescriptionError, LocalizedError
{
	private let descritpion: String

	public init(_ error: Error)
	{
		descritpion = (error as? LocalizedError)?.localizedDescription ?? error.localizedDescription
	}

	public var userDescription: String { return descritpion }
	public var localizedDescription: String { return descritpion }
}
