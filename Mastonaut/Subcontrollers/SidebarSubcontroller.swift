//
//  SidebarSubcontroller.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 14.04.19.
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

protocol SidebarContainer: AnyObject
{
	var client: ClientType? { get }
	var currentAccount: AuthorizedAccount? { get }
	var currentInstance: Instance? { get }
	var sidebarViewController: SidebarViewController? { get set }

	func willInstallSidebar(viewController: NSViewController)
	func didInstallSidebar(viewController: NSViewController, with mode: SidebarMode)
	func didUpdateSidebar(viewController: NSViewController, previousViewController: NSViewController, with mode: SidebarMode)
	func willUninstallSidebar(viewController: NSViewController)
	func didUninstallSidebar(viewController: NSViewController)
}

class SidebarSubcontroller
{
	private unowned let sidebarContainer: SidebarContainer
	private unowned let navigationControl: NSSegmentedControl

	private(set) var navigationStack: NavigationStack<SidebarMode>?

	private(set) var sidebarMode: SidebarMode?
	{
		set
		{
			NSAnimationContext.runAnimationGroup { animationContext in
				animationContext.allowsImplicitAnimation = true
				setSidebarController(from: newValue)
			}
		}

		get
		{
			return sidebarContainer.sidebarViewController?.sidebarModelValue as? SidebarMode
		}
	}

	init(sidebarContainer: SidebarContainer,
		 navigationControl: NSSegmentedControl,
		 navigationStack: NavigationStack<SidebarMode>?)
	{
		self.sidebarContainer = sidebarContainer
		self.navigationControl = navigationControl
		self.navigationStack = navigationStack

		navigationControl.target = self
		navigationControl.action = #selector(navigateSidebar(_:))

		if let currentMode = navigationStack?.currentItem
		{
			sidebarMode = currentMode
		}
	}

	func installSidebar(mode: SidebarMode)
	{
		guard sidebarMode != mode else { return }

		if let navigationStack = self.navigationStack
		{
			navigationStack.set(currentItem: mode)
		}
		else
		{
			navigationStack = NavigationStack(currentItem: mode)
		}

		sidebarMode = mode
	}

	func uninstallSidebar()
	{
		navigationStack = nil
		sidebarMode = nil
	}

	private func setSidebarController(from sidebarMode: SidebarMode?)
	{
		updateNavigationSegmentedControlState()

		guard self.sidebarMode != sidebarMode else
		{
			return
		}

		guard let sidebarMode = sidebarMode else
		{
			let viewController = sidebarContainer.sidebarViewController

			viewController.map { sidebarContainer.willUninstallSidebar(viewController: $0) }
			navigationStack = nil
			sidebarContainer.sidebarViewController = nil
			viewController.map { sidebarContainer.didUninstallSidebar(viewController: $0) }
			return
		}

		guard let client = sidebarContainer.client, let instance = sidebarContainer.currentInstance else
		{
			return
		}

		let oldValue = self.sidebarMode
		let account = sidebarContainer.currentAccount

		let oldViewController = sidebarContainer.sidebarViewController
		let viewController = sidebarMode.makeViewController(client: client,
															currentAccount: account,
															currentInstance: instance)

		sidebarContainer.sidebarViewController = viewController

		if oldValue == nil
		{
			sidebarContainer.willInstallSidebar(viewController: viewController)
		}

		if AppDelegate.shared.appIsReady
		{
			sidebarContainer.sidebarViewController?.client = client
		}

		if oldValue == nil
		{
			sidebarContainer.didInstallSidebar(viewController: viewController, with: sidebarMode)
		}
		else if let oldViewController = oldViewController
		{
			sidebarContainer.didUpdateSidebar(viewController: viewController,
											  previousViewController: oldViewController,
											  with: sidebarMode)
		}
	}

	private func updateNavigationSegmentedControlState()
	{
		navigationControl.setEnabled(navigationStack?.canGoBackward ?? false, forSegment: 0)
		navigationControl.setEnabled(navigationStack?.canGoForward ?? false, forSegment: 1)
	}

	@objc private func navigateSidebar(_ sender: NSSegmentedControl)
	{
		guard let navigationStack = self.navigationStack else { return }

		switch sender.selectedSegment
		{
		case 0:
			sidebarMode = navigationStack.goBack()

		case 1:
			sidebarMode = navigationStack.goForward()

		default:
			break
		}
	}
}
