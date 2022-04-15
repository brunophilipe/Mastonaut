//
//  AttachmentViewController.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 07.01.19.
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
import MastodonKit
import CoreTootin

class AttachmentViewController: NSViewController
{
	@IBOutlet private weak var firstImageView: AttachmentImageView?
	@IBOutlet private weak var secondImageView: AttachmentImageView?
	@IBOutlet private weak var thirdImageView: AttachmentImageView?
	@IBOutlet private weak var fourthImageView: AttachmentImageView?
	@IBOutlet private weak var moreLabel: NSTextField?

	private let resourcesFetcher = ResourcesFetcher(urlSession: AppDelegate.shared.resourcesUrlSession)

	private weak var attachmentPresenter: AttachmentPresenting?

	private var imageViewAttachmentMap = NSMapTable<NSControl, Attachment>(keyOptions: .weakMemory,
																		   valueOptions: .structPersonality)

	private(set) var sensitiveMedia: Bool

	private let coverView = CoverView(backgroundColor: #colorLiteral(red: 0.05655267835, green: 0.05655267835, blue: 0.05655267835, alpha: 1),
									  textColor: #colorLiteral(red: 0.9999966025, green: 1, blue: 1, alpha: 0.8470588235),
									  message: 🔠("Media Hidden: Click visibility button below to toggle display."))

	let attachmentGroup: AttachmentGroup

	var previewAttachments: [NSView] = []

	var isMediaHidden: Bool {
		return coverView.isHidden == false
	}

	override var nibName: NSNib.Name?
	{
		let count = attachmentGroup.attachmentCount

		switch count
		{
		case 1:		return "SingleAttachmentView"
		case 2:		return "DoubleAttachmentView"
		case 3:		return "TripleAttachmentView"
		case 4:		return "QuadrupleAttachmentView"
		case 5...:	return "MultipleAttachmentView"
		default:	return nil
		}
	}

	init(attachments: [Attachment], attachmentPresenter: AttachmentPresenting, sensitiveMedia: Bool, mediaHidden: Bool?)
	{
		self.attachmentGroup = AttachmentGroup(attachments: attachments)
		self.attachmentPresenter = attachmentPresenter
		self.sensitiveMedia = sensitiveMedia
		super.init(nibName: nil, bundle: nil)

		mediaHidden.map { setMediaHidden($0, animated: false) }
	}

	required init?(coder: NSCoder)
	{
		fatalError("init(coder:) has not been implemented")
	}

	override func viewDidLoad()
	{
		super.viewDidLoad()

		let imageViews = [firstImageView, secondImageView, thirdImageView, fourthImageView].compacted()

		setupCoverView()

		zip(attachmentGroup.attachments, imageViews).forEach
		{
			(attachment, imageView) in

			// If we don't have a meta size, we use a placeholder one that closely matches the best size on the UI.
			// This will avoid unecessary layout passes when the image is loaded and set to the image view.
			imageView.overrideContentSize = attachment.meta?.original?.size?.limit(width: 790, height: 460)
											?? NSSize(width: 395, height: 230)

			fetchImage(with: attachment.parsedPreviewUrl ?? attachment.parsedUrl,
					   fallbackUrl: attachment.parsedUrl,
					   from: attachment,
					   placingInto: imageView)

			if [.video, .gifv].contains(attachment.type)
			{
				let playGlyphView = NSButton(image: #imageLiteral(resourceName: "play_big"), target: self, action: #selector(presentAttachment(_:)))
				playGlyphView.bezelStyle = .regularSquare
				playGlyphView.isBordered = false
				playGlyphView.translatesAutoresizingMaskIntoConstraints = false
				view.addSubview(playGlyphView)
				previewAttachments.append(playGlyphView)

				NSLayoutConstraint.activate([
					imageView.leadingAnchor.constraint(equalTo: playGlyphView.leadingAnchor),
					imageView.trailingAnchor.constraint(equalTo: playGlyphView.trailingAnchor),
					imageView.topAnchor.constraint(equalTo: playGlyphView.topAnchor),
					imageView.bottomAnchor.constraint(equalTo: playGlyphView.bottomAnchor)
				])

				imageViewAttachmentMap.setObject(attachment, forKey: playGlyphView)
			}
			else
			{
				imageViewAttachmentMap.setObject(attachment, forKey: imageView)
			}
		}
	}

	func setMediaHidden(_ hideMedia: Bool, animated: Bool = true)
	{
		let imageViews = [firstImageView, secondImageView, thirdImageView, fourthImageView].compacted()

		coverView.setHidden(!hideMedia, animated: animated)
		(imageViews + previewAttachments).forEach({ $0.setHidden(hideMedia, animated: animated) })
	}

	private func setupCoverView()
	{
		view.addSubview(coverView)

		NSLayoutConstraint.activate([
			view.leftAnchor.constraint(equalTo: coverView.leftAnchor),
			view.rightAnchor.constraint(equalTo: coverView.rightAnchor),
			view.topAnchor.constraint(equalTo: coverView.topAnchor),
			view.bottomAnchor.constraint(equalTo: coverView.bottomAnchor)
		])
	}

	private func fetchImage(with url: URL, fallbackUrl: URL?, from attachment: Attachment, placingInto imageView: AttachmentImageView?)
	{
		resourcesFetcher.fetchImage(with: url)
		{
			[weak imageView, weak self] (result) in

			guard case .success(let image) = result else
			{
				DispatchQueue.main.async
					{
						imageView?.image = NSImage.previewErrorImage

						if let fallbackUrl = fallbackUrl
						{
							self?.fetchImage(with: fallbackUrl, fallbackUrl: nil,
											 from: attachment, placingInto: imageView)
						}
					}

				return
			}

			let finalImage: NSImage

			if image.pixelSize.area > NSSize(width: 1024, height: 1024).area
			{
				finalImage = image.resizedImage(withSize: NSSize(width: 1024, height: 1024))
			}
			else
			{
				finalImage = image
			}

			DispatchQueue.main.async
			{
				guard let self = self else
				{
					return
				}

				self.attachmentGroup.set(preview: finalImage, for: attachment)

				imageView?.image = finalImage
				imageView?.toolTip = attachment.description
				imageView?.setAccessibilityLabel(attachment.description)

				imageView?.target = self
				imageView?.action = #selector(AttachmentViewController.presentAttachment(_:))
			}
		}
	}

	@objc func presentAttachment(_ sender: Any?)
	{
		guard
			let control = sender as? NSControl ?? firstImageView,
			let window = control.window,
			let attachment = imageViewAttachmentMap.object(forKey: control),
			let attachmentPresenter = self.attachmentPresenter
		else
		{
			return
		}

		attachmentPresenter.present(attachment: attachment, from: attachmentGroup, senderWindow: window)
	}
}

protocol AttachmentPresenting: AnyObject
{
	func present(attachment: Attachment, from group: AttachmentGroup, senderWindow: NSWindow)
}
