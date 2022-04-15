//
//  InstancePickerWindowController.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 29.12.18.
//  Mastonaut - Mastodon Client for Mac
//  Copyright © 2018 Bruno Philipe.
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
import MastodonKit
import CoreTootin

class InstancePickerWindowController: NSWindowController, NSWindowDelegate
{
	@IBOutlet private unowned var nextButton: NSButton!
	@IBOutlet private unowned var cancelButton: NSButton!
	@IBOutlet private unowned var domainTextField: NSTextField!
	@IBOutlet private unowned var validDomainImageView: NSImageView!
	@IBOutlet private unowned var progressIndicator: NSProgressIndicator!

	@IBOutlet private unowned var instanceControlsStackView: NSStackView!

	@IBOutlet private unowned var instanceInfoContainerView: NSView!
	@IBOutlet private unowned var instanceImageView: NSImageView!
	@IBOutlet private unowned var instanceNameLabel: NSTextField!
	@IBOutlet private unowned var instanceInfoLabel: AttributedLabel!
	@IBOutlet private unowned var instanceInfoDisclosureButton: NSButton!
	@IBOutlet private unowned var instanceStatusCountLabel: NSTextField!
	@IBOutlet private unowned var instanceUserCountLabel: NSTextField!
	@IBOutlet private unowned var instanceVersionLabel: NSTextField!

	@IBOutlet private unowned var instanceInfoPopover: NSPopover!
	@IBOutlet private unowned var instanceInfoPopoverLabel: NSTextView!

	@IBOutlet private unowned var instancesTableView: NSTableView!

	@IBOutlet private unowned var errorPlaceholderView: NSView!

	public weak var delegate: InstancePickerWindowControllerDelegate? = nil

	private let directoryService = DirectoryService(urlSession: AppDelegate.shared.clientsUrlSession)
	private var directory: [DirectoryService.Instance]? = nil
	{
		didSet
		{
			instancesTableView.reloadData()
			setErrorPlaceholder(visible: false)
		}
	}
	
	@objc public dynamic var currentInstanceDomain: String = ""
	
	private var observations: [NSKeyValueObservation] = []

	private lazy var resourcesFetcher = ResourcesFetcher(urlSession: AppDelegate.shared.resourcesUrlSession)

	private static let infoLabelAttributes: [NSAttributedString.Key: AnyObject] = [
		.foregroundColor: NSColor.labelColor, .font: NSFont.labelFont(ofSize: 14),
		.underlineStyle: NSNumber(value: 0) // <-- This is a hack to prevent the label's contents from shifting
		// vertically when clicked.
	]

	private static let infoLabelLinkAttributes: [NSAttributedString.Key: AnyObject] = [
		.foregroundColor: NSColor.safeControlTintColor,
		.font: NSFont.systemFont(ofSize: 14, weight: .medium),
		.underlineStyle: NSNumber(value: 1)
	]

	private static let infoPopoverLabelLinkAttributes: [NSAttributedString.Key: AnyObject] = [
		.foregroundColor: NSColor.labelColor,
		.font: NSFont.systemFont(ofSize: 14, weight: .medium),
		.underlineStyle: NSNumber(value: 1)
	]
	
	private var isCurrentInstanceDomainValid: Bool = false
	{
		didSet
		{
			let isValid = isCurrentInstanceDomainValid
			nextButton.isEnabled = isValid
			progressIndicator.stopAnimation(nil)
			validDomainImageView.image = isValid ? #imageLiteral(resourceName: "round_check") : #imageLiteral(resourceName: "round_cross")
		}
	}

	private var currentInstanceInfo: AuthController.ValidInstance? = nil
	{
		didSet
		{
			guard let info = currentInstanceInfo else
			{
				instanceControlsStackView.setArrangedSubview(instanceInfoContainerView, hidden: true, animated: true)
				return
			}

			updateInstanceInfoControls(info)
			instanceControlsStackView.setArrangedSubview(instanceInfoContainerView, hidden: false, animated: true)
		}
	}
	
	override var windowNibName: NSNib.Name?
	{
		return "InstancePickerWindowController"
	}
	
	override func windowDidLoad()
	{
		super.windowDidLoad()
		
		nextButton.isEnabled = false
		validDomainImageView.image = nil
		
		observations.append(observe(\InstancePickerWindowController.currentInstanceDomain)
		{
			(_, _) in self.waitAndValidateDomain()
		})

		instanceInfoContainerView.isHidden = true
		instanceInfoLabel.linkTextAttributes = InstancePickerWindowController.infoLabelLinkAttributes
		instanceInfoLabel.linkHandler = self
		instanceInfoPopoverLabel.linkTextAttributes = InstancePickerWindowController.infoPopoverLabelLinkAttributes
		instanceInfoPopoverLabel.textContainerInset = NSSize(width: 12, height: 12)

		instancesTableView.register(NSNib(nibNamed: "InstanceTableCellView", bundle: .main),
									forIdentifier: CellViewIdentifier.instance)

		loadInstanceList()
	}

	deinit
	{
		InstancePickerWindowController.cancelPreviousPerformRequests(withTarget: self)
	}

