//
//  AttachmentWindowController.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 23.01.19.
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
import AVKit
import MastodonKit
import CoreTootin

class AttachmentWindowController: NSWindowController, NSMenuItemValidation
{
	@IBOutlet private unowned var imageView: NSImageView!
	@IBOutlet private unowned var videoPlayerView: AVPlayerView!
	@IBOutlet private unowned var progressIndicator: NSProgressIndicator!
	@IBOutlet private unowned var buttonNext: NSButton!
	@IBOutlet private unowned var buttonPrevious: NSButton!
	@IBOutlet private unowned var shareButton: NSButton!
	@IBOutlet private unowned var shareMenu: NSMenu!
	@IBOutlet private unowned var shareShadowView: NSView!
	@IBOutlet private unowned var hoverView: CallbackHoverView!

	private let resourcesFetcher = ResourcesFetcher(urlSession: AppDelegate.shared.resourcesUrlSession)

	private var loadingTask: URLSessionTask? = nil
	private var attachmentGroup: IndexedAttachmentGroup? = nil

	private var playerLooper: AVPlayerLooper? = nil
	private var currentAttachment: (attachment: Attachment, image: NSImage)? = nil
	{
		didSet { playerLooper = nil }
	}

	private var attachmentsPendingWindowLoad: (Attachment, AttachmentGroup, NSWindow)? = nil

	override var windowNibName: NSNib.Name?
	{
		return "AttachmentWindowController"
	}

	override func windowDidLoad()
	{
		super.windowDidLoad()

		hoverView.mouseEntered =
			{
				[unowned self] in self.setControlsHidden(false)
			}

		hoverView.mouseExited =
			{
				[unowned self] in self.setControlsHidden(true)
			}

		if let (attachment, attachmentGroup, senderWindow) = attachmentsPendingWindowLoad
		{
			attachmentsPendingWindowLoad = nil
			set(attachment: attachment, attachmentGroup: attachmentGroup, senderWindow: senderWindow)
		}
	}

	func set(attachment: Attachment, attachmentGroup: AttachmentGroup, senderWindow: NSWindow)
	{
		guard isWindowLoaded else
		{
			attachmentsPendingWindowLoad = (attachment, attachmentGroup, senderWindow)
			return
		}

		guard let currentIndex = attachmentGroup.attachments.firstIndex(of: attachment) else
		{
			return
		}

		self.attachmentGroup = attachmentGroup.asIndexedGroup(initialIndex: currentIndex)

		repositionWindow(for: attachment, senderWindow: senderWindow)
		setCurrentAttachment(attachment, currentPreview: attachmentGroup.preview(for: attachment))
	}

	func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
		switch menuItem.action {
		case #selector(togglePresentableMediaVisible(_:)):
			menuItem.title = 🔠("status.action.media.close")
			return true

		case #selector(nextAttachment(_:)),
			 #selector(previousAttachment(_:)),
			 #selector(share(_:)),
			 #selector(saveToDownloads(_:)),
			 #selector(saveToLocation(_:)),
			 #selector(copyImage(_:)),
			 #selector(copyImageAddress(_:)),
			 #selector(openInBrowser(_:)):
			return true

		default:
			return false
		}
	}

	@IBAction
	func togglePresentableMediaVisible(_ sender: Any?) {
		close()
	}
}

private extension AttachmentWindowController
{
	func setControlsHidden(_ shouldHide: Bool)
	{
		let windowButtons = [NSWindow.ButtonType.closeButton, .miniaturizeButton, .zoomButton]
		for buttonType in windowButtons
		{
			guard let button = window?.standardWindowButton(buttonType) else { continue }
			button.setInvisible(shouldHide, animated: true)
			button.isEnabled = true
		}

		shareButton.setInvisible(shouldHide, animated: true)
		shareShadowView.setInvisible(shouldHide, animated: true)

		setNextPreviousButtonsHidden(shouldHide)
	}

	func setNextPreviousButtonsHidden(_ shouldHide: Bool)
	{
		guard !shouldHide else
		{
			buttonPrevious.setInvisible(true, animated: true)
			buttonNext.setInvisible(true, animated: true)
			return
		}

		guard let attachmentGroup = self.attachmentGroup else
		{
			return
		}

		let attachments = attachmentGroup.attachments
		let currentIsFirst = attachmentGroup.currentIndex == attachments.startIndex
		let currentIsLast = attachmentGroup.currentIndex == attachments.index(before: attachments.endIndex)

		buttonPrevious.setInvisible(currentIsFirst, animated: true)
		buttonNext.setInvisible(currentIsLast, animated: true)
	}

