//
//  TimelinesSplitViewController.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 04.04.20.
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
import CoreTootin

typealias SidebarViewController = NSViewController & SidebarPresentable

class TimelinesSplitViewController: NSSplitViewController {

	private var didInitialize = false

	var preserveSplitViewSizeForNextSidebarInstall = false

	var sidebarViewController: SidebarViewController? = nil {
		didSet {
			switch (oldValue, sidebarViewController) {
			case (.none, .some(let viewController)):
				showSidebar(viewController)
			case (.some, .some(let viewController)):
				replaceSidebar(viewController)
			case (.some, .none):
				hideSidebar()
			default:
				break
			}
		}
	}

	private var isWindowFullScreen: Bool {
		return view.window?.styleMask.contains(.fullScreen) == true
	}

	private var sidebarCollapseBehavior: NSSplitViewItem.CollapseBehavior {
		guard preserveSplitViewSizeForNextSidebarInstall == false else {
			preserveSplitViewSizeForNextSidebarInstall = false
			return .preferResizingSiblingsWithFixedSplitView
		}

        guard isWindowFullScreen == false else {
            return .preferResizingSiblingsWithFixedSplitView
        }

		return Preferences.timelinesResizeMode == .expandWindowFirst ? .preferResizingSplitViewWithFixedSiblings
																	 : .preferResizingSiblingsWithFixedSplitView
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		splitViewItems.first?.minimumThickness = 320
		hideSidebar()
		didInitialize = true
	}

	private func showSidebar(_ viewController: SidebarViewController) {
		guard splitViewItems.count == 1 else {
			replaceSidebar(viewController)
			return
		}
		splitView.dividerStyle = .paneSplitter

		let splitViewItem = makeSidebarSplitViewItem(for: viewController)
		splitViewItem.isCollapsed = true
		insertSplitViewItem(splitViewItem, at: 1)

		splitViewItem.animator().isCollapsed = false

		viewController.activateKeyboardNavigation(preferredFocusRegion: nil)
	}

	private func replaceSidebar(_ viewController: SidebarViewController) {
		guard splitViewItems.count >= 1 else {
			showSidebar(viewController)
			return
		}

		splitViewItems.first!.holdingPriority = .required

		removeSplitViewItem(splitViewItems.last!)
		insertSplitViewItem(makeSidebarSplitViewItem(for: viewController), at: 1)
		splitView.dividerStyle = .paneSplitter

		splitViewItems.first!.holdingPriority = .defaultLow

		viewController.activateKeyboardNavigation(preferredFocusRegion: nil)
	}

	private func hideSidebar() {
		guard let splitViewItem = splitViewItems.last else { return }

		splitViewItems.first?.holdingPriority = isWindowFullScreen ? .defaultLow : .required
		splitView.dividerStyle = .thin

		splitViewItem.collapseBehavior = sidebarCollapseBehavior

		guard didInitialize else {
			removeSplitViewItem(splitViewItem)
			splitViewItems.first?.holdingPriority = .defaultLow
			return
		}

		NSAnimationContext.runAnimationGroup { (context) in
			splitViewItem.animator().isCollapsed = true
		} completionHandler: { [weak self] in
			guard let self = self else { return }
			self.splitViewItems.first?.holdingPriority = .defaultLow
			guard self.splitViewItems.last === splitViewItem else { return }
			self.removeSplitViewItem(splitViewItem)
		}
	}

	private func makeSidebarSplitViewItem(for viewController: NSViewController) -> NSSplitViewItem {
		let splitViewItem = NSSplitViewItem(viewController: viewController).with(holdingPriority: .defaultLow)
		splitViewItem.collapseBehavior = sidebarCollapseBehavior
		splitViewItem.minimumThickness = 320
		return splitViewItem
	}

	override func splitView(_ splitView: NSSplitView, shouldHideDividerAt dividerIndex: Int) -> Bool {
		return splitViewItems.count == 1
	}
}

private extension NSSplitViewItem {

	func with(holdingPriority: NSLayoutConstraint.Priority) -> NSSplitViewItem {
		self.holdingPriority = holdingPriority
		return self
	}
}

private class EmptyViewController: NSViewController {

	init() {
		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder: NSCoder) {
		super.init(coder: coder)
	}

	override func loadView() {
		view = NSView()
	}
}
