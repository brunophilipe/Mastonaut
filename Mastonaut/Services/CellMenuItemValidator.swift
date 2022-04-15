//
//  CellMenuItemHandler.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 03.09.20.
//  Copyright © 2020 Bruno Philipe. All rights reserved.
//

import Foundation
import CoreTootin

class CellMenuItemHandler {

	unowned let tableView: NSTableView
	unowned let interactionHandler: StatusInteractionHandling

	init(tableView: NSTableView, interactionHandler: StatusInteractionHandling) {
		self.tableView = tableView
		self.interactionHandler = interactionHandler
	}

	func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {

		guard let selectedIndex = tableView.selectedRowIndexes.first,
			  let view = tableView.view(atColumn: 0, row: selectedIndex, makeIfNecessary: false),
			  let cellView = view as? StatusTableCellView,
			  let cellModel = cellView.cellModel
		else {
			return false
		}

		switch menuItem.action {
		case #selector(favoriteSelectedStatus(_:)):
			menuItem.title = cellModel.isFavorited == true ? 🔠("status.action.favorite.undo")
														   : 🔠("status.action.favorite")

		case #selector(reblogSelectedStatus(_:)):
			menuItem.title = cellModel.isReblogged == true ? 🔠("status.action.reblog.undo")
														   : 🔠("status.action.reblog")

		case #selector(toggleMediaVisibilityOfSelectedStatus(_:)):
			menuItem.title = cellView.isMediaHidden ? 🔠("status.action.media")
													: 🔠("status.action.media.undo")

			return cellView.hasMedia

		case #selector(toggleContentVisibilityOfSelectedStatus(_:)):
			menuItem.title = cellView.isContentHidden ? 🔠("status.action.content")
													  : 🔠("status.action.content.undo")

			return cellView.hasSpoiler

		case #selector(replyToSelectedStatus(_:)),
			 #selector(showDetailsOfSelectedStatus(_:)):
			break

		default:
			return false
		}

		return true
	}

	private func selectedCellView() -> StatusTableCellView? {
		guard let selectedRow = tableView.selectedRowIndexes.first,
			  let cellView = tableView.view(atColumn: 0, row: selectedRow, makeIfNecessary: false)
		else { return nil }

		return cellView as? StatusTableCellView
	}

	private func selectedCellViewModel() -> StatusCellModel? {
		return selectedCellView()?.cellModel
	}

	@objc
	func favoriteSelectedStatus(_ sender: Any?) {
		guard let cellModel = selectedCellViewModel() else { return }

		if cellModel.isFavorited {
			cellModel.handle(interaction: .unfavorite)
		} else {
			cellModel.handle(interaction: .favorite)
		}
	}

	@objc
	func reblogSelectedStatus(_ sender: Any?) {
		guard let cellModel = selectedCellViewModel() else { return }

		if cellModel.isReblogged {
			cellModel.handle(interaction: .unreblog)
		} else {
			cellModel.handle(interaction: .reblog)
		}
	}

	@objc
	func replyToSelectedStatus(_ sender: Any?) {
		selectedCellViewModel()?.handle(interaction: .reply)
	}

	@objc
	func toggleMediaVisibilityOfSelectedStatus(_ sender: Any?) {
		selectedCellView()?.toggleMediaVisibility()
	}

	@objc
	func toggleContentVisibilityOfSelectedStatus(_ sender: Any?) {
		selectedCellView()?.toggleContentVisibility()
	}

	@objc
	func showDetailsOfSelectedStatus(_ sender: Any?) {
		guard let cellModel = selectedCellViewModel() else { return }
		interactionHandler.show(status: cellModel.status)
	}
}