	func repositionWindow(for attachment: Attachment, senderWindow: NSWindow)
	{
		guard
			let window = window,
			let screen = senderWindow.screen,
			let imageSize = attachment.meta?.original?.size ?? attachmentGroup?.preview(for: attachment)?.size,
			imageSize.area > 0
		else
		{
			return
		}

		let visibleFrame = screen.visibleFrame
		let maxFrame = visibleFrame.insetBy(dx: visibleFrame.width * 0.1, dy: visibleFrame.height * 0.1)
		let finalSize = imageSize.area < maxFrame.size.area ? imageSize : imageSize.fitting(on: maxFrame.size)

		let finalFrame = NSRect(x: screen.frame.origin.x + (screen.frame.width - finalSize.width) * 0.5,
								y: screen.frame.origin.y + (screen.frame.height - finalSize.height) * 0.5,

								width: finalSize.width, height: finalSize.height)

		window.setFrame(finalFrame, display: true, animate: true)
	}

	func setCurrentAttachment(_ attachment: Attachment, currentPreview: NSImage?)
	{
		setNextPreviousButtonsHidden(false)

		currentAttachment = currentPreview.map({ (attachment, $0) })
		updateShareMenu(with: attachment, image: currentPreview)

		switch attachment.type
		{
		case .image:
			setImageAttachment(attachment, currentPreview: currentPreview)

		case .video:
			setVideoAttachment(attachment, currentPreview: currentPreview, shouldLoop: false)

		case .gifv:
			setVideoAttachment(attachment, currentPreview: currentPreview, shouldLoop: true)

		case .unknown:
			setFailedLoadingContent()
			break
		}
	}

	func setImageAttachment(_ attachment: Attachment, currentPreview: NSImage?)
	{
		videoPlayerView.isHidden = true
		imageView.isHidden = false

		guard let url = URL(string: attachment.remoteURL ?? attachment.url) else
		{
			imageView.image = #imageLiteral(resourceName: "missing")
			return
		}

		imageView.image = currentPreview ?? #imageLiteral(resourceName: "missing")
		imageView.toolTip = attachment.description

		let progressHandler: (Double) -> Void =
		{
			[weak progressIndicator] ratio in

			DispatchQueue.main.async
				{
					guard let indicator = progressIndicator else
					{
						return
					}

					if ratio >= 1
					{
						indicator.animator().isHidden = true
					}
					else
					{
						indicator.animator().doubleValue = ratio * 100
					}
			}
		}

		progressIndicator.doubleValue = 0
		progressIndicator.isHidden = false

		let taskPromise = Promise<URLSessionTask>()

		let task = resourcesFetcher.fetchImage(with: url, progress: progressHandler)
		{
			[weak self] result in

			DispatchQueue.main.async
				{
					// Check if we're still interested in the loaded image
					guard self?.loadingTask == taskPromise.value, let imageView = self?.imageView else
					{
						return
					}

					self?.loadingTask = nil

					switch result
					{
					case .success(let image):
						imageView.image = image
						self?.currentAttachment = (attachment, image)
						self?.updateShareMenu(with: attachment, image: image)

					case .failure(let error):
						guard (error as NSError).code != NSURLErrorCancelled else
						{
							break
						}

						fallthrough

					case .emptyResponse:
						imageView.image = #imageLiteral(resourceName: "missing")
					}
			}
		}

		taskPromise.value = task
		loadingTask = task
	}

	func setVideoAttachment(_ attachment: Attachment, currentPreview: NSImage?, shouldLoop: Bool)
	{
		videoPlayerView.isHidden = false
		imageView.isHidden = true

		guard let url = URL(string: attachment.remoteURL ?? attachment.url) else
		{
			setFailedLoadingContent()
			return
		}

		let player: AVPlayer

		if shouldLoop
		{
			let queuePlayer = AVQueuePlayer()
			playerLooper = AVPlayerLooper(player: queuePlayer, templateItem: AVPlayerItem(url: url))
			player = queuePlayer
		}
		else
		{
			player = AVPlayer(playerItem: AVPlayerItem(url: url))
		}

		videoPlayerView.player = player

		if Preferences.autoplayVideos
		{
			player.play()
		}
	}

	func setFailedLoadingContent()
	{
		videoPlayerView.isHidden = true
		imageView.isHidden = false

		imageView.image = NSImage.previewErrorImage
	}

