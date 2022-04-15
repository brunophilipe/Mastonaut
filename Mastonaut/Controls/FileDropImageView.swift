//
//  FileDropImageView.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 26.02.19.
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

class FileDropImageView: NSImageView
{
	var allowedDropFileTypes: [CFString]? = nil

	private(set) var isReceivingDrag: Bool = false
	{
		didSet
		{
			layer?.cornerRadius = 6.0
			layer?.backgroundColor = isReceivingDrag ? NSColor.safeControlTintColor.withAlphaComponent(0.5).cgColor
													 : nil
		}
	}

	required init?(coder: NSCoder)
	{
		super.init(coder: coder)

		registerForDraggedTypes([.fileURL])
	}

	private var filteringOptions: [NSPasteboard.ReadingOptionKey: Any]?
	{
		guard let types = allowedDropFileTypes else { return nil }
		return [.urlReadingContentsConformToTypes: types]
	}

	override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation
	{
		guard isEnabled, sender.draggingPasteboard.canReadObject(forClasses: [NSURL.self], options: filteringOptions) else
		{
			return NSDragOperation()
		}

		isReceivingDrag = true

		return .copy
	}

	override func draggingExited(_ sender: NSDraggingInfo?)
	{
		isReceivingDrag = false
	}

	override func performDragOperation(_ sender: NSDraggingInfo) -> Bool
	{
		guard let target = target, let action = action else { return false }
		target.performSelector(onMainThread: action, with: sender, waitUntilDone: false)
		return true
	}

	override func concludeDragOperation(_ sender: NSDraggingInfo?)
	{
		isReceivingDrag = false
	}
}