	private func loadInstanceList()
	{
		directoryService.fetch()
			{
				[weak self] (result) in

				if case .success(let instances) = result
				{
					DispatchQueue.main.async {
						let blockedDomains = AuthController.blockedDomains
						self?.directory = instances.filter({ blockedDomains.contains($0.name) == false })
					}
				}
				else
				{
					DispatchQueue.main.async { self?.setErrorPlaceholder(visible: true) }
				}
			}
	}

	private func setErrorPlaceholder(visible: Bool)
	{
		instancesTableView.enclosingScrollView?.isHidden = visible
		errorPlaceholderView.isHidden = !visible
	}

	private func waitAndValidateDomain()
	{
		nextButton.isEnabled = false
		progressIndicator.startAnimation(nil)

		InstancePickerWindowController.cancelPreviousPerformRequests(withTarget: self,
																	 selector: #selector(validateDomain), object: nil)
		perform(#selector(validateDomain), with: nil, afterDelay: 0.66)
	}

	@objc func validateDomain()
	{
		AppDelegate.shared.authController.checkValidInstanceDomain(currentInstanceDomain)
		{
			[weak self] result in
			
			DispatchQueue.main.async
			{
				guard let self = self else { return }

				switch result
				{
				case .failure:
					self.currentInstanceInfo = nil
					self.isCurrentInstanceDomainValid = false

				case .success(let instanceInfo):
					self.currentInstanceInfo = instanceInfo
					self.isCurrentInstanceDomainValid = true
				}
			}
		}
	}

	private func updateInstanceInfoControls(_ instance: AuthController.ValidInstance)
	{
		guard let info = instance.instance else {
			instanceNameLabel.stringValue = instance.baseURL.host ?? instance.baseURL.absoluteString
			instanceInfoLabel.stringValue = 🔠("instance.info.no-info")

			instanceStatusCountLabel.stringValue = "?"
			instanceUserCountLabel.stringValue = "?"
			instanceVersionLabel.stringValue = "?"

			instanceImageView.image = #imageLiteral(resourceName: "missing")
			return
		}

		instanceNameLabel.stringValue = info.title
		instanceInfoLabel.set(attributedStringValue: info.attributedDescription,
							  applyingAttributes: InstancePickerWindowController.infoLabelAttributes)

		instanceStatusCountLabel.stringValue = (info.stats?.statusCount).map { "\($0)" } ?? "?"
		instanceUserCountLabel.stringValue = (info.stats?.userCount).map { "\($0)" } ?? "?"
		instanceVersionLabel.stringValue = info.version ?? "< 1.3.0"

		instanceImageView.image = #imageLiteral(resourceName: "missing")

		guard let imageUrl = info.thumbnail else
		{
			instanceImageView.isHidden = true
			return
		}

		resourcesFetcher.fetchImage(with: imageUrl)
			{
				[weak self] (result) in

				DispatchQueue.main.async
					{
						switch result
						{
						case .success(let image):
							self?.instanceImageView.image = image

						case .failure, .emptyResponse:
							self?.instanceImageView.isHidden = true
						}
					}
			}
	}

	fileprivate struct CellViewIdentifier
	{
		static let instance = NSUserInterfaceItemIdentifier("instance")
	}
}

extension InstancePickerWindowController: AttributedLabelLinkHandler
{
	func handle(linkURL: URL)
	{
		NSWorkspace.shared.open(linkURL)
	}
}

extension InstancePickerWindowController: NSTextFieldDelegate
{
	func controlTextDidChange(_ obj: Foundation.Notification)
	{
		instancesTableView.deselectAll(nil)
	}
}

extension InstancePickerWindowController // Actions
{
	@IBAction func cancel(_ sender: Any?)
	{
		window?.dismissSheetOrClose(modalResponse: .cancel)
	}
	
	@IBAction func next(_ sender: Any?)
	{
		if let window = self.window, let instanceURI = currentInstanceInfo?.baseURL.host
		{
			let baseDomain = URL(string: instanceURI)?.host ?? instanceURI
			delegate?.authWindow(window, didPickValidBaseDomain: baseDomain)
		}

		window?.dismissSheetOrClose(modalResponse: .continue)
	}

	@IBAction func showInfoPopover(_ sender: NSButton)
	{
		instanceInfoPopoverLabel.undoManager?.removeAllActions()
		instanceInfoPopoverLabel.textStorage?.setAttributedString(instanceInfoLabel.attributedStringValue)
		instanceInfoPopover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .maxX)
	}

	@IBAction func reloadInstanceList(_ sender: NSButton)
	{
		loadInstanceList()
	}
}

extension InstancePickerWindowController: NSTableViewDataSource, NSTableViewDelegate
{
	func numberOfRows(in tableView: NSTableView) -> Int
	{
		return directory?.count ?? 0
	}

	func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView?
	{
		let cellView = tableView.makeView(withIdentifier: CellViewIdentifier.instance, owner: nil)

		if let instance = directory?[row], let instanceCellView = cellView as? InstanceTableCellView
		{
			instanceCellView.set(instance: instance)
		}

		return cellView
	}

	func tableViewSelectionDidChange(_ notification: Foundation.Notification)
	{
		let selectedRow = instancesTableView.selectedRow

		guard selectedRow >= 0, let instance = directory?[selectedRow] else { return }

		currentInstanceDomain = instance.name
	}
}

protocol InstancePickerWindowControllerDelegate: AnyObject
{
	func authWindow(_ window: NSWindow, didPickValidBaseDomain: String)
}