	func updateShareMenu(with attachment: Attachment, image: NSImage?)
	{
		guard let shareItem = shareMenu.item(withTag: 1000) else
		{
			return
		}

		let bestUrl = attachment.bestUrl
		shareMenu.setSubmenu(ShareMenuFactory.shareMenu(for: bestUrl, previewImage: image), for: shareItem)
	}

	func writeImage(to url: URL)
	{
		guard
			let image = currentAttachment?.image,
			let fileType = currentAttachment?.attachment.parsedUrl.fileUTI
		else { return }

		do
		{
			try image.dataUsingRepresentation(for: fileType as CFString).write(to: url)
		}
		catch
		{
			presentError(error, modalFor: window!, delegate: nil, didPresent: nil, contextInfo: nil)
		}
	}
}

extension AttachmentWindowController
{
	@IBAction private func nextAttachment(_ sender: Any?)
	{
		guard
			let attachmentGroup = self.attachmentGroup,
			attachmentGroup.attachments.index(after: attachmentGroup.currentIndex) != attachmentGroup.attachments.endIndex
		else
		{
			return
		}


		let nextIndex = attachmentGroup.attachments.index(after: attachmentGroup.currentIndex)
		let nextAttachment = attachmentGroup.attachments[nextIndex]

		attachmentGroup.currentIndex = nextIndex
		setCurrentAttachment(nextAttachment, currentPreview: attachmentGroup.preview(for: nextAttachment))
	}

	@IBAction private func previousAttachment(_ sender: Any?)
	{
		guard
			let attachmentGroup = self.attachmentGroup,
			attachmentGroup.currentIndex != attachmentGroup.attachments.startIndex
			else
		{
			return
		}

		let previousIndex = attachmentGroup.attachments.index(before: attachmentGroup.currentIndex)
		let previousAttachment = attachmentGroup.attachments[previousIndex]

		attachmentGroup.currentIndex = previousIndex
		setCurrentAttachment(previousAttachment, currentPreview: attachmentGroup.preview(for: previousAttachment))
	}

	@IBAction private func share(_ sender: Any?)
	{
		let frame = shareButton.frame
		shareMenu.popUp(positioning: nil, at: NSPoint(x: frame.maxX, y: frame.midY), in: shareButton)
	}

	@IBAction private func saveToDownloads(_ sender: Any?)
	{
		guard let window = self.window, let fileName = currentAttachment?.attachment.parsedUrl.lastPathComponent else
		{
			return
		}

		do
		{
			let url = try FileManager.default.url(for: .downloadsDirectory, in: .userDomainMask,
												  appropriateFor: nil, create: true)

			writeImage(to: url.appendingPathComponent(fileName))
		}
		catch
		{
			presentError(error, modalFor: window, delegate: nil, didPresent: nil, contextInfo: nil)
		}
	}

	@IBAction private func saveToLocation(_ sender: Any?)
	{
		guard
			let window = self.window,
			let attachment = currentAttachment?.attachment,
			let fileType = attachment.parsedUrl.fileUTI
		else { return }

		let savePanel = NSSavePanel()
		savePanel.allowedFileTypes = [fileType]
		savePanel.nameFieldStringValue = attachment.parsedUrl.lastPathComponent
		savePanel.beginSheetModal(for: window)
		{
			[unowned self] (response) in

			if response == NSApplication.ModalResponse.OK, let url = savePanel.url
			{
				self.writeImage(to: url)
			}
		}
	}

	@IBAction private func copyImage(_ sender: Any?)
	{
		if let image = currentAttachment?.image
		{
			NSPasteboard.general.clearContents()
			NSPasteboard.general.writeObjects([image])
		}
	}

	@IBAction private func copyImageAddress(_ sender: Any?)
	{
		if let attachment = currentAttachment?.attachment
		{
			NSPasteboard.general.clearContents()
			NSPasteboard.general.writeObjects([attachment.bestUrl.absoluteString as NSString])
		}
	}

	@IBAction private func openInBrowser(_ sender: Any?)
	{
		if let attachment = currentAttachment?.attachment
		{
			NSPasteboard.general.clearContents()
			NSWorkspace.shared.open(attachment.bestUrl)
		}
	}
}

extension AttachmentWindowController: NSWindowDelegate
{
	func windowWillClose(_ notification: Foundation.Notification)
	{
		videoPlayerView.player?.pause()
		loadingTask?.cancel()
	}
}

class DraggingImageView: NSImageView
{
	override var mouseDownCanMoveWindow: Bool
	{
		return true
	}
}
