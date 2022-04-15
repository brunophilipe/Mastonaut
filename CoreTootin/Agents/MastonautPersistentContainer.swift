//
//  MastonautPersistentContainer.swift
//  CoreTootin
//
//  Created by Bruno Philipe on 13.09.19.
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
import CoreData

class MastonautPersistentContainer: NSPersistentContainer
{
	static let appGroup = "R85D3K8ATT.app.mastonaut.mac"

	override open class func defaultDirectoryURL() -> URL {
		let storeURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup)!
		let directoryURL = storeURL.appendingPathComponent("Mastonaut", isDirectory: true)

		if FileManager.default.fileExists(atPath: directoryURL.path, isDirectory: nil) == false
		{
			try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
		}

		return directoryURL
	}
}
