//
//  TogglingTextField.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 07.06.19.
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
class InsetTextFieldCell: NSTextFieldCell
{
	@IBInspectable var insetLeft: CGFloat = 0
	@IBInspectable var insetRight: CGFloat = 0
	@IBInspectable var insetTop: CGFloat = 0
	@IBInspectable var insetBottom: CGFloat = 0

	private var contentInset: NSSize
	{
		return NSSize(width: insetLeft + insetRight,
					  height: insetTop + insetBottom)
	}

	override func cellSize(forBounds rect: NSRect) -> NSSize
	{
		var size = super.cellSize(forBounds: rect)
		size.height += contentInset.height * 2
		return size
	}

	override func titleRect(forBounds rect: NSRect) -> NSRect
	{
		return rect.insetBy(left: insetLeft, right: insetRight,
							top: insetTop, bottom: insetBottom)
	}

	override func edit(withFrame rect: NSRect, in controlView: NSView,
					   editor textObj: NSText, delegate: Any?, event: NSEvent?)
	{
		let insetRect = rect.insetBy(left: insetLeft, right: insetRight,
									 top: insetTop, bottom: insetBottom)

		super.edit(withFrame: insetRect, in: controlView,
				   editor: textObj, delegate: delegate, event: event)
	}

	override func select(withFrame rect: NSRect, in controlView: NSView,
						 editor textObj: NSText, delegate: Any?, start selStart: Int, length selLength: Int)
	{
		let insetRect = rect.insetBy(left: insetLeft, right: insetRight,
									 top: insetTop, bottom: insetBottom)

		super.select(withFrame: insetRect, in: controlView, editor: textObj,
					 delegate: delegate, start: selStart, length: selLength)
	}

	override func drawInterior(withFrame cellFrame: NSRect, in controlView: NSView)
	{
		let insetRect = cellFrame.insetBy(left: insetLeft, right: insetRight,
										  top: insetTop, bottom: insetBottom)

		super.drawInterior(withFrame: insetRect, in: controlView)
	}
}

extension NSRect
{
	nonmutating func insetBy(left: CGFloat, right: CGFloat, top: CGFloat, bottom: CGFloat) -> NSRect
	{
		var rect = self
		rect.origin.x += left
		rect.origin.y += top
		rect.size.width -= left + right
		rect.size.height -= top + bottom
		return rect
	}
}
