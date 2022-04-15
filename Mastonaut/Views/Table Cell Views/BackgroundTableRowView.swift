//
//  BackgroundTableRowView.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 27.01.19.
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

@IBDesignable
class BackgroundTableRowView: NSTableRowView
{
	@IBInspectable
	var customBackgroundColor: NSColor = .clear

	private var tableView: NSTableView? {
		return superview as? NSTableView
	}

	private var tableClipView: NSClipView? {
		return tableView?.enclosingScrollView?.contentView
	}

	var rowIndex: Int = -1

	override func updateLayer()
	{
		super.updateLayer()

		if backgroundLayer.superlayer == nil
		{
			layer?.insertSublayer(backgroundLayer, at: 0)
			backgroundColor = .clear
		}

		// FIXME: Remove once rdar://50772119 is resolved
		if let contentInsets = tableClipView?.contentInsets, let cellView = view(atColumn: 0) as? NSView,
		   frame.width + (contentInsets.left + contentInsets.right) != cellView.frame.width,
		   cellView.frame.height != frame.height - 2,
		   rowIndex >= 0 {
			tableView?.noteHeightOfRows(withIndexesChanged: IndexSet(integer: rowIndex))
		}

		updateEffectiveBackgroundColor()
	}

	private lazy var backgroundLayer: CALayer = CALayer()

	override func layout()
	{
		super.layout()
		CATransaction.begin()
		CATransaction.setDisableActions(true)
		backgroundLayer.frame = CGRect(x: 0, y: 1, width: frame.width, height: frame.height - 2)
		CATransaction.commit()
	}

	override var isSelected: Bool {
		didSet {
			for column in 0..<numberOfColumns {
				(view(atColumn: column) as? MastonautTableCellView)?.isSelected = isSelected
			}
		}
	}

	private func updateEffectiveBackgroundColor()
	{
		backgroundLayer.backgroundColor = customBackgroundColor.cgColor
	}
}
