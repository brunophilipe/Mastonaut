//
//  SearchResultsViewController.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 01.07.19.
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
import MastodonKit
import CoreTootin

class SearchResultsViewController<Element: AnyObject>: NSViewController, NSTableViewDataSource, NSTableViewDelegate, SearchResultsPresenter
{
	weak var delegate: SearchResultsPresenterDelegate?

	internal var elements: [Element] = []
	{
		didSet
		{
			tableView?.reloadData()
		}
	}

	private var currentSelection: SearchResultSelection?
	{
		let selectedRow = tableView.selectedRow

		guard (0..<elements.count).contains(selectedRow) else
		{
			return nil
		}

		return makeSelection(for: elements[selectedRow])
	}

	override func viewDidLoad()
	{
		super.viewDidLoad()

		tableView.doubleAction = #selector(SearchResultsViewController.didDoubleClickTableView(_:))
	}

	override func viewWillDisappear()
	{
		super.viewWillDisappear()
		tableView.deselectAll(nil)
	}

	@objc func didDoubleClickTableView(_ sender: Any?)
	{
		guard let selection = currentSelection else { return }
		delegate?.searchResultsPresenter(self, userDidDoubleClick: selection)
	}

	func set(results: ResultsType, instance: Instance)
	{
		fatalError("Should be overriden by concrete subclasses")
	}

	internal unowned var tableView: NSTableView!
	{
		fatalError("Should be overriden by concrete subclasses")
	}

	internal var cellIdentifier: NSUserInterfaceItemIdentifier
	{
		fatalError("Should be overriden by concrete subclasses")
	}

	internal func populate(cell: NSTableCellView, for element: Element)
	{
		fatalError("Should be overriden by concrete subclasses")
	}

	internal func makeSelection(for element: Element) -> SearchResultSelection
	{
		fatalError("Should be overriden by concrete subclasses")
	}

	internal func cellView(for element: Element, makeIfNecessary: Bool = false) -> NSTableCellView?
	{
		guard let index = elements.firstIndex(where: { $0 ?=== element }) else { return nil }
		return tableView.view(atColumn: 0, row: index, makeIfNecessary: makeIfNecessary) as? NSTableCellView
	}

	func numberOfRows(in tableView: NSTableView) -> Int
	{
		return elements.count
	}

	func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView?
	{
		guard let view = tableView.makeView(withIdentifier: cellIdentifier, owner: nil) as? NSTableCellView else
		{
			return nil
		}

		populate(cell: view, for: elements[row])

		return view
	}

	func tableViewSelectionDidChange(_ notification: Foundation.Notification)
	{
		guard let selection = currentSelection else
		{
			delegate?.searchResultsPresenter(self, userDidSelect: nil)
			return
		}

		delegate?.searchResultsPresenter(self, userDidSelect: selection)
	}
}
