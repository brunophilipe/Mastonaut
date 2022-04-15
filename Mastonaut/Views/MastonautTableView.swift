//
//  MastonautTableView.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 16.06.20.
//  Mastonaut - Mastodon Client for Mac
//  Copyright © 2020 Bruno Philipe.
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
import Carbon

class MastonautTableView: NoInsetsTableView {

	override func resignFirstResponder() -> Bool {
		defer {
			(delegate as? MastonautTableViewDelegate)?.tableViewDidResignFirstResponder?(self)
		}
		return super.resignFirstResponder()
	}

	override func becomeFirstResponder() -> Bool {
		defer {
			(delegate as? MastonautTableViewDelegate)?.tableViewDidBecomeFirstResponder?(self)
		}
		return super.becomeFirstResponder()
	}
	
	override func scrollRowToVisible(_ row: Int) {
		NSAnimationContext.runAnimationGroup { context in
			context.allowsImplicitAnimation = true
			super.scrollRowToVisible(row)
		}
	}

	override func keyDown(with event: NSEvent) {

		switch Int(event.keyCode) {
		case kVK_DownArrow, kVK_UpArrow:
			guard selectedRowIndexes.first.flatMap({ isRowVisible($0) }) != true else {
				super.keyDown(with: event)
				return
			}
			selectFirstVisibleRow()

		case kVK_Space:
			if let delegate = self.delegate as? MastonautTableViewDelegate,
			   delegate.responds(to: #selector(MastonautTableViewDelegate.tableView(_:shouldTogglePreviewForRow:))),
			   let selectedRow = selectedRowIndexes.first {
				delegate.tableView?(self, shouldTogglePreviewForRow: selectedRow)
			} else {
				super.keyDown(with: event)
			}

		default:
			super.keyDown(with: event)
		}
	}

	func isRowVisible(_ row: Int) -> Bool {
		guard let rowView = rowView(atRow: row, makeIfNecessary: false) else {
			return false
		}

		return visibleRect.intersects(rowView.frame)
	}
}

@objc
protocol MastonautTableViewDelegate: NSTableViewDelegate {

	@objc
	optional func tableViewDidResignFirstResponder(_ tableView: MastonautTableView)

	@objc
	optional func tableViewDidBecomeFirstResponder(_ tableView: MastonautTableView)

	@objc
	optional func tableView(_ tableView: MastonautTableView, shouldTogglePreviewForRow rowIndex: Int)
}
