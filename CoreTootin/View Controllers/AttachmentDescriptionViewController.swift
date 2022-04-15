//
//  AttachmentDescriptionViewController.swift
//  CoreTootin
//
//  Created by Bruno Philipe on 20.09.19.
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

class AttachmentDescriptionViewController: NSViewController
{
	@IBOutlet private(set) weak var imageDescriptionPopover: NSPopover!
	@IBOutlet private(set) weak var imageDescriptionPopoverTextField: NSTextField!
	@IBOutlet private(set) weak var imageDescriptionCountLabel: NSTextField!
	@IBOutlet private(set) weak var imageDescriptionButton: NSButton!
	@IBOutlet private(set) weak var imageDescriptionFailureIndicator: NSView!

	var descriptionStringValueDidChangeHandler: (() -> Void)?
	var didClickSubmitChangeHandler: (() -> Void)?

	override var nibBundle: Bundle?
	{
		return Bundle(for: AttachmentDescriptionViewController.self)
	}

	override var nibName: NSNib.Name?
	{
		return "AttachmentDescriptionViewController"
	}

	var descriptionStringValue: String
	{
		return imageDescriptionPopoverTextField.stringValue
	}

	func set(description: String, hasError: Bool)
	{
		imageDescriptionPopoverTextField.stringValue = description
		imageDescriptionFailureIndicator.isHidden = !hasError
	}

	func set(remainingCount: Int)
	{
		imageDescriptionCountLabel.integerValue = remainingCount
		imageDescriptionCountLabel.textColor = .labelColor(for: remainingCount)
	}

	func set(submitEnabled: Bool)
	{
		imageDescriptionButton.isEnabled = submitEnabled
	}

	func showPopover(relativeTo frame: CGRect, of view: NSView)
	{
		imageDescriptionPopover.show(relativeTo: frame, of: view, preferredEdge: .maxY)
	}
}

extension AttachmentDescriptionViewController
{
	@IBAction func clickedApplyDescriptionButton(_ sender: Any?)
	{
		imageDescriptionPopover.performClose(sender)
		didClickSubmitChangeHandler?()
	}
}

extension AttachmentDescriptionViewController: NSTextFieldDelegate
{
	public func controlTextDidChange(_ notification: Foundation.Notification)
	{
		if (notification.object as? NSTextField) === imageDescriptionPopoverTextField
		{
			descriptionStringValueDidChangeHandler?()
		}
	}
}
