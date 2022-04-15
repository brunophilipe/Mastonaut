//
//  FocusedStatusTableCellView.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 25.05.19.
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

class FocusedStatusTableCellView: StatusTableCellView
{
	@IBOutlet private unowned var appNameConatiner: NSView!
	@IBOutlet private unowned var appNameLabel: NSButton!

	private var sourceApplication: Application? = nil

	private static let _authorLabelAttributes: [NSAttributedString.Key: AnyObject] = [
		.foregroundColor: NSColor.labelColor, .font: NSFont.systemFont(ofSize: 15, weight: .semibold)
	]

	private static let _statusLabelAttributes: [NSAttributedString.Key: AnyObject] = [
		.foregroundColor: NSColor.labelColor, .font: NSFont.labelFont(ofSize: 16),
		.underlineStyle: NSNumber(value: 0) // <-- This is a hack to prevent the label's contents from shifting
		// vertically when clicked.
	]

	private static let _statusLabelLinkAttributes: [NSAttributedString.Key: AnyObject] = [
		.foregroundColor: NSColor.safeControlTintColor,
		.font: NSFont.systemFont(ofSize: 16, weight: .medium),
		.underlineStyle: NSNumber(value: 1)
	]

	internal override func authorLabelAttributes() -> [NSAttributedString.Key: AnyObject]
	{
		return FocusedStatusTableCellView._authorLabelAttributes
	}

	internal override func statusLabelAttributes() -> [NSAttributedString.Key: AnyObject]
	{
		return FocusedStatusTableCellView._statusLabelAttributes
	}

	internal override func statusLabelLinkAttributes() -> [NSAttributedString.Key: AnyObject]
	{
		return FocusedStatusTableCellView._statusLabelLinkAttributes
	}

	override func set(displayedStatus status: Status,
					  poll: Poll?,
					  attachmentPresenter: AttachmentPresenting,
					  interactionHandler: StatusInteractionHandling,
					  activeInstance: Instance)
	{
		super.set(displayedStatus: status,
				  poll: poll,
				  attachmentPresenter: attachmentPresenter,
				  interactionHandler: interactionHandler,
				  activeInstance: activeInstance)

		setContentLabelsSelectable(true)

		if let application = status.application
		{
			sourceApplication = application
			appNameLabel.title = application.name
			appNameLabel.isEnabled = application.website != nil
			appNameConatiner.isHidden = false
		}
		else
		{
			appNameLabel.title = ""
			appNameConatiner.isHidden = true
		}
	}

	override func prepareForReuse()
	{
		super.prepareForReuse()

		sourceApplication = nil
	}

	@IBAction func showStatusApp(_ sender: Any?)
	{
		guard let applicationWebsite = sourceApplication?.website, let url = URL(string: applicationWebsite) else
		{
			return
		}

		NSWorkspace.shared.open(url)
	}
}
