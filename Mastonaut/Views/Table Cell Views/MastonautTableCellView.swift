//
//  BackgroundTableCellView.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 14.05.19.
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

protocol LazyMenuProviding
{
	var menuItemsProvider: (() -> [NSMenuItem]?)? { get set }
}

class MastonautTableCellView: NSTableCellView, LazyMenuProviding, Selectable
{
	@IBInspectable
	var backgroundColor = NSColor(named: "TableCellBackground")!
	var selectedBackgroundColor = NSColor(named: "SelectedTableCellBackground")!

	var menuItemsProvider: (() -> [NSMenuItem]?)?

	var isSelected: Bool = false {
		didSet {
			updateEffectiveBackgroundColor()
			needsDisplay = true
		}
	}

	override func updateLayer()
	{
		super.updateLayer()

		if backgroundLayer.superlayer == nil
		{
			layer?.insertSublayer(backgroundLayer, at: 0)
		}

		updateEffectiveBackgroundColor()
	}

	private lazy var backgroundLayer: CALayer = CALayer()

	override func layout()
	{
		super.layout()
		CATransaction.begin()
		CATransaction.setDisableActions(true)
		backgroundLayer.frame = bounds
		CATransaction.commit()
	}

	private func updateEffectiveBackgroundColor()
	{
		let color = isSelected ? selectedBackgroundColor : backgroundColor
		backgroundLayer.backgroundColor = color.cgColor
	}

	override var menu: NSMenu?
	{
		set(menu)
		{
			super.menu = menu
		}

		get
		{
			guard let menuItems = menuItemsProvider?() else { return super.menu }

			let menu = NSMenu(title: "")
			menu.setItems(menuItems)
			return menu
		}
	}
}
