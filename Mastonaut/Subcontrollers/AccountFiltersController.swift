//
//  AccountFiltersController.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 16.05.21.
//  Mastonaut - Mastodon Client for Mac
//  Copyright © 2021 Bruno Philipe.
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
import CoreTootin
import MastodonKit

class AccountFiltersController: NSObject {

	@IBOutlet weak var tableView: NSTableView!

	@objc dynamic
	private(set) var canEditFilter: Bool = false

	@objc dynamic
	private(set) var filters: NSArrayController = {
		let controller = NSArrayController()
		controller.selectsInsertedObjects = false
		return controller
	}()

	private var presentedFilterEditorWindowController: FilterEditorWindowController? = nil

	var account: AuthorizedAccount? = nil {
		didSet {
			filters.removeAllObjects()

			if let oldAccount = oldValue, let filterService = FilterService.service(for: oldAccount) {
				filterService.remove(observer: self)
			}

			guard let account = account, let filterService = FilterService.service(for: account) else { return }

			if let filters = filterService.filters {
				self.filters.content = NSMutableArray(array: filters.map(UserFilterWrapper.init))
			}

			filters.sortDescriptors = [NSSortDescriptor(key: "phrase", ascending: true)]

			filterService.register(observer: self)
		}
	}

	func setAccount(uuid: UUID?) {
		assert(Thread.isMainThread)

		guard let uuid = uuid else {
			account = nil
			return
		}

		account = AppDelegate.shared.accountsService.account(with: uuid)
	}

	@IBAction
	func showFilterCreator(_ sender: Any?) {
		startFilterEditor(with: nil)
	}

	@IBAction
	func confirmDeletingSelectedFilter(_ sender: Any?) {
		guard tableView.selectedRow >= 0,
			  let filter = (filters.arrangedObjects as? [UserFilterWrapper])?[tableView.selectedRow].filter,
			  let window = tableView.window else {
			return
		}

		let alert = NSAlert(style: .warning,
							title: 🔠("Attention"),
							message: 🔠("dialog.filter.delete.confirmation"))

		alert.addButton(withTitle: 🔠("Delete Filter"))
		alert.addButton(withTitle: 🔠("Cancel"))

		alert.beginSheetModal(for: window) { [weak self] response in
			switch response
			{
			case .alertFirstButtonReturn:
				self?.deleteFilter(filter)

			default:
				break
			}
		}
	}

	@IBAction
	func editSelectedFilter(_ sender: Any?) {
		guard tableView.selectedRow >= 0,
			  let wrapper = (filters.arrangedObjects as? [UserFilterWrapper])?[tableView.selectedRow]
		else {
			return
		}

		startFilterEditor(with: wrapper.filter)
	}

	private func startFilterEditor(with filter: UserFilter?) {
		let filterEditor = FilterEditorWindowController()

		guard let editorWindow = filterEditor.window else { return }

		filterEditor.mode = filter.map(FilterEditorWindowController.Mode.edit) ?? .create

		presentedFilterEditorWindowController = filterEditor

		filterEditor.dismissBlock = { [unowned self, unowned editorWindow] in
			self.tableView.window?.endSheet(editorWindow)
		}

		filterEditor.saveBlock = { [unowned self] filter, mode in
			guard let account = self.account, let filterService = FilterService.service(for: account) else { return }

			switch mode {
			case .create:
				filterService.create(filter: filter) { [weak self] result in
					DispatchQueue.main.async { [weak self] in
						self?.handleFilterCreateUpdateResponse(result: result)
					}
				}
			case .edit(let originalFilter):
				filterService.updateFilter(id: originalFilter.id, updatedFilter: filter) { [weak self] result in
					DispatchQueue.main.async { [weak self] in
						self?.handleFilterCreateUpdateResponse(result: result)
					}
				}
			}
		}

		tableView.window?.beginSheet(editorWindow)
	}

	private func handleFilterCreateUpdateResponse(result: Result<Filter>) {
		guard let editorWindow = presentedFilterEditorWindowController?.window else { return }

		switch result {
		case .success:
			tableView.window?.endSheet(editorWindow)
		case .failure(let error):
			editorWindow.presentError(error)
		}
	}

	private func deleteFilter(_ filter: UserFilter) {
		guard let account = account, let filterService = FilterService.service(for: account) else { return }

		filterService.delete(filter: filter) { [weak self] result in
			guard case .failure(let error) = result else { return }

			DispatchQueue.main.async {
				let alert = NSAlert(style: .warning,
									title: 🔠("Error"),
									message: 🔠("dialog.filter.delete.error", error.localizedDescription))

				alert.addButton(withTitle: 🔠("OK"))

				if let window = self?.tableView.window {
					alert.beginSheetModal(for: window, completionHandler: nil)
				} else {
					alert.runModal()
				}
			}
		}
	}
}

extension AccountFiltersController: FilterServiceObserver {
	func filterServiceDidUpdateFilters(_ filterService: FilterService) {
		guard let refreshedFilters = filterService.filters else {
			return
		}

		for filter in refreshedFilters.map(UserFilterWrapper.init) {
			if (filters.content as? NSArray)?.contains(filter) == false {
				filters.addObject(filter)
			}
		}

		for wrapper in filters.content as? [UserFilterWrapper] ?? [] {
			filters.removeObject(wrapper)
			if let refreshedFilter = refreshedFilters.first(where: { $0.id == wrapper.filter.id }) {
				filters.addObject(UserFilterWrapper(refreshedFilter))
			}
		}
	}
}

extension AccountFiltersController: NSTableViewDelegate {

	func tableViewSelectionDidChange(_ notification: Foundation.Notification) {
		canEditFilter = tableView.selectedRow >= 0
	}
}

extension NSArrayController {

	func removeAllObjects() {
		guard let count = (arrangedObjects as? NSArray)?.count, count > 0 else {
			return
		}

		remove(atArrangedObjectIndexes: IndexSet(integersIn: 0..<count))
	}
}

@objc
private class UserFilterWrapper: NSObject {
	let filter: UserFilter

	@objc
	override var hash: Int {
		return filter.id.hashValue
	}

	@objc
	var phrase: String {
		return filter.phrase
	}

	@objc
	var contextDescription: String {
		return filter.context.map(\.rawValue).joined(separator: ", ")
	}

	@objc
	var expiration: NSDate? {
		return filter.expiresAt as NSDate?
	}

	init(_ filter: UserFilter) {
		self.filter = filter
		super.init()
	}

	override func isEqual(_ object: Any?) -> Bool {
		guard let otherFilter = object as? UserFilterWrapper else {
			return super.isEqual(object)
		}

		return filter.id == otherFilter.filter.id
	}
}
