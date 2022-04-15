//
//  Persistence.swift
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

import AppKit
import CoreData

public class Persistence
{
	public static func overwritePersistenceStorage(with contents: FileWrapper)
	{
		assert(contents.isDirectory)

		guard let fileWrappers = contents.fileWrappers, fileWrappers.count > 0 else
		{
			fatalError("Could not migrate persitence to shared framework storage! Empty data from old storage.")
		}

		do
		{
			try FileManager.default.removeItem(at: MastonautPersistentContainer.defaultDirectoryURL())
			let baseURL = MastonautPersistentContainer.defaultDirectoryURL()

			for (filename, fileWrapper) in contents.fileWrappers ?? [:]
			{
				try fileWrapper.write(to: baseURL.appendingPathComponent(filename),
									  options: [], originalContentsURL: nil)
			}
		}
		catch
		{
			NSLog("Error migrating peristence: \(error)")
			fatalError("Could not migrate persitence to shared framework storage: \(error)")
		}
	}

	public init() {}

	public lazy var persistentContainer: NSPersistentContainer = {
		/*
		The persistent container for the application. This implementation
		creates and returns a container, having loaded the store for the
		application to it. This property is optional since there are legitimate
		error conditions that could cause the creation of the store to fail.
		*/
		let container = MastonautPersistentContainer(name: "Mastonaut")
		container.loadPersistentStores(completionHandler: { (storeDescription, error) in
			if let error = error {
				// Replace this implementation with code to handle the error appropriately.
				// fatalError() causes the application to generate a crash log and terminate. You should not use this
				// function in a shipping application, although it may be useful during development.

				/*
				Typical reasons for an error here include:
				* The parent directory does not exist, cannot be created, or disallows writing.
				* The persistent store is not accessible, due to permissions or data protection when the device is locked.
				* The device is out of space.
				* The store could not be migrated to the current model version.
				Check the error message to determine what the actual problem was.
				*/
				fatalError("Unresolved error \(error)")
			}
		})
		return container
	}()

	public var managedObjectContext: NSManagedObjectContext
	{
		return persistentContainer.viewContext
	}

	// MARK: Core Data Saving and Undo support

	public func saveContext() {
		// Performs the save action for the application, which is to send the save: message to the application's managed object context. Any encountered errors are presented to the user.
		let context = persistentContainer.viewContext

		if !context.commitEditing() {
			NSLog("\(NSStringFromClass(type(of: self))) unable to commit editing before saving")
		}
		if context.hasChanges {
			do {
				try context.save()
			} catch {
				// Customize this code block to include application-specific recovery steps.
				let nserror = error as NSError
				NSApplication.shared.presentError(nserror)
			}
		}
	}
}
