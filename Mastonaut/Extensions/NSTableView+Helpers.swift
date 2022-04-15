//
//  NSTableView+Helpers.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 10.11.19.
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

extension NSTableView
{
	func insertRowsAnimatingIfVisible(at rowIndices: IndexSet)
	{
		guard rowIndices.count > 0 else { return }

		let visibleRows = rows(in: visibleRect)
		let firstRowVisible = visibleRows.contains(rowIndices.first!)

		insertRows(at: rowIndices, withAnimation: firstRowVisible ? .effectGap : [])

		if !firstRowVisible, rowIndices.max()! < visibleRows.lowerBound,
			let contentView = enclosingScrollView?.contentView
		{
			let count = CGFloat(rowIndices.count)
			contentView.bounds.origin.y += (rowHeight + intercellSpacing.height) * count
		}
	}

	func removeRowsAnimatingIfVisible(at rowIndices: IndexSet)
	{
		guard rowIndices.count > 0 else { return }

		let visibleRows = rows(in: visibleRect)
		let anyRowVisible = rowIndices.first(where: { visibleRows.contains($0) }) != nil
		let removedRowsHeight = effectiveScrollHeightForRows(at: rowIndices)

		removeRows(at: rowIndices, withAnimation: anyRowVisible ? .effectFade : [])

		if !anyRowVisible, let contentView = enclosingScrollView?.contentView
		{
			contentView.bounds.origin.y -= removedRowsHeight
		}
	}

	func selectFirstVisibleRow(byExtendingSelection extendSelection: Bool = false) {
		let visibleRectMinY = visibleRect.minY
		var topmostVisibleRow: (minY: CGFloat, index: Int) = (.greatestFiniteMagnitude, -1)

		enumerateAvailableRowViews { (rowView, rowIndex) in
			let minY = rowView.frame.minY
			if minY >= max(visibleRectMinY - 1, 0), minY < topmostVisibleRow.minY,
			   delegate?.tableView?(self, shouldSelectRow: rowIndex) != false {
				topmostVisibleRow = (minY, rowIndex)
			}
		}

		if topmostVisibleRow.index > -1 {
			selectRowIndexes(IndexSet(integer: topmostVisibleRow.index), byExtendingSelection: extendSelection)
		}
	}

	private func effectiveScrollHeightForRows(at indexSet: IndexSet) -> CGFloat
	{
		return indexSet.reduce(CGFloat(0)) { $0 + effectiveHeight(forRowView: $1) + intercellSpacing.height }
	}

	private func effectiveHeight(forRowView row: Int) -> CGFloat
	{
		return view(atColumn: 0, row: row, makeIfNecessary: false)?.frame.height ?? rowHeight
	}
}
