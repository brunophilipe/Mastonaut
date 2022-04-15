//
//  ToolbarWindow.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 25.01.19.
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

class ToolbarWindow: NSWindow
{
	lazy var titlebarContainerView: NSView? =
		{
			contentView?.superview?.findTitlebarContainerView()
				// If we're on full screen, then the titlebar actually lives in a separate NSWindow
				?? standardWindowButton(.closeButton)?.window?.contentView?.findTitlebarContainerView()
		}()

	lazy var toolbarView: NSView? =
		{
			titlebarContainerView?.findSubview(withClassName: "NSToolbarView")
		}()

	override func toggleToolbarShown(_ sender: Any?) {
		super.toggleToolbarShown(sender)
		(windowController as? ToolbarWindowController)?.didToggleToolbarShown(self)
	}
}

private extension NSView
{
	func findTitlebarContainerView() -> NSView?
	{
		return findSubview(withClassName: "NSTitlebarContainerView", recursive: false)
	}
}

protocol ToolbarWindowController {

	/// Called when the toolbar is toggled between being shown or not
	/// - Parameter window: The sender window
	func didToggleToolbarShown(_ window: ToolbarWindow)
}
