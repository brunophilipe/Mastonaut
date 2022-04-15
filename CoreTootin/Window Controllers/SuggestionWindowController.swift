//
//  SuggestionWindowController.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 10.06.19.
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

import Cocoa

public class SuggestionWindowController: NSWindowController
{
	@IBOutlet private(set) unowned var tableView: NSTableView!

	private var suggestions: [Suggestion]? = nil

	public weak var imagesProvider: SuggestionWindowImagesProvider? = nil

	public var isWindowVisible: Bool
	{
		return window?.isVisible ?? false
	}

	public var insertSuggestionBlock: ((Suggestion) -> Void)? = nil

	public convenience init()
	{
		self.init(windowNibName: NSNib.Name("SuggestionWindowController"))
	}

	public override func windowDidLoad()
	{
		super.windowDidLoad()

		tableView.target = self
		tableView.doubleAction = #selector(didDoubleClickTableView(_:))
	}

	public func positionWindow(under textRect: NSRect)
	{
		if let suggestionsCount = suggestions?.count
		{
			let visibleCount = CGFloat(min(suggestionsCount, 8))
			let bestHeight = visibleCount * (tableView.rowHeight + tableView.intercellSpacing.height)
			window?.setContentSize(NSSize(width: 482, height: bestHeight))
		}

		window?.setFrameTopLeftPoint(NSPoint(x: textRect.minX - 30, y: textRect.minY))
	}

	public func set(suggestions: [Suggestion])
	{
		self.suggestions = suggestions
		tableView?.reloadData()
		tableView?.selectRowAndScrollToVisible(0)
	}

	public func insertSelectedSuggestion()
	{
		let currentSelection = tableView.selectedRow

		guard
			let suggestions = self.suggestions,
			(0..<suggestions.count).contains(currentSelection),
			let block = insertSuggestionBlock
		else { return }

		block(suggestions[currentSelection])
	}

	@objc func didDoubleClickTableView(_ sender: Any)
	{
		insertSelectedSuggestion()
	}

	@IBAction func selectNext(_ sender: Any?)
	{
		guard let suggestions = self.suggestions else { return }
		let currentSelection = tableView.selectedRow

		guard (0..<suggestions.count).contains(currentSelection + 1) else
		{
			tableView.selectRowAndScrollToVisible(0)
			return
		}

		tableView.selectRowAndScrollToVisible(currentSelection + 1)
	}

	@IBAction func selectPrevious(_ sender: Any?)
	{
		guard let suggestions = self.suggestions else { return }
		let currentSelection = tableView.selectedRow

		guard currentSelection > 0 else
		{
			tableView.selectRowAndScrollToVisible(suggestions.count - 1)
			return
		}

		tableView.selectRowAndScrollToVisible(currentSelection - 1)
	}
}

extension SuggestionWindowController: NSTableViewDataSource
{
	public func numberOfRows(in tableView: NSTableView) -> Int
	{
		return suggestions?.count ?? 0
	}
}

extension SuggestionWindowController: NSTableViewDelegate
{
	public func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView?
	{
		guard let identifier = tableColumn?.identifier else { return nil }

		let view = tableView.makeView(withIdentifier: identifier, owner: nil)

		if let suggestion = suggestions?[row], let cellView = view as? NSTableCellView
		{
			switch identifier.rawValue
			{
			case "avatar":
				cellView.imageView?.image = #imageLiteral(resourceName: "missing.png")
				guard let imageURL = suggestion.imageUrl else { break }
				imagesProvider?.suggestionWindow(self, imageForSuggestionUsingURL: imageURL)
					{
						[weak self] image in
						guard let image = image else { return }
						DispatchQueue.main.async
							{
								self?.updateImage(for: suggestion, originalIndex: row, image: image)
							}
					}

			case "suggestion":
				cellView.textField?.stringValue = suggestion.text

			case "displayName":
				cellView.textField?.stringValue = suggestion.displayName

			default:
				break
			}
		}

		return view
	}

	private func updateImage(for suggestion: Suggestion, originalIndex: Int, image: NSImage)
	{
		guard
			let suggestions = self.suggestions,
			originalIndex < suggestions.count,
			suggestions[originalIndex].imageUrl == suggestion.imageUrl
		else { return }

		let view = tableView.view(atColumn: 0, row: originalIndex, makeIfNecessary: false)

		if let cellView = view as? NSTableCellView
		{
			cellView.imageView?.image = image
		}
	}
}

private extension NSTableView
{
	func selectRowAndScrollToVisible(_ row: Int)
	{
		selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
		scrollRowToVisible(row)
	}
}

@objc public protocol SuggestionWindowImagesProvider: AnyObject
{
	func suggestionWindow(_ windowController: SuggestionWindowController,
						  imageForSuggestionUsingURL: URL,
						  completion: @escaping (NSImage?) -> Void)
}
