//
//  AttachmentItem.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 05.02.19.
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

public class AttachmentItem: NSCollectionViewItem
{
	var descriptionButtonAction: (() -> Void)? = nil
	var removeButtonAction: (() -> Void)? = nil

	@IBOutlet private weak var itemImageView: AttachmentImageView!
	@IBOutlet private weak var itemDetailIcon: NSImageView!
	@IBOutlet private weak var itemDetailLabel: NSTextField!
	@IBOutlet private weak var itemDetailContainer: NSView!
	@IBOutlet private weak var failureIndicatorImageView: NSImageView!

	@IBOutlet private weak var showDescriptionEditorButton: NSButton!

	@IBOutlet private weak var progressIndicator: NSProgressIndicator!
	@IBOutlet private weak var descriptionProgressIndicator: NSProgressIndicator!

	var displayedItemHashValue: Int? = nil

	public override var nibBundle: Bundle?
	{
		return Bundle(for: AttachmentItem.self)
	}

	var hasFailure: Bool = false
	{
		didSet { failureIndicatorImageView.isHidden = !hasFailure }
	}

	var isPendingSetDescription: Bool = false
	{
		didSet
		{
			if isPendingSetDescription
			{
				descriptionProgressIndicator.startAnimation(nil)
				showDescriptionEditorButton.isEnabled = false
			}
			else
			{
				descriptionProgressIndicator.stopAnimation(nil)
				showDescriptionEditorButton.isEnabled = true
			}
		}
	}

	public override func awakeFromNib()
	{
		super.awakeFromNib()

		itemImageView.unregisterDraggedTypes()
		failureIndicatorImageView.unregisterDraggedTypes()
		itemDetailIcon.unregisterDraggedTypes()
	}

	func set(progressIndicatorState state: UploadState)
	{
		switch state
		{
		case .waitingToUpload:
			progressIndicator.isIndeterminate = true
			progressIndicator.isHidden = false
			progressIndicator.startAnimation(nil)

		case .uploading(let progress):
			progressIndicator.stopAnimation(nil)
			progressIndicator.isIndeterminate = false
			progressIndicator.isHidden = false
			progressIndicator.doubleValue = progress * 100

		case .uploaded:
			progressIndicator.stopAnimation(nil)
			progressIndicator.isIndeterminate = false
			progressIndicator.isHidden = true
		}
	}

	func set(itemMetadata: Metadata?)
	{
		switch itemMetadata
		{
		case .some(.picture(let byteCount)):
			detailIcon = Bundle(for: AttachmentItem.self).image(forResource: "tiny_camera")
			detail = ByteCountFormatter().string(fromByteCount: byteCount)

		case .some(.movie(let duration)):
			detailIcon = Bundle(for: AttachmentItem.self).image(forResource: "tiny_film")
			detail = duration.formattedStringValue

		default:
			detailIcon = nil
			detail = nil
		}
	}

	var image: NSImage?
	{
		get { return itemImageView.image }
		set { itemImageView.image = newValue}
	}

	var detail: String?
	{
		get { return itemDetailLabel.stringValue }
		set
		{
			if let detail = newValue
			{
				itemDetailLabel.stringValue = detail
				itemDetailContainer.isHidden = false
			}
			else
			{
				itemDetailLabel.stringValue = ""
				itemDetailContainer.isHidden = true
			}
		}
	}

	var detailIcon: NSImage?
	{
		get { return itemDetailIcon.image }
		set { itemDetailIcon.image = newValue}
	}

	@IBAction private func descriptionButtonClicked(_ sender: Any?)
	{
		descriptionButtonAction?()
	}

	@IBAction private func removeButtonClicked(_ sender: Any?)
	{
		removeButtonAction?()
	}

	enum UploadState
	{
		case waitingToUpload
		case uploading(progress: Double)
		case uploaded
	}
}

class AttachmentItemImageView: NSImageView
{
	@IBInspectable
	var cornerRadius: CGFloat = 0.0
	{
		didSet
		{
			if let layer = self.layer
			{
				layer.cornerRadius = cornerRadius
			}
		}
	}
}

class ShowOnHoverView: HoverView
{
	required init?(coder: NSCoder)
	{
		super.init(coder: coder)
		alphaValue = 0.001
	}

	override func mouseEntered(with event: NSEvent)
	{
		super.mouseEntered(with: event)

		animator().alphaValue = 1.0
	}

	override func mouseExited(with event: NSEvent)
	{
		super.mouseExited(with: event)

		animator().alphaValue = 0.001
	}
}
